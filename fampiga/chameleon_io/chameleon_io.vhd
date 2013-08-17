-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Multi purpose FPGA expansion for the Commodore 64 computer
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2013 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--
-- -----------------------------------------------------------------------
--
-- For better understanding what this entity does in detail, please refer
-- to the Chameleon core-developers manual. It has documentation about
-- the CPLD MUX, signal timing, docking-station protocol and the cartridge port access.
--
-- Chameleon timing and I/O driver. Handles all the timing and multiplexing
-- details of the cartridge port and the CPLD mux.
--   - Detects the type of mode the chameleon is running in.
--   - Multiplexes the PS/2 keyboard and mouse signals.
--   - Gives access to joysticks and keyboard on a C64 in cartridge mode.
--   - Gives access to joysticks and keyboard on a docking-station
--   - Gives access to MMC card and serial-flash through the CPLD MUX.
--   - Drives the two LEDs on the Chameleon (or an optional Amiga keyboard).
--   - Can optionally give access to the IEC bus
--   - Can optionally give access to other C64 resources like the SID.
--
-- -----------------------------------------------------------------------
-- clk             - system clock
-- reset           - Perform a reset of the subsystems
-- to_usb_rx
--
-- led_green       - Control the green LED (0 off, 1 on). Also power LED on Amiga keyboard.
-- led_red         - Control the red LED (0 off, 1 on). Also drive LED on Amiga keyboard.
-- ir              - ir signal. Input for the chameleon_cdtv_remote entity.
--
-- ps2_*           - PS2 signals for both keyboard and mouse.
-- button_reset_n  - Status of blue reset button (right button) on the Chameleon. Low active.
-- iec_*           - IEC signals. Only valid when enable_iec_access is set to true.
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- -----------------------------------------------------------------------

entity chameleon_io is
    generic (
        enable_iec_access : boolean := false
    );
    port (
-- Clocks
        clk : in std_logic;
        clk_mux : in std_logic;
        reset : in std_logic;

-- Chameleon FPGA pins
        -- C64 Clocks
        phi2_n : in std_logic;
        dotclock_n : in std_logic;
        -- C64 cartridge control lines
        io_ef_n : in std_logic;
        rom_lh_n : in std_logic;
        -- SPI bus
        spi_miso : in std_logic;
        -- CPLD multiplexer
        mux_clk : out std_logic;
        mux : out unsigned(3 downto 0);
        mux_d : out unsigned(3 downto 0);
        mux_q : in unsigned(3 downto 0);

-- USB microcontroller (To RX of micro)
        to_usb_rx : in std_logic := '1';

-- SPI chip-selects
        mmc_cs_n : in std_logic := '1';
        flash_cs_n : in std_logic := '1';
        rtc_cs : in std_logic := '0';

-- SPI raw signals (enable_raw_spi must be set to true)
        spi_raw_clk : in std_logic := '1';
        spi_raw_mosi : in std_logic := '1';
        spi_raw_ack : out std_logic;  -- Added by AMR
        
-- LEDs
        led_green : in std_logic := '0';
        led_red : in std_logic := '0';
        ir : out std_logic;

-- PS/2 Keyboard
        ps2_keyboard_clk_out: in std_logic := '1';
        ps2_keyboard_dat_out: in std_logic := '1';
        ps2_keyboard_clk_in: out std_logic;
        ps2_keyboard_dat_in: out std_logic;

-- PS/2 Mouse
        ps2_mouse_clk_out: in std_logic := '1';
        ps2_mouse_dat_out: in std_logic := '1';
        ps2_mouse_clk_in: out std_logic;
        ps2_mouse_dat_in: out std_logic;

-- Buttons
        button_reset_n : out std_logic;

-- IEC bus
        iec_clk_out : in std_logic := '1';
        iec_dat_out : in std_logic := '1';
        iec_atn_out : in std_logic := '1';
        iec_srq_out : in std_logic := '1';
        iec_clk_in : out std_logic;
        iec_dat_in : out std_logic;
        iec_atn_in : out std_logic;
        iec_srq_in : out std_logic;
        
-- clockport
        cp_req : in std_logic := '0'; -- one mux_clk 1 -> perform clockport op
        cp_ack : out std_logic; -- one mux_clk 1 -> op is done
        cp_wr : in std_logic := '0'; -- 1=write 0=read op
        cp_dat_d : in unsigned(7 downto 0) := (others => '0'); -- cp data in
        cp_dat_q : out unsigned(7 downto 0);
        cp_addr : in unsigned(3 downto 0) := (others => '0');     
        cp_irq : out std_logic -- one mux_clk 1 -> irq detect
    );
end entity;
-- -----------------------------------------------------------------------

architecture rtl of chameleon_io is
-- MUX

    -- we split the mux_clk of 113.45/2 MHz into 3 phases
    -- 1. SPI/USART updates (18.9 MHz > 2 * 8 MHz SPI clk)
    -- 2. MISC: PS2, LED/BUTTON, IEC
    -- 3. CLKPORT: run clock port state
    type muxphase_t is (
        MUX_SPI,
        MUX_MISC,
        MUX_CLKPORT
    );

    type miscstate_t is (
        MISC_PS2,
        MISC_LED,
        MISC_IEC
    );
    
    type cpstate_t is (
        -- init states
        CP_INIT1,
        CP_INIT2,
        CP_INIT3,
        -- idle states
        CP_IDLE,
        -- read sequence
        CP_READ_ADDR,
        CP_READ_OE_BEGIN,
        CP_READ_IOR_BEGIN,
        CP_READ_WS,
        CP_READ_D03,
        CP_READ_D47,
        CP_READ_IOR_END,
        CP_READ_OE_END,
        -- write sequence
        CP_WRITE_ADDR,
        CP_WRITE_OE_BEGIN,
        CP_WRITE_D03,
        CP_WRITE_D47,
        CP_WRITE_IOW_BEGIN,
        CP_WRITE_WS,
        CP_WRITE_IOW_END,
        CP_WRITE_OE_END
    );

    signal mux_phase : muxphase_t;
    signal misc_state : miscstate_t;
    signal cp_state : cpstate_t;

    signal mux_clk_reg : std_logic := '0';
    signal mux_d_reg : unsigned(mux_d'range) := X"F";
    signal mux_reg : unsigned(mux'range) := X"F";

-- IEC
    signal iec_clk_reg : std_logic := '1';
    signal iec_dat_reg : std_logic := '1';
    signal iec_atn_reg : std_logic := '1';
    signal iec_srq_reg : std_logic := '1';

-- clockport
    signal cp_busy_reg : std_logic := '0';
    signal cp_ack_reg : std_logic := '0';
    signal cp_wr_reg : std_logic := '0';
    signal cp_addr_reg : unsigned(3 downto 0);
    signal cp_dat_d_reg : unsigned(7 downto 0);
    signal cp_dat_q_reg : unsigned(7 downto 0) := X"00";
    
    signal cp_ws_count : unsigned(3 downto 0);
begin

    cp_ack <= cp_ack_reg;
    cp_dat_q <= cp_dat_q_reg;
    
    -- accept request for op and store it
    process(clk_mux)
    begin
        if rising_edge(clk_mux) then
            if reset = '1' then
                cp_busy_reg <= '0';
            else
                -- if no op is currently active then accept op request
                if cp_busy_reg = '0' then
                    cp_busy_reg <= cp_req;
                    cp_wr_reg <= cp_wr;
                    cp_dat_d_reg <= cp_dat_d;
                    cp_addr_reg <= cp_addr;
                else 
                    -- end of op
                    if cp_ack_reg = '1' then
                        cp_busy_reg <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ---- mux -----

    -- MUX clock
    process(clk_mux)
    begin
        if rising_edge(clk_mux) then
            mux_clk_reg <= not mux_clk_reg;
        end if;
    end process;

    -- MUX sequence
    process(clk_mux)
    begin
        if rising_edge(clk_mux) then
            if mux_clk_reg = '1' then
                --- phase states
                case mux_phase is
                    when MUX_SPI =>     mux_phase <= MUX_MISC;
                    when MUX_MISC =>    mux_phase <= MUX_CLKPORT;
                    when MUX_CLKPORT => mux_phase <= MUX_SPI;
                    when others =>      mux_phase <= MUX_SPI;
                end case;
                --- misc states
                if mux_phase = MUX_MISC then
                    case misc_state is
                        when MISC_PS2 => misc_state <= MISC_LED;
                        when MISC_LED => misc_state <= MISC_IEC;
                        when MISC_IEC => misc_state <= MISC_PS2;
                        when others =>   misc_state <= MISC_PS2;
                    end case;
                end if;
                --- clockport stats
                if mux_phase = MUX_CLKPORT then
                    case cp_state is
                        when CP_INIT1 => cp_state <= CP_INIT2;
                        when CP_INIT2 => cp_state <= CP_INIT3;
                        when CP_INIT3 => cp_state <= CP_IDLE;
                        -- idle
                        when CP_IDLE =>
                            cp_state <= CP_IDLE;
                            -- is a request pending?
                            if cp_busy_reg = '1' then
                                if cp_wr_reg = '1' then
                                    cp_state <= CP_WRITE_ADDR;
                                else
                                    cp_state <= CP_READ_ADDR;
                                end if;
                            end if;
                        -- ----- read cycle -----
                        when CP_READ_ADDR => cp_state <= CP_READ_OE_BEGIN;
                        when CP_READ_OE_BEGIN => cp_state <= CP_READ_IOR_BEGIN;
                        when CP_READ_IOR_BEGIN => 
                            cp_ws_count <= (others => '0');
                            cp_state <= CP_READ_WS;
                        when CP_READ_WS => 
                            if cp_ws_count = "0100" then -- wait states (52ns per count)
                                cp_state <= CP_READ_D03;
                            else
                                cp_ws_count <= cp_ws_count + 1;
                            end if;
                        when CP_READ_D03 => cp_state <= CP_READ_D47;
                        when CP_READ_D47 => cp_state <= CP_READ_IOR_END;
                        when CP_READ_IOR_END => cp_state <= CP_READ_OE_END;
                        when CP_READ_OE_END => cp_state <= CP_IDLE;
                        -- ----- write cycle -----
                        when CP_WRITE_ADDR => cp_state <= CP_WRITE_D03;
                        when CP_WRITE_D03 => cp_state <= CP_WRITE_D47;
                        when CP_WRITE_D47 => cp_state <= CP_WRITE_OE_BEGIN;
                        when CP_WRITE_OE_BEGIN => cp_state <= CP_WRITE_IOW_BEGIN;
                        when CP_WRITE_IOW_BEGIN => 
                            cp_ws_count <= (others => '0');
                            cp_state <= CP_WRITE_WS;
                        when CP_WRITE_WS => 
                            if cp_ws_count = "0100" then -- wait states (52ns per count)
                                cp_state <= CP_WRITE_IOW_END;
                            else
                                cp_ws_count <= cp_ws_count + 1;
                            end if;
                        when CP_WRITE_IOW_END => cp_state <= CP_WRITE_OE_END;
                        when CP_WRITE_OE_END => cp_state <= CP_IDLE;
                        when others =>   cp_state <= CP_INIT1;
                    end case;
                end if;
            end if;
        end if;
    end process;

    -- MUX read
    process(clk_mux)
    begin
        if rising_edge(clk_mux) then
            if mux_clk_reg = '1' then
                case mux_reg is
                when X"0" =>
                    cp_dat_q_reg(3 downto 0) <= mux_q;
                when X"1" =>
                    cp_dat_q_reg(7 downto 4) <= mux_q;
                when X"6" =>
                    cp_irq <= not mux_q(3); -- nmi_n
                when X"B" =>
                    button_reset_n <= mux_q(1);
                    ir <= mux_q(3);
                when X"D" =>
                    iec_dat_reg <= mux_q(0);
                    iec_clk_reg <= mux_q(1);
                    iec_srq_reg <= mux_q(2);
                    iec_atn_reg <= mux_q(3);
                when X"E" =>
                    ps2_keyboard_dat_in <= mux_q(0);
                    ps2_keyboard_clk_in <= mux_q(1);
                    ps2_mouse_dat_in <= mux_q(2);
                    ps2_mouse_clk_in <= mux_q(3);
                when others =>
                    null;
                end case;
            end if;
            iec_dat_in <= iec_dat_reg;
            iec_clk_in <= iec_clk_reg;
            iec_srq_in <= iec_srq_reg;
            iec_atn_in <= iec_atn_reg;
        end if;
    end process;

    -- MUX write
    process(clk_mux)
    begin
        if rising_edge(clk_mux) then
            spi_raw_ack <= '0';
            cp_ack_reg <= '0';
            if mux_clk_reg = '1' then
                case mux_phase is
-- SPI
                when MUX_SPI =>
                    mux_d_reg(0) <= spi_raw_clk;
                    mux_d_reg(1) <= spi_raw_mosi;
                    mux_d_reg(2) <= mmc_cs_n; 
                    mux_d_reg(3) <= to_usb_rx;
                    mux_reg <= X"C";
                    spi_raw_ack <= '1';
-- MISC
                when MUX_MISC =>
                    case misc_state is
                        when MISC_LED =>
                            mux_d_reg <= flash_cs_n & rtc_cs & led_green & led_red;
                            mux_reg <= X"B";
                        when MISC_PS2 =>        
                            mux_d_reg(0) <= ps2_keyboard_dat_out;
                            mux_d_reg(1) <= ps2_keyboard_clk_out;
                            mux_d_reg(2) <= ps2_mouse_dat_out;
                            mux_d_reg(3) <= ps2_mouse_clk_out;
                            mux_reg <= X"E";
                        when MISC_IEC =>
                            mux_d_reg(0) <= iec_dat_out;
                            mux_d_reg(1) <= iec_clk_out;
                            mux_d_reg(2) <= iec_srq_out;
                            mux_d_reg(3) <= iec_atn_out;
                            mux_reg <= X"D";                            
                    end case;
-- clockport
                when MUX_CLKPORT =>
                    case cp_state is
                        -- init
                        when CP_INIT1 =>
                            mux_reg <= X"3"; -- A07 .. A04
                            mux_d_reg <= X"0";        
                        when CP_INIT2 =>
                            mux_reg <= X"4"; -- A11 .. A08
                            mux_d_reg <= X"e";        
                        when CP_INIT3 =>
                            mux_reg <= X"5"; -- A15 .. A12
                            mux_d_reg <= X"d";
                        -- idle states
                        when CP_IDLE =>
                            mux_d_reg <= "1101"; -- disable irq, reset, enable dma
                            mux_reg <= X"6";
                        -- read sequence
                        when CP_READ_ADDR =>
                            mux_d_reg <= cp_addr_reg;
                            mux_reg <= X"2";
                        when CP_READ_OE_BEGIN =>
                            mux_d_reg <= "0011"; -- /OE A0..A11 enable, /OE D0..D7 disable
                            mux_reg <= X"7";
                        when CP_READ_IOR_BEGIN =>
                            mux_d_reg <= "0010"; -- /IOR enable
                            mux_reg <= X"8"; 
                        when CP_READ_WS =>
                            mux_d_reg <= "----"; -- idle
                            mux_reg <= X"F";
                        when CP_READ_D03 =>
                            mux_d_reg <= "0000"; -- dummy?
                            mux_reg <= X"0"; 
                        when CP_READ_D47 =>
                            mux_d_reg <= "0000"; -- dummy?
                            mux_reg <= X"1"; 
                        when CP_READ_IOR_END =>
                            mux_d_reg <= "0011"; -- /IOR, /IOW disable
                            mux_reg <= X"8";
                        when CP_READ_OE_END =>
                            mux_d_reg <= "1111"; -- disable all /OE
                            mux_reg <= X"7";
                            cp_ack_reg <= '1';
                        -- write sequence
                        when CP_WRITE_ADDR =>
                            mux_d_reg <= cp_addr_reg;
                            mux_reg <= X"2";
                        when CP_WRITE_D03 =>
                            mux_d_reg <= cp_dat_d_reg(3 downto 0);
                            mux_reg <= X"0"; 
                        when CP_WRITE_D47 =>
                            mux_d_reg <= cp_dat_d_reg(7 downto 4);
                            mux_reg <= X"1"; 
                        when CP_WRITE_OE_BEGIN =>
                            mux_d_reg <= "0000"; -- /OE A0..A11 enable /OE D0..D7 enable
                            mux_reg <= X"7";
                        when CP_WRITE_IOW_BEGIN =>
                            mux_d_reg <= "0001"; -- /IOW enable
                            mux_reg <= X"8"; 
                        when CP_WRITE_WS =>
                            mux_d_reg <= "----"; -- idle
                            mux_reg <= X"F";
                        when CP_WRITE_IOW_END =>
                            mux_d_reg <= "0011"; -- /IOR, /IOW disable
                            mux_reg <= X"8";
                        when CP_WRITE_OE_END =>
                            mux_d_reg <= "1111"; -- disable all /OE
                            mux_reg <= X"7";
                            cp_ack_reg <= '1';
                    end case;
                end case;
            end if;
        end if;
    end process;

    mux_clk <= mux_clk_reg;
    mux_d <= mux_d_reg;
    mux <= mux_reg;
end architecture;
