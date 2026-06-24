library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.twiddle_pkg.all;

entity FFTstage is
    generic (
        DATA_WIDTH  : integer;
        N_POINTS    : integer;
        FRAC_WIDTH  : integer;
        STAGE_INDEX : integer
    );
    port (
        stage_in  : in  std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
        stage_out : out std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0)
    );
end entity FFTstage;

architecture Behavioral of FFTstage is

    function pow2(n : integer) return integer is
        variable r : integer := 1;
    begin
        for i in 1 to n loop
            r := r * 2;
        end loop;
        return r;
    end function;

    --Distancia de i entre A de B (1,3) -> 2
    constant DISTANCE   : integer := pow2(STAGE_INDEX);
    --Num de operaciones por grupo
    constant GROUP_SIZE : integer := 2 * DISTANCE;
    --Numero de grupos en base a la etapa
    constant NUM_GROUPS : integer := N_POINTS / GROUP_SIZE;

begin

    gen_groups : for g in 0 to NUM_GROUPS-1 generate

        
        constant BASE_IDX : integer := g * GROUP_SIZE; 

    begin

        gen_butterflies : for j in 0 to DISTANCE-1 generate

            constant A_IDX : integer := BASE_IDX + j;
            constant B_IDX : integer := BASE_IDX + j + DISTANCE;
            constant K_IDX : integer := j * NUM_GROUPS;

        begin

            U_DFT : entity work.DFTmod
                generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    FRAC_WIDTH => FRAC_WIDTH
                )
                port map (
                    complex_a_in => stage_in(
                        (A_IDX+1)*DATA_WIDTH-1 downto A_IDX*DATA_WIDTH
                    ),

                    complex_b_in => stage_in(
                        (B_IDX+1)*DATA_WIDTH-1 downto B_IDX*DATA_WIDTH
                    ),

                    k_in => K_IDX,

                    sum_out => stage_out(
                        (A_IDX+1)*DATA_WIDTH-1 downto A_IDX*DATA_WIDTH
                    ),

                    res_out => stage_out(
                        (B_IDX+1)*DATA_WIDTH-1 downto B_IDX*DATA_WIDTH
                    )
                );

        end generate gen_butterflies;

    end generate gen_groups;

end architecture Behavioral;
