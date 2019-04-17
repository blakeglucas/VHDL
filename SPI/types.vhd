library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package types is
    type spi_data_buf_t is array(0 to 7) of std_logic_vector(7 downto 0);
end types;