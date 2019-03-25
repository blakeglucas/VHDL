library ieee;
library std;
use ieee.std_logic_1164.all;
use std.textio.all;

entity UART is
	port(
    	TX: out std_logic := '1';
        RX: in std_logic;
        clk: in std_logic;
        tx_begin: in std_logic;
		tx_data: in std_logic_vector(7 downto 0) := (others => '0');
        tx_done: out std_logic := '1';
        rx_data: out std_logic_vector(7 downto 0) := (others => '0');
        rx_flag: out std_logic := '0'
    );
end UART;

architecture RTL of UART is
	-- Fosc / baud
    -- 25 M / 115200 = 217
	constant ticks: integer := 217;
    type tx_state_t is (TX_IDLE, TX_START, TX_SEND, TX_STOP);
    signal tx_state: tx_state_t := TX_IDLE;
    type rx_state_t is (RX_IDLE, RX_START, RX_RECV, RX_STOP);
    signal rx_state: rx_state_t := RX_IDLE;
begin

    handle_tx: process (clk) is
    	variable tick_count: integer := 0;
    	variable bit_index: integer := 0;
        variable l: line;
    begin
    	if rising_edge(clk) then
            tick_count := tick_count + 1;
            case tx_state is
                when TX_IDLE =>
                    TX <= '1';
                    tx_done <= '1';
                    if tx_begin = '1' then
                        tx_state <= TX_START;
                        tx_done <= '0';
                        write(l, String'("Start"));
                        writeline(output, l);
                    end if;
                when TX_START =>
                    tick_count := 0;
                    TX <= '0';
                    tx_state <= TX_SEND;
                    write(l, String'("Send"));
                    writeline(output, l);
                when TX_SEND =>
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
                    TX <= '1';
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
    
    handle_rx: process(clk) is
    	variable bit_index: integer := 0;
        variable tick_count: integer := 0;
    begin
    	if rising_edge(clk) then
        	tick_count := tick_count + 1;
            case rx_state is
                when RX_IDLE =>
                    rx_flag <= '0';
                    if RX = '0' then
            	        rx_state <= RX_START;
                        tick_count := 0;
                    end if;
                when RX_START =>
                    -- Align the sampling with the middle of the bit_indexes
                    if tick_count >= ticks / 2 then
                        tick_count := 0;
                        rx_state <= RX_RECV;
                    end if;
                when RX_RECV =>
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