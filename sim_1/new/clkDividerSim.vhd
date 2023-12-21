library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clkDividerSim is
end clkDividerSim;

architecture Behavioral of clkDividerSim is
component clkdivider is 
    port(
        mclk : in std_logic; --assuming 100 MHz clock
        pclk : out std_logic  -- to make 25 MHz clock
    );
end component;
signal clock : std_logic := '0';
signal pclock : std_logic;
begin
    cd : clkdivider port map(clock,pclock);
    clock <= not clock after 10 ns;
end Behavioral;
