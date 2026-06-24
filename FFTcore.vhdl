library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.twiddle_pkg.all;

entity FFTcore is
    generic (
        DATA_WIDTH : integer;
        N_POINTS   : integer;
        FRAC_WIDTH : integer
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        start    : in  std_logic;
        done     : out std_logic;
        data_in  : in  std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);
        data_out : out std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0)
    );
end entity FFTcore;

architecture Behavioral of FFTcore is

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

    type stage_bus_array_t is array (natural range <>)
        of std_logic_vector(N_POINTS*DATA_WIDTH-1 downto 0);

    signal stage_reg  : stage_bus_array_t(0 to N_STAGES);
    signal stage_comb : stage_bus_array_t(0 to N_STAGES-1);
    signal valid_pipe : std_logic_vector(0 to N_STAGES) := (others => '0');

    --bus para la stage0 (butterfly)
    type bf_out_array_t is array (0 to N_POINTS/2 - 1)
        of std_logic_vector(2*DATA_WIDTH-1 downto 0);

    signal bf_out_s : bf_out_array_t;

begin

    gen_stage0 : for j in 0 to N_POINTS/2 - 1 generate
    begin

        U_BFLY : entity work.Butterfly
            generic map (
                DATA_WIDTH => DATA_WIDTH
            )
            port map (
                complex_a_in => stage_reg(0)(
                    (2*j+1)*DATA_WIDTH-1 downto (2*j)*DATA_WIDTH
                ),

                complex_b_in => stage_reg(0)(
                    (2*j+2)*DATA_WIDTH-1 downto (2*j+1)*DATA_WIDTH
                ),

                data_out => bf_out_s(j)
            );

        --suma
        stage_comb(0)(
            (2*j+1)*DATA_WIDTH-1 downto (2*j)*DATA_WIDTH
        ) <= bf_out_s(j)(DATA_WIDTH-1 downto 0);

        --resta
        stage_comb(0)(
            (2*j+2)*DATA_WIDTH-1 downto (2*j+1)*DATA_WIDTH
        ) <= bf_out_s(j)(2*DATA_WIDTH-1 downto DATA_WIDTH);

    end generate gen_stage0;

    gen_fft_stages : for s in 1 to N_STAGES-1 generate
    begin
        U_STAGE : entity work.FFTstage
            generic map (
                DATA_WIDTH  => DATA_WIDTH,
                N_POINTS    => N_POINTS,
                FRAC_WIDTH  => FRAC_WIDTH,
                STAGE_INDEX => s
            )
            port map (
                stage_in  => stage_reg(s),
                stage_out => stage_comb(s)
            );
    end generate gen_fft_stages;

    proc_input_reg : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                stage_reg(0)  <= (others => '0');
                valid_pipe(0) <= '0';
            else
                stage_reg(0)  <= data_in;
                valid_pipe(0) <= start;
            end if;
        end if;
    end process;


    gen_pipe_regs : for s in 0 to N_STAGES-1 generate
    begin
        proc_pipe : process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    stage_reg(s+1)  <= (others => '0');
                    valid_pipe(s+1) <= '0';
                else
                    stage_reg(s+1)  <= stage_comb(s);
                    valid_pipe(s+1) <= valid_pipe(s);
                end if;
            end if;
        end process;
    end generate gen_pipe_regs;

    data_out <= stage_reg(N_STAGES);
    done     <= valid_pipe(N_STAGES);

end architecture Behavioral;
