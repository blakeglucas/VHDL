library IEEE;
use IEEE.std_logic_1164.all;

entity uart_test is
end uart_test;

architecture rtl of uart_test is
	signal clk: std_logic := '0';
    signal TX: std_logic := '1';
    signal RX: std_logic := '1';
    signal tx_begin: std_logic := '0';
    signal tx_data: std_logic_vector(7 downto 0);
    signal tx_done: std_logic := '0';
    signal rx_data: std_logic_vector(7 downto 0);
    signal rx_done: std_logic := '0';
    constant test_data: std_logic_vector(7 downto 0) := x"55";
    constant infloop: std_logic := '1';
begin
	-- 25 MHz clock
	clk <= not clk after 20 ns;
    UART_Inst: entity work.UART
    	port map(
        	TX => TX,
            RX => RX,
            clk => clk,
            tx_begin => tx_begin,
            tx_data => tx_data,
            tx_done => tx_done,
            rx_data => rx_data,
            rx_done => rx_done
        );

	process
	begin
        while infloop = '1' loop
            if tx_done = '1' then
                tx_data <= test_data;
                tx_begin <= '1';
                report "Began TX test";
                wait until tx_done = '0';
                tx_begin <= '0';
                wait until tx_done = '1';
                report "TX test ended.";
                RX <= '0';
                wait for 8680 ns;
                for i in 0 to 7 loop
                    RX <= test_data(i);
                    wait for 8680 ns;
                end loop;
                RX <= '1';
                wait for 8680 ns;
                report "Test finished.";
                wait;
            end if;
        end loop;
	end process;
end rtl;