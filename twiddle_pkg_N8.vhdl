library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package twiddle_pkg is

    constant FFT_SIZE    : integer := 32;
    constant NUM_TWIDDLE : integer := FFT_SIZE / 2;
    constant COEFF_WIDTH : integer := 16;

    type t_twiddle_array is array (0 to NUM_TWIDDLE-1) of integer;

    constant TWIDDLE_RE : t_twiddle_array := (
         32767,  -- k = 0
         32138,  -- k = 1
         30274,  -- k = 2
         27246,  -- k = 3
         23170,  -- k = 4
         18205,  -- k = 5
         12540,  -- k = 6
          6393,  -- k = 7
             0,  -- k = 8
         -6393,  -- k = 9
        -12540,  -- k = 10
        -18205,  -- k = 11
        -23170,  -- k = 12
        -27246,  -- k = 13
        -30274,  -- k = 14
        -32138   -- k = 15
    );

    constant TWIDDLE_IM : t_twiddle_array := (
             0,  -- k = 0
         -6393,  -- k = 1
        -12540,  -- k = 2
        -18205,  -- k = 3
        -23170,  -- k = 4
        -27246,  -- k = 5
        -30274,  -- k = 6
        -32138,  -- k = 7
        -32768,  -- k = 8
        -32138,  -- k = 9
        -30274,  -- k = 10
        -27246,  -- k = 11
        -23170,  -- k = 12
        -18205,  -- k = 13
        -12540,  -- k = 14
         -6393   -- k = 15
    );

end package twiddle_pkg;
