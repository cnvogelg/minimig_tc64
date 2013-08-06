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
		iec_srq_in : out std_logic
	);
end entity;
-- -----------------------------------------------------------------------

architecture rtl of chameleon_io is
-- MUX
	type muxstate_t is (
		-- Reset phase
		MUX_RESET,
		-- MMC
		MUX_MMC0L, MUX_MMC0H, MUX_MMC1L, MUX_MMC1H, MUX_MMC2L, MUX_MMC2H, MUX_MMC3L, MUX_MMC3H,
		MUX_MMC4L, MUX_MMC4H, MUX_MMC5L, MUX_MMC5H, MUX_MMC6L, MUX_MMC6H, MUX_MMC7L, MUX_MMC7H,
		-- IEC
		MUX_IEC1, MUX_IEC2, MUX_IEC3, MUX_IEC4,
		-- PS2
		MUX_PS2,
		-- LED
		MUX_LED,
		-- PHI=0
		MUX_WAIT0,
		MUX_A3_C, MUX_BUSVIC,
		MUX_D0VIC, MUX_D1VIC,
		MUX_NMIIRQ1, MUX_NMIIRQ2,
		MUX_ULTIMAX,
		MUX_END0,
		-- PHI=1
		MUX_WAIT1,
		MUX_BUS, MUX_CLKPORT,
		MUX_A0, MUX_A1, MUX_A2, MUX_A3,
		MUX_D0WR, MUX_D1WR, MUX_D0WR_1, MUX_D1WR_1, MUX_D0WR_2, MUX_D1WR_2,
		MUX_D0RD_1, MUX_D1RD_1, MUX_D0RD_2, MUX_D1RD_2
	);
	signal mux_state : muxstate_t;
	signal mux_toggle : std_logic := '0';

	signal mux_clk_reg : std_logic := '0';
	signal mux_d_reg : unsigned(mux_d'range) := X"F";
	signal mux_reg : unsigned(mux'range) := X"F";

-- IEC
	signal iec_clk_reg : std_logic := '1';
	signal iec_dat_reg : std_logic := '1';
	signal iec_atn_reg : std_logic := '1';
	signal iec_srq_reg : std_logic := '1';
begin

-- -----------------------------------------------------------------------
-- MUX CPLD
-- -----------------------------------------------------------------------
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
				mux_toggle <= not mux_toggle;
				case mux_state is
				when MUX_RESET   =>
					mux_state <= MUX_WAIT0;
-- PHI2  0
				when MUX_WAIT0   =>
					mux_state <= MUX_MMC0L;
				when MUX_MMC0L   => mux_state <= MUX_A3_C;
				when MUX_A3_C    => mux_state <= MUX_ULTIMAX;
				when MUX_ULTIMAX => mux_state <= MUX_MMC0H;
				when MUX_MMC0H   => mux_state <= MUX_BUSVIC;
				when MUX_BUSVIC  => mux_state <= MUX_IEC1;
				when MUX_IEC1    => mux_state <= MUX_MMC1L;
				when MUX_MMC1L   => mux_state <= MUX_PS2;
				when MUX_PS2     => mux_state <= MUX_A2;
				when MUX_A2      => mux_state <= MUX_MMC1H;
				when MUX_MMC1H   => mux_state <= MUX_NMIIRQ1;
				when MUX_NMIIRQ1 => mux_state <= MUX_LED;
				when MUX_LED     => mux_state <= MUX_MMC2L;
				when MUX_MMC2L   => mux_state <= MUX_A0;
				when MUX_A0      => mux_state <= MUX_IEC4;
				when MUX_IEC4    => mux_state <= MUX_MMC2H;
				when MUX_MMC2H   => mux_state <= MUX_A1;
				when MUX_A1      => mux_state <= MUX_D0VIC;
				when MUX_D0VIC   => mux_state <= MUX_D1VIC;
				when MUX_D1VIC   => mux_state <= MUX_MMC3L;
				when MUX_MMC3L   => mux_state <= MUX_IEC3;
				when MUX_IEC3    => mux_state <= MUX_MMC3H;
				when MUX_MMC3H   => mux_state <= MUX_END0;
				when MUX_END0    => mux_state <= MUX_WAIT1;
-- PHI2  1
				when MUX_WAIT1 =>
					mux_state <= MUX_MMC4L;
				when MUX_MMC4L   => mux_state <= MUX_BUS;
				when MUX_BUS     => mux_state <= MUX_D0WR;
				when MUX_D0WR    => mux_state <= MUX_D1WR;
				when MUX_D1WR    => mux_state <= MUX_MMC4H;
				when MUX_MMC4H   => mux_state <= MUX_A3;
				when MUX_A3      => mux_state <= MUX_CLKPORT;
				when MUX_CLKPORT => mux_state <= MUX_MMC5L;
				when MUX_MMC5L   => mux_state <= MUX_NMIIRQ2;
				when MUX_NMIIRQ2 => mux_state <= MUX_MMC5H;
				when MUX_MMC5H   => mux_state <= MUX_D0WR_1;
				when MUX_D0WR_1  => mux_state <= MUX_D1WR_1;
				when MUX_D1WR_1  => mux_state <= MUX_MMC6L;
				when MUX_MMC6L   => mux_state <= MUX_IEC2;
				when MUX_IEC2    => mux_state <= MUX_MMC6H;
				--when MUX_LED     => mux_state <= MUX_MMC6H;
				when MUX_MMC6H   => mux_state <= MUX_D0WR_2;
				when MUX_D0WR_2  => mux_state <= MUX_D1WR_2;
				when MUX_D1WR_2  => mux_state <= MUX_MMC7L;
				when MUX_MMC7L   => mux_state <= MUX_D0RD_1;
				when MUX_D0RD_1  => mux_state <= MUX_D1RD_1;
				when MUX_D1RD_1  => mux_state <= MUX_MMC7H;
				when MUX_MMC7H   => mux_state <= MUX_D0RD_2;
				when MUX_D0RD_2  => mux_state <= MUX_D1RD_2;
				when MUX_D1RD_2  => mux_state <= MUX_WAIT0;
				end case;
			end if;
		end if;
	end process;

	-- MUX read
	process(clk_mux)
	begin
		if rising_edge(clk_mux) then
			if mux_clk_reg = '1' then
				case mux_reg is
--				when X"0" =>
--					c64_data_reg(3 downto 0) <= mux_q;
--				when X"1" =>
--					c64_data_reg(7 downto 4) <= mux_q;
--				when X"6" =>
--					c64_reset_reg <= not mux_q(0);
--					c64_irq_n <= mux_q(2);
--					c64_nmi_n <= mux_q(3);
--					reset_pending <= reset; -- or c64_reset_reg;
--					if reset_pending = '0' then
--						reset_in <= c64_reset_reg;
--					else
--						reset_in <= '0';
--					end if;
				when X"7" =>
--					c64_ba_reg <= mux_q(1);
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
			if mux_clk_reg = '1' then
				case mux_state is
--
-- RESET
				when MUX_RESET =>
					mux_d_reg <= (others => '-');
					mux_reg <= X"F";
--
-- MMC
				when MUX_MMC0L =>
                    -- CV: raw spi
					mux_d_reg(0) <= spi_raw_clk;
					mux_d_reg(1) <= spi_raw_mosi;
					mux_d_reg(2) <= mmc_cs_n; 
					mux_d_reg(3) <= to_usb_rx;
					mux_reg <= X"C";
					spi_raw_ack <= '1';
				when MUX_MMC1L | MUX_MMC2L | MUX_MMC3L
				   | MUX_MMC4L | MUX_MMC5L | MUX_MMC6L | MUX_MMC7L =>
                   -- CV: raw spi
					mux_d_reg(0) <= spi_raw_clk;
					mux_d_reg(1) <= spi_raw_mosi;
					mux_d_reg(2) <= mmc_cs_n;
					mux_d_reg(3) <= to_usb_rx;
					mux_reg <= X"C";
					spi_raw_ack <= '1';

				when MUX_MMC0H | MUX_MMC1H | MUX_MMC2H | MUX_MMC3H
				   | MUX_MMC4H | MUX_MMC5H | MUX_MMC6H | MUX_MMC7H =>
                   -- CV: raw spi
					mux_d_reg(0) <= spi_raw_clk;
					mux_d_reg(1) <= spi_raw_mosi;
					mux_d_reg(2) <= mmc_cs_n;
					mux_d_reg(3) <= to_usb_rx;
					mux_reg <= X"C";
					spi_raw_ack <= '1';
				when MUX_NMIIRQ1 | MUX_NMIIRQ2=>
					mux_d_reg <= "110" & (not reset);
					mux_reg <= X"6";
--
-- IEC
				when MUX_IEC1 | MUX_IEC2 | MUX_IEC3 | MUX_IEC4 =>
					mux_d_reg(0) <= iec_dat_out;
					mux_d_reg(1) <= iec_clk_out;
					mux_d_reg(2) <= iec_srq_out;
					mux_d_reg(3) <= iec_atn_out;
					mux_reg <= X"D";
--
-- USART, LEDs and IR
				when MUX_LED =>
					mux_d_reg <= flash_cs_n & rtc_cs & led_green & led_red;
					mux_reg <= X"B";
--
-- PS2
				when MUX_PS2 =>
					mux_d_reg(0) <= ps2_keyboard_dat_out;
					mux_d_reg(1) <= ps2_keyboard_clk_out;
					mux_d_reg(2) <= ps2_mouse_dat_out;
					mux_d_reg(3) <= ps2_mouse_clk_out;
					mux_reg <= X"E";
--
-- WAITS
				when MUX_WAIT0 =>
					-- Use dead time to do IEC reads/writes
                    -- CV: raw_spi
					mux_d_reg(0) <= spi_raw_clk;
					mux_d_reg(1) <= spi_raw_mosi;
					mux_d_reg(2) <= mmc_cs_n;
					mux_d_reg(3) <= to_usb_rx;
					mux_reg <= X"C";
					spi_raw_ack <= '1';
				when MUX_WAIT1 =>
					-- Continue BUSVIC output at end of phi2=0, so we sample BA a few times.
					mux_d_reg <= "0101";
					mux_reg <= X"7";
					-- Toggle between SPI/IEC and updating BUSVIC.
					if mux_toggle = '1' then
						mux_d_reg(0) <= spi_raw_clk;
						mux_d_reg(1) <= spi_raw_mosi;
						mux_d_reg(2) <= mmc_cs_n;
						mux_d_reg(3) <= to_usb_rx;
						mux_reg <= X"C";
						spi_raw_ack <= '1';
					end if;
--
-- PHI2  0
				when MUX_A3_C =>
					mux_d_reg <= X"C";
					mux_reg <= X"5";
				when MUX_BUSVIC =>
					mux_d_reg <= "0101";
					mux_reg <= X"7";
				when MUX_ULTIMAX =>
					mux_d_reg <= "1011";
					mux_reg <= X"8";
				when MUX_D0VIC =>
--					mux_d_reg <= c64_to_io(3 downto 0);
					mux_reg <= X"0";
				when MUX_D1VIC =>
--					mux_d_reg <= c64_to_io(7 downto 4);
					mux_reg <= X"1";
				when MUX_END0 =>
					mux_d_reg <= "0111";
					mux_reg <= X"7";
--
-- PHI2  1
				when MUX_A0 =>
--					mux_d_reg <= c64_addr(3 downto 0);
					mux_reg <= X"2";
				when MUX_A1 =>
--					mux_d_reg <= c64_addr(7 downto 4);
					mux_reg <= X"3";
				when MUX_A2 =>
--					mux_d_reg <= c64_addr(11 downto 8);
					mux_reg <= X"4";
				when MUX_BUS =>
--					if c64_vic_loc = '0' then
--						if c64_cs_loc = '1' then
--							mux_d_reg <= "00" & (not c64_we_loc) & (not c64_we_loc);
--							mux_reg <= X"7";
--						end if;
--					else
						-- A15..12 driven, A11..0 not driven, Data driven, no write.
						mux_d_reg <= "0101";
						mux_reg <= X"7";
--					end if;
				when MUX_CLKPORT =>
					-- GAME = low unless accessing roms
					mux_d_reg <= "1011";
--					if c64_clockport_loc = '1' then
--						if c64_we_loc = '0' then
--							-- Clockport read
--							mux_d_reg <= "1010";
--						else
--							-- Clockport write
--							mux_d_reg <= "1001";
--						end if;
--					end if;
					mux_reg <= X"8";
--				when MUX_A3 =>
--					if c64_vic_loc = '0' then
--						if c64_cs_loc = '1' then
--							mux_d_reg <= c64_addr(15 downto 12);
--							mux_reg <= X"5";
--						end if;
--					end if;
--				when MUX_D0WR | MUX_D0WR_1 | MUX_D0WR_2 =>
				when MUX_D0WR | MUX_D0WR_1 | MUX_D0WR_2 | MUX_D0RD_1 | MUX_D0RD_2 =>
--					mux_d_reg <= c64_to_io(3 downto 0);
					mux_reg <= X"0";
--				when MUX_D1WR | MUX_D1WR_1 | MUX_D1WR_2 =>
				when MUX_D1WR | MUX_D1WR_1 | MUX_D1WR_2 | MUX_D1RD_1 | MUX_D1RD_2 =>
--					mux_d_reg <= c64_to_io(7 downto 4);
					mux_reg <= X"1";
				when others =>
					null;
				end case;
			end if;
		end if;
	end process;

	mux_clk <= mux_clk_reg;
	mux_d <= mux_d_reg;
	mux <= mux_reg;
end architecture;
