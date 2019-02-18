# VHDL

Various VHDL libraries and utilities I've written. All examples are specific to the NandLand GO Board (<https://www.nandland.com/goboard/index.html>), but the libraries should work across all FPGA's, depending on your synthesis tool.

## Contents

The following are included in the repository:

 - I2C Library and Testbench
 - UART Library and Testbench
 - Various Utilities
 - Examples

## Known Bugs

 - [UART] First byte sent is always trash, afterwards fine

## TODO

 - [I2C] Handle ACK/nACK in WRITE mode
 - [I2C] Give real ACK/nACK in READ mode
 - [I2C] Handle clock stretching
 - [I2C] Provide error signal out?
 - [I2C] Configurable speed
 - [UART] Configurable baudrate
 - [UART] Fix testbench

## Future Libraries

 - SPI
 - USB, ideally, may not be possible yet

## Testing/Simulating

All libraries have been tested with GHDL (<http://ghdl.free.fr/>) and GTKWave (<http://gtkwave.sourceforge.net/>). A `test.sh` script is included in each file that will automatically analyze, emulate, and run tests for each library, if GHDL is installed an on the PATH. VHDL 2008 standard should be specified.

## License

ALl files in this repository are released under the MIT License:

Copyright 2019 Blake Lucas

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.