---------------------------------------------------------------
-- UART Library. Handles receive and transmit asynchronously.
--
-- Author:  Blake Lucas
-- Date:    18 February 2019
--
-- Serial parameters:
--      115200 baud
--      8 bits
--      No parity
--      Start/stop bits
--      No flow control
---------------------------------------------------------------
library IEEE;
library std;
use IEEE.std_logic_1164.all;
-- For simulation debugging (write & writeline)
use std.textio.all;

entity UART is
	port(
        -- TX Line
    	TX: out std_logic := '1';
        -- RX Line
        RX: in std_logic;
        -- clk input
        clk: in std_logic;
        -- tx_begin control line. Starts UART transmission
        tx_begin: in std_logic;
        -- Transmit buffer; data to be sent in transmission
		tx_data: in std_logic_vector(7 downto 0) := (others => '0');
        -- Flag set when transmission has been completed
        tx_done: out std_logic := '1';
        -- Receive buffer; data received stored here
        rx_data: out std_logic_vector(7 downto 0) := (others => '0');
        -- Flag to be set when a receive has been completed
        rx_flag: out std_logic := '0'
    );
end UART;

architecture RTL of UART is
	-- Fosc / baud
    -- 25 M / 115200 = 217
    -- TODO Configurable baudrate
	constant ticks: integer := 217;
    -- State machine for transmit
    type tx_state_t is (TX_IDLE, TX_START, TX_SEND, TX_STOP);
    signal tx_state: tx_state_t := TX_IDLE;
    -- State machine for receive
    type rx_state_t is (RX_IDLE, RX_START, RX_RECV, RX_STOP);
    signal rx_state: rx_state_t := RX_IDLE;
begin
    -- Process to handle transmission
    handle_tx: process (clk) is
        -- Count the clock ticks to match baudrate
        -- Could generate baudclock?
    	variable tick_count: integer := 0;
        -- Current bit index: which bit is up to be transmitted
    	variable bit_index: integer := 0;
        -- Line for simulation debugging
        variable l: line;
    begin
    	if rising_edge(clk) then
            tick_count := tick_count + 1;
            case tx_state is
                -- Idle operation. Wait for begin signal.
                when TX_IDLE =>
                    tx_done <= '1';
                    if tx_begin = '1' then
                        tx_state <= TX_START;
                        tx_done <= '0';
                        write(l, String'("Start"));
                        writeline(output, l);
                    end if;
                when TX_START =>
                    -- Reset tick count to synchronize baud
                    tick_count := 0;
                    -- Generate stop bit
                    TX <= '0';
                    tx_state <= TX_SEND;
                    write(l, String'("Send"));
                    writeline(output, l);
                when TX_SEND =>
                    -- If coming from START, hold start bit
                    -- for full period. Else, hold last bit
                    -- for full period.
                    if tick_count >= ticks then
                        if bit_index < 8 then
                            TX <= tx_data(bit_index);
                            bit_index := bit_index + 1;
                        else
                            bit_index := 0;
                            tx_state <= TX_STOP;
                            write(l, String'("Stop"));
                            writeline(output, l);
                        end if;
                        tick_count := 0;
                    end if;
                when TX_STOP =>
                    -- Generate stop bit
                    TX <= '1';
                    -- Hold stop bit for full period before
                    -- returning to IDLE.
                    if tick_count >= ticks then
                        tx_state <= TX_IDLE;
                        write(l, String'("Idle"));
                        writeline(output, l);
                        tick_count := 0;
                    end if;
                when others =>
                    tx_state <= TX_IDLE;
                    write(l, String'("Idle"));
                    writeline(output, l);
            end case;
        end if;
    end process;
    
    -- Process to handle reception
    handle_rx: process(clk) is
        -- Current bit in data buffer to store
    	variable bit_index: integer := 0;
        -- Clock tick count to synchronize baudrate
        variable tick_count: integer := 0;
    begin
    	if rising_edge(clk) then
        	tick_count := tick_count + 1;
            case rx_state is
                when RX_IDLE =>
                    -- Detect start bit
                    if RX = '0' then
            	        rx_state <= RX_START;
                        tick_count := 0;
                        rx_flag <= '0';
                    end if;
                when RX_START =>
                    -- Align the sampling with the middle of
                    -- the bit. This will allow further
                    -- states to sample in the middle of
                    -- subsequent bits. Effectively phase-
                    -- shifts the sampling baudclock.
                    if tick_count >= ticks / 2 then
                        tick_count := 0;
                        rx_state <= RX_RECV;
                    end if;
                when RX_RECV =>
                    -- "Wait" for bit period
                    if tick_count >= ticks then
                        if bit_index < 8 then
                            rx_data(bit_index) <= RX;
                            bit_index := bit_index + 1;
                        else
                            bit_index := 0;
                            rx_state <= RX_STOP;
                        end if;
                        tick_count := 0;
                    end if;
                when RX_STOP =>
                    -- Set the interrupt flag and return to
                    -- IDLE state.
                    if ticks >= tick_count then
                        rx_flag <= '1';
                        rx_state <= RX_IDLE;
                        tick_count := 0;
                    end if;
                when others =>
                    rx_state <= RX_IDLE;
            end case;
        end if;
    end process;
end RTL;