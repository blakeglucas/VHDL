----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/07/2019 09:49:17 PM
-- Design Name: 
-- Module Name: example - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity example is
    port(
        CLK100MHz:      in std_logic;
        ACL_MISO:       in std_logic;
        ACL_MOSI:       out std_logic;
        ACL_SCLK:       out std_logic;
        ACL_CSN:        out std_logic;
        UART_TXD_IN:    in std_logic;
        UART_RXD_OUT:   out std_logic
    );
end example;

architecture RTL of example is
    signal spi_start: std_logic := '0';
    signal spi_idle: std_logic;
    signal spi_tx_bytes: integer := 0;
    signal spi_rx_bytes: integer := 0;
    signal spi_tx_data: spi_data_buf_t := (others => (others => '0'));
    signal spi_rx_data: spi_data_buf_t := (others => (others => '0'));
    
    signal uart_tx_begin: std_logic := '0';
    signal uart_tx_done: std_logic := '1';
    signal uart_tx_data: std_logic_vector(7 downto 0);
    
    type application_state_t is (IDLE, SEND, VERIFY);
    signal state: application_state_t := IDLE;
begin
    UART_Inst: entity work.UART
        port map(
            TX => UART_RXD_OUT,
            RX => UART_TXD_IN,
            clk => CLK100MHz,
            tx_begin => uart_tx_begin,
            tx_done => uart_tx_done,
            tx_data => uart_tx_data
        );
        
    SPI_Master_Inst: entity work.SPI_Master
        port map(
            clk => CLK100MHz,
            sck => ACL_SCLK,
            mosi => ACL_MOSI,
            miso => ACL_MISO,
            ss => ACL_CSN,
            start => spi_start,
            idle => spi_idle,
            tx_bytes => spi_tx_bytes,
            rx_bytes => spi_rx_bytes,
            tx_data => spi_tx_data,
            rx_data => spi_rx_data
        );
        
    main: process(CLK100MHz) is
        variable ticks: integer := 0;
    begin
        if rising_edge(CLK100MHz) then
            if spi_start = '1' then
                spi_start <= '0';
            end if;
            if uart_tx_begin = '1' then
                uart_tx_begin <= '0';
            end if;
            case state is
                when IDLE =>
                    if ticks = 100000000 then
                        ticks := 0;
                        state <= SEND;
                    else
                        ticks := ticks + 1;
                    end if;
                when SEND =>
                    if spi_idle = '1' then
                        spi_tx_data(0) <= x"0B";
                        spi_tx_data(1) <= x"00";
                        spi_tx_bytes <= 2;
                        spi_rx_bytes <= 1;
                        spi_start <= '1';
                    end if;
                    if spi_idle = '0' then
                        state <= VERIFY;
                    end if;
                when VERIFY =>
                    if spi_idle = '1' then
                        -- Finished transaction
                        if uart_tx_done = '1' then
                            uart_tx_data <= spi_rx_data(0);
                            uart_tx_begin <= '1';
                        end if;
                        if uart_tx_done = '0' then
                            state <= IDLE;
                        end if;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
end RTL;
