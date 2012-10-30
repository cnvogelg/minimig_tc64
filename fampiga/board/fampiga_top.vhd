-- Copyright (C) 1991-2012 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II 32-bit"
-- VERSION		"Version 12.0 Build 232 07/05/2012 Service Pack 1 SJ Web Edition"
-- CREATED		"Mon Oct 29 22:38:36 2012"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY fampiga_top IS 
	PORT
	(
		clk8 :  IN  STD_LOGIC;
		phi2_n :  IN  STD_LOGIC;
		mmc_wp :  IN  STD_LOGIC;
		mmc_cd_n :  IN  STD_LOGIC;
		freeze_n :  IN  STD_LOGIC;
		usart_tx :  IN  STD_LOGIC;
		usart_clk :  IN  STD_LOGIC;
		usart_rts :  IN  STD_LOGIC;
		usart_cts :  IN  STD_LOGIC;
		spi_miso :  IN  STD_LOGIC;
		romlh_n :  IN  STD_LOGIC;
		ioef_n :  IN  STD_LOGIC;
		dotclock_n :  IN  STD_LOGIC;
		mux_q :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		sd_data :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		mux_clk :  OUT  STD_LOGIC;
		sd_ldqm :  OUT  STD_LOGIC;
		sd_udqm :  OUT  STD_LOGIC;
		sd_we_n :  OUT  STD_LOGIC;
		sd_ras_n :  OUT  STD_LOGIC;
		sd_cas_n :  OUT  STD_LOGIC;
		sd_ba_0 :  OUT  STD_LOGIC;
		sd_ba_1 :  OUT  STD_LOGIC;
		sigmaL :  OUT  STD_LOGIC;
		sigmaR :  OUT  STD_LOGIC;
		nHSync :  OUT  STD_LOGIC;
		nVSync :  OUT  STD_LOGIC;
		sd_clk :  OUT  STD_LOGIC;
		blu :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0);
		grn :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0);
		mux :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		mux_d :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		red :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0);
		sd_addr :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0)
	);
END fampiga_top;

ARCHITECTURE bdf_type OF fampiga_top IS 

--COMPONENT palclk
--	PORT(inclk0 : IN STD_LOGIC;
--		 c0 : OUT STD_LOGIC;
--		 c1 : OUT STD_LOGIC;
--		 c2 : OUT STD_LOGIC;
--		 c3 : OUT STD_LOGIC;
--		 locked : OUT STD_LOGIC
--	);
--END COMPONENT;
--
COMPONENT minimig1
GENERIC (NTSC : INTEGER
			);
	PORT(n_cpu_as : IN STD_LOGIC;
		 n_cpu_uds : IN STD_LOGIC;
		 n_cpu_lds : IN STD_LOGIC;
		 cpu_r_w : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 clk28m : IN STD_LOGIC;
		 rxd : IN STD_LOGIC;
		 cts : IN STD_LOGIC;
		 n_15khz : IN STD_LOGIC;
		 kbddat : IN STD_LOGIC;
		 kbdclk : IN STD_LOGIC;
		 msdat : IN STD_LOGIC;
		 msclk : IN STD_LOGIC;
		 direct_sdi : IN STD_LOGIC;
		 sdi : IN STD_LOGIC;
		 sck : IN STD_LOGIC;
		 cpurst : IN STD_LOGIC;
		 locked : IN STD_LOGIC;
		 sysclock : IN STD_LOGIC;
		 sdo : INOUT STD_LOGIC;
		 n_joy1 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 n_joy2 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 n_joy3 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 n_joy4 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 n_scs : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 ascancode : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
		 cpu_address : IN STD_LOGIC_VECTOR(23 DOWNTO 1);
		 cpu_wrdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 ramdata_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 n_cpu_dtack : OUT STD_LOGIC;
		 n_cpu_reset : OUT STD_LOGIC;
		 n_ram_bhe : OUT STD_LOGIC;
		 n_ram_ble : OUT STD_LOGIC;
		 n_ram_we : OUT STD_LOGIC;
		 n_ram_oe : OUT STD_LOGIC;
		 txd : OUT STD_LOGIC;
		 rts : OUT STD_LOGIC;
		 pwrled : OUT STD_LOGIC;
		 msdato : OUT STD_LOGIC;
		 msclko : OUT STD_LOGIC;
		 kbddato : OUT STD_LOGIC;
		 kbdclko : OUT STD_LOGIC;
		 n_hsync : OUT STD_LOGIC;
		 n_vsync : OUT STD_LOGIC;
		 left : OUT STD_LOGIC;
		 right : OUT STD_LOGIC;
		 drv_snd : OUT STD_LOGIC;
		 floppyled : OUT STD_LOGIC;
		 init_b : OUT STD_LOGIC;
		 reconfigure : OUT STD_LOGIC;
		 n_cpu_ipl : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		 n_ram_ce : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 cpu_config : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		 cpu_data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 memcfg : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		 ram_address : OUT STD_LOGIC_VECTOR(21 DOWNTO 1);
		 ram_data : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

--
--COMPONENT chameleon_cdtv_remote
--	PORT(clk : IN STD_LOGIC;
--		 ena_1mhz : IN STD_LOGIC;
--		 ir : IN STD_LOGIC;
--		 trigger : OUT STD_LOGIC;
--		 key_1 : OUT STD_LOGIC;
--		 key_2 : OUT STD_LOGIC;
--		 key_3 : OUT STD_LOGIC;
--		 key_4 : OUT STD_LOGIC;
--		 key_5 : OUT STD_LOGIC;
--		 key_6 : OUT STD_LOGIC;
--		 key_7 : OUT STD_LOGIC;
--		 key_8 : OUT STD_LOGIC;
--		 key_9 : OUT STD_LOGIC;
--		 key_0 : OUT STD_LOGIC;
--		 key_escape : OUT STD_LOGIC;
--		 key_enter : OUT STD_LOGIC;
--		 key_genlock : OUT STD_LOGIC;
--		 key_cdtv : OUT STD_LOGIC;
--		 key_power : OUT STD_LOGIC;
--		 key_rew : OUT STD_LOGIC;
--		 key_play : OUT STD_LOGIC;
--		 key_ff : OUT STD_LOGIC;
--		 key_stop : OUT STD_LOGIC;
--		 key_vol_up : OUT STD_LOGIC;
--		 key_vol_dn : OUT STD_LOGIC;
--		 joystick_a : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 joystick_b : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
--	);
--END COMPONENT;
--
--COMPONENT chameleon_docking_station
--	PORT(clk : IN STD_LOGIC;
--		 dotclock_n : IN STD_LOGIC;
--		 io_ef_n : IN STD_LOGIC;
--		 rom_lh_n : IN STD_LOGIC;
--		 irq_d : IN STD_LOGIC;
--		 amiga_power_led : IN STD_LOGIC;
--		 amiga_drive_led : IN STD_LOGIC;
--		 irq_q : OUT STD_LOGIC;
--		 restore_key_n : OUT STD_LOGIC;
--		 amiga_reset_n : OUT STD_LOGIC;
--		 amiga_trigger : OUT STD_LOGIC;
--		 amiga_scancode : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--		 joystick1 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 joystick2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 joystick3 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 joystick4 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 keys : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
--	);
--END COMPONENT;
--
--COMPONENT cfide
--	PORT(sysclk : IN STD_LOGIC;
--		 n_reset : IN STD_LOGIC;
--		 cpuena_in : IN STD_LOGIC;
--		 lds : IN STD_LOGIC;
--		 uds : IN STD_LOGIC;
--		 sd_di : IN STD_LOGIC;
--		 sd_dimm : IN STD_LOGIC;
--		 enaWRreg : IN STD_LOGIC;
--		 kb_clki : IN STD_LOGIC;
--		 kb_datai : IN STD_LOGIC;
--		 ms_clki : IN STD_LOGIC;
--		 ms_datai : IN STD_LOGIC;
--		 irq_d : IN STD_LOGIC;
--		 amiser_txd : IN STD_LOGIC;
--		 usart_clk : IN STD_LOGIC;
--		 usart_rts : IN STD_LOGIC;
--		 reconfigure : IN STD_LOGIC;
--		 addr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
--		 cpudata_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 led : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 memdata_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 mux_q : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--		 state : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 mux_clk : OUT STD_LOGIC;
--		 memce : OUT STD_LOGIC;
--		 cpuena : OUT STD_LOGIC;
--		 TxD : OUT STD_LOGIC;
--		 sd_clk : OUT STD_LOGIC;
--		 sd_do : OUT STD_LOGIC;
--		 kb_clk : OUT STD_LOGIC;
--		 kb_data : OUT STD_LOGIC;
--		 ms_clk : OUT STD_LOGIC;
--		 ms_data : OUT STD_LOGIC;
--		 nreset : OUT STD_LOGIC;
--		 ir : OUT STD_LOGIC;
--		 ena1MHz : OUT STD_LOGIC;
--		 amiser_rxd : OUT STD_LOGIC;
--		 cpudata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 mux : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--		 mux_d : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--		 sd_cs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
--	);
--END COMPONENT;
--
--COMPONENT sdram
--	PORT(sysclk : IN STD_LOGIC;
--		 reset_in : IN STD_LOGIC;
--		 hostL : IN STD_LOGIC;
--		 hostU : IN STD_LOGIC;
--		 cpuU : IN STD_LOGIC;
--		 cpuL : IN STD_LOGIC;
--		 cpu_dma : IN STD_LOGIC;
--		 chipU : IN STD_LOGIC;
--		 chipL : IN STD_LOGIC;
--		 chipRW : IN STD_LOGIC;
--		 chip_dma : IN STD_LOGIC;
--		 c_7m : IN STD_LOGIC;
--		 chipAddr : IN STD_LOGIC_VECTOR(23 DOWNTO 1);
--		 chipWR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 cpuAddr : IN STD_LOGIC_VECTOR(24 DOWNTO 1);
--		 cpustate : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 cpuWR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 hostAddr : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
--		 hostState : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--		 hostWR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 sdata : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 sd_we : OUT STD_LOGIC;
--		 sd_ras : OUT STD_LOGIC;
--		 sd_cas : OUT STD_LOGIC;
--		 hostena : OUT STD_LOGIC;
--		 cpuena : OUT STD_LOGIC;
--		 reset_out : OUT STD_LOGIC;
--		 enaRDreg : OUT STD_LOGIC;
--		 enaWRreg : OUT STD_LOGIC;
--		 ena7RDreg : OUT STD_LOGIC;
--		 ena7WRreg : OUT STD_LOGIC;
--		 ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 chipRD : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 cpuRD : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 dqm : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 hostRD : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 sd_cs : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--		 sdaddr : OUT STD_LOGIC_VECTOR(12 DOWNTO 0)
--	);
--END COMPONENT;
--
--COMPONENT tg68kdotc_kernel
--GENERIC (BitField : INTEGER;
--			DIV_Mode : INTEGER;
--			extAddr_Mode : INTEGER;
--			MUL_Mode : INTEGER;
--			SR_Read : INTEGER;
--			VBR_Stackframe : INTEGER
--			);
--	PORT(clk : IN STD_LOGIC;
--		 nReset : IN STD_LOGIC;
--		 clkena_in : IN STD_LOGIC;
--		 IPL_autovector : IN STD_LOGIC;
--		 CPU : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 data_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 IPL : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--		 nWr : OUT STD_LOGIC;
--		 nUDS : OUT STD_LOGIC;
--		 nLDS : OUT STD_LOGIC;
--		 nResetOut : OUT STD_LOGIC;
--		 skipFetch : OUT STD_LOGIC;
--		 addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--		 busstate : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 data_write : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 FC : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
--		 regin : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
--	);
--END COMPONENT;
--
--COMPONENT tg68k
--	PORT(clk : IN STD_LOGIC;
--		 reset : IN STD_LOGIC;
--		 clkena_in : IN STD_LOGIC;
--		 dtack : IN STD_LOGIC;
--		 vpa : IN STD_LOGIC;
--		 ein : IN STD_LOGIC;
--		 ena7RDreg : IN STD_LOGIC;
--		 ena7WRreg : IN STD_LOGIC;
--		 enaWRreg : IN STD_LOGIC;
--		 ramready : IN STD_LOGIC;
--		 cpu : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--		 data_read : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 fromram : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 IPL : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--		 memcfg : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 as : OUT STD_LOGIC;
--		 uds : OUT STD_LOGIC;
--		 lds : OUT STD_LOGIC;
--		 rw : OUT STD_LOGIC;
--		 e : OUT STD_LOGIC;
--		 vma : OUT STD_LOGIC;
--		 wrd : OUT STD_LOGIC;
--		 nResetOut : OUT STD_LOGIC;
--		 skipFetch : OUT STD_LOGIC;
--		 cpuDMA : OUT STD_LOGIC;
--		 ramlds : OUT STD_LOGIC;
--		 ramuds : OUT STD_LOGIC;
--		 addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--		 cpustate : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--		 data_write : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 ramaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
--	);
--END COMPONENT;

SIGNAL	ad :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	addr :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	amiser_rxd :  STD_LOGIC;
SIGNAL	amiser_txd :  STD_LOGIC;
SIGNAL	ascan :  STD_LOGIC_VECTOR(8 DOWNTO 0);
SIGNAL	B :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	ba :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	breset :  STD_LOGIC;
SIGNAL	c_28m :  STD_LOGIC;
SIGNAL	c_7m :  STD_LOGIC;
SIGNAL	cad :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	cdma :  STD_LOGIC;
SIGNAL	clds :  STD_LOGIC;
SIGNAL	cout :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	cpu :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	cpuena :  STD_LOGIC;
SIGNAL	cpustate :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	cs :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	cuds :  STD_LOGIC;
SIGNAL	cwr :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	cwrd :  STD_LOGIC;
SIGNAL	dout :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	dqm :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	drd :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	dtack :  STD_LOGIC;
SIGNAL	ena7RDreg :  STD_LOGIC;
SIGNAL	ena7WRreg :  STD_LOGIC;
SIGNAL	enaWRreg :  STD_LOGIC;
SIGNAL	floppyled :  STD_LOGIC;
SIGNAL	g :  STD_LOGIC;
SIGNAL	GR :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	IPL :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	irq_q :  STD_LOGIC;
SIGNAL	joyA :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	joyB :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	joyC :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	joyD :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	kbc :  STD_LOGIC;
SIGNAL	kbci :  STD_LOGIC;
SIGNAL	kbd :  STD_LOGIC;
SIGNAL	kbdi :  STD_LOGIC;
SIGNAL	locked :  STD_LOGIC;
SIGNAL	memce :  STD_LOGIC;
SIGNAL	memcfg :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	mmc_clk :  STD_LOGIC;
SIGNAL	msc :  STD_LOGIC;
SIGNAL	msci :  STD_LOGIC;
SIGNAL	msd :  STD_LOGIC;
SIGNAL	msdi :  STD_LOGIC;
SIGNAL	pwled :  STD_LOGIC;
SIGNAL	R :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	ra :  STD_LOGIC_VECTOR(21 DOWNTO 1);
SIGNAL	sd_do :  STD_LOGIC;
SIGNAL	sdreset :  STD_LOGIC;
SIGNAL	Spi_CS :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	state :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	sysclk :  STD_LOGIC;
SIGNAL	v :  STD_LOGIC;
SIGNAL	zena :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_9 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_36 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_37 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_38 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_16 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_39 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_18 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_19 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_22 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_23 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_24 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_25 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_26 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_28 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_29 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_30 :  STD_LOGIC_VECTOR(0 TO 1);
SIGNAL	SYNTHESIZED_WIRE_31 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_32 :  STD_LOGIC_VECTOR(0 TO 2);
SIGNAL	SYNTHESIZED_WIRE_34 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_35 :  STD_LOGIC;

SIGNAL	GDFX_TEMP_SIGNAL_0 :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	GDFX_TEMP_SIGNAL_2 :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	GDFX_TEMP_SIGNAL_1 :  STD_LOGIC_VECTOR(23 DOWNTO 1);

signal fastramcfg : std_logic_vector(1 downto 0);
signal turbochipram : std_logic;

BEGIN 
SYNTHESIZED_WIRE_29 <= '1';
SYNTHESIZED_WIRE_30 <= "00";
SYNTHESIZED_WIRE_32 <= "111";

GDFX_TEMP_SIGNAL_0 <= (pwled & floppyled);
GDFX_TEMP_SIGNAL_2 <= (memce & state(1 DOWNTO 0));
GDFX_TEMP_SIGNAL_1 <= (g & g & ra(21 DOWNTO 1));


b2v_inst : entity work.palclk
PORT MAP(inclk0 => clk8,
		 c0 => sd_clk,
		 c1 => sysclk,
		 c2 => c_28m,
		 c3 => c_7m,
		 locked => SYNTHESIZED_WIRE_19);


b2v_inst1 : minimig1
GENERIC MAP(NTSC => 0
			)
PORT MAP(n_cpu_as => SYNTHESIZED_WIRE_0,
		 n_cpu_uds => SYNTHESIZED_WIRE_1,
		 n_cpu_lds => SYNTHESIZED_WIRE_2,
		 cpu_r_w => SYNTHESIZED_WIRE_3,
		 clk => c_7m,
		 clk28m => c_28m,
		 rxd => amiser_rxd,
		 cts => '1',
		 n_15khz => v,
		 kbddat => kbd,
		 kbdclk => kbc,
		 msdat => msd,
		 msclk => msc,
		 direct_sdi => spi_miso,
		 sdi => sd_do,
		 sck => mmc_clk,
		 cpurst => SYNTHESIZED_WIRE_4,
		 locked => sdreset,
		 sysclock => sysclk,
		 sdo => SYNTHESIZED_WIRE_15,
		 n_joy1 => joyA,
		 n_joy2 => joyB,
		 n_joy3 => joyC,
		 n_joy4 => joyD,
		 n_scs => Spi_CS(6 DOWNTO 4),
		 ascancode => ascan,
		 cpu_address => ad(23 DOWNTO 1),
		 cpu_wrdata => cwr,
		 ramdata_in => dout,
		 n_cpu_dtack => dtack,
		 n_cpu_reset => SYNTHESIZED_WIRE_35,
		 n_ram_bhe => SYNTHESIZED_WIRE_22,
		 n_ram_ble => SYNTHESIZED_WIRE_23,
		 n_ram_we => SYNTHESIZED_WIRE_24,
		 n_ram_oe => SYNTHESIZED_WIRE_25,
		 txd => amiser_txd,
		 pwrled => pwled,
		 msdato => msdi,
		 msclko => msci,
		 kbddato => kbdi,
		 kbdclko => kbci,
		 n_hsync => nHSync,
		 n_vsync => nVSync,
		 left => sigmaL,
		 right => sigmaR,
		 floppyled => floppyled,
		 reconfigure => SYNTHESIZED_WIRE_16,
		 n_cpu_ipl => IPL,
		 blue => B,
		 cpu_config => cpu,
		 cpu_data => drd,
		 green => GR,
		 memcfg => memcfg,
		 ram_address => ra,
		 ram_data => SYNTHESIZED_WIRE_26,
		 red => R);



b2v_inst11 : entity work.chameleon_cdtv_remote
PORT MAP(clk => sysclk,
		 ena_1mhz => SYNTHESIZED_WIRE_5,
		 ir => SYNTHESIZED_WIRE_6,
		 joystick_a => SYNTHESIZED_WIRE_7,
		 joystick_b => SYNTHESIZED_WIRE_9);


b2v_inst12 : entity work.chameleon_docking_station
PORT MAP(clk => sysclk,
		 dotclock_n => dotclock_n,
		 io_ef_n => ioef_n,
		 rom_lh_n => romlh_n,
		 irq_d => v,
		 amiga_power_led => pwled,
		 amiga_drive_led => floppyled,
		 irq_q => irq_q,
		 amiga_reset_n => ascan(8),
		 amiga_scancode => ascan(7 DOWNTO 0),
		 joystick1 => SYNTHESIZED_WIRE_8,
		 joystick2 => SYNTHESIZED_WIRE_10,
		 joystick3 => joyC,
		 joystick4 => joyD);


joyA <= SYNTHESIZED_WIRE_7 AND SYNTHESIZED_WIRE_8;


joyB <= SYNTHESIZED_WIRE_9 AND SYNTHESIZED_WIRE_10;




SYNTHESIZED_WIRE_4 <= NOT(SYNTHESIZED_WIRE_36 AND SYNTHESIZED_WIRE_12);



b2v_inst3 : entity work.cfide
PORT MAP(sysclk => sysclk,
		 n_reset => sdreset,
		 cpuena_in => zena,
		 lds => SYNTHESIZED_WIRE_37,
		 uds => SYNTHESIZED_WIRE_38,
		 sd_di => SYNTHESIZED_WIRE_15,
		 sd_dimm => spi_miso,
		 enaWRreg => enaWRreg,
		 kb_clki => kbci,
		 kb_datai => kbdi,
		 ms_clki => msci,
		 ms_datai => msdi,
		 irq_d => irq_q,
		 amiser_txd => amiser_txd,
		 usart_clk => usart_clk,
		 usart_rts => usart_rts,
		 reconfigure => SYNTHESIZED_WIRE_16,
		 addr => addr(23 DOWNTO 0),
		 cpudata_in => SYNTHESIZED_WIRE_39,
		 led => GDFX_TEMP_SIGNAL_0,
		 memdata_in => SYNTHESIZED_WIRE_18,
		 mux_q => mux_q,
		 state => state,
		 mux_clk => mux_clk,
		 memce => memce,
		 cpuena => SYNTHESIZED_WIRE_34,
		 sd_clk => mmc_clk,
		 sd_do => sd_do,
		 kb_clk => kbc,
		 kb_data => kbd,
		 ms_clk => msc,
		 ms_data => msd,
		 nreset => breset,
		 ir => SYNTHESIZED_WIRE_6,
		 ena1MHz => SYNTHESIZED_WIRE_5,
		 amiser_rxd => amiser_rxd,
		 cpudata => SYNTHESIZED_WIRE_31,
		 mux => mux,
		 mux_d => mux_d,
		 sd_cs => Spi_CS,
		 fastramcfg => fastramcfg,
		 turbochipram => turbochipram);




locked <= SYNTHESIZED_WIRE_19 AND breset;


b2v_inst5 : entity work.sdram
PORT MAP(sysclk => sysclk,
		 reset_in => locked,
		 hostL => SYNTHESIZED_WIRE_37,
		 hostU => SYNTHESIZED_WIRE_38,
		 cpuU => cuds,
		 cpuL => clds,
		 cpu_dma => cdma,
		 chipU => SYNTHESIZED_WIRE_22,
		 chipL => SYNTHESIZED_WIRE_23,
		 chipRW => SYNTHESIZED_WIRE_24,
		 chip_dma => SYNTHESIZED_WIRE_25,
		 c_7m => c_7m,
		 chipAddr => GDFX_TEMP_SIGNAL_1,
		 chipWR => SYNTHESIZED_WIRE_26,
		 cpuAddr => cad(24 DOWNTO 1),
		 cpustate => cpustate,
		 cpuWR => cwr,
		 hostAddr => addr(23 DOWNTO 0),
		 hostState => GDFX_TEMP_SIGNAL_2,
		 hostWR => SYNTHESIZED_WIRE_39,
		 sdata => sd_data,
		 sd_we => sd_we_n,
		 sd_ras => sd_ras_n,
		 sd_cas => sd_cas_n,
		 hostena => zena,
		 cpuena => cpuena,
		 reset_out => sdreset,
		 enaWRreg => enaWRreg,
		 ena7RDreg => ena7RDreg,
		 ena7WRreg => ena7WRreg,
		 ba => ba,
		 chipRD => dout,
		 cpuRD => cout,
		 dqm => dqm,
		 hostRD => SYNTHESIZED_WIRE_18,
		 sdaddr => sd_addr);


b2v_inst6 : entity work.tg68kdotc_kernel
GENERIC MAP(BitField => 0,
			DIV_Mode => 0,
			extAddr_Mode => 0,
			MUL_Mode => 0,
			SR_Read => 0,
			VBR_Stackframe => 0
			)
PORT MAP(clk => sysclk,
		 nReset => sdreset,
		 clkena_in => SYNTHESIZED_WIRE_28,
		 IPL_autovector => SYNTHESIZED_WIRE_29,
		 CPU => SYNTHESIZED_WIRE_30,
		 data_in => SYNTHESIZED_WIRE_31,
		 IPL => SYNTHESIZED_WIRE_32,
		 nUDS => SYNTHESIZED_WIRE_38,
		 nLDS => SYNTHESIZED_WIRE_37,
		 addr => addr,
		 busstate => state,
		 data_write => SYNTHESIZED_WIRE_39);


b2v_inst7 : entity work.tg68k
PORT MAP(clk => sysclk,
		 reset => SYNTHESIZED_WIRE_36,
		 clkena_in => v,
		 dtack => dtack,
		 vpa => v,
		 ein => v,
		 ena7RDreg => ena7RDreg,
		 ena7WRreg => ena7WRreg,
		 enaWRreg => enaWRreg,
		 ramready => cpuena,
		 cpu => cpu,
		 data_read => drd,
		 fromram => cout,
		 IPL => IPL,
		 memcfg => memcfg,
		 fastramcfg => fastramcfg,
		 turbochipram => turbochipram,
		 as => SYNTHESIZED_WIRE_0,
		 uds => SYNTHESIZED_WIRE_1,
		 lds => SYNTHESIZED_WIRE_2,
		 rw => SYNTHESIZED_WIRE_3,
		 nResetOut => SYNTHESIZED_WIRE_12,
		 cpuDMA => cdma,
		 ramlds => clds,
		 ramuds => cuds,
		 addr => ad,
		 cpustate => cpustate,
		 data_write => cwr,
		 ramaddr => cad);


SYNTHESIZED_WIRE_28 <= SYNTHESIZED_WIRE_34 AND enaWRreg;


SYNTHESIZED_WIRE_36 <= SYNTHESIZED_WIRE_35 AND sdreset;

sd_ldqm <= dqm(0);
sd_udqm <= dqm(1);
sd_ba_0 <= ba(0);
sd_ba_1 <= ba(1);
blu(4 DOWNTO 1) <= B;
blu(0) <= g;
grn(4 DOWNTO 1) <= GR;
grn(0) <= g;
red(4 DOWNTO 1) <= R;
red(0) <= g;

g <= '0';
v <= '1';
END bdf_type;