---------------------------------------------------------------
-- Example usage of UART library. Written for NandLand GO
-- Board. Synthesized with iCEcube2.
--
-- Author:  Blake Lucas
-- Date:    18 February 2019
--
-- Echoes back the string representation of the last key
-- pressed in a serial console (PuTTY, TeraTerm, etc).
--
-- Serial parameters:
--      115200 baud
--      8 bits
--      No parity
--      Start/stop bits
--      No flow control
---------------------------------------------------------------
library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Need to link stringutil file in Synthesis tool.
use work.stringutil.all;

entity main is
    port(
        i_UART_RX: in std_logic;
        o_UART_TX: out std_logic;
        -- Testing UART over PMOD connector
        -- io_PMOD_1: in std_logic;
        -- io_PMOD_2: out std_logic;
        i_Clk: in std_logic;
        o_Segment1_A: out std_logic;
        o_Segment1_B: out std_logic;
        o_Segment1_C: out std_logic;
        o_Segment1_D: out std_logic;
        o_Segment1_E: out std_logic;
        o_Segment1_F: out std_logic;
        o_Segment1_G: out std_logic;
        o_Segment2_A: out std_logic;
        o_Segment2_B: out std_logic;
        o_Segment2_C: out std_logic;
        o_Segment2_D: out std_logic;
        o_Segment2_E: out std_logic;
        o_Segment2_F: out std_logic;
        o_Segment2_G: out std_logic
    );
end main;

architecture RTL of main is
    -- Flag to tell UART to begin transmission
    signal tx_begin: std_logic := '0';
    -- Data to transmit. Set before activating tx_begin
    signal tx_data: std_logic_vector(7 downto 0);
    -- Signal set by UART when data is finished transmitting
    signal tx_done: std_logic := '1';
    -- Received data buffer.
    signal rx_data: std_logic_vector(7 downto 0);
    -- Flag set by UART when data has been received. Treat like
    -- interrupt flag
    signal rx_done: std_logic := '0';
begin
    UART_Inst: entity work.UART
        port map(
            TX => o_UART_TX,
            RX => i_UART_RX,
            -- TX => io_PMOD_2,
            -- RX => io_PMOD_1,
            clk => i_Clk,
            tx_begin => tx_begin,
            tx_done => tx_done,
            tx_data => tx_data,
            rx_data => rx_data,
            rx_flag => rx_done
        );

    S1B27Driver: entity work.Binary7SegDriver
        port map(
            i_Clk => i_Clk,
            i_Binary_Num => rx_data(7 downto 4),
            o_Segment_A => o_Segment1_A,
            o_Segment_B => o_Segment1_B,
            o_Segment_C => o_Segment1_C,
            o_Segment_D => o_Segment1_D,
            o_Segment_E => o_Segment1_E,
            o_Segment_F => o_Segment1_F,
            o_Segment_G => o_Segment1_G
        );

    S2B27Driver: entity work.Binary7SegDriver
        port map(
            i_Clk => i_Clk,
            i_Binary_Num => rx_data(3 downto 0),
            o_Segment_A => o_Segment2_A,
            o_Segment_B => o_Segment2_B,
            o_Segment_C => o_Segment2_C,
            o_Segment_D => o_Segment2_D,
            o_Segment_E => o_Segment2_E,
            o_Segment_F => o_Segment2_F,
            o_Segment_G => o_Segment2_G
        );

    process(i_Clk) is
        -- Track state of rx_done
        variable rx_done_prev: std_logic := '0';
        -- Track state of tx_done
        variable tx_done_prev: std_logic := '0';
        -- Counter to transmit multi-character strings
        variable char_index: integer := 0;
        -- String to transmit
        variable s: string(0 to 7);
    begin
        if rising_edge(i_Clk) then
            if rx_done_prev = '0' and rx_done = '1' then
                s := hex_stringify(rx_data);
                -- Begin transmission
                char_index := 0;
            end if;
            -- Advance to next character
            if tx_done_prev= '0' and tx_done = '1' then
                char_index := char_index + 1;
            end if;
            if char_index < s'length then
                if tx_done = '1' then
                    tx_data <= std_logic_vector(to_unsigned(character'pos(character(s(char_index))), 8));
                    tx_begin <= '1';     -- Begin transfer
                end if;
            end if;
            -- Would be included in UART if possible
            if tx_begin = '1' then
                -- Always keep tx_begin low, only pull high to initiate transfer.
                tx_begin <= '0';
            end if;
            rx_done_prev := rx_done;
            tx_done_prev := tx_done;
        end if;
    end process;
end RTL;