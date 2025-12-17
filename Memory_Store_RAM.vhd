library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Store is
  port(
    clk      : in  std_logic;
    we       : in  std_logic; -- Write Enable
    Addr_in  : in  std_logic_vector(7 downto 0);
    Data_in  : in  std_logic_vector(23 downto 0);
    Data_out : out std_logic_vector(23 downto 0)
  );
end entity;

architecture Behavioral of Memory_Store is
  -- Opcodes
  constant OP_LDX   : std_logic_vector(7 downto 0) := x"01"; -- Cargar Registro X
  constant OP_LDY   : std_logic_vector(7 downto 0) := x"02"; -- Cargar Registro Y
  constant OP_ADD   : std_logic_vector(7 downto 0) := x"03"; -- Suma (X + Y)
  constant OP_ADDI  : std_logic_vector(7 downto 0) := x"04"; -- Suma Inmediata
  constant OP_CMP   : std_logic_vector(7 downto 0) := x"05"; -- Comparar (X - Y)
  constant OP_DISP  : std_logic_vector(7 downto 0) := x"06"; -- Mostrar en Display
  constant OP_JUMP  : std_logic_vector(7 downto 0) := x"07"; -- Salto Incondicional
  constant OP_BR_NZ : std_logic_vector(7 downto 0) := x"08"; -- Salto si no es 0
  constant OP_SUB   : std_logic_vector(7 downto 0) := x"09"; -- Resta (X - Y)
  constant OP_WAIT  : std_logic_vector(7 downto 0) := x"0A"; -- Esperar 1 segundo
  constant OP_BS    : std_logic_vector(7 downto 0) := x"0B"; -- Salto si S=1 (Signo Negativo)
  constant OP_BNC   : std_logic_vector(7 downto 0) := x"0C"; -- Salto si C=0 (No Carry/Mayor o Igual)
  constant OP_BNV   : std_logic_vector(7 downto 0) := x"0D"; -- Salto si OV=0 (No Overflow)
  constant OP_MUL   : std_logic_vector(7 downto 0) := x"0E"; -- Multiplicación
  constant OP_STOP  : std_logic_vector(7 downto 0) := x"0F"; -- Detener CPU
  constant OP_DIV   : std_logic_vector(7 downto 0) := x"10"; -- División
  constant OP_STX   : std_logic_vector(7 downto 0) := x"11"; -- Guardar Registro X en Memoria
  
  -- x"00" - x"99": Espacio de Programa
  -- x"A0" - x"AF": Datos de Entrada y Constantes
  -- x"B0" - x"BF": Variables Temporales
  -- x"E0"       : Dirección de Salida a LEDs
  -- x"F0"       : Dirección de Entrada de Switches
  
  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);
  
  signal mem_array : t_mem_array := (
    -- SELECTOR DE ECUACION
    -- Lee los switches físicos y decide que bloque de codigo ejecutar
    -- PC=0: Lectura de Switches
    0  => OP_LDX   & x"F0" & x"00", 
    1  => OP_STX   & x"BF" & x"00", -- Guardar seleccion en variable temporal
    
    -- Comparar con 0 (Binario "00") -> Ir a Ecuación A
    2  => OP_LDY   & x"A6" & x"00", -- Cargar 0
    3  => OP_CMP   & x"00" & x"00", 
    4  => OP_BR_NZ & x"07" & x"00", -- Si no es 0, ir a siguiente chequeo
    5  => OP_JUMP  & x"17" & x"00", -- Es 0: Saltar a PC=23 (Ec. A)
    6  => (others => '0'),          -- NOP

    -- Comparar con 1 (Binario "01") -> Ir a Ecuación B
    7  => OP_LDX   & x"BF" & x"00", -- Recuperar selección
    8  => OP_LDY   & x"A5" & x"00", -- Cargar 1
    9  => OP_CMP   & x"00" & x"00", 
    10 => OP_BR_NZ & x"0D" & x"00", -- Si no es 1, ir a siguiente chequeo
    11 => OP_JUMP  & x"2E" & x"00", -- Es 1: Saltar a PC=46 (Ec. B)
    12 => (others => '0'),          -- NOP

    -- Comparar con 2 (Binario "10") -> Ir a Ecuación C
    13 => OP_LDX   & x"BF" & x"00", -- Recuperar selección
    14 => OP_LDY   & x"A4" & x"00", -- Cargar 2
    15 => OP_CMP   & x"00" & x"00", 
    16 => OP_BR_NZ & x"14" & x"00", -- Si no es 2, ir a siguiente (Caso "11")
    17 => OP_JUMP  & x"43" & x"00", -- Es 2: Saltar a PC=67 (Ec. C)
    18 => (others => '0'),
    19 => (others => '0'),

    -- Caso "11": Ecuación D (Mostrar 0000 y parar)
    20 => OP_LDX   & x"A6" & x"00", -- Cargar 0
    21 => OP_DISP  & x"00" & x"00", -- Mostrar en Display
    22 => OP_STOP  & x"00" & x"00", -- Fin de ejecución
    
    -- BLOQUES DE ECUACIONES
    -- Valores de prueba: X=3, Y=2, Z=80, W=40
    ------------------------------------------------------------------
    
    -- ECUACIÓN A (PC=23): F = 17X + 25Y - W/4
    -- Resultado esperado: 17(3) + 25(2) - 40/4 = 51 + 50 - 10 = 91
    23 => OP_LDX   & x"A0" & x"00", -- X = 3
    24 => OP_LDY   & x"AE" & x"00", -- Y = 17
    25 => OP_MUL   & x"00" & x"00", -- X = 17*3 = 51
    26 => OP_STX   & x"D0" & x"00", -- Guardar Término 1
    27 => OP_LDX   & x"A1" & x"00", -- X = 2
    28 => OP_LDY   & x"AB" & x"00", -- Y = 25
    29 => OP_MUL   & x"00" & x"00", -- X = 25*2 = 50
    30 => OP_STX   & x"D1" & x"00", -- Guardar Término 2
    31 => OP_LDX   & x"A3" & x"00", -- X = 40
    32 => OP_LDY   & x"AC" & x"00", -- Y = 4
    33 => OP_DIV   & x"00" & x"00", -- X = 40/4 = 10
    34 => OP_STX   & x"D2" & x"00", -- Guardar Término 3
    35 => OP_LDX   & x"D0" & x"00", -- Recuperar T1
    36 => OP_LDY   & x"D1" & x"00", -- Recuperar T2
    37 => OP_ADD   & x"00" & x"00", -- Sumar T1 + T2
    38 => OP_LDY   & x"D2" & x"00", -- Recuperar T3
    39 => OP_SUB   & x"00" & x"00", -- Restar T3
    40 => OP_STX   & x"D3" & x"00", -- Guardar Resultado Final (F=91)
    41 => OP_JUMP  & x"61" & x"00", -- Ir a Lógica Común (PC=97)
    42 => (others => '0'),
    43 => (others => '0'),
    44 => (others => '0'),
    45 => (others => '0'),

    -- ECUACIÓN B (PC=46): F = 10X^2 + 30X - Z/2
    -- Resultado esperado: 10(9) + 90 - 40 = 140
    46 => OP_LDX   & x"A0" & x"00", -- X = 3
    47 => OP_LDY   & x"A0" & x"00", -- Y = 3
    48 => OP_MUL   & x"00" & x"00", -- X = X^2 = 9
    49 => OP_LDY   & x"B0" & x"00", -- Y = 10
    50 => OP_MUL   & x"00" & x"00", -- X = 90
    51 => OP_STX   & x"D0" & x"00", -- Guardar Término 1
    52 => OP_LDX   & x"A0" & x"00", -- X = 3
    53 => OP_LDY   & x"B1" & x"00", -- Y = 30
    54 => OP_MUL   & x"00" & x"00", -- X = 90
    55 => OP_STX   & x"D1" & x"00", -- Guardar Término 2
    56 => OP_LDX   & x"A2" & x"00", -- X = 80
    57 => OP_LDY   & x"A4" & x"00", -- Y = 2
    58 => OP_DIV   & x"00" & x"00", -- X = 40
    59 => OP_STX   & x"D2" & x"00", -- Guardar Término 3
    60 => OP_LDX   & x"D0" & x"00", -- Sumar T1...
    61 => OP_LDY   & x"D1" & x"00", -- ... + T2
    62 => OP_ADD   & x"00" & x"00", 
    63 => OP_LDY   & x"D2" & x"00", -- Restar T3
    64 => OP_SUB   & x"00" & x"00", 
    65 => OP_STX   & x"D3" & x"00", -- Guardar Resultado Final (F=140)
    66 => OP_JUMP  & x"61" & x"00", -- Ir a Lógica Común (PC=97)

    -- ECUACIÓN C (PC=67): F = -X^3 - 7Z + W/10
    -- Resultado esperado: -27 - 560 + 4 = -583
    67 => OP_LDX   & x"A0" & x"00", -- X = 3
    68 => OP_LDY   & x"A0" & x"00", 
    69 => OP_MUL   & x"00" & x"00", -- X = X^2 = 9
    70 => OP_LDY   & x"A0" & x"00", 
    71 => OP_MUL   & x"00" & x"00", -- X = X^3 = 27
    
    -- Uso de RAM como puente (Swap) para mover X a Y
    72 => OP_STX   & x"B3" & x"00", -- Guardar X^3 en Temp
    73 => OP_LDY   & x"B3" & x"00", -- Cargar Y desde Temp
    
    74 => OP_LDX   & x"A6" & x"00", -- X = 0
    75 => OP_SUB   & x"00" & x"00", -- 0 - 27 = -27
    76 => OP_STX   & x"D0" & x"00", -- Guardar Término 1
    77 => OP_LDX   & x"A2" & x"00", -- X = 80
    78 => OP_LDY   & x"AF" & x"00", -- Y = 7
    79 => OP_MUL   & x"00" & x"00", -- X = 560
    
    -- Uso de RAM como puente para 7Z
    80 => OP_STX   & x"B3" & x"00", 
    81 => OP_LDY   & x"B3" & x"00", 
    
    82 => OP_LDX   & x"A6" & x"00", -- X = 0
    83 => OP_SUB   & x"00" & x"00", -- 0 - 560 = -560
    84 => OP_STX   & x"D1" & x"00", -- Guardar Término 2
    85 => OP_LDX   & x"A3" & x"00", -- X = 40
    86 => OP_LDY   & x"B0" & x"00", -- Y = 10
    87 => OP_DIV   & x"00" & x"00", -- X = 4
    88 => OP_STX   & x"D2" & x"00", -- Guardar Término 3
    89 => OP_LDX   & x"D0" & x"00", -- Sumar todos los términos negativos y positivos
    90 => OP_LDY   & x"D1" & x"00", 
    91 => OP_ADD   & x"00" & x"00", 
    92 => OP_LDY   & x"D2" & x"00", 
    93 => OP_ADD   & x"00" & x"00", 
    94 => OP_STX   & x"D3" & x"00", -- Guardar Resultado Final (F=-583)
    95 => (others => '0'), 
    96 => (others => '0'), 

    -- LÓGICA COMÚN (Visualización y Temporizadores)
    -- Muestra el resultado, espera 10s y luego inicia contador 0-30
    ------------------------------------------------------------------
    
    -- 1. Mostrar Resultado por 10 segundos
    97 => OP_LDX   & x"D3" & x"00", -- Cargar Resultado F
    98 => OP_DISP  & x"00" & x"00", -- Enviar al Display de 7 segmentos
    99 => OP_LDX   & x"A7" & x"00", -- Cargar constante 10 (segundos)
    100 => OP_STX  & x"D6" & x"00", -- Inicializar contador de espera
    
    -- Bucle de espera de 10s (Visualizando en LEDs)
    101 => OP_LDX  & x"D6" & x"00", 
    102 => OP_STX  & x"E0" & x"00", -- Enviar tiempo restante a LEDs (MMIO x"E0")
    103 => OP_WAIT & x"00" & x"00", -- Retardo de hardware de 1 seg
    104 => OP_LDX  & x"D6" & x"00", 
    105 => OP_LDY  & x"A5" & x"00", -- Restar 1
    106 => OP_SUB  & x"00" & x"00", 
    107 => OP_STX  & x"D6" & x"00", 
    108 => OP_BR_NZ & x"65" & x"00",-- Si no es 0, repetir bucle (Ir a PC=101)
    
    -- 2. Determinar Retardo Variable 'T' según el resultado 'F'
    109 => OP_LDX  & x"D3" & x"00", -- Cargar F
    110 => OP_LDY  & x"A9" & x"00", -- Comparar con 100
    111 => OP_CMP  & x"00" & x"00", 
    112 => OP_BNC  & x"92" & x"00", -- Si F >= 100, T=2s (PC=146)
    113 => OP_LDY  & x"AA" & x"00", -- Comparar con 60
    114 => OP_CMP  & x"00" & x"00", 
    115 => OP_BNC  & x"94" & x"00", -- Si F >= 60, T=3s (PC=148)
    116 => OP_LDY  & x"AB" & x"00", -- Comparar con 25
    117 => OP_CMP  & x"00" & x"00", 
    118 => OP_BNC  & x"96" & x"00", -- Si F >= 25, T=4s (PC=150)
    119 => OP_LDY  & x"A6" & x"00", -- Comparar con 0
    120 => OP_CMP  & x"00" & x"00", 
    121 => OP_BNC  & x"98" & x"00", -- Si F >= 0, T=1s (PC=152)
    122 => OP_LDX  & x"AD" & x"00", -- Sino (Negativo), T=5s
    123 => OP_JUMP & x"99" & x"00", -- Ir a Guardar T (PC=153)

    -- 3. Contador Ascendente 0 a 30 con Retardo T
    -- Inicialización
    124 => OP_LDX  & x"A6" & x"00", -- Cargar 0
    125 => OP_STX  & x"D4" & x"00", -- Guardar en Variable Contador N
    
    -- Inicio del ciclo de cuenta (N)
    126 => OP_LDX  & x"D4" & x"00", -- Cargar N
    127 => OP_DISP & x"00" & x"00", -- Mostrar N en Display
    128 => OP_LDX  & x"D5" & x"00", -- Cargar T (Tiempo calculado antes)
    129 => OP_STX  & x"D6" & x"00", -- Inicializar contador temporal de espera
    
    -- Sub-ciclo de espera de T segundos (Visualizando en LEDs)
    130 => OP_LDX  & x"D6" & x"00", 
    131 => OP_STX  & x"E0" & x"00", -- Actualizar LEDs con segundos restantes
    132 => OP_WAIT & x"00" & x"00", -- Esperar 1s
    133 => OP_LDX  & x"D6" & x"00", 
    134 => OP_LDY  & x"A5" & x"00", -- Restar 1
    135 => OP_SUB  & x"00" & x"00", 
    136 => OP_STX  & x"D6" & x"00", 
    137 => OP_BR_NZ & x"82" & x"00",-- Repetir espera si no ha terminado (Ir a PC=130)
    
    -- Incrementar Contador N y verificar límite (30)
    138 => OP_LDX  & x"D4" & x"00", 
    139 => OP_LDY  & x"A5" & x"00", 
    140 => OP_ADD  & x"00" & x"00", -- N = N + 1
    141 => OP_STX  & x"D4" & x"00", 
    142 => OP_LDY  & x"A8" & x"00", -- Comparar con 30
    143 => OP_CMP  & x"00" & x"00", 
    144 => OP_BNC  & x"9B" & x"00", -- Si N >= 30, Terminar (PC=155)
    145 => OP_JUMP & x"7E" & x"00", -- Sino, Repetir ciclo principal (Ir a PC=126)
    
    -- Bloques de Asignación de Tiempos (Saltos desde comparaciones)
    146 => OP_LDX  & x"A4" & x"00", -- Cargar 2s
    147 => OP_JUMP & x"99" & x"00", 
    148 => OP_LDX  & x"B2" & x"00", -- Cargar 3s
    149 => OP_JUMP & x"99" & x"00", 
    150 => OP_LDX  & x"AC" & x"00", -- Cargar 4s
    151 => OP_JUMP & x"99" & x"00", 
    152 => OP_LDX  & x"A5" & x"00", -- Cargar 1s
    
    -- Guardar Tiempo T seleccionado
    153 => OP_STX  & x"D5" & x"00", 
    154 => OP_JUMP & x"7C" & x"00", -- Ir al inicio del contador (PC=124)
    
    -- Fin del Programa
    155 => OP_STOP & x"00" & x"00",

    ------------------------------------------------------------------
    -- SECCIÓN DE DATOS (CONSTANTES Y ENTRADAS)
    -- Dirección Base: x"A0" (160 decimal)
    ------------------------------------------------------------------
    160 => x"00" & std_logic_vector(to_unsigned(3, 16)),    -- x"A0": VALOR X (3)
    161 => x"00" & std_logic_vector(to_unsigned(2, 16)),    -- x"A1": VALOR Y (2)
    162 => x"00" & std_logic_vector(to_unsigned(80, 16)),   -- x"A2": VALOR Z (80)
    163 => x"00" & std_logic_vector(to_unsigned(40, 16)),   -- x"A3": VALOR W (40)
    164 => x"00" & std_logic_vector(to_unsigned(2, 16)),    -- x"A4": CONST 2
    165 => x"00" & std_logic_vector(to_unsigned(1, 16)),    -- x"A5": CONST 1
    166 => x"00" & std_logic_vector(to_unsigned(0, 16)),    -- x"A6": CONST 0
    167 => x"00" & std_logic_vector(to_unsigned(10, 16)),   -- x"A7": CONST 10
    168 => x"00" & std_logic_vector(to_unsigned(31, 16)),   -- x"A8": CONST 31 (Límite)
    169 => x"00" & std_logic_vector(to_unsigned(100, 16)),  -- x"A9": CONST 100
    170 => x"00" & std_logic_vector(to_unsigned(60, 16)),   -- x"AA": CONST 60
    171 => x"00" & std_logic_vector(to_unsigned(25, 16)),   -- x"AB": CONST 25
    172 => x"00" & std_logic_vector(to_unsigned(4, 16)),    -- x"AC": CONST 4
    173 => x"00" & std_logic_vector(to_unsigned(5, 16)),    -- x"AD": CONST 5
    174 => x"00" & std_logic_vector(to_unsigned(17, 16)),   -- x"AE": CONST 17
    175 => x"00" & std_logic_vector(to_unsigned(7, 16)),    -- x"AF": CONST 7
    176 => x"00" & std_logic_vector(to_unsigned(10, 16)),   -- x"B0": CONST 10
    177 => x"00" & std_logic_vector(to_unsigned(30, 16)),   -- x"B1": CONST 30
    178 => x"00" & std_logic_vector(to_unsigned(3, 16)),    -- x"B2": CONST 3

    -- Relleno para el resto de la memoria
    others => (others => '0')
  );

begin

  -- Lectura asíncrona de la memoria
  Data_out <= mem_array(to_integer(unsigned(Addr_in)));

  -- Proceso de escritura síncrona
  Write_Process : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem_array(to_integer(unsigned(Addr_in))) <= Data_in;
      end if;
    end if;
  end process Write_Process;

end architecture;