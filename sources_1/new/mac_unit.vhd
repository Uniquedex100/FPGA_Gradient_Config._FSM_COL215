library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
entity mac_unit is
    port(
        clk : in std_logic;
        act : in std_logic;
        inp1 : in std_logic_vector(7 downto 0);
        inp2 : in std_logic_vector(7 downto 0);
        outp : out std_logic_vector(15 downto 0)
    );
end mac_unit;
architecture Behavioral of mac_unit is
    signal output : std_logic_vector(15 downto 0);
begin
main : process(clk)
    variable var1 : integer := 0;
    variable var2 : integer := 0;
    variable result : integer := 0;
    variable clock : integer := 0;
    variable counter : integer := 0;
begin
    if rising_edge(clk) then
        if( act = '1') then 
            if(counter = 9) then 
                counter := 0;
                result := 0;
            end if;
            var1 := to_integer(unsigned(inp1));
            var2 := to_integer(signed(inp2));
            result := result + var1 * var2;
    
            output <= std_logic_vector(to_unsigned(result,16));
            counter := counter+1;
        end if;
     end if;
end process;
outp <= output;
end Behavioral;
