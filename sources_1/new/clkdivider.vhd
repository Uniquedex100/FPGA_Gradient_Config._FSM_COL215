library ieee;
use ieee.std_logic_1164.all;
entity clkdivider is
    port(
        mclk : in std_logic; --assuming 100 MHz clock
        pclk : out std_logic  -- to make 25 MHz clock
    );
end clkdivider;
architecture arch of clkdivider is
signal q : integer := 0;
signal temp : std_logic := '0';
begin
    process(mclk)
    begin
        if mclk'event and mclk = '1' then
            if q > 0 then
                q <= 0;
                temp <= not temp;
            else
                q <= q + 1;
            end if;
        end if;
    end process;
    pclk <= temp;
end arch;