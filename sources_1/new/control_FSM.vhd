library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity FSM is
Port(
-- Main input ports : 
    clk:in std_logic;   
    rst:in std_logic; 
-- Main output ports : 
    hsync: out std_logic;
    vsync: out std_logic;
    r: out std_logic_vector(3 downto 0);
    g: out std_logic_vector(3 downto 0);
    b: out std_logic_vector(3 downto 0)
);
end FSM;

architecture Machine of FSM is
component dist_mem_gen_0
        port(
             clk: in std_logic;
             a: in std_logic_vector(11 downto 0);
             spo: out std_logic_vector(7 downto 0)
        );
end component;
component dist_mem_gen_1
        port(
             clk: in std_logic;
             a: in std_logic_vector(11 downto 0);
             d:in std_logic_vector(7 downto 0);
             we: in std_logic;
             spo:out std_logic_vector(7 downto 0)
        );
end component;
component dist_mem_gen_2
        port(
            clk : in std_logic;
            a : in std_logic_vector(3 downto 0);
            spo : out std_logic_vector(7 downto 0)
        );
end component;
component clkdivider
    port(
        mclk : in std_logic; --assuming 100 MHz clock
        pclk : out std_logic
    );
end component;

component hcounter
    port(
        pclk : in std_logic;
        rst : in std_logic;
        hcnt : out integer;
        en : out std_logic
    );
end component;

component vcounter
    port(
        pclk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        vcnt : out integer
    );
end component;
component mac_unit
    port(
        clk : in std_logic;
        act : in std_logic;
        inp1 : in std_logic_vector(7 downto 0);
        inp2 : in std_logic_vector(7 downto 0);
        outp : out std_logic_vector(15 downto 0)
    );
end component;

-- signals for running display : 
signal clk25: std_logic:='0';
signal horcount: integer:=0;
signal vercount: integer:=0;
signal switchdisplay: std_logic:='0';
signal enable : std_logic := '0';
signal displayaddress: integer :=0;

-- signals for writing and reading ram : 
signal romaddress: std_logic_vector(11 downto 0) := (others => '0');
signal ramaddress : std_logic_vector(11 downto 0) := (others => '0');
signal romdata: std_logic_vector(7 downto 0) := (others => '0');
signal ramdata : std_logic_vector(7 downto 0) := (others => '0');
signal dram : std_logic_vector(7 downto 0) := (others => '0');
signal wr: std_logic:= '1';

--signals for reading kernel: 
signal kerneladdress: std_logic_vector(3 downto 0) := (others => '0');
signal kerneldata: std_logic_vector(7 downto 0) := (others => '0');
signal macresult: std_logic_vector(15 downto 0) := (others => '0');--16 bit to adjust according to input.
signal input1: std_logic_vector(7 downto 0) := (others => '0');
signal input2: std_logic_vector(7 downto 0) := (others => '0');

shared variable input1a : std_logic_vector(7 downto 0) := (others => '0');
shared variable input1b : std_logic_vector(7 downto 0) := (others => '0');
shared variable input2a : std_logic_vector(7 downto 0) := (others => '0');
shared variable input2b : std_logic_vector(7 downto 0) := (others => '0');

signal activ: std_logic := '0';
shared variable activ1: std_logic := '0';
shared variable activ2: std_logic := '0';
--signals for use in filtering operation : 
signal maxvalue : integer := 0;
signal minvalue : integer := 0;


shared variable tempcolor : std_logic_vector(3 downto 0) := "1010";
--extra variables for flow of information
shared variable i: integer:=0;
shared variable j: integer:=0;
shared variable i2: integer:=0;
shared variable j2: integer:=0;
--signal mode: integer:=64 * 2;
shared variable mode: integer:=0;
shared variable dmode: integer:= 0;
shared variable kmode: integer:= 0;
--signal clk : std_logic:='0';
--signal rst : std_logic:='0';
signal i00 : integer := 0;
signal i01 : integer := 0;
signal i02 : integer := 0;
signal i10 : integer := 0;
signal i11 : integer := 0;
signal i12 : integer := 0;
signal i20 : integer := 0;
signal i21 : integer := 0;
signal i22 : integer := 0;

signal val00 : integer := 0;
signal val01 : integer := 0;
signal val02 : integer := 0;
signal val10 : integer := 0;
signal val11 : integer := 0;
signal val12 : integer := 0;
signal val20 : integer := 0;
signal val21 : integer := 0;
signal val22 : integer := 0;
signal ans : integer := 0;
signal tempromaddress : std_logic_vector(11 downto 0) := (others => '0');
shared variable tempromaddress2 : std_logic_vector(11 downto 0) := (others => '0');

-- for fsm : 
type state_type is (ak, mm, ar, d);
signal cur_state : state_type := ak;
signal next_state : state_type := ak;
signal doneak,donemm,donear,doned : integer :=0;

begin
                     
--clk <= not clk after 5 ns;
            
-- Declaring alll the components : 
cd : clkdivider port map(clk,clk25);
rom: dist_mem_gen_0 port map(clk,romaddress,romdata);
ram: dist_mem_gen_1 port map(clk,ramaddress,dram,wr,ramdata);
kernel : dist_mem_gen_2 port map(clk,kerneladdress,kerneldata);
hc: hcounter port map(clk25,rst,horcount,enable);
vc: vcounter port map(clk25,rst,enable,vercount);
mac : mac_unit port map(clk,activ,input1,input2,macresult);
--mac : mac_unit port map(clk,input1,kerneldata,macresult);

process (clk, rst)
begin
    if (rst = '1') then
        cur_state <= ak;
    elsif (clk'EVENT AND clk = '1') then
    cur_state <= next_state;
    end if;
end process;
fsm : process (clk)
begin
    if(rising_edge(clk)) then 
        next_state <= cur_state;
        case cur_state is
            when ak =>
                if doneak = 1 then
                    next_state <= mm;
                end if;
            when mm =>
                if donemm = 1 then
                    next_state <= ar;
                end if;
            when ar =>
                if donear = 1 then
                    next_state <= d;
                end if;
            when d =>
                if doned = 1 then
                    next_state <= ar;
                end if;
        end case;
     end if;
end process;
-- assgning the ram memory : 
assign_kernel : process(clk)
       variable aclock : integer := 0;
begin
   if cur_state = ak and kmode = 0 then
     if(clk'event and clk = '1') then 
           if(aclock = 0) then
                kerneladdress <= std_logic_vector(to_unsigned(0,4));
                aclock := 1;
           elsif aclock = 1 then aclock := 2;
           elsif aclock = 2 then aclock := 3;
           elsif(aclock = 3) then aclock := 4;
                i00 <= to_integer(signed(kerneldata)); 
           elsif(aclock = 4) then aclock := 5;
           elsif(aclock = 5) then aclock := 6;
           elsif(aclock = 6) then aclock := 7;
                kerneladdress <= std_logic_vector(to_unsigned(1,4));
           elsif(aclock = 7) then aclock := 8;
           elsif(aclock = 8) then aclock := 9;
           elsif(aclock = 9) then aclock := 10;
                i01 <= to_integer(signed(kerneldata));
           elsif(aclock = 10) then aclock := 11;
           elsif(aclock = 11) then aclock := 12;
           elsif(aclock = 12) then aclock := 13;
                kerneladdress <= std_logic_vector(to_unsigned(2,4));
           elsif(aclock = 13) then aclock := 14;
           elsif(aclock = 14) then aclock := 15;
           elsif(aclock = 15) then aclock := 16;
                i02 <= to_integer(signed(kerneldata));
           elsif(aclock = 16) then aclock := 17;
           elsif(aclock = 17) then aclock := 18;
           elsif(aclock = 18) then aclock := 19;
                kerneladdress <= std_logic_vector(to_unsigned(3,4));
           elsif(aclock = 19) then aclock := 20;
           elsif(aclock = 20) then aclock := 21;
           elsif(aclock = 21) then aclock := 22;
                i10 <= to_integer(signed(kerneldata));
           elsif(aclock = 22) then aclock := 23;
           elsif(aclock = 23) then aclock := 24;
           elsif(aclock = 24) then aclock := 25;
                kerneladdress <= std_logic_vector(to_unsigned(4,4));
           elsif(aclock = 25) then aclock := 26;
           elsif(aclock = 26) then aclock := 27;
           elsif(aclock = 27) then aclock := 28;
                i11 <= to_integer(signed(kerneldata));
           elsif(aclock = 28) then aclock := 29;
           elsif(aclock = 29) then aclock := 30;
           elsif(aclock = 30) then aclock := 31;
                kerneladdress <= std_logic_vector(to_unsigned(5,4));
           elsif(aclock = 31) then aclock := 32;
           elsif(aclock = 32) then aclock := 33;
           elsif(aclock = 33) then aclock := 34;
                i12 <= to_integer(signed(kerneldata));
           elsif(aclock = 34) then aclock := 35;
           elsif(aclock = 35) then aclock := 36;
           elsif(aclock = 36) then aclock := 37;
                kerneladdress <= std_logic_vector(to_unsigned(6,4));
           elsif(aclock = 37) then aclock := 38;
           elsif(aclock = 38) then aclock := 39;
           elsif(aclock = 39) then aclock := 40;
                i20 <= to_integer(signed(kerneldata));
           elsif(aclock = 40) then aclock := 41;
           elsif(aclock = 41) then aclock := 42;
           elsif(aclock = 42) then aclock := 43;
                kerneladdress <= std_logic_vector(to_unsigned(7,4));
           elsif(aclock = 43) then aclock := 44;
           elsif(aclock = 44) then aclock := 45;
           elsif(aclock = 45) then aclock := 46;
                i21 <= to_integer(signed(kerneldata));
           elsif(aclock = 46) then aclock := 47;
           elsif(aclock = 47) then aclock := 48;
           elsif(aclock = 48) then aclock := 49;
                kerneladdress <= std_logic_vector(to_unsigned(8,4));
           elsif(aclock = 49) then aclock := 50;
           elsif(aclock = 50) then aclock := 51;
           elsif(aclock = 51) then 
                i22 <= to_integer(signed(kerneldata));
                aclock := 52;
                doneak<= 1;
                kmode := 1;
           end if; 
     end if;
   end if;
end process;
calc_max_min : process(clk)
variable bclock : integer := 0;
variable cclock : integer := 0;
begin
if dmode < 64 and cur_state = mm and kmode = 1 then 
     if(clk'event and clk = '1') then 
        if(bclock = 0) then bclock := 1;
           if (i-1<64 and i-1>=0) then
           end if;
       elsif(bclock = 1) then bclock := 2;
       elsif(bclock = 2) then bclock := 3;
       elsif(bclock = 3) then bclock := 4;
            if (i-1<64 and i-1>=0) then
                  val00 <= val01;
            else
                val00 <= 0;
            end if;
       elsif(bclock = 4) then bclock := 5;
       elsif(bclock = 5) then bclock := 6;
       elsif(bclock = 6) then bclock := 7;
            if (i<64 and i>=0) then
            end if;
       elsif(bclock = 7) then bclock := 8;
       elsif(bclock = 8) then bclock := 9;
       elsif(bclock = 9) then bclock := 10;
            if (i<64 and i>=0) then
                  val01 <= val02;
            else
                val01 <= 0;
            end if;
       elsif(bclock = 10) then bclock := 11;
       elsif(bclock = 11) then bclock := 12;
       elsif(bclock = 12) then bclock := 13;
            if (i+1<64 and i+1>=0 and j-1>=0 and j-1< 64) then
                tempromaddress <= std_logic_vector(to_unsigned(64*(j-1) + i + 1,12));
            end if;
       elsif(bclock = 13) then bclock := 14;
       elsif(bclock = 14) then bclock := 15;
       elsif(bclock = 15) then bclock := 16;
            if (i+1<64 and i+1>=0 and j-1>=0 and j-1< 64) then
                val02 <= to_integer(unsigned(romdata));
            else
                val02 <= 0;
            end if;
       elsif(bclock = 16) then bclock := 17;
       elsif(bclock = 17) then bclock := 18;
       elsif(bclock = 18) then bclock := 19;
           if (i-1<64 and i-1>=0) then
           end if;
       elsif(bclock = 19) then bclock := 20;
       elsif(bclock = 20) then bclock := 21;
       elsif(bclock = 21) then bclock := 22;
            if (i-1<64 and i-1>=0) then
                  val10 <= val11;
            else
                val10 <= 0;
            end if;
       elsif(bclock = 22) then bclock := 23;
       elsif(bclock = 23) then bclock := 24;
       elsif(bclock = 24) then bclock := 25;
            if (i<64 and i>=0) then
            end if;
       elsif(bclock = 25) then bclock := 26;
       elsif(bclock = 26) then bclock := 27;
       elsif(bclock = 27) then bclock := 28;
            if (i<64 and i>=0) then
                  val11 <= val12;
            else
                val11 <= 0;
            end if;
       elsif(bclock = 28) then bclock := 29;
       elsif(bclock = 29) then bclock := 30;
       elsif(bclock = 30) then bclock := 31;
            if (i+1<64 and i+1>=0 and j>=0 and j< 64) then
                tempromaddress <= std_logic_vector(to_unsigned(64*j + i + 1,12));
            end if;
       elsif(bclock = 31) then bclock := 32;
       elsif(bclock = 32) then bclock := 33;
       elsif(bclock = 33) then bclock := 34;
            if (i+1<64 and i+1>=0 and j>=0 and j< 64) then
                val12 <= to_integer(unsigned(romdata));
            else
                val12 <= 0;
            end if;
       elsif(bclock = 34) then bclock := 35;
       elsif(bclock = 35) then bclock := 36;
       elsif(bclock = 36) then bclock := 37;
           if (i-1<64 and i-1>=0) then
           end if;
       elsif(bclock = 37) then bclock := 38;
       elsif(bclock = 38) then bclock := 39;
       elsif(bclock = 39) then bclock := 40;
            if (i-1<64 and i-1>=0) then
                  val20 <= val21;
            else
                val20 <= 0;
            end if;
       elsif(bclock = 40) then bclock := 41;
       elsif(bclock = 41) then bclock := 42;
       elsif(bclock = 42) then bclock := 43;
            if (i<64 and i>=0) then
            end if;
       elsif(bclock = 43) then bclock := 44;
       elsif(bclock = 44) then bclock := 45;
       elsif(bclock = 45) then bclock := 46;
            if (i<64 and i>=0) then
                  val21 <= val22;
            else
                val21 <= 0;
            end if;
       elsif(bclock = 46) then bclock := 47;
       elsif(bclock = 47) then bclock := 48;
       elsif(bclock = 48) then bclock := 49;
            if (i+1<64 and i>=0 and j+1>=0 and j+1<64) then
                tempromaddress <= std_logic_vector(to_unsigned(64*(j+1) + i + 1,12));
            end if;
       elsif(bclock = 49) then bclock := 50;
       elsif(bclock = 50) then bclock := 51;
       elsif(bclock = 51) then bclock := 52;
            if (i+1<64 and i+1>=0 and j+1>=0 and j+1<64) then
                val22 <= to_integer(unsigned(romdata));
            else
                val22 <= 0;
            end if;
       elsif(bclock = 52) then bclock := 53;
       elsif(bclock = 53) then bclock := 54;
       elsif(bclock = 54) then
           activ1 := '1';
           if(cclock = 0) then 
                input1a := std_logic_vector(to_unsigned(val00,8));
                input2a := std_logic_vector(to_unsigned(i00,8));
                cclock := 1;
           elsif(cclock = 1) then 
                input1a := std_logic_vector(to_unsigned(val01,8));
                input2a := std_logic_vector(to_unsigned(i01,8));
                cclock := 2;
           elsif(cclock = 2) then 
                input1a := std_logic_vector(to_unsigned(val02,8));
                input2a := std_logic_vector(to_unsigned(i02,8));
                cclock := 3;
           elsif(cclock = 3) then 
                input1a := std_logic_vector(to_unsigned(val10,8));
                input2a := std_logic_vector(to_unsigned(i10,8));
                cclock := 4;
           elsif(cclock = 4) then 
                input1a := std_logic_vector(to_unsigned(val11,8));
                input2a := std_logic_vector(to_unsigned(i11,8));
                cclock := 5;
           elsif(cclock = 5) then 
                input1a := std_logic_vector(to_unsigned(val12,8));
                input2a := std_logic_vector(to_unsigned(i12,8));
                cclock := 6;
           elsif(cclock = 6) then 
                input1a := std_logic_vector(to_unsigned(val20,8));
                input2a := std_logic_vector(to_unsigned(i20,8));
                cclock := 7;
           elsif(cclock = 7) then 
                input1a := std_logic_vector(to_unsigned(val21,8));
                input2a := std_logic_vector(to_unsigned(i21,8));
                cclock := 8;
           elsif(cclock = 8) then 
                input1a := std_logic_vector(to_unsigned(val22,8));
                input2a := std_logic_vector(to_unsigned(i22,8));
                cclock := 9;
           elsif(cclock = 9) then cclock := 10;
--                ans := to_integer(signed(macresult));  
                ans <= i00*val00;
           elsif cclock = 10 then cclock := 11;
           elsif cclock = 11 then cclock := 12;
                ans <= ans + i01*val01;
           elsif cclock = 12 then cclock := 13;
           elsif cclock = 13 then cclock := 14;
                ans <= ans + i02*val02;
           elsif cclock = 14 then cclock := 15;
           elsif cclock = 15 then cclock := 16;
                ans <= ans + i10*val10;
           elsif cclock = 16 then cclock := 17;
           elsif cclock = 17 then cclock := 18;
                ans <= ans + i11*val11;
           elsif cclock = 18 then cclock := 19;
           elsif cclock = 19 then cclock := 20;
                ans <= ans + i12*val12;
           elsif cclock = 20 then cclock := 21;
           elsif cclock = 21 then cclock := 22;
                ans <= ans + i20*val20;
           elsif cclock = 22 then cclock := 23;
           elsif cclock = 23 then cclock := 24;
                ans <= ans + i21*val21;
           elsif cclock = 24 then cclock := 25;
           elsif cclock = 25 then cclock := 26;
                ans <= ans + i22*val22;
           elsif cclock = 26 then cclock := 27;
           elsif cclock = 27 then cclock := 28;
                input2a := std_logic_vector(to_unsigned(0,8));
                input1a := std_logic_vector(to_unsigned(0,8));
                cclock := 0;
                activ1 := '0';
                bclock := 55;
           end if;
       elsif(bclock = 55) then bclock := 56;
       elsif(bclock = 56) then bclock := 57;
       elsif(bclock = 57) then bclock := 58;
       elsif(bclock = 58) then bclock := 59;
       elsif(bclock = 59) then bclock := 60;
       elsif(bclock = 60) then bclock := 61;
            if(maxvalue < ans) then 
                maxvalue <= ans;
            end if;
            if(minvalue > ans) then 
                minvalue <= ans;
            end if;
       elsif(bclock = 61) then bclock := 62;
       elsif(bclock = 62) then bclock := 63;
       elsif(bclock = 63) then bclock := 64;
           i := i + 1;
           if(i = 64) then
                i := 0;
                j := j + 1;
                if(j = 64) then 
                    j := 0;
                    donemm <= 1;
                end if;
                
                val00 <= 0;
                val01 <= 0;
                val02 <= 0;
                val10 <= 0;
                val11 <= 0;
                val12 <= 0;
                val20 <= 0;
                val21 <= 0;
                val22 <= 0;
                dmode := dmode + 1;
                tempcolor := "0011";
           end if;
           bclock := 0;
       end if;
     end if;
end if;
end process;
write_in_ram : process(clk)
       variable clock : integer := 0;
       variable intclock : integer := 0;
       variable temp1 : integer := 0;
       variable temp2 : integer := 0;
       variable temp3 : integer := 0;
       variable val00 : integer := 0;
       variable val01 : integer := 0;
       variable val02 : integer := 0;
       variable val10 : integer := 0;
       variable val11 : integer := 0;
       variable val12 : integer := 0;
       variable val20 : integer := 0;
       variable val21 : integer := 0;
       variable val22 : integer := 0;
       variable ans : integer := 0;
       
       variable temp_mac_result : integer := 0;
   begin
   if mode < 64 and dmode = 64 and cur_state = ar and kmode = 1 then
     if(clk'event and clk = '1') then
       if(clock = 0) then clock := 1;
           if (i2-1<64 and i2-1>=0) then
           end if;
       elsif(clock = 1) then clock := 2;
       elsif(clock = 2) then clock := 3;
       elsif(clock = 3) then clock := 4;
            if (i2-1<64 and i2-1>=0) then
                  val00 := val01;
            else
                val00 := 0;
            end if;
       elsif(clock = 4) then clock := 5;
       elsif(clock = 5) then clock := 6;
       elsif(clock = 6) then clock := 7;
            if (i2<64 and i2>=0) then
            end if;
       elsif(clock = 7) then clock := 8;
       elsif(clock = 8) then clock := 9;
       elsif(clock = 9) then clock := 10;
            if (i2<64 and i2>=0) then
                  val01 := val02;
            else
                val01 := 0;
            end if;
       elsif(clock = 10) then clock := 11;
       elsif(clock = 11) then clock := 12;
       elsif(clock = 12) then clock := 13;
            if (i2+1<64 and i2+1>=0 and j2-1>=0 and j2-1< 64) then
                tempromaddress2 := std_logic_vector(to_unsigned(64*(j2-1) + i2 + 1,12));
            end if;
       elsif(clock = 13) then clock := 14;
       elsif(clock = 14) then clock := 15;
       elsif(clock = 15) then clock := 16;
            if (i2+1<64 and i2+1>=0 and j2-1>=0 and j2-1< 64) then
                val02 := to_integer(unsigned(romdata));
            else
                val02 := 0;
            end if;
       elsif(clock = 16) then clock := 17;
       elsif(clock = 17) then clock := 18;
       elsif(clock = 18) then clock := 19;
           if (i2-1<64 and i2-1>=0) then
           end if;
       elsif(clock = 19) then clock := 20;
       elsif(clock = 20) then clock := 21;
       elsif(clock = 21) then clock := 22;
            if (i2-1<64 and i2-1>=0) then
                  val10 := val11;
            else
                val10 := 0;
            end if;
       elsif(clock = 22) then clock := 23;
       elsif(clock = 23) then clock := 24;
       elsif(clock = 24) then clock := 25;
            if (i2<64 and i2>=0) then
            end if;
       elsif(clock = 25) then clock := 26;
       elsif(clock = 26) then clock := 27;
       elsif(clock = 27) then clock := 28;
            if (i2<64 and i2>=0) then
                  val11 := val12;
            else
                val11 := 0;
            end if;
       elsif(clock = 28) then clock := 29;
       elsif(clock = 29) then clock := 30;
       elsif(clock = 30) then clock := 31;
            if (i2+1<64 and i2+1>=0 and j2>=0 and j2< 64) then
                tempromaddress2 := std_logic_vector(to_unsigned(64*j2 + i2 + 1,12));
            end if;
       elsif(clock = 31) then clock := 32;
       elsif(clock = 32) then clock := 33;
       elsif(clock = 33) then clock := 34;
            if (i2+1<64 and i2+1>=0 and j2>=0 and j2< 64) then
                val12 := to_integer(unsigned(romdata));
            else
                val12 := 0;
            end if;
       elsif(clock = 34) then clock := 35;
       elsif(clock = 35) then clock := 36;
       elsif(clock = 36) then clock := 37;
           if (i2-1<64 and i2-1>=0) then
           end if;
       elsif(clock = 37) then clock := 38;
       elsif(clock = 38) then clock := 39;
       elsif(clock = 39) then clock := 40;
            if (i2-1<64 and i2-1>=0) then
                  val20 := val21;
            else
                val20 := 0;
            end if;
       elsif(clock = 40) then clock := 41;
       elsif(clock = 41) then clock := 42;
       elsif(clock = 42) then clock := 43;
            if (i2<64 and i2>=0) then
            end if;
       elsif(clock = 43) then clock := 44;
       elsif(clock = 44) then clock := 45;
       elsif(clock = 45) then clock := 46;
            if (i2<64 and i2>=0) then
                  val21 := val22;
            else
                val21 := 0;
            end if;
       elsif(clock = 46) then clock := 47;
       elsif(clock = 47) then clock := 48;
       elsif(clock = 48) then clock := 49;
            if (i2+1<64 and i2>=0 and j2+1>=0 and j2+1<64) then
                tempromaddress2 := std_logic_vector(to_unsigned(64*(j2+1) + i2 + 1,12));
            end if;
       elsif(clock = 49) then clock := 50;
       elsif(clock = 50) then clock := 51;
       elsif(clock = 51) then clock := 52;
            if (i2+1<64 and i2+1>=0 and j2+1>=0 and j2+1<64) then
                val22 := to_integer(unsigned(romdata));
            else
                val22 := 0;
            end if;
       elsif(clock = 52) then clock := 53;
       elsif(clock = 53) then clock := 54;
       elsif(clock = 54) then
           activ2 := '1';
           if(intclock = 0) then 
                input1b := std_logic_vector(to_unsigned(val00,8));
                input2b := std_logic_vector(to_unsigned(i00,8));
                intclock := 1;
           elsif(intclock = 1) then 
                input1b := std_logic_vector(to_unsigned(val01,8));
                input2b := std_logic_vector(to_unsigned(i01,8));
                intclock := 2;
           elsif(intclock = 2) then 
                input1b := std_logic_vector(to_unsigned(val02,8));
                input2b := std_logic_vector(to_unsigned(i02,8));
                intclock := 3;
           elsif(intclock = 3) then 
                input1b := std_logic_vector(to_unsigned(val10,8));
                input2b := std_logic_vector(to_unsigned(i10,8));
                intclock := 4;
           elsif(intclock = 4) then 
                input1b := std_logic_vector(to_unsigned(val11,8));
                input2b := std_logic_vector(to_unsigned(i11,8));
                intclock := 5;
           elsif(intclock = 5) then 
                input1b := std_logic_vector(to_unsigned(val12,8));
                input2b := std_logic_vector(to_unsigned(i12,8));
                intclock := 6;
           elsif(intclock = 6) then 
                input1b := std_logic_vector(to_unsigned(val20,8));
                input2b := std_logic_vector(to_unsigned(i20,8));
                intclock := 7;
           elsif(intclock = 7) then 
                input1b := std_logic_vector(to_unsigned(val21,8));
                input2b := std_logic_vector(to_unsigned(i21,8));
                intclock := 8;
           elsif(intclock = 8) then 
                input1b := std_logic_vector(to_unsigned(val22,8));
                input2b := std_logic_vector(to_unsigned(i22,8));
                intclock := 9;
--                ans := to_integer(signed(macresult)); 
                ans := i00*val00;
           elsif intclock = 9 then intclock := 10;
           elsif intclock = 10 then intclock := 11;
           elsif intclock = 11 then intclock := 12;
                ans := ans + i01*val01;
           elsif intclock = 12 then intclock := 13;
           elsif intclock = 13 then intclock := 14;
                ans := ans + i02*val02;
           elsif intclock = 14 then intclock := 15;
           elsif intclock = 15 then intclock := 16;
                ans := ans + i10*val10;
           elsif intclock = 16 then intclock := 17;
           elsif intclock = 17 then intclock := 18;
                ans := ans + i11*val11;
           elsif intclock = 18 then intclock := 19;
           elsif intclock = 19 then intclock := 20;
                ans := ans + i12*val12;
           elsif intclock = 20 then intclock := 21;
           elsif intclock = 21 then intclock := 22;
                ans := ans + i20*val20;
           elsif intclock = 22 then intclock := 23;
           elsif intclock = 23 then intclock := 24;
                ans := ans + i21*val21;
           elsif intclock = 24 then intclock := 25;
           elsif intclock = 25 then intclock := 26;
                ans := ans + i22*val22;
           elsif intclock = 26 then intclock := 27;
           elsif intclock = 27 then intclock := 28;
                input2b := std_logic_vector(to_unsigned(0,8));
                input1b := std_logic_vector(to_unsigned(0,8));
                intclock := 0;
                activ2 := '0';
                clock := 55;
           end if;
       elsif(clock = 55) then clock := 56;
            temp_mac_result := ans - minvalue;
       elsif(clock = 56) then clock := 57;
            temp_mac_result := temp_mac_result * 255;
       elsif(clock = 57) then clock := 58;
       elsif(clock = 58) then clock := 59; 
            temp1 := (maxvalue - minvalue);
       elsif(clock = 59) then clock := 60;
       elsif(clock = 60) then clock := 61;
       elsif(clock = 61) then clock := 62;
       elsif(clock = 62) then clock := 63;
            temp_mac_result := temp_mac_result/temp1;
--              if(temp_mac_result > 255) then temp_mac_result := 255;
--              elsif temp_mac_result < 0 then temp_mac_result := 0;
--              end if;
       elsif(clock = 63) then clock := 64;
       elsif(clock = 64) then clock := 65;
       elsif(clock = 65) then clock := 66;
       elsif(clock = 66) then clock := 67;
       elsif(clock = 67) then clock := 68;
       elsif(clock = 68) then clock := 69;
       elsif(clock = 69) then clock := 70;
       elsif(clock = 70) then clock := 71;
       elsif(clock = 71) then clock := 72;
       elsif(clock = 72) then clock := 73;
       elsif(clock = 73) then clock := 74;
       elsif(clock = 74) then clock := 75;
       elsif(clock = 75) then clock := 76;
       elsif(clock = 76) then clock := 77;
       elsif(clock = 77) then clock := 78;
       elsif(clock = 78) then clock := 79;
       elsif(clock = 79) then clock := 80;
       elsif(clock = 80) then clock := 81;
       elsif(clock = 81) then clock := 82;
       elsif(clock = 82) then clock := 83;

            dram <= std_logic_vector(to_unsigned(temp_mac_result,8));
--            dram <= "11111111";
--            dram <= "10101010";    

       elsif(clock = 83) then clock := 84;
       elsif(clock = 84) then clock := 85;
       elsif(clock = 85) then clock := 86;
           i2 := i2 + 1;
           if(i2 = 64) then
                i2 := 0;
                j2 := j2 + 1;
                if(j2 = 64) then
                    donear <= 1;
                end if;
                val00 := 0;
                val01 := 0;
                val02 := 0;
                val10 := 0;
                val11 := 0;
                val12 := 0;
                val20 := 0;
                val21 := 0;
                val22 := 0;
                mode := mode + 1;
           end if;
           clock := 0;
       end if;
   end if;
 end if;
end process;

-- assigning the sync signals for the display :
-- note that these are assigned always
assign_sync : process(horcount,vercount)
begin
    if(horcount <= 655 or horcount >= 751) then
        hsync <= '1';
    else
        hsync <= '0';
    end if;
    if(vercount <= 489 or vercount >= 491) then
        vsync <= '1';
    else
        vsync <= '0';
    end if;
end process;

-- assign if the screen is displaying or not.
assign_display : process(clk25,rst,horcount,vercount)
begin
  if(rst='1') then
      switchdisplay <= '0';
   elsif(clk25'event and clk25='1') then
        if(horcount<=639 and vercount<=479) then
           switchdisplay<='1';
        else
           switchdisplay<='0';
        end if;
   end if;
end process;

-- a separate process to assign the addresses as it is not 
-- possible to assign addresses in 2 separate processes.
assign_address: process(clk)
    begin
    if(rising_edge(clk)) then
        if(mode < 64 and dmode = 64) then
            ramaddress<=std_logic_vector(to_unsigned(64*j2+i2, 12));
            wr<='1';
        elsif(mode = 64) then
             ramaddress<=std_logic_vector(to_unsigned(displayaddress, 12));
             wr<='0';
        end if;
    end if;
end process;
ppp: process(clk)
    begin
    if(rising_edge(clk)) then
        if(dmode < 64 and kmode = 1) then
            romaddress<=tempromaddress;
        elsif(mode < 64 and dmode = 64) then
            romaddress<=tempromaddress2;
        end if;
    end if;
end process;
qqq: process(clk)
    begin
    if(rising_edge(clk)) then
        if(dmode < 64 and kmode = 1) then
            input1<=input1a;
        elsif(mode < 64 and dmode = 64) then
            input1<=input1b;
        end if;
    end if;
end process;
rrr: process(clk)
    begin
    if(rising_edge(clk)) then
        if(dmode < 64 and kmode = 1) then
            input2<=input2a;
        elsif(mode < 64 and dmode = 64) then
            input2<=input2b;
        end if;
    end if;
end process;
sss: process(clk)
    begin
    if(rising_edge(clk)) then
        if(dmode < 64 and kmode = 1) then
            activ<=activ1;
        elsif(mode < 64 and dmode = 64) then
            activ<=activ2;
        end if;
    end if;
end process;
-- Final process to display the stuff
display_on_vga:process(clk25, rst , horcount, vercount, switchdisplay)
begin
if(clk25'event and clk25 = '1') then
   if(mode=64 and dmode = 64 and cur_state = d and kmode = 1 and rst = '0' and switchdisplay = '1' and horcount>=110 and horcount<=173 and vercount>=110 and vercount<=173) then
        r(0)<=ramdata(4);
        r(1)<=ramdata(5);
        r(2)<=ramdata(6);
        r(3)<=ramdata(7);
        
        g(0)<=ramdata(4);
        g(1)<=ramdata(5);
        g(2)<=ramdata(6);
        g(3)<=ramdata(7);
        
        b(0)<=ramdata(4);
        b(1)<=ramdata(5);
        b(2)<=ramdata(6);
        b(3)<=ramdata(7);
        
        if(horcount=173 and vercount=173) then
            displayaddress<=0;
        else
            displayaddress<=displayaddress+1;
        end if;     
    else
          r<="0000";
          g<="0000";
          b<="0000";
    end if;
end if;
end process;
end Machine;
--445 and -374//