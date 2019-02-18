library ieee;
use ieee.std_logic_1164.all;

package stringutil is

    -----------------------------------------------------------
    -- Pads a string of length n to required length l. Also
    -- inserts a CR as the last character of the string.
    --
    -- TODO: custom EOS character
    --
    -- n: integer: length of input string
    -- a: string: input string
    -- l: integer: desired string length
    -- returns: padded string
    -----------------------------------------------------------
    function pad_string(
        n: integer;
        a: string(0 to n-1);
        l: integer
    ) return string;

    -----------------------------------------------------------
    -- Hackishly translates a half-byte (word, 4 bits, etc.) to
    -- the corresponding string representation. 8 -> "8", 15 ->
    -- "F", etc.
    --
    -- a: std_logic_vector: vector representing half-byte
    -- returns: string representation of a
    -----------------------------------------------------------
    function slv_word_to_hex(
        a: std_logic_vector(3 downto 0)
    ) return string;

    -----------------------------------------------------------
    -- Converts a byte-long hex number to a string, usually for
    -- transmission over UART. Adds CR to end.
    --
    -- a: std_logic_vector: vector to convert
    -- returns: converted string
    -----------------------------------------------------------
    function hex_stringify(
        a: in std_logic_vector(7 downto 0)
    ) return string;

end package;

package body stringutil is
    function pad_string(
        n: integer;
        a: string(0 to n-1);
        l: integer
    ) return string is
        variable result: string(0 to l-1);
    begin
        for i in 0 to a'length-1 loop
            result(i) := a(i);
        end loop;
        result(result'length - 1) := CR;
        return result;
    end function;

    function slv_word_to_hex(
        a: std_logic_vector(3 downto 0)
    ) return string is
    begin
        case a is
            when x"F" =>
                return "F";
            when x"E" =>
                return "E";
            when x"D" =>
                return "D";
            when x"C" =>
                return "C";
            when x"B" =>
                return "B";
            when x"A" =>
                return "A";
            when x"9" =>
                return "9";
            when x"8" =>
                return "8";
            when x"7" =>
                return "7";
            when x"6" =>
                return "6";
            when x"5" =>
                return "5";
            when x"4" =>
                return "4";
            when x"3" =>
                return "3";
            when x"2" =>
                return "2";
            when x"1" =>
                return "1";
            when x"0" =>
                return "0";
            when others =>
                return "";
        end case;
    end function;

    function hex_stringify(
        a: in std_logic_vector(7 downto 0)
    ) return string is
        variable result: string(0 to 7);
    begin
        -- Pad it to match exactly, otherwise assumes maximum length?
        result := pad_string(4, "0x" & slv_word_to_hex(a(7 downto 4)) & slv_word_to_hex(a(3 downto 0)), 8);
        return result;
    end function;
end package body;