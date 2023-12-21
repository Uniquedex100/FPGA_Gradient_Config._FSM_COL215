library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hCountSim is
end hCountSim;

architecture Behavioral of hCountSim is
component hcounter is
  port (
    pclk : in std_logic;
    rst : in std_logic;
    hcnt : out integer;
    en : out std_logic
  ) ;
end component;
component clkdivider is 
    port(
        mclk : in std_logic; --assuming 100 MHz clock
        pclk : out std_logic  -- to make 25 MHz clock
    );
end component;

signal clock : std_logic := '0';
signal pclock : std_logic;
signal counter : integer := 0;
signal enable : std_logic;
signal reset : std_logic := '0';
begin
    cdd : clkdivider port map(clock,pclock);
    hc : hcounter port map(pclock,reset,counter,enable);
    clock <= not clock after 5 ns;
end Behavioral;
