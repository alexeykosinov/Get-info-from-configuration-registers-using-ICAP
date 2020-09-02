library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
	use UNISIM.vcomponents.all;

entity sysinfo_top is 
	port(
		CLK : in std_logic
	); 
end entity;

architecture structural of sysinfo_top is

	signal CONTROL0 : std_logic_vector(35 downto 0);
	signal SYNC_OUT	: std_logic_vector(0 downto 0);
	signal SYNC_IN	: std_logic_vector(95 downto 0);

	signal get_info								: std_logic := '0';
    signal icap_csb, icap_rdwrb					: std_logic;
	signal icap_o, icap_i						: std_logic_vector(31 downto 0);
	signal idcode_reg, stat_reg, bootsts_reg	: std_logic_vector(31 downto 0);

begin
 
	SYSINFO_INST : entity WORK.sysinfo
		port map(
			CLK			=> CLK,
			TRIGGER		=> get_info,
			IDCODE    	=> idcode_reg,
			STAT    	=> stat_reg,
			BOOTSTS    	=> bootsts_reg,
			ICAP_RDWRB	=> icap_rdwrb,
			ICAP_CSB  	=> icap_csb,
			ICAP_O    	=> icap_o,
			ICAP_I    	=> icap_i
		);

	ICAP_INST : ICAP_VIRTEX6
		generic map(SIM_CFG_FILE_NAME => "NONE", DEVICE_ID => x"04250093", ICAP_WIDTH => "X32")
		port map(BUSY => open, O => icap_o, CLK => CLK, CSB => icap_csb, I => icap_i, RDWRB => icap_rdwrb);

	icon0_i 	: entity WORK.icon0 port map(CONTROL0 => CONTROL0);	
	vio0_i 		: entity WORK.vio0 	port map(CLK => CLK, CONTROL => CONTROL0, SYNC_IN => SYNC_IN, SYNC_OUT => SYNC_OUT);

	get_info				<= SYNC_OUT(0);

	SYNC_IN(31 downto 0)	<= idcode_reg;
	SYNC_IN(63 downto 32)	<= stat_reg;
	SYNC_IN(95 downto 64)	<= bootsts_reg;

end architecture;
