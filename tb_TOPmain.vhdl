library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
 
entity tb_TOPmain is
end entity tb_TOPmain;
 
architecture sim of tb_TOPmain is
 
    constant DATA_WIDTH : integer := 32;
    constant N_POINTS   : integer := 256;
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
        -469, -319, -13, 207, 377, 575, 851, 1191, 1508, 1681, 1625, 1339, 924, 171, -41, -9,
        228, 553, 830, 968, 962, 878, 801, 775, 775, 720, 158, -209, -689, -1501, -1438, -1464,
        -1232, -850, -474, -235, -186, 275, -431, -896, -910, -875, -869, -952, -1120, -1290, -1336, -1156,
        -731, -142, 455, 904, 745, 722, 568, 412, 348, 393, 139, 560, 554, 495, 469, 572,
        854, 907, 1339, 1626, 1657, 1414, 984, 517, 152, -41, 477, -59, -59, -123, -580, -620,
        -539, -330, -71, 110, 92, -169, -612, -1448, -1458, -1588, -1476, -1568, -1255, -1001, -833, -705,
        -542, -294, 16, 302, 452, 398, 161, -147, -734, -736, -479, -26, 486, 916, 1181, 1847,
        1307, 1330, 1395, 1474, 1132, 984, 688, 299, -47, -215, -133, 165, 553, 872, 999, 904,
        649, 347, -269, -432, -546, -687, -907, -1191, -1452, -1568, -1456, -1114, -642, -199, 69, -272,
        -453, -1074, -942, -1024, -402, -822, -688, -606, -550, -439, -186, 238, 408, 923, 1269, 1351,
        1176, 850, 530, 348, 355, 510, 713, 868, 938, 594, 644, 783, 1008, 1233, 984, 1213,
        844, 311, -230, -622, -773, -694, -849, -637, -517, 54, -547, -560, -498, -383, -300, -347,
        -573, -936, -1310, -1908, -1882, -1583, -1097, -573, -152, 97, 195, -124, 285, 404, 552, 649,
        258, 105, -98, -222, -148, 169, 669, 1209, 1627, 1813, 1757, 1540, 1283, 719, 1167, 536,
        429, 238, -16, -246, -339, -229, 65, 429, 353, 764, 197, -199, -655, -1029, -1237, -1287,
        -1251, -1217, -1226, -1248, -1203, -1012, -659, -581, -178, 46, 20, -221, -553, -816, -887, -735
        );
        
        
    constant X_IM : int_vec_t := (
        -719, -452, 3, 159, 18, -217, -317, -198, 42, 258, 409, 331, 633, 1024, 1310, 1278,
        886, 318, -140, -310, -232, -94, -304, -356, -388, -327, -244, -298, -575, -293, -1213, -1106,
        -647, -301, 180, 427, 512, 181, 689, 754, 662, 423, 207, 220, 266, 683, 944, 867,
        499, 48, -294, -491, -637, -815, -969, -1203, -912, -441, 635, 81, -105, -399, -544, -420,
        -110, 213, 198, 404, 678, 1025, 1292, 1278, 921, 380, -462, -206, -71, -111, -15, -79,
        -195, -251, -262, -357, -629, -1004, -1253, -487, -956, -337, 165, 400, 427, 415, 471, 553,
        546, 416, 286, 90, 407, 842, 1124, 1054, 654, 142, -255, -457, -552, -655, -1020, -1419,
        -801, -416, -77, 0, 447, -564, -748, -623, -254, -90, 229, 457, 695, 985, 1223, 1229,
        922, 429, 20, -90, -157, 125, 271, 198, 4, -166, -271, -400, -656, -1001, -1241, -1417,
        -979, 308, 140, 356, -76, 232, 235, 332, 411, 396, 106, 206, 529, 965, 1259, 1199,
        785, 232, -203, -404, -443, -719, -782, -800, -662, -377, -115, -82, -335, -707, -249, -798,
        -637, -140, 248, 491, 683, 907, 1108, 1133, 889, 64, 106, -220, 13, 353, 544, 466,
        202, -75, -268, -427, -655, -956, -1430, -1370, -967, -380, 109, 970, 210, 42, -8, 102,
        264, 113, 170, 310, 629, 1050, 1345, 1297, 886, 314, -142, -331, -565, -507, -917, -553,
        -499, -324, -148, -159, -430, -819, -1055, -1192, -75, -188, 255, 503, 644, 793, 951, 996,
        824, 485, -61, -92, 179, 564, 794, 715, 392, 21, -253, -434, -626, -1124, -1315, -1275
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
