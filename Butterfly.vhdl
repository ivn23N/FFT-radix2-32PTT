library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Butterfly is
    generic (
        DATA_WIDTH : integer
    );
    port (
        complex_a_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        complex_b_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out     : out std_logic_vector(2*DATA_WIDTH-1 downto 0)
    );
end Butterfly;

architecture Behavioral of Butterfly is

    constant HALF_WIDTH : integer := DATA_WIDTH/2;

    signal sum_re, sum_im : signed(HALF_WIDTH-1 downto 0);
    signal res_re, res_im : signed(HALF_WIDTH-1 downto 0);

    signal sum_c : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal res_c : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    sum_re <= signed(complex_a_in(HALF_WIDTH-1 downto 0)) +
              signed(complex_b_in(HALF_WIDTH-1 downto 0));

    sum_im <= signed(complex_a_in(DATA_WIDTH-1 downto HALF_WIDTH)) +
              signed(complex_b_in(DATA_WIDTH-1 downto HALF_WIDTH));

    res_re <= signed(complex_a_in(HALF_WIDTH-1 downto 0)) -
              signed(complex_b_in(HALF_WIDTH-1 downto 0));

    res_im <= signed(complex_a_in(DATA_WIDTH-1 downto HALF_WIDTH)) -
              signed(complex_b_in(DATA_WIDTH-1 downto HALF_WIDTH));

    sum_c(HALF_WIDTH-1 downto 0)          <= std_logic_vector(sum_re);
    sum_c(DATA_WIDTH-1 downto HALF_WIDTH) <= std_logic_vector(sum_im);

    res_c(HALF_WIDTH-1 downto 0)          <= std_logic_vector(res_re);
    res_c(DATA_WIDTH-1 downto HALF_WIDTH) <= std_logic_vector(res_im);

    data_out(DATA_WIDTH-1 downto 0)            <= sum_c;
    data_out(2*DATA_WIDTH-1 downto DATA_WIDTH) <= res_c;

end Behavioral;
