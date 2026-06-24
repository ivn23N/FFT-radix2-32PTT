library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
 
entity tb_TOPmain is
end entity tb_TOPmain;
 
architecture sim of tb_TOPmain is
 
    constant DATA_WIDTH : integer := 32;
    constant N_POINTS   : integer := 32;
    constant FRAC_WIDTH : integer := 15;
    constant HALF_WIDTH : integer := DATA_WIDTH / 2;
 
    constant FRAC_DATA_WIDTH : integer := 8;
    constant DATA_SCALE      : integer := 2 ** FRAC_DATA_WIDTH;
 
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal start : std_logic := '0';
    signal done  : std_logic;
 
    signal data_in  : std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0)
                      := (others => '0');
    signal data_out : std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
 
    signal sim_done : boolean := false;
 
    type int_vec_t is array (0 to N_POINTS-1) of integer;
 
     constant X_RE : int_vec_t := (
         1239,  1355,   744,   474,
          738,   669,   480,   486,
         1202,  1581,  1099,   530,
          268,   289,  -206,  -551,
          -74,   964,   600,   116,
         -198,   -84,  -636, -1229,
        -1228,  -578,  -170,  -290,
         -305,   -83,  -215,  -841
    );
    
    constant X_IM : int_vec_t := (
          558,   171,   100,   946,
          850,   221,   183,  -462,
         -611,   213,    76,  -513,
         -445, -1089,  -945,    62,
         -143,  -619,  -207,  -667,
         -223,   779,   684,   718,
          680,   140,   466,  1015,
          348,   136,  -263,  -959
    );
 
    function pack_complex(re : integer; im : integer)
        return std_logic_vector
    is
        variable v : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        v(HALF_WIDTH-1 downto 0)          :=
            std_logic_vector(to_signed(re, HALF_WIDTH));
        v(DATA_WIDTH-1 downto HALF_WIDTH) :=
            std_logic_vector(to_signed(im, HALF_WIDTH));
        return v;
    end function;
 
    function get_re(sample : std_logic_vector(DATA_WIDTH-1 downto 0))
        return integer is
    begin
        return to_integer(signed(sample(HALF_WIDTH-1 downto 0)));
    end function;
 
    function get_im(sample : std_logic_vector(DATA_WIDTH-1 downto 0))
        return integer is
    begin
        return to_integer(signed(sample(DATA_WIDTH-1 downto HALF_WIDTH)));
    end function;
 
begin
 
    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;
 
    DUT : entity work.TOPmain
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            N_POINTS   => N_POINTS,
            FRAC_WIDTH => FRAC_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            data_in  => data_in,
            data_out => data_out,
            done     => done
        );
 
    stim_proc : process
    variable re_hw, im_hw : integer;
    file out_file : text;
    variable out_line : line;
    variable sample_slv : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    begin
 
        wait until falling_edge(clk);
        rst   <= '1';
        start <= '0';
        for i in 0 to 4 loop
            wait until falling_edge(clk);
        end loop;
        rst <= '0';
        wait until falling_edge(clk);

        for i in 0 to N_POINTS-1 loop
            data_in(
                (i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH
            ) <= pack_complex(X_RE(i), X_IM(i));
        end loop;
 
        wait until falling_edge(clk);
 
        start <= '1';
        wait until falling_edge(clk);
        start <= '0';
 
        for guard in 0 to 63 loop
            exit when done = '1';
            wait until rising_edge(clk);
        end loop;
 
        wait for 1 ns;

        for i in 0 to N_POINTS-1 loop
            re_hw := get_re(data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH));
            im_hw := get_im(data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH));
        end loop;

        file_open(out_file, "C:/TFG/SimuacionesFTT256/vivado_data_out_256.txt", write_mode);
        
        for i in N_POINTS-1 downto 0 loop
            sample_slv := data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH);
            hwrite(out_line, sample_slv);
        end loop;
        
        writeline(out_file, out_line);
        file_close(out_file);
 
        sim_done <= true;
        wait;
 
    end process;
 
end architecture sim;
