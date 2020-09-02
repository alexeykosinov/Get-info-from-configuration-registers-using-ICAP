----------------------------------------------------------------------------------
-- Company			: Research Institute of Precision Instruments
-- Engineer			: Kosinov Alexey
-- Create Date		: 02/09/2020 
-- Target Devices	: Virtex-6 (XC6VSX315T-2FF1759)
-- Tool versions	: ISE Design 14.7
-- Encoding			: UTF-8
-- Description		: Get info from IDCODE, STAT and BOOTSTS configuration registers
--					: IDCODE 	: x"28018001"
--					: STAT 		: x"2800E001"
--					: BOOTSTS 	: x"2802C001"
----------------------------------------------------------------------------------
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;

entity sysinfo is
	port (
		CLK			: in  std_logic;
		TRIGGER		: in  std_logic;

		IDCODE    	: out std_logic_vector(31 downto 0);
		STAT    	: out std_logic_vector(31 downto 0);
		BOOTSTS    	: out std_logic_vector(31 downto 0);

		ICAP_RDWRB	: out std_logic;
		ICAP_CSB  	: out std_logic;
		ICAP_O    	: in  std_logic_vector(31 downto 0);
		ICAP_I    	: out std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of sysinfo is

	type ram_t is array (0 to 14) of std_logic_vector(31 downto 0); -- MSB first  

	constant RAM_IDCODE  : ram_t := (x"00000000",x"00000000",x"00000000",x"FFFFFFFF",x"AA995566",x"20000000",x"20000000",x"28018001",x"00000000",x"00000000",x"20000000",x"20000000",x"20000000",x"20000000",x"00000000");
	constant RAM_STAT 	 : ram_t := (x"00000000",x"00000000",x"00000000",x"FFFFFFFF",x"AA995566",x"20000000",x"20000000",x"2800E001",x"00000000",x"00000000",x"20000000",x"20000000",x"20000000",x"20000000",x"00000000");
	constant RAM_BOOTSTS : ram_t := (x"00000000",x"00000000",x"00000000",x"FFFFFFFF",x"AA995566",x"20000000",x"20000000",x"2802C001",x"00000000",x"00000000",x"20000000",x"20000000",x"20000000",x"20000000",x"00000000");
	
	signal ct_word 												: unsigned(5 downto 0) := (others => '0');
	signal rdwrb_t, csb_t 										: std_logic := '1';
	signal data_t, data_bs, bootsts_reg, stat_reg, idcode_reg	: std_logic_vector(31 downto 0) := (others => '0');
	signal reset_start, set_start 								: std_logic := '0';

begin

	process(CLK, TRIGGER, reset_start)
	begin
		if rising_edge(CLK) then
			if (TRIGGER = '1') then
				set_start <= '1';
			elsif (reset_start = '1') then
				set_start <= '0';
			end if;
		end if;
	end process;

	process (CLK, ct_word)
	begin
		if rising_edge(CLK) then
			if (ct_word = 47) then
				reset_start <= '1';
			else
				reset_start <= '0';
			end if;
		end if;
	end process;
	
	process(CLK, set_start)
	begin
		if rising_edge(CLK) then
			if (set_start = '0') then
				rdwrb_t		<= '1';
				csb_t		<= '1';
				data_t		<= x"5555DDDD";
				ct_word		<= (others => '0');
			else
				if (ct_word /= 47) then
					ct_word <= ct_word + 1;
					case to_integer(ct_word) is
						when 0  to 14 	=> data_t <= RAM_IDCODE(to_integer(ct_word));
						when 16 to 30 	=> data_t <= RAM_STAT(to_integer(ct_word-16));
						when 32 to 46 	=> data_t <= RAM_BOOTSTS(to_integer(ct_word-32));
						when others 	=> data_t <= x"5555DDDD";
					end case;

					case to_integer(ct_word) is
						when 0 | 9 | 13 | 14 	=> rdwrb_t <= '1'; csb_t <= '1';
						when 1 | 8 				=> rdwrb_t <= '0'; csb_t <= '1';
						when 2 to 7 			=> rdwrb_t <= '0'; csb_t <= '0';
						when 10 to 12 			=> rdwrb_t <= '1'; csb_t <= '0';
						when 16 | 25 | 29 | 30 	=> rdwrb_t <= '1'; csb_t <= '1';
						when 17 | 24 			=> rdwrb_t <= '0'; csb_t <= '1';
						when 18 to 23 			=> rdwrb_t <= '0'; csb_t <= '0';
						when 26 to 28 			=> rdwrb_t <= '1'; csb_t <= '0';
						when 32 | 41 | 45 | 46 	=> rdwrb_t <= '1'; csb_t <= '1';
						when 33 | 40 			=> rdwrb_t <= '0'; csb_t <= '1';
						when 34 to 39 			=> rdwrb_t <= '0'; csb_t <= '0';
						when 42 to 44 			=> rdwrb_t <= '1'; csb_t <= '0';
						when others 			=> rdwrb_t <= '1'; csb_t <= '1';
					end case;

				end if;
			end if;
		end if;
	end process;

	Data_Swapping : for i in 0 to 7 generate begin -- Swap within bit and reverse order of byte (in accordance with the Xilinx UG360)
		data_bs(7 - i)	<= data_t(i);
		data_bs(15 - i)	<= data_t(8 + i);
		data_bs(23 - i)	<= data_t(16 + i);
		data_bs(31 - i)	<= data_t(24 + i);
	end generate;

	process (CLK, ct_word)
	begin
		if rising_edge(CLK) then
			if (to_integer(ct_word) = 13 or to_integer(ct_word) = 14) then
				idcode_reg <= ICAP_O;
			end if;

			if (to_integer(ct_word) = 29 or to_integer(ct_word) = 30) then
				stat_reg <= ICAP_O;
			end if;

			if (to_integer(ct_word) = 45 or to_integer(ct_word) = 46) then
				bootsts_reg <= ICAP_O;
			end if;
		end if;
	end process;

	IDCODE_Swapping : for i in 0 to 7 generate begin -- Swap within bit and reverse order of byte (in accordance with the Xilinx UG360)
		IDCODE(7 - i)	<= idcode_reg(i);
		IDCODE(15 - i)	<= idcode_reg(8 + i);
		IDCODE(23 - i)	<= idcode_reg(16 + i);
		IDCODE(31 - i)	<= idcode_reg(24 + i);
	end generate;

	STAT_Swapping : for i in 0 to 7 generate begin -- Swap within bit and reverse order of byte (in accordance with the Xilinx UG360)
		STAT(7 - i)		<= stat_reg(i);
		STAT(15 - i)	<= stat_reg(8 + i);
		STAT(23 - i)	<= stat_reg(16 + i);
		STAT(31 - i)	<= stat_reg(24 + i);
	end generate;

	BOOTSTS_Swapping : for i in 0 to 7 generate begin -- Swap within bit and reverse order of byte (in accordance with the Xilinx UG360)
		BOOTSTS(7 - i)	<= bootsts_reg(i);
		BOOTSTS(15 - i)	<= bootsts_reg(8 + i);
		BOOTSTS(23 - i)	<= bootsts_reg(16 + i);
		BOOTSTS(31 - i)	<= bootsts_reg(24 + i);
	end generate;

	ICAP_RDWRB	<= rdwrb_t;
	ICAP_CSB  	<= csb_t;
	ICAP_I 		<= data_bs;

end architecture;
