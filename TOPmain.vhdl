library ieee;
use ieee.std_logic_1164.all;

entity TOPmain is
    generic (
        DATA_WIDTH : integer := 32;
        N_POINTS   : integer := 32;
        FRAC_WIDTH : integer := 15
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        data_in  : in  std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
        data_out : out std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
        done     : out std_logic
    );
end TOPmain;

architecture Behavioral of TOPmain is

    -- Bit-reverse
    signal data_in_br : std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);

begin

    --1 Separar
    U_BITREV : entity work.BitReverse
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            N_POINTS   => N_POINTS
        )
        port map (
            data_in  => data_in,
            data_out => data_in_br
        );

    --Mandar al core
    U_CORE : entity work.FFTcore
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            N_POINTS   => N_POINTS,
            FRAC_WIDTH => FRAC_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            data_in  => data_in_br,
            data_out => data_out,
            done     => done
        );

end architecture Behavioral;
