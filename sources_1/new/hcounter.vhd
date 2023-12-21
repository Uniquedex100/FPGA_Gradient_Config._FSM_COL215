library ieee ;
    use ieee.std_logic_1164.all ;
entity hcounter is
  port (
    pclk : in std_logic;
    rst : in std_logic;
    hcnt : out integer;
    en : out std_logic
  ) ;
end hcounter;

architecture arch of hcounter is
signal counter : integer := 0;
signal enable : std_logic;
begin
  process(pclk,rst)
  begin
    if rst = '1' then
      counter <= 0;
      enable <= '0';
    elsif pclk'event and pclk = '1' then
      if counter = 799 then
        counter <= 0;
        enable <= '1';
      else 
        counter <= counter + 1;
        enable <= '0';
      end if;
    end if;
  end process;
  hcnt <= counter;
  en <= enable;
end architecture ;