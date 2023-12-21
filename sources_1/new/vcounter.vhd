library ieee ;
    use ieee.std_logic_1164.all ;
entity vcounter is
  port (
    pclk : in std_logic;
    rst : in std_logic;
    en : in std_logic;
    vcnt : out integer
  ) ;
end vcounter ; 

architecture arch of vcounter is
signal counter : integer := 0;
begin
    -- Do we actually need pclk in sensitivity list?
    process(pclk,en,rst)
    begin 
        if rst = '1' then
            counter <= 0;
        elsif en'event and en = '1' then
            if counter = 524 then
                counter <= 0;
            else 
                counter <= counter + 1;
            end if;
        end if;
    end process;
    vcnt <= counter;
end architecture ;