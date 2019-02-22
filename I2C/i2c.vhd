library IEEE;
use IEEE.std_logic_1164.all;
use work.types.all;

entity I2C_Master is
	port(
		clk: in std_logic;
        sda: inout std_logic;
        scl: out std_logic;
        tx_data: in i2c_data_buf_t;
        rx_data: out i2c_data_buf_t;
        tx_bytes: in integer;
        rx_bytes: in integer;
        idle: out std_logic := '1';
        start: in std_logic
    );    
end I2C_Master;

architecture RTL of I2C_Master is
    constant clk_ticks: integer := 125;
	type sda_state_t is (SDA_IDLE, SDA_START, SDA_WRITE, SDA_READ, SDA_ACK, SDA_STOP);
    signal sda_state: sda_state_t := SDA_IDLE;
	signal scl_state: std_logic := '1';
    signal sda_buf: std_logic := 'Z';
    signal tick_count: integer := 0;
begin
	scl_gen: process(clk) is
	begin
    	if rising_edge(clk) then
        	tick_count <= tick_count + 1;
        	if tick_count >= clk_ticks then
            	scl_state <= not scl_state;
                tick_count <= 0;
            end if;
        end if;
    end process;
    
    data_handler: process(clk) is
        constant h_clk_ticks: integer := clk_ticks / 2;
        variable tx_count: integer := 0;
        variable rx_count: integer := 0;
        variable start_set: std_logic := '0';
        variable addr_bit: std_logic := '0';
        variable addr_buf: std_logic_vector(7 downto 0) := (others => '0');
        variable did_nack: std_logic := 'U';
        variable index: integer := 0;
        variable rw: std_logic := '0';
    begin
        if rising_edge(clk) then
            case sda_state is
                when SDA_IDLE =>
                    idle <= '1';
                    tx_count := 0;
                    rx_count := 0;
                    if start = '1' then
                        sda_state <= SDA_START;
                        idle <= '0';
                    end if;
                when SDA_START =>
                    if scl_state = '0' and start_set = '0' then
                        sda_buf <= '1';
                    end if;
                    if tick_count = 3 * clk_ticks / 4 then
                        if scl_state = '1' then
                            -- SET START BIT
                            sda_buf <= '0';
                            start_set := '1';
                        elsif scl_state = '0' and start_set = '1' then
                            if tx_count = 0 and rx_count = 0 then
                                rw := '0';
                                addr_bit := '1';
                                sda_state <= SDA_WRITE;
                                start_set := '0';
                                index := 0;
                            elsif rx_count = 0 and rx_bytes > 0 and tx_count >= tx_bytes then
                                rw := '1';
                                addr_bit := '1';
                                sda_state <= SDA_WRITE;
                                start_set := '0';
                                index := 0;
                            end if;
                        end if;
                    end if;
                when SDA_WRITE =>
                    if index < 8 then
                        if addr_bit = '1' then
                            -- First packet -> address
                            addr_buf := tx_data(0)(6 downto 0) & rw;
                            sda_buf <= addr_buf(7-index);
                        else
                            -- 0 bit is address
                            sda_buf <= tx_data(tx_count + 1)(7-index);
                        end if;
                    end if;
                    if scl_state = '0' then
                        if index >= 8 then
                            did_nack := 'U';
                            sda_state <= SDA_ACK;
                        end if;
                        if tick_count = 0 then
                            if index < 8 then
                                index := index + 1;
                            end if;
                        end if;
                    end if;
                when SDA_READ =>
                    if index < 8 then
                        if tick_count = 0 and scl_state = '1' then
                            rx_data(rx_count)(7-index) <= sda;
                            index := index + 1;
                        end if;
                    -- elsif sda = 'Z' then **STUCK IN READ** (for simulation)
                    elsif sda = '1' then
                        sda_state <= SDA_ACK;
                    end if;
                when SDA_ACK =>
                    if rw = '0' or addr_bit = '1' then
                        sda_buf <= 'Z';
                    elsif rw = '1' then
                        -- TODO ACK vs NACK
                        sda_buf <= '0';
                    end if;
                    -- Sample on rising edge
                    if tick_count = 0 and scl_state = '1' and rw = '0' then
                            did_nack := sda;
                    end if;
                    if tick_count = 0 and scl_state = '0' then
                        if rw = '0' then
                            if addr_bit = '1' then
                                sda_state <= SDA_WRITE;
                                index := 0;
                                addr_bit := '0';
                            else
                                tx_count := tx_count + 1;
                                if tx_count < tx_bytes then
                                    sda_state <= SDA_WRITE;
                                    index := 0;
                                else
                                    if rx_bytes > 0 then
                                        -- Restart condition
                                        sda_state <= SDA_START;
                                    else
                                        sda_state <= SDA_STOP;
                                    end if;
                                end if;
                            end if;
                        elsif rw = '1' then
                            if addr_bit = '1' then
                                sda_state <= SDA_READ;
                                index := 0;
                                addr_bit := '0';
                            else
                                rx_count := rx_count + 1;
                                if rx_count < rx_bytes then
                                    sda_state <= SDA_READ;
                                    index := 0;
                                else
                                    sda_state <= SDA_STOP;
                                end if;
                            end if;
                        end if;
                    end if;
                when SDA_STOP =>
                    if tick_count = 3 * clk_ticks / 4 and scl_state = '1' then
                        sda_state <= SDA_IDLE;
                    elsif tick_count >= clk_ticks / 4 and scl_state = '1' then
                        sda_buf <= 'Z';
                    else
                        sda_buf <= '0';
                    end if;
                when others =>
                    sda_state <= SDA_IDLE;
            end case;
        end if;
    end process;
    sda <=  sda_buf when sda_state = SDA_START else
    		sda_buf when sda_state = SDA_WRITE else
            'Z' when sda_state = SDA_READ else
            sda_buf when sda_state = SDA_ACK else
            sda_buf when sda_state = SDA_STOP else
            'Z';
    scl <= 'Z' when sda_state = SDA_IDLE else
            scl_state;
end RTL;