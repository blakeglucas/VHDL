----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/07/2019 09:07:59 PM
-- Design Name: 
-- Module Name: spi - RTL
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

entity SPI_Master is
    port (
        clk:        in std_logic;
        sck:        out std_logic;
        mosi:       out std_logic;
        miso:       in std_logic;
        ss:         out std_logic;
        start:      in std_logic;
        idle:       out std_logic;
        tx_bytes:   in integer;
        rx_bytes:   in integer;
        tx_data:     in spi_data_buf_t;
        rx_data:     out spi_data_buf_t
    );
end SPI_Master;

architecture RTL of SPI_Master is
    -- FOSC / (2 * FSPI) (half period)
    -- FSPI = 1 MHz
    constant hper_ticks: integer := 50;
    
    type spi_state_t is (SPI_IDLE, SPI_WRITE, SPI_READ);
    signal state: spi_state_t := SPI_IDLE;
    
    signal ticks: integer := 0;
    signal sck_state: std_logic := '0';
    
    signal mosi_buf: std_logic := '0';
    signal ss_state: std_logic := '1';
begin

    sck_gen: process(clk, ss_state) is
    begin
        if ss_state = '1' then
            ticks <= 0;
            sck_state <= '0';
        elsif rising_edge(clk) then
            if ticks = hper_ticks then
                sck_state <= not sck_state;
                ticks <= 0;
            else
                ticks <= ticks + 1;
            end if;
        end if;
    end process;
    
    state_machine: process(clk) is
        variable byte_index: integer := 0;
        variable bit_index: integer := 0;
    begin
        if rising_edge(clk) then
            case state is
                when SPI_IDLE =>
                    idle <= '1';
                    ss_state <= '1';
                    if start = '1' then
                        idle <= '0';
                        ss_state <= '0';
                        state <= SPI_WRITE;
                    end if;
                when SPI_WRITE =>
                    -- Shift data on falling edge.
                    -- TODO Make configurable
                    if bit_index = 8 then
                        byte_index := byte_index + 1;
                        bit_index := 0;
                    end if;
                    if byte_index = tx_bytes then
                        if sck_state = '0' and ticks = 0 then
                            byte_index := 0;
                            bit_index := 0;
                            state <= SPI_READ;
                        end if;
                    elsif sck_state = '0' and ticks = hper_ticks / 2 then
                        mosi_buf <= tx_data(byte_index)(7-bit_index);
                        bit_index := bit_index + 1;
                    end if;
                when SPI_READ =>
                    if bit_index = 8 then
                        byte_index := byte_index + 1;
                        bit_index := 0;
                    end if;
                    if byte_index = rx_bytes then
                        if sck_state = '0' then
                            byte_index := 0;
                            bit_index := 0;
                            state <= SPI_IDLE;
                        end if;
                    elsif sck_state = '1' and ticks = hper_ticks / 2 then
                        -- Sample at midpoint of rising edge to avoid sampling race condition
                        rx_data(byte_index)(7-bit_index) <= miso;
                        bit_index := bit_index + 1;
                    end if;
                when others =>
                    state <= SPI_IDLE;
            end case;
        end if;
    end process;
    
    sck <= sck_state;
    -- TODO: Verify MOSI idle low
    -- MISO: idle high
    mosi <= mosi_buf when state = SPI_WRITE else '0';
    ss <= ss_state;

end RTL;
