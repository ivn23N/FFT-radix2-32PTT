library ieee;
use ieee.std_logic_1164.all;
 
package fft_wiring_pkg is
 
    function bit_reverse(idx : integer; n_bits : integer) return integer;
 
end package fft_wiring_pkg;
 
 
package body fft_wiring_pkg is
 
    --------------------------------------------------------------------
    -- bit_reverse
    --
    -- Shift the input value bit by bit into the result, low bit first.
    -- After n_bits iterations the result holds the reversed pattern.
    --------------------------------------------------------------------
    function bit_reverse(idx : integer; n_bits : integer) return integer is
        variable src : integer := idx;
        variable res : integer := 0;
    begin
        for i in 0 to n_bits-1 loop
            res := res * 2 + (src mod 2);
            src := src / 2;
        end loop;
        return res;
    end function;
 
end package body fft_wiring_pkg;
