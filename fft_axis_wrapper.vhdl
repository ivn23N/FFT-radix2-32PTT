library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft_axis_wrapper is
    generic (
        N_POINTS   : integer := 32;
        DATA_WIDTH : integer := 32;
        FRAC_WIDTH : integer := 15
    );
    port (
        aclk    : in std_logic;
        aresetn : in std_logic;

        --S_AXIS: entrada desde el AXI DMA, canal MM2S
        s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axis_tkeep  : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast  : in  std_logic;

        --M_AXIS: salida hacia el AXI DMA, canal S2MM
        m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axis_tkeep  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast  : out std_logic
    );
end entity fft_axis_wrapper;

architecture rtl of fft_axis_wrapper is

    constant TOTAL_BITS : integer := N_POINTS * DATA_WIDTH;
    constant KEEP_ALL : std_logic_vector(DATA_WIDTH/8-1 downto 0) :=
        (others => '1');

    signal input_buf : std_logic_vector(TOTAL_BITS-1 downto 0);
    signal output_buf : std_logic_vector(TOTAL_BITS-1 downto 0);

    signal fft_start : std_logic;
    signal fft_done  : std_logic;

    signal fft_data_out :
        std_logic_vector(TOTAL_BITS-1 downto 0);

    signal in_count :
        integer range 0 to N_POINTS-1;

    signal out_count :
        integer range 0 to N_POINTS-1;

    -- Registros AXI
    signal s_tready_r : std_logic;
    signal m_tvalid_r : std_logic;

    signal m_tdata_reg :
        std_logic_vector(DATA_WIDTH-1 downto 0);

    type t_state is (
        S_RECV,
        S_COMPUTE,
        S_SEND
    );

    signal state : t_state;
    signal rst_core : std_logic;

    -- Atributos para que Vivado reconozca las interfaces AXI4-Stream
    attribute X_INTERFACE_INFO : string;
    attribute X_INTERFACE_PARAMETER : string;

    attribute X_INTERFACE_INFO of aclk : signal is
        "xilinx.com:signal:clock:1.0 aclk CLK";

    attribute X_INTERFACE_PARAMETER of aclk : signal is
        "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET aresetn";

    attribute X_INTERFACE_INFO of aresetn : signal is
        "xilinx.com:signal:reset:1.0 aresetn RST";

    attribute X_INTERFACE_PARAMETER of aresetn : signal is
        "POLARITY ACTIVE_LOW";

    attribute X_INTERFACE_INFO of s_axis_tdata : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TDATA";

    attribute X_INTERFACE_INFO of s_axis_tkeep : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TKEEP";

    attribute X_INTERFACE_INFO of s_axis_tvalid : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TVALID";

    attribute X_INTERFACE_INFO of s_axis_tready : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TREADY";

    attribute X_INTERFACE_INFO of s_axis_tlast : signal is
        "xilinx.com:interface:axis:1.0 S_AXIS TLAST";

    attribute X_INTERFACE_INFO of m_axis_tdata : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TDATA";

    attribute X_INTERFACE_INFO of m_axis_tkeep : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TKEEP";

    attribute X_INTERFACE_INFO of m_axis_tvalid : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TVALID";

    attribute X_INTERFACE_INFO of m_axis_tready : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TREADY";

    attribute X_INTERFACE_INFO of m_axis_tlast : signal is
        "xilinx.com:interface:axis:1.0 M_AXIS TLAST";

begin

    rst_core <= not aresetn;

    U_FFT : entity work.TOPmain
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            N_POINTS   => N_POINTS,
            FRAC_WIDTH => FRAC_WIDTH
        )
        port map (
            clk      => aclk,
            rst      => rst_core,
            start    => fft_start,
            data_in  => input_buf,
            data_out => fft_data_out,
            done     => fft_done
        );

    -- Máquina de estados y control
    p_fsm : process(aclk)
    begin
        if rising_edge(aclk) then

            if rst_core = '1' then
                state       <= S_RECV;
                in_count    <= 0;
                out_count   <= 0;
                fft_start   <= '0';
                input_buf   <= (others => '0');
                output_buf  <= (others => '0');
                s_tready_r  <= '1';
                m_tvalid_r  <= '0';
                m_tdata_reg <= (others => '0');
            else
                fft_start <= '0';

                case state is
                    when S_RECV =>

                        s_tready_r <= '1';
                        m_tvalid_r <= '0';

                        if s_axis_tvalid = '1'
                           and s_tready_r = '1' then

                            input_buf(
                                (in_count + 1) * DATA_WIDTH - 1
                                downto
                                in_count * DATA_WIDTH
                            ) <= s_axis_tdata;

                            --Al recibir la muestra 32, arrancar la FFT
                            if in_count = N_POINTS - 1 then
                                in_count    <= 0;
                                fft_start   <= '1';
                                s_tready_r  <= '0';
                                state       <= S_COMPUTE;
                            else
                                in_count <= in_count + 1;
                            end if;
                        end if;

                    -- Espera mientras la FFT procesa el bloque
                    when S_COMPUTE =>
                        s_tready_r <= '0';
                        m_tvalid_r <= '0';
                        if fft_done = '1' then
                            --Guardar los 32 resultados
                            output_buf <= fft_data_out;
                            out_count <= 0;

                            --Precargar el primer resultado
                            m_tdata_reg <=
                                fft_data_out(DATA_WIDTH-1 downto 0);
                            m_tvalid_r <= '1';

                            state <= S_SEND;
                        end if;

                    --Envío de las 32 muestras de salida
                    when S_SEND =>
                        s_tready_r <= '0';
                        m_tvalid_r <= '1';

                        --Avanzar solo cuando el receptor acepta el dato
                        if m_tvalid_r = '1'
                           and m_axis_tready = '1' then
                            if out_count = N_POINTS - 1 then
                                -- La última muestra acaba de ser aceptada
                                out_count   <= 0;
                                m_tvalid_r  <= '0';
                                s_tready_r  <= '1';
                                state <= S_RECV;
                            else
                                --Preparar la siguiente muestra
                                out_count <= out_count + 1;
                                m_tdata_reg <= output_buf(
                                    (out_count + 2) * DATA_WIDTH - 1
                                    downto
                                    (out_count + 1) * DATA_WIDTH
                                );
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process p_fsm;

    --Salidas AXI registradas
    s_axis_tready <= s_tready_r;
    m_axis_tdata  <= m_tdata_reg;
    m_axis_tkeep  <= KEEP_ALL;
    m_axis_tvalid <= m_tvalid_r;

    m_axis_tlast <= '1'
        when state = S_SEND
         and out_count = N_POINTS - 1
         and m_tvalid_r = '1'
        else '0';
end architecture rtl;
