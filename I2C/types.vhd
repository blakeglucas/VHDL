library IEEE;
use IEEE.std_logic_1164.all;

package types is
    type i2c_data_buf_t is array(0 to 7) of std_logic_vector(7 downto 0);
end types;