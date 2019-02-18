---------------------------------------------------------------
-- Example usage of I2C library. Written for NandLand GO
-- Board. Synthesized with iCEcube2.
--
-- Author:  Blake Lucas
-- Date:    18 February 2019
--
-- Reads the two ID bits from the VCNL4200 proximity sensor and
-- sends them over UART.
--
-- Serial parameters:
--      115200 baud
--      8 bits
--      No parity
--      Start/stop bits
--      No flow control
---------------------------------------------------------------
library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.types.all;
-- Need to link stringutil file in Synthesis tool.
use work.stringutil.all;
-- Need to link UART file in Synthesis as well.

entity i2c_main is
    port(
        i_Clk: in std_logic;
        io_PMOD_1: out std_logic;
        io_PMOD_2: inout std_logic;
        o_UART_TX: out std_logic;
        i_UART_RX: in std_logic
    );
end i2c_main;

architecture RTL of i2c_main is
    -- I2C transmit data buffer
    signal tx_data: i2c_data_buf_t;
    -- I2C receive data buffer
    signal rx_data: i2c_data_buf_t;
    -- Number of bytes (NOT INCLUDING ADDRESS byte) in
    -- transmit transaction
    signal tx_bytes: integer := 0;
    -- Number of bytes (NOT INCLUDING ADDRESS bytes) in
    -- receive transaction
    signal rx_bytes: integer := 0;
    -- I2C bus idle flag. Do not set start signal if this flag
    -- is low.
    signal i2c_idle: std_logic;
    -- Signal to begin I2C transaction. Will begin both
    -- transmit and receive.
    signal start: std_logic := '0';
    -- Process state machine
    type process_state_t is (IDLE, CMD, DATA);
    signal process_state: process_state_t := IDLE;
    -- UART transmit begin flag.
    signal uart_tx_begin: std_logic := '0';
    -- UART idle flag. If high, free to transmit
    signal uart_tx_idle: std_logic;
    -- UART transmit data buffer
    signal uart_tx_data: std_logic_vector(7 downto 0) := (others => '0');
begin

    UART_Inst: entity work.UART
        port map(
            TX => o_UART_TX,
            RX => i_UART_RX,
            clk => i_Clk,
            tx_begin => uart_tx_begin,
            tx_done => uart_tx_idle,
            tx_data => uart_tx_data,
            rx_data => open,
            rx_flag => open
        );

    I2C_Master_Inst: entity work.I2C_Master
        port map(
            clk => i_Clk,
            scl => io_PMOD_1,
            sda => io_PMOD_2,
            tx_data => tx_data,
            rx_data => rx_data,
            tx_bytes => tx_bytes,
            rx_bytes => rx_bytes,
            idle => i2c_idle,
            start => start
        );

    process(i_Clk) is
        -- Counts clock ticks. Used for brief delay to not
        -- overwhelm UART
        variable ticks: integer := 0;
        -- Counter for UART bytes transmitted
        variable ubytes: integer := 0;
        -- String buffer for UART transmission
        variable s: string(0 to 7);
        -- Maintain the state of tx_idle signal
        variable tx_idle_prev: std_logic := '0';
        -- Current string character to transmit
        variable char_index: integer := 0;
    begin
        if rising_edge(i_Clk) then
            -- Keep the two transmission trigger signals always
            -- low. Would be included in modules if possible.
            if start = '1' then
                start <= '0';
            end if;
            if uart_tx_begin = '1' then
                uart_tx_begin <= '0';
            end if;
            -- Begin state machine
            case process_state is
                when IDLE =>
                    -- Brief delay before beginnging transmissions
                    if ticks >= 10000 then
                        process_state <= CMD;
                        ticks := 0;                        
                    else
                        ticks := ticks + 1;
                    end if;
                when CMD =>
                    -- Verify that I2C bus is idle
                    if i2c_idle = '1' then
                        -- Set address
                        tx_data(0) <= x"51";
                        -- Set other data bytes. In this case,
                        -- 0xE is the ID register on the
                        -- VCNL4200.
                        tx_data(1) <= x"0E";
                        -- Transmit 1 byte
                        tx_bytes <= 1;
                        -- Receive two bytes
                        rx_bytes <= 2;
                        -- DO NOT INCLUDE ADDRESS BYTE IN TX_
                        -- OR RX_BYTES!
                        start <= '1';
                    end if;
                    -- If we have begun the transmission,
                    -- initiate state transition
                    if i2c_idle = '0' then
                        process_state <= DATA;
                    end if;
                when DATA =>
                    -- DATA state will wait until the bus is idle
                    if i2c_idle = '1' then
                        -- Transmit all received bytes over
                        -- UART as hex code strings
                        if ubytes < rx_bytes then
                            s := hex_stringify(rx_data(ubytes));
                            if tx_idle_prev = '0' and uart_tx_idle= '1' then
                                char_index := char_index + 1;
                            end if;
                            if char_index < s'length then
                                if uart_tx_idle = '1' then
                                    uart_tx_data <= std_logic_vector(to_unsigned(character'pos(character(s(char_index))), 8));
                                    uart_tx_begin <= '1';     -- Begin transfer
                                end if;
                            else
                                ubytes := ubytes + 1;
                                char_index := 0;
                            end if;
                        else
                            -- We're finished, back to IDLE
                            process_state <= IDLE;
                            ubytes := 0;
                        end if;
                    end if;
                    tx_idle_prev := uart_tx_idle;
                when others =>
                    process_state <= IDLE;
            end case;
        end if;
    end process;
end RTL;