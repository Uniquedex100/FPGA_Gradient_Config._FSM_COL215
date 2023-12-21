
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity SimMac_Unit is
end SimMac_Unit;

architecture Behavioral of SimMac_Unit is
component mac_unit
    port(
        clk : in std_logic;
        act : in std_logic;
        inp1 : in std_logic_vector(7 downto 0);
        inp2 : in std_logic_vector(7 downto 0);
        outp : out std_logic_vector(15 downto 0)
    );
end component;
signal clock : std_logic := '0';
signal var1 : integer := 1;
signal var2 : integer := 2;
signal result : integer := 0;
signal input1 : std_logic_vector(7 downto 0) := (others => '0');
signal input2 : std_logic_vector(7 downto 0) := (others => '0');
signal output : std_logic_vector(15 downto 0) := (others => '0');
signal active : std_logic := '1';
begin

mu : mac_unit port map(clock,active,input1,input2,output);
clock <= not clock after 10ns;
input1 <= std_logic_vector(to_unsigned(var1,8));
input2 <= std_logic_vector(to_unsigned(var2,8));
result <= to_integer(unsigned(output));
end Behavioral;
