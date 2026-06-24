library ieee;
use ieee.std_logic_1164.all;

use work.fft_wiring_pkg.all;   -- bit_reverse(idx, n_bits)

entity BitReverse is
    generic (
        DATA_WIDTH : integer;
        N_POINTS   : integer
    );
    port (
        data_in  : in  std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
        data_out : out std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0)
    );
end entity BitReverse;

architecture Behavioral of BitReverse is

    function clog2(n : integer) return integer is
        variable tmp : integer := n;
        variable res : integer := 0;
    begin
        while tmp > 1 loop
            tmp := tmp / 2;
            res := res + 1;
        end loop;
        return res;
    end function;

    constant N_STAGES : integer := clog2(N_POINTS);

begin

    gen_bit_reverse : for i in 0 to N_POINTS-1 generate
        constant DST : integer := bit_reverse(i, N_STAGES);
    begin
        data_out(
            (DST+1)*DATA_WIDTH-1 downto DST*DATA_WIDTH
        ) <= data_in(
            (i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH
        );
    end generate gen_bit_reverse;

end architecture Behavioral;
