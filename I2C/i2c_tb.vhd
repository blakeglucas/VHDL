library IEEE;
use IEEE.std_logic_1164.all;
use work.types.all;

entity i2c_test is
end i2c_test;

architecture behavior of i2c_test is
	signal clk: std_logic := '0';
    signal scl: std_logic;
    signal sda: std_logic;
    signal ack: std_logic := '0';
    signal tx_data: i2c_data_buf_t;
    signal rx_data: i2c_data_buf_t;
    signal tx_bytes: integer := 0;
    signal rx_bytes: integer := 0;
    signal i2c_idle: std_logic;
    signal start: std_logic := '0';
    signal sda_buf: std_logic := 'Z';
    signal test_data: i2c_data_buf_t := (0 => x"AA", 1 => x"55", others => x"00");
begin
    
    -- 25 MHz
    clk <= not clk after 20 ns;
    
    I2C_Master_Inst: entity work.I2C_Master
    	port map(
        	clk => clk,
            scl => scl,
            sda => sda,
            tx_data => tx_data,
            rx_data => rx_data,
            tx_bytes => tx_bytes,
            rx_bytes => rx_bytes,
            idle => i2c_idle,
            start => start
        );
    
    process is
    begin
        if i2c_idle = '1' then
            tx_data(0) <= x"51";
            tx_data(1) <= x"0E";
            tx_bytes <= 1;
            rx_bytes <= 2;
            start <= '1';
            wait until i2c_idle = '0';
            start <= '0';
            report "Testing write";
            -- TODO Assert verification?
            for i in 0 to tx_bytes+1 loop
                wait until sda = 'Z';
                ack <= '1';
                wait until falling_edge(scl);
                ack <= '0';
            end loop;
            report "Ended write test.";
            -- Restart condition
            wait for 14 us;
            -- Address nACK
            wait until sda = 'Z';
            ack <= '1';
            wait until falling_edge(scl);
            ack <= '0';
            report "Testing read.";
            for j in 0 to rx_bytes-1 loop
                wait until sda = 'Z';
                for jj in 0 to 8 loop
                    if jj > 0 then
                        wait until falling_edge(scl);
                    end if;
                    if jj < 8 then
                        sda_buf <= test_data(j)(7-jj);
                    else
                        -- Release buffer for ACK
                        sda_buf <= 'Z';
                    end if;
                end loop;
                -- Wait until device has responded to byte (ACK/nACK)
                wait until sda /= 'Z';
                assert sda = '0'
                    report "Received ACK"
                    severity Failure;
            end loop;
            report "Ended read test.";
            wait until i2c_idle = '1';
            report "Test Finshed";
            assert rx_data(0) = x"AA" and rx_data(1) = x"55"
                report "Data receive failed"
                severity Failure;
            report "Test Passed";
            wait;
        end if;
    end process;
    sda <= '0' when ack = '1' else sda_buf;
end behavior;