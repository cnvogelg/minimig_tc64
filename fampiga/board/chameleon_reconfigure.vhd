-- Sending data to the Chameleon's microcontroller

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity chameleon_reconfigure is
	generic (
		resetCycles: integer := 131072
	);
   port (
		clk : in std_logic;
--		reset : in std_logic;
		reconfigure : in std_logic;

		serial_clk : in std_logic;
		serial_txd : out std_logic;
		serial_cts_n : in std_logic := '0'
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of chameleon_reconfigure is
	type state_t is (
	   STATE_INIT,
		STATE_IDLE,
		STATE_XFER,
		STATE_STOP);

	signal resetcnt : integer range 0 to resetCycles := 0;
	signal reset : std_logic := '1' ;
	signal transmit_state : state_t := STATE_INIT;
	signal transmit_empty : std_logic := '1';
	signal transmit_shift : unsigned(8 downto 0) := (others => '0');
	signal transmit_cnt : integer range 0 to 8 := 0;
	signal scts_n : std_logic;
	signal sclk : std_logic;
	signal sclk_d : std_logic;
	signal reconfig_pending : std_logic :='0';
begin

	process(clk,serial_clk,serial_cts_n)
	begin
		if rising_edge(clk) then
			sclk<=serial_clk;
			sclk_d<=sclk;
			scts_n<=serial_cts_n;
		end if;
	end process;
	
	transmit_process: process(clk, serial_clk, reconfigure)
	begin
		
		if rising_edge(clk) then
			if reconfigure='1' then
				reconfig_pending<='1';
			end if;

			if sclk='0' and sclk_d='1' then -- falling edge
				if resetcnt=(resetCycles-1) then
					reset <= '0';
				else
					reset <= '1';
					resetcnt <=resetcnt+1;
				end if;
				
				case transmit_state is
				when STATE_INIT =>
					if reset='0' then
						transmit_shift <= "100101010"; -- 42, 0x12A
						transmit_empty <='0';
						transmit_state<=STATE_IDLE;
					end if;
				when STATE_IDLE =>
					transmit_cnt <= 0;

					if reconfig_pending='1' then
						transmit_shift <= "111110000";
						transmit_empty <='0';
						reconfig_pending<='0';
					end if;	
					if (transmit_empty = '0') and (scts_n = '0') then
						transmit_empty <= '1';
						transmit_state <= STATE_XFER;
						serial_txd <= '0';
					else
						serial_txd <= '1';
					end if;
				when STATE_XFER =>
					serial_txd <= transmit_shift(transmit_cnt);
					if transmit_cnt = 8 then
						transmit_state <= STATE_STOP;
					else
						transmit_cnt <= transmit_cnt + 1;
					end if;
				when STATE_STOP =>
					serial_txd <= '1';
					transmit_state <= STATE_IDLE;
				end case;
			end if;
		end if;
	end process;
end architecture;
