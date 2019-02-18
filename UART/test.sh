ghdl -a --std=08 uart.vhd
ghdl -a --std=08 uart_tb.vhd
ghdl -e --std=08 uart_test
ghdl -r --std=08 uart_test --wave=waveform.ghw