library ieee;
use ieee.std_logic_1164.all;

entity batalha_naval is port(
        clock: in std_logic;
        sw: in std_logic_vector(9 downto 0);
        ledg: out std_logic_vector(7 downto 0)
    );
end batalha_naval;

architecture comportamento of batalha_naval is
    begin process(clock)
    begin
        ledg(0) <= '1';
        ledg(5) <= '1';
    end process;

end architecture;