library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.twiddle_pkg.all;

entity DFTmod is
    generic (
        DATA_WIDTH : integer;
        FRAC_WIDTH : integer
    );
    port (
        complex_a_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        complex_b_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        k_in         : in  integer range 0 to NUM_TWIDDLE-1;

        sum_out      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        res_out      : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end DFTmod;

architecture Behavioral of DFTmod is

    constant HALF_WIDTH : integer := DATA_WIDTH / 2;
    constant SCALE      : integer := 2 ** FRAC_WIDTH;

    constant MAX_HALF : integer :=  2**(HALF_WIDTH-1) - 1;
    constant MIN_HALF : integer := -2**(HALF_WIDTH-1);

    signal a_re, a_im : integer;
    signal b_re, b_im : integer;

    signal w_re, w_im : integer;

    signal wb_re, wb_im : integer;
    signal y0_re, y0_im : integer;
    signal y1_re, y1_im : integer;

begin

    a_re <= to_integer(signed(complex_a_in(HALF_WIDTH-1 downto 0)));
    a_im <= to_integer(signed(complex_a_in(DATA_WIDTH-1 downto HALF_WIDTH)));

    b_re <= to_integer(signed(complex_b_in(HALF_WIDTH-1 downto 0)));
    b_im <= to_integer(signed(complex_b_in(DATA_WIDTH-1 downto HALF_WIDTH)));

    w_re <= TWIDDLE_RE(k_in);
    w_im <= TWIDDLE_IM(k_in);

    wb_re <= ((w_re * b_re) - (w_im * b_im)) / SCALE;
    wb_im <= ((w_re * b_im) + (w_im * b_re)) / SCALE;

    y0_re <= (a_re + wb_re) / 2;
    y0_im <= (a_im + wb_im) / 2;

    y1_re <= (a_re - wb_re) / 2;
    y1_im <= (a_im - wb_im) / 2;

    sum_out(HALF_WIDTH-1 downto 0)          <= std_logic_vector(to_signed(y0_re, HALF_WIDTH));
    sum_out(DATA_WIDTH-1 downto HALF_WIDTH) <= std_logic_vector(to_signed(y0_im, HALF_WIDTH));

    res_out(HALF_WIDTH-1 downto 0)          <= std_logic_vector(to_signed(y1_re, HALF_WIDTH));
    res_out(DATA_WIDTH-1 downto HALF_WIDTH) <= std_logic_vector(to_signed(y1_im, HALF_WIDTH));

end Behavioral;
