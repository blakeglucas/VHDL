###############################################################
# Begins I2C Library testing and simulation. Add any additional
# files that need to be included, if any, before the i2c_tb.vhd
# file entry.
###############################################################
ghdl -a --std=08 types.vhd
ghdl -a --std=08 i2c.vhd
# Add new files here:
# ghdl -a --std=08 newfile.vhd
ghdl -a --std=08 i2c_tb.vhd
ghdl -e --std=08 i2c_test
ghdl -r --std=08 i2c_test --wave=waveform.ghw