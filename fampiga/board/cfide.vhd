------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2008-2011 Tobias Gubener                                   -- 
-- Subdesign fAMpIGA by TobiFlex                                            --
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU General Public License as published        --
-- by the Free Software Foundation, either version 3 of the License, or     --
-- (at your option) any later version.                                      --
--                                                                          --
-- This source file is distributed in the hope that it will be useful,      --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
-- GNU General Public License for more details.                             --
--                                                                          --
-- You should have received a copy of the GNU General Public License        --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------
 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

 
entity cfide is
   port ( 
-- MUX CPLD
	mux_clk : out std_logic;
	mux : out unsigned(3 downto 0);
	mux_d : out unsigned(3 downto 0);
	mux_q : in unsigned(3 downto 0);
	sysclk: in std_logic;	
	n_reset: in std_logic;	
	cpuena_in: in std_logic;			
	memdata_in: in std_logic_vector(15 downto 0);		
	addr: in std_logic_vector(23 downto 0);		
	cpudata_in: in std_logic_vector(15 downto 0);	
	state: in std_logic_vector(1 downto 0);		
	lds: in std_logic;			
	uds: in std_logic;			
	sd_di		: in std_logic;
		
	memce: out std_logic;			
	cpudata: out std_logic_vector(15 downto 0);		
	cpuena: buffer std_logic;			
	TxD: out std_logic;			
	sd_cs 		: out std_logic_vector(7 downto 0);
	sd_clk 		: out std_logic;
	sd_do		: out std_logic;
	sd_dimm		: in std_logic;		--for sdcard
	enaWRreg    : in std_logic:='1';
	
	kb_clki: in std_logic;
	kb_datai: in std_logic;
	ms_clki: in std_logic;
	ms_datai: in std_logic;
	kb_clk: out std_logic;
	kb_data: out std_logic;
	ms_clk: out std_logic;
	ms_data: out std_logic;
	nreset: out std_logic;
	ir: buffer std_logic;
	ena1MHz: buffer std_logic; -- Needed by CDTV controller unit
	irq_d: in std_logic :='1';
	led: in std_logic_vector(1 downto 0);

	amiser_txd: in std_logic;	-- CV: amiga serial txd		
	amiser_rxd: out std_logic;  -- CV: amiga serial rxd

-- USART
	usart_clk : in std_logic;
	usart_rts : in std_logic;
	fastramsize : out std_logic_vector(2 downto 0);
	turbochipram : out std_logic;
--	reconfigure: in std_logic	-- reset Chameleon to core 0	

	phi2_n : in std_logic;
	dotclock_n : in std_logic;
	io_ef_n : in std_logic;
	rom_lh_n : in std_logic;
	joystick1 : out unsigned(5 downto 0);
	joystick2 : out unsigned(5 downto 0);
	joystick3 : out unsigned(5 downto 0);
	joystick4 : out unsigned(5 downto 0);
	scandoubler : out std_logic;
	freeze_n : in std_logic;
	menu_n : in std_logic
   );

end cfide;


architecture wire of cfide is

	COMPONENT startram
    PORT 
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		byteena		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
	END COMPONENT;




signal shift: std_logic_vector(9 downto 0);
signal clkgen: unsigned(9 downto 0);
signal shiftout: std_logic;
signal txbusy: std_logic;
signal ld: std_logic;
signal rs232_select: std_logic;
signal KEY_select: std_logic;
signal PART_select: std_logic;
signal SPI_select: std_logic;
signal ROM_select: std_logic;
signal RAM_write: std_logic;
signal rs232data: std_logic_vector(15 downto 0);
signal part_in: std_logic_vector(15 downto 0);
signal IOdata: std_logic_vector(15 downto 0);
signal IOcpuena: std_logic;

--type micro_states is (idle, io_aktion, ide1, set_addr, set_data1, set_data2, set_data3, read1, read2, read3, read4, waitclose, setwaitend, waitend);
--signal micro_state		: micro_states;
--signal next_micro_state		: micro_states;

type support_states is (idle, io_aktion);
signal support_state		: support_states;
signal next_support_state		: support_states;

signal sd_out	: std_logic_vector(15 downto 0);
signal sd_in	: std_logic_vector(15 downto 0);
signal sd_in_shift	: std_logic_vector(15 downto 0);
signal sd_di_in	: std_logic;
--signal spi_word	: std_logic;
signal shiftcnt	: unsigned(13 downto 0);
signal sck		: std_logic;
signal scs		: std_logic_vector(7 downto 0);
signal dscs		: std_logic;
signal SD_busy		: std_logic;
signal spi_div: unsigned(7 downto 0);
signal spi_speed: unsigned(7 downto 0);
signal rom_data: std_logic_vector(15 downto 0);
signal spi_raw_ack : std_logic;
signal spi_wait : std_logic;
signal spi_wait_d : std_logic;

signal timecnt: unsigned(15 downto 0);
signal timeprecnt: unsigned(15 downto 0);

--signal led_green	 : std_logic;
--signal led_red	 : std_logic;
--signal ir	 : std_logic;
signal enacnt: unsigned(6 downto 0);

signal usart_rx : std_logic :='1';

signal freeze_n_r : std_logic;
signal menu_n_r : std_logic;
signal freeze_n_r2 : std_logic;
signal menu_n_r2 : std_logic;

-- MUX
	signal mux_clk_reg : std_logic := '0';
	signal mux_reg : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_regd : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_d_reg : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_d_regd : std_logic_vector(3 downto 0) := (others => '1');

signal reconfigure : std_logic :='0';

signal slower : std_logic_vector(2 downto 0);
	
-- C64 IO signals

signal button_reset_n : std_logic;

signal no_clock : std_logic;
signal docking_station : std_logic;
signal c64_keys : unsigned(63 downto 0);
signal c64_restore_key_n : std_logic;
signal c64_nmi_n : std_logic;
signal c64_joy1 : unsigned(5 downto 0);
signal c64_joy2 : unsigned(5 downto 0);


begin

-- Synchronise buttons.
process(sysclk)
begin
	if rising_edge(sysclk) then
		freeze_n_r2 <= freeze_n;
		freeze_n_r <= freeze_n_r2;
		menu_n_r2 <= menu_n;
		menu_n_r <= menu_n_r2;
	end if;
end process;


-- Reset circuit

	myReset : entity work.gen_reset
		generic map (
			resetCycles => 131071
		)
		port map (
			clk => sysclk,
			enable => '1',
			button => not button_reset_n,
			nreset => nreset
		);


-- Reverse order of direction signals.
joystick1<=c64_joy1(5 downto 4)&c64_joy1(0)&c64_joy1(1)&c64_joy1(2)&c64_joy1(3);
joystick2<=c64_joy2(5 downto 4)&c64_joy2(0)&c64_joy2(1)&c64_joy2(2)&c64_joy2(3);

-- C64 IO
-- FIXME - re-enable RS232-over-IEC

	myIO : entity work.chameleon_io
		generic map (
			enable_docking_station => true,
			enable_c64_joykeyb => true,
			enable_c64_4player => true,
			enable_raw_spi => true
		)
		port map (
		-- Clocks
			clk => sysclk,	-- present
			clk_mux => sysclk, -- present
			ena_1mhz => ena1Mhz, -- present
			reset => not n_reset, -- present, but inverted
			
			no_clock => no_clock,  -- output
			docking_station => docking_station, -- output
			
		-- Chameleon FPGA pins
			-- C64 Clocks
			phi2_n => phi2_n,
			dotclock_n => dotclock_n, 
			-- C64 cartridge control lines
			io_ef_n => io_ef_n,
			rom_lh_n => rom_lh_n,
			-- SPI bus
			spi_miso => sd_dimm,  -- present
			-- CPLD multiplexer
			mux_clk => mux_clk,  -- present
			mux => mux,  -- present
			mux_d => mux_d,  -- present
			mux_q => mux_q,  -- present
			
			to_usb_rx => usart_rx,

		-- SPI raw signals (enable_raw_spi must be set to true)
			mmc_cs_n => NOT scs(1),
			spi_raw_clk => NOT sck,
			spi_raw_mosi => sd_out(15),
			spi_raw_ack => spi_raw_ack,

		-- LEDs
			led_green => led(0),  -- present
			led_red => led(1),  -- present
			ir => ir,  -- present
		
		-- PS/2 Keyboard
			ps2_keyboard_clk_out => kb_clki, -- present
			ps2_keyboard_dat_out => kb_datai, -- present
			ps2_keyboard_clk_in => kb_clk, -- present
			ps2_keyboard_dat_in => kb_data, -- present
	
		-- PS/2 Mouse
			ps2_mouse_clk_out => ms_clki, -- present
			ps2_mouse_dat_out => ms_datai, -- present
			ps2_mouse_clk_in => ms_clk, -- present
			ps2_mouse_dat_in => ms_data, -- present

		-- Buttons
			button_reset_n => button_reset_n, -- present (nreset)

		-- Joysticks
			joystick1 => c64_joy1,
			joystick2 => c64_joy2,
			joystick3 => joystick3, 
			joystick4 => joystick4,

		-- Keyboards
			keys => c64_keys,	-- missing - how to map?  Array, readable in software?
			restore_key_n => c64_restore_key_n, -- missing
			c64_nmi_n => c64_nmi_n -- missing			
		);


srom: startram
	PORT MAP 
	(
		address => addr(11 downto 1),	--: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		byteena(0)	=> not lds,			--	: IN STD_LOGIC_VECTOR (1 DOWNTO 0),
		byteena(1)	=> not uds,			--	: IN STD_LOGIC_VECTOR (1 DOWNTO 0),
		clock   => sysclk,								--: IN STD_LOGIC ;
		data	=> cpudata_in,		--	: IN STD_LOGIC_VECTOR (15 DOWNTO 0),
		wren	=> RAM_write AND enaWRreg,		-- 	: IN STD_LOGIC ,
		q		=> rom_data									--: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );


-- Slow down accesses
process(sysclk, cpuena)
begin
	if rising_edge(sysclk) then
		slower<='0'&slower(2 downto 1);
		if cpuena='1' then
			slower<="111";
		end if;	
	end if;
end process;

memce <= slower(0) WHEN ROM_select='0' AND addr(23)='0' ELSE '1';
--memce <= '0' WHEN ROM_select='0' AND addr(23)='0' ELSE '1';

cpudata <=  rom_data WHEN ROM_select='1' ELSE 
			IOdata WHEN IOcpuena='1' ELSE
			part_in WHEN PART_select='1' ELSE 
			memdata_in;
part_in <= 
			std_logic_vector(timecnt) WHEN addr(4 downto 1)="1000" ELSE	--DEE010
			"XXXXXXXX"&"1"&"0000001" WHEN addr(4 downto 1)="1001" ELSE	--DEE012
			"01" & not (c64_keys(63) and menu_n_r) & '0'&"00000011"&"0101";	-- Bits 3:0 -> memory size.  (1<<memsize gives the size in megabytes.)
			-- Yuck - but C64 joystick in port 1 interferes with keyboard scanning.
												-- Bit  4 -> Turbo chipram supported
												-- Bit  5 -> Reconfig supportred 
												-- Bit  6 -> Action replay supported
												-- Bit 13 -> OSD button (active low)
												-- Bit 14 -> Scandoubler software-controllable.
			--  WHEN addr(4 downto 1)="1010" ELSE	--DEE014

IOdata <= sd_in;			
--IOdata <=   --rs232data WHEN rs232_select='1' ELSE 
--			sd_in WHEN SPI_select='1' ELSE
--			IDErd_data(7 downto 0)&IDErd_data(15 downto 8);
cpuena <= '1' WHEN ROM_select='1' OR PART_select='1' OR state="01" ELSE
		  IOcpuena WHEN rs232_select='1' OR SPI_select='1' ELSE 
		  cpuena_in; 

rs232data <= X"FFFF" WHEN txbusy='1' ELSE X"0000";

sd_in(15 downto 8) <= sd_in_shift(15 downto 8) WHEN lds='0' ELSE sd_in_shift(7 downto 0); 
sd_in(7 downto 0) <= sd_in_shift(7 downto 0);

RAM_write <= '1' when ROM_select='1' AND state="11" ELSE '0';
ROM_select <= '1' when addr(23 downto 12)=X"000" ELSE '0';
rs232_select <= '1' when addr(23 downto 12)=X"DA8" ELSE '0';
KEY_select <= '1' when addr(23 downto 12)=X"DE0" ELSE '0';
PART_select <= '1' when addr(23 downto 12)=X"DEE" ELSE '0';
SPI_select <= '1' when addr(23 downto 12)=X"DA4" AND state(1)='1' ELSE '0';

---------------------------------
-- Platform specific registers --
---------------------------------

process(sysclk,n_reset)
begin
	if rising_edge(sysclk) then
		if n_reset='0' then
			fastramsize<="000";
			turbochipram<='0';
			scandoubler<='1';
		end if;
		reconfigure<='0';
		if PART_select='1' and state="11" then	-- Write to platform registers
			case addr(4 downto 1) is
				when "1010" => -- DEE014
					fastramsize<=cpudata_in(2 downto 0);
					turbochipram<=cpudata_in(15);
					scandoubler<=cpudata_in(14);
				when "1011" => -- DEE016
					reconfigure<='1';
				when others =>
					null;
			end case;
		end if;
	end if;
end process;

-----------------------------------------------------------------
-- Support States
-----------------------------------------------------------------
process(sysclk, shift)
begin
   	IF sysclk'event AND sysclk = '1' THEN
		IF enacnt="1101100" THEN
			enacnt <= "0000000";
			ena1MHz <= '1';
		ELSE
			enacnt <= enacnt+1;
			ena1MHz <= '0';
		END IF;
		IF enaWRreg='1' THEN
			support_state <= idle;
			ld <= '0';
			IOcpuena <= '0';
			CASE support_state IS
				WHEN idle => 
					IF rs232_select='1' AND state="11" THEN
						IF txbusy='0' THEN
							ld <= '1';
							support_state <= io_aktion;
							IOcpuena <= '1';
						END IF;	
					ELSIF SPI_select='1' THEN		
						IF SD_busy='0' THEN
							support_state <= io_aktion;
							IOcpuena <= '1';
						END IF;
					END IF;
						
				WHEN io_aktion => 
					support_state <= idle;
					
				WHEN OTHERS => 
					support_state <= idle;
			END CASE;
		END IF;	
	END IF;	
end process; 


-- -----------------------------------------------------------------------
-- MUX CPLD
-- -----------------------------------------------------------------------
--	-- MUX clock
--	process(sysclk)
--	begin
--		if rising_edge(sysclk) then
----			if enaWRreg = '1' then
--				mux_clk_reg <= not mux_clk_reg;
----			end if;
--		end if;
--	end process;
--
--	-- MUX read
--	process(sysclk)
--	begin
--		if rising_edge(sysclk) then
----			if mux_clk_reg = '1' and enaWRreg = '1' then
--			if mux_clk_reg = '1' then
--				case mux_reg is
--				when X"B" =>
----					reset_button_n <= mux_q(1);
--					nreset <= mux_q(1);
----					led_green <= mux_q(1);
--					ir <= mux_q(3);
--				when X"A" =>
----					vga_id <= mux_q;
--				when X"E" =>
--					kb_data <= mux_q(0);
--					kb_clk <= mux_q(1);
--					ms_data <= mux_q(2);
--					ms_clk <= mux_q(3);
--				when X"D" =>
--					amiser_rxd <= mux_q(1); -- IEC_CLK = amiga serial rxd
--				when others =>
--					null;
--				end case;
--			end if;
--		end if;
--	end process;
--
--	-- MUX write
--	process(sysclk)
--	begin
----		led_red <= ir;
--		if rising_edge(sysclk) then
--			if mux_clk_reg = '1' then
--				mux_reg <= X"C";
--				mux_d_reg(3) <= usart_rx;	-- AMR transmit to Chameleons uC
--				mux_d_reg(2) <= NOT scs(1);
--				mux_d_reg(1) <= sd_out(15);
--				mux_d_reg(0) <= NOT sck;
--				case mux_reg is
--					when X"6" =>
----						mux_d_reg <= "1111";
----						if docking_station = '1' then
----							mux_d_reg <= "1" & docking_irq & "11";
----						end if;
----						mux_reg <= X"6";
----						
----						mux_d_regd <= "10" & led_green & led_red;
--						mux_d_regd <= "10" & led(0) & led(1);
--						mux_regd <= X"B";
--					when X"B" =>
--						mux_d_regd(2 downto 1) <= "11";
--						mux_d_regd(3) <= amiser_txd; -- CV: IEC ATN is amiga serial txd
--						mux_d_regd(0) <= not shiftout; -- CV: invert serial signal to fit USB2serial dongle
----						mux_d_regd(0) <= '1';
--						mux_regd <= X"D";
--					when X"C" =>
----	--					mux_d_reg <= iec_reg;
----						mux_regd <= X"D";
--						mux_reg <= mux_regd;
--						mux_d_reg <= mux_d_regd;
--					when X"D" =>
--						mux_d_regd(0) <= kb_datai;
--						mux_d_regd(1) <= kb_clki;
--						mux_d_regd(2) <= ms_datai;
--						mux_d_regd(3) <= ms_clki;
--						mux_regd <= X"E";
--					when X"E" =>
--	--					mux_reg <= X"A";
--	--					mux_D_reg <= X"F";
----						mux_d_regd <= "10" & led_green & led_red;
----						mux_regd <= X"B";
--
--						mux_d_regd <= "1" & irq_d & "11";
--						mux_regd <= X"6";
--					when others =>
--						mux_regd <= X"B";
----						mux_d_regd <= "10" & led_green & led_red;
--						mux_d_regd <= "10" & led(0) & led(1);
--				end case;
--			end if;
--		end if;
--	end process;
--	
--	mux_clk <= mux_clk_reg;
--	mux_d <= mux_d_reg;
--	mux <= mux_reg;


-----------------------------------------------------------------
-- SPI-Interface
-----------------------------------------------------------------	
	sd_cs <= NOT scs;
	sd_clk <= NOT sck;
	sd_do <= sd_out(15);
	SD_busy <= shiftcnt(13);
	
	PROCESS (sysclk, n_reset, scs, sd_di, sd_dimm) BEGIN
--		IF (sysclk'event AND sysclk='0') THEN
			IF scs(1)='0' THEN
				sd_di_in <= sd_di;
			ELSE	
				sd_di_in <= sd_dimm;
			END IF;
--		END IF;
		IF n_reset ='0' THEN 
			shiftcnt <= (OTHERS => '0');
			spi_div <= (OTHERS => '0');
			scs <= (OTHERS => '0');
			sck <= '0';
			spi_speed <= "00000000";
			dscs <= '0';
		ELSIF (sysclk'event AND sysclk='1') THEN

		if spi_raw_ack='1' then -- Unpause SPI as soon as the IO controller has written to the MUX
			if spi_wait_d='1' then
				spi_wait_d<='0';
			else
				spi_wait<='0';
				spi_wait_d<='1';
			end if;
		end if;

		IF enaWRreg='1' THEN
			IF SPI_select='1' AND state="11" AND SD_busy='0' THEN	 --SD write
				IF addr(3)='1' THEN				--DA4008
					spi_speed <= unsigned(cpudata_in(7 downto 0));
				ELSIF addr(2)='1' THEN				--DA4004
					scs(0) <= not cpudata_in(0);
					IF cpudata_in(7)='1' THEN
						scs(7) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(6)='1' THEN
						scs(6) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(5)='1' THEN
						scs(5) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(4)='1' THEN
						scs(4) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(3)='1' THEN
						scs(3) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(2)='1' THEN
						scs(2) <= not cpudata_in(0);
					END IF;
					IF cpudata_in(1)='1' THEN
						scs(1) <= not cpudata_in(0);
					END IF;
				ELSE							--DA4000

					if scs(1)='0' then
						spi_div <= spi_speed;
					else
						spi_div <= spi_speed+2; -- FIXME: ugly - find a better way to do this.
					end if;

					sd_out <= cpudata_in(15 downto 0);
					IF scs(6)='1' THEN		-- SPI direkt Mode
						shiftcnt <= "10111111111111";
--						shiftcnt <= "100"&cpudata_in(7 downto 0)&"111";
						sd_out <= "1111111111111111";
--						sd_out(15 downto 8) <= cpudata_in(7 downto 0);
					ELSIF uds='0' AND lds='0' THEN
						shiftcnt <= "10000000001111";
--						spi_word <= '1';
					ELSE
						shiftcnt <= "10000000000111";
--						spi_word <= '0';
						IF lds='0' THEN
							sd_out(15 downto 8) <= cpudata_in(7 downto 0);
						END IF;
					END IF;
--					IF uds='1' THEN
--						sd_out(15 downto 8) <= cpudata_in(7 downto 0);
--					END IF;	
					sck <= '1';
--					spi_div <= spi_speed;
--					IF scs(6)='1' THEN		-- SPI direkt Mode
--						shiftcnt <= "10111111111111";
----						shiftcnt <= "100"&cpudata_in(7 downto 0)&"111";
----						sd_out <= "11111111";
--					ELSE
--						shiftcnt <= "10000000000111";
--					END IF;
--					sd_out <= cpudata_in(7 downto 0);
--					sck <= '1';
				END IF;
			ELSE
				IF spi_div="00000000" then
					if spi_wait='0' or scs(1)='0' THEN -- Wait for io component to propagate signals.
						spi_wait<='1'; -- Only wait if SPI needs to go through the MUX
						if scs(1)='0' then
							spi_div <= spi_speed;
						else
							spi_div <= spi_speed+2; -- FIXME: ugly - find a better way to do this.
						end if;
						IF SD_busy='1' THEN
							IF sck='0' THEN
								IF shiftcnt(12 downto 0)/="0000000000000" THEN
									sck <='1';
								END IF;
								shiftcnt <= shiftcnt-1;
								sd_out <= sd_out(14 downto 0)&'1';
							ELSE	
								sck <='0';
								sd_in_shift <= sd_in_shift(14 downto 0)&sd_di_in;
	--							IF spi_word='0' THEN
	--								sd_in_shift(8) <= sd_di_in;
	--							END IF;
							END IF;
						end if;
					END IF;
				ELSE
					spi_div <= spi_div-1;
				END IF;
			END IF;		
		END IF;	
		END IF;		
	END PROCESS;

-----------------------------------------------------------------
-- Simple UART only TxD
-----------------------------------------------------------------
TxD <= not shiftout;
process(n_reset, sysclk, shift)
begin
	if shift="0000000000" then
		txbusy <= '0';
	else
		txbusy <= '1';
	end if;

	if n_reset='0' then
		shiftout <= '0';
		shift <= "0000000000"; 
	elsif sysclk'event and sysclk = '1' then
	IF enaWRreg='1' THEN
		if ld = '1' then
			IF lds='0'THEN
				shift <=  '1' & cpudata_in(7 downto 0) & '0';			--STOP,MSB...LSB, START
			ELSE	
				shift <=  '1' & cpudata_in(15 downto 8) & '0';			--STOP,MSB...LSB, START
			END IF;		
		end if;
		if clkgen/=0 then
			clkgen <= clkgen-1;
		else	
--			clkgen <= "1110101001";--937;		--108MHz/115200
--			clkgen <= "0011101010";--234;		--27MHz/115200
			clkgen <= "0011111000";--249-1;		--28,7MHz/115200
--			clkgen <= "0011110101";--246-1;		--28,7MHz/115200
--			clkgen <= "0001111100";--249-1;		--14,3MHz/115200
			shiftout <= not shift(0) and txbusy;
		   	shift <=  '0' & shift(9 downto 1);
		end if;
	END IF;		
	end if;
end process; 


-----------------------------------------------------------------
-- timer
-----------------------------------------------------------------
process(sysclk)
begin
   	IF sysclk'event AND sysclk = '1' THEN
	IF enaWRreg='1' THEN
		IF timeprecnt=0 THEN
			timeprecnt <= X"3808";
			timecnt <= timecnt+1;
		ELSE
			timeprecnt <= timeprecnt-1;
		END IF;
	END IF;
	end if;
end process; 

-----------------------------------------------------------------
-- reconfigure chameleon
-----------------------------------------------------------------

myReconfig : entity work.chameleon_reconfigure
	port map (
		clk => sysclk,
		--reset => n_reset,
		reconfigure => reconfigure,	
		serial_clk => usart_clk,
		serial_txd => usart_rx,
		serial_cts_n => usart_rts
	);


end;  

