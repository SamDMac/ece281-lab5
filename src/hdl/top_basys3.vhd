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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- 
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        btnC    :   in std_logic; --tdm_reset
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
 
-- 7SEG COMPONENT
      component sevenSegDecoder is
            port( i_D : in STD_LOGIC_VECTOR (3 downto 0);
             o_S : out STD_LOGIC_VECTOR (6 downto 0));
            end component sevenSegDecoder;
-- TDM COMPONENT
      component TDM4 is
            generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
            Port ( i_clk        : in  STD_LOGIC;
                   i_reset        : in  STD_LOGIC; -- asynchronous
                   i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                   i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                   i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                   i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                   o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                   o_sel        : out STD_LOGIC_VECTOR (3 downto 0)
                   );
            end component TDM4;
-- CLOCK COMPONENT
      component clock_divider is  
          generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                       -- Effectively, you divide the clk double this 
                                                       -- number (e.g., k_DIV := 2 --> clock divider of 4)
            port (  i_clk    : in std_logic;
                    i_reset  : in std_logic;           -- asynchronous
                    o_clk    : out std_logic           -- divided (slow) clock
            );
        end component clock_divider;
-- 2SCOMP COMPONENT
--    component twoscomp_decimal is
--        port (
--            i_binary: in std_logic_vector(7 downto 0);
--            o_negative: out std_logic;
--            o_hundreds: out std_logic_vector(3 downto 0);
--            o_tens: out std_logic_vector(3 downto 0);
--            o_ones: out std_logic_vector(3 downto 0)
--        );
--    end component twoscomp_decimal;
--ALU COMPONENT    
   component ALU is
   generic(N: integer := 8);
   Port ( i_A : in STD_LOGIC_VECTOR (N-1 downto 0);
          i_B : in STD_LOGIC_VECTOR (N-1 downto 0);
          o_flag : out STD_LOGIC_VECTOR(2 downto 0);
          o_ALU : out STD_LOGIC_VECTOR (N-1 downto 0);
          op : in std_logic_vector(2 downto 0));
   end component ALU;
--CONTROLLER COMPONENT
    component controller_fsm is
        Port ( i_input : in std_logic_vector(7 downto 0);
               i_adv : in STD_LOGIC;
               i_reset : in STD_LOGIC;
               o_S : out STD_LOGIC_VECTOR(3 downto 0);
               o_A : out STD_logic_vector(7 downto 0);
               o_B : out STD_logic_vector(7 downto 0)
               );
    end component controller_fsm;
   
--signals: 
        --choosing A&B
signal w_A : std_logic_vector(7 downto 0);
signal w_B : std_logic_vector(7 downto 0);
signal w_cycle : std_logic_vector(3 downto 0);
signal w_display : std_logic_vector(7 downto 0);
        --clock
signal w_clk : std_logic;
        --decimal #
signal w_negative : std_logic;
signal w_hundreds : std_logic_vector(3 downto 0);
signal w_tens : std_logic_vector(3 downto 0);
signal w_ones : std_logic_vector(3 downto 0);
        --TDM
signal w_data : std_logic_vector(3 downto 0);
signal w_sel : std_logic_vector(3 downto 0);
        --ALU
signal w_result : std_logic_vector(7 downto 0);
signal w_bin : std_logic_vector(7 downto 0);
signal w_ALU : std_logic_vector(7 downto 0);
signal w_op : std_logic_vector(2 downto 0);
        --7seg
signal w_7SD_EN_n : std_logic;
--
--BEGINNING HERE!!!!!!!!!!!!!!!!
--
begin
	-- PORT MAPS ----------------------------------------
ALU_inst : ALU
        port map (
        i_A => w_A,
        i_B => w_B,
        o_flag => led(15 downto 13),
        o_ALU => w_ALU,
        op => sw(15 downto 13)
        );

TDM4_inst : TDM4
        port map ( i_clk => w_clk,
                 i_reset => btnU,  
                 i_D3 => w_display(7 downto 4),
                 i_D2 => w_display(3 downto 0),    
                 i_D1 => w_display(3 downto 0),        
                 i_D0 => w_display(7 downto 4),
                 o_data => w_data,
                 o_sel => w_sel
                 );
sevenSegDecoder_inst : sevenSegDecoder
       port map (
               i_D => w_data,
               o_S => seg
                     );	
clkdiv_inst : clock_divider
       generic map (k_DIV => 100000)
       port map (
              i_clk => clk,
              i_reset => btnL,
              o_clk => w_clk
                            );   
controller_fsm_inst : controller_fsm
       port map (
              i_input => sw(7 downto 0),
              i_adv => btnC,
              i_reset => btnR,
              o_S => w_cycle,
              o_A => w_A,
              o_B => w_B           
                            ); 
	-- CONCURRENT STATEMENTS ----------------------------

--INPUT REGISTERS

--what to display
 w_display <= w_A when w_cycle="0001" else
              w_B when w_cycle="0010" else
              w_ALU when w_cycle="0100";	
--anodes	
	w_7SD_EN_n <= '1';
        an(3) <= w_7SD_EN_n;
        an(2) <= w_7SD_EN_n;
        an(1) <= '1' when w_cycle="1000" or w_sel="1011" or w_sel="1101" else '0';
        an(0) <= '1' when w_cycle="1000" or w_sel="0111" or w_sel="1110" else '0';
--LEDs
    led(3 downto 0) <= w_cycle;
	led(12 downto 4) <= "000000000";
end top_basys3_arch;
