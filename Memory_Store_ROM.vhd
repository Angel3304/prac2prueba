library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Store is
  port(
    Addr_in  : in  std_logic_vector(7 downto 0);
    Data_bus : out std_logic_vector(23 downto 0)
  );
end entity;

architecture Behavioral of Memory_Store is
  -- Opcodes
  constant OP_LDX   : std_logic_vector(7 downto 0) := x"01";
  constant OP_LDY   : std_logic_vector(7 downto 0) := x"02";
  constant OP_ADD   : std_logic_vector(7 downto 0) := x"03";
  constant OP_ADDI  : std_logic_vector(7 downto 0) := x"04";
  constant OP_DISP  : std_logic_vector(7 downto 0) := x"06";
  constant OP_JUMP  : std_logic_vector(7 downto 0) := x"07";
  constant OP_BR_NZ : std_logic_vector(7 downto 0) := x"08";
  constant OP_SUB   : std_logic_vector(7 downto 0) := x"09";
  constant OP_WAIT  : std_logic_vector(7 downto 0) := x"0A";
  constant OP_STOP  : std_logic_vector(7 downto 0) := x"0F";

  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);
  
  -- Programa original de la Practica 2 (10 valores + delay)
  constant Program_Data : t_mem_array := (
    -- 1. Operación (105 + 5)
    0  => OP_LDX   & x"80" & x"00", -- Carga 105
    1  => OP_ADDI  & x"00" & x"05", -- Suma 5
    2  => OP_DISP  & x"00" & x"00", -- Muestra 110
    3  => OP_WAIT  & x"00" & x"00", -- Espera
    
    -- 2. Operación (10 + 6)
    4  => OP_LDX   & x"81" & x"00", 
    5  => OP_ADDI  & x"00" & x"06",
    6  => OP_DISP  & x"00" & x"00",
    7  => OP_WAIT  & x"00" & x"00", 

    -- 3. Operación (65 + 7)
    8  => OP_LDX   & x"82" & x"00",
    9  => OP_ADDI  & x"00" & x"07",
    10 => OP_DISP  & x"00" & x"00",
    11 => OP_WAIT  & x"00" & x"00",

    -- 4. Operación (50 + 8)
    12 => OP_LDX   & x"83" & x"00",
    13 => OP_ADDI  & x"00" & x"08",
    14 => OP_DISP  & x"00" & x"00",
    15 => OP_WAIT  & x"00" & x"00",

    -- 5. Operación (129 + 9)
    16 => OP_LDX   & x"84" & x"00",
    17 => OP_ADDI  & x"00" & x"09",
    18 => OP_DISP  & x"00" & x"00",
    19 => OP_WAIT  & x"00" & x"00",

    -- 6. Operación (400 + 10)
    20 => OP_LDX   & x"85" & x"00",
    21 => OP_ADDI  & x"00" & x"0A",
    22 => OP_DISP  & x"00" & x"00",
    23 => OP_WAIT  & x"00" & x"00",

    -- 7. Operación (783 + 11)
    24 => OP_LDX   & x"86" & x"00",
    25 => OP_ADDI  & x"00" & x"0B",
    26 => OP_DISP  & x"00" & x"00",
    27 => OP_WAIT  & x"00" & x"00",

    -- 8. Operación (15 + 12)
    28 => OP_LDX   & x"87" & x"00",
    29 => OP_ADDI  & x"00" & x"0C",
    30 => OP_DISP  & x"00" & x"00",
    31 => OP_WAIT  & x"00" & x"00",

    -- 9. Operación (230 + 13)
    32 => OP_LDX   & x"88" & x"00",
    33 => OP_ADDI  & x"00" & x"0D",
    34 => OP_DISP  & x"00" & x"00",
    35 => OP_WAIT  & x"00" & x"00",

    -- 10. Operación (3230 + 14)
    36 => OP_LDX   & x"89" & x"00",
    37 => OP_ADDI  & x"00" & x"0E",
    38 => OP_DISP  & x"00" & x"00",
    39 => OP_WAIT  & x"00" & x"00",

    -- HALT FINAL (Paro)
    40 => OP_STOP  & x"00" & x"00",

    -- DATOS (Direcciones 128 en adelante)
    128 => x"00" & std_logic_vector(to_unsigned(105, 16)),
    129 => x"00" & std_logic_vector(to_unsigned(10, 16)),
    130 => x"00" & std_logic_vector(to_unsigned(65, 16)),
    131 => x"00" & std_logic_vector(to_unsigned(50, 16)),
    132 => x"00" & std_logic_vector(to_unsigned(129, 16)),
    133 => x"00" & std_logic_vector(to_unsigned(400, 16)),
    134 => x"00" & std_logic_vector(to_unsigned(783, 16)),
    135 => x"00" & std_logic_vector(to_unsigned(15, 16)),
    136 => x"00" & std_logic_vector(to_unsigned(230, 16)),
    137 => x"00" & std_logic_vector(to_unsigned(3230, 16)),

    others => (others => '0')
  );
begin
  Data_bus <= Program_Data(to_integer(unsigned(Addr_in)));
end architecture;