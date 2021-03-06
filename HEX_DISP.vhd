LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

-- Hexadecimal to 7 Segment Decoder for LED Display
--  1) when free held low, displays latched data
--  2) when free held high, constantly displays input (free-run)
--  3) data is latched on rising edge of CS

ENTITY HEX_DISP IS
  PORT( hex_val  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        cs       : IN STD_LOGIC := '0';
        free     : IN STD_LOGIC := '0';
        resetn   : IN STD_LOGIC := '1';
        segments : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
END HEX_DISP;

ARCHITECTURE a OF HEX_DISP IS
  SIGNAL latched_hex : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL hex_d       : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

  PROCESS (resetn, cs)
  BEGIN
    IF (resetn = '0') THEN
      latched_hex <= "0000";
    ELSIF ( RISING_EDGE(cs) ) THEN
      latched_hex <= hex_val;
    END IF;
  END PROCESS;
  
  WITH free SELECT
    hex_d  <= latched_hex WHEN '0',
              hex_val     WHEN '1';
           
  WITH hex_d SELECT
    segments <= "1111111" WHEN "0000",
                "1111101" WHEN "0001",
                "1111011" WHEN "0010",
                "1111001" WHEN "0011",
                "0011001" WHEN "0100",
                "0010010" WHEN "0101",
                "0000010" WHEN "0110",
                "1111000" WHEN "0111",
                "0000000" WHEN "1000",
                "0010000" WHEN "1001", 
                "0001000" WHEN "1010",
                "0000011" WHEN "1011", 
                "1000110" WHEN "1100", 
                "0100001" WHEN "1101", 
                "0000110" WHEN "1110", 
                "0001110" WHEN "1111", 
                "0111111" WHEN OTHERS;
END a;

