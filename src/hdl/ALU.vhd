--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|     SUB     001
--|     AND     01X
--|     LSH     100
--|     RSH     101
--|     OR      11X
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
   generic(N: integer := 8);
   Port ( i_A : in STD_LOGIC_VECTOR (N-1 downto 0);
          i_B : in STD_LOGIC_VECTOR (N-1 downto 0);
          o_flag : out STD_LOGIC_VECTOR(2 downto 0);
          o_ALU : out STD_LOGIC_VECTOR (N-1 downto 0);
          op : in std_logic_vector(2 downto 0));
end ALU;

architecture behavioral of ALU is 

	-- declare components and signals
signal w_shift : std_logic_vector(N-1 downto 0);
signal w_and : std_logic_vector(N-1 downto 0);
signal w_ALUout : std_logic_vector(N-1 downto 0);
signal w_or : std_logic_vector(N-1 downto 0);
signal w_add : STD_LOGIC_VECTOR(N downto 0);
signal w_cout : std_logic;
signal w_B : STD_LOGIC_VECTOR(N-1 downto 0);
signal cin : STD_LOGIC_VECTOR (0 downto 0);

begin
	cin <= op(0 downto 0);
-- ADDER CODE
    w_B <= i_B when op(0)='0' else not i_B; 
    w_add(N-1 downto 0) <= std_logic_vector(unsigned(i_A) + unsigned(w_B) + unsigned(cin));
    
-- SHIFTER CODE
--    w_shift <= std_logic_vector(shift_left(unsigned(i_A),unsigned(i_B(2 downto 0))));
-- AND/OR CODE	
    
-- OUTPUT CODE
	
	w_ALUout <= w_add(N-1 downto 0); --when op(2 downto 1)=x"0" else
	         --w_shift when op(2 downto 1)=x"2" else
	         --w_or when op(2 downto 1)=x"3" else
	         --w_and;
   
    o_ALU <= w_ALUout;
    o_flag(0) <= w_add(N);
    o_flag(1) <= '1' when w_ALUout="00000000" else '0';
    o_flag(2) <= '0';--w_ALUout(N-1);
	
	
end behavioral;
