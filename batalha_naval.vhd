library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity batalha_naval is port(
        key: in std_logic_vector(3 downto 0); -- key(3) é o clock, key(0) é o reset
        sw: in std_logic_vector(9 downto 0); -- sw(0) ao sw(3) é a posição do barco
                                             -- sw(4) é horizontal/vertical quando for 0/1 respectivamente
                                             -- sw(6) ao sw(9) é a mira do jogador
        ledG: out std_logic_vector(7 downto 0); -- ledG(0) acende quando acerta
        ledR: out std_logic_vector(9 downto 0); -- ledR(0) acende quando erra
        hex0, hex1, hex2, hex3: out std_logic_vector(6 downto 0);
        -- apenas em dev
        q_out: out std_logic_vector(5 downto 0);
        o_barco1, o_barco2_1, o_barco2_2, o_tiro: out std_logic_vector(3 downto 0);
        o_acertos: out std_logic_vector(2 downto 0)
    );
end batalha_naval;

architecture comportamento of batalha_naval is
    type estado is (q_input_1, q_input_2, q_gameplay, q_verificar, q_venceu, q_perdeu);
    signal q: estado;
    signal barco1, barco2_1, barco2_2: std_logic_vector(3 downto 0);
    signal acertos: std_logic_vector(2 downto 0);
    signal vetor_cheio: std_logic_vector(2 downto 0) := "111";
    signal tentativas: integer := 6;

    function codificar(input: std_logic_vector(3 downto 0)) return std_logic_vector is
        variable a, b, c, d : std_logic;
        variable resultado : std_logic_vector(3 downto 0);
    begin
        a := input(3);
        b := input(2);
        c := input(1);
        d := input(0);

        resultado(3) := (b and d) or (not a and not c and d) or (a and c and not d) or (not b and c and not d);
        resultado(2) := (a and not c) or (not b and not c) or (a and not b and not d) or (a and b and d);
        resultado(1) := (not b and not c and not d) or (not a and c and d) or (not b and c and d) or (a and c and not d) or (a and b and not c and d);
        resultado(0) := (not a and d) or (a and not c and not d) or (b and not c and d) or (not a and b and c);
        return resultado;
    end codificar;

    function decodificar(input: std_logic_vector(3 downto 0)) return std_logic_vector is
        variable a, b, c, d : std_logic;
        variable resultado : std_logic_vector(3 downto 0);
    begin
        a := input(3);
        b := input(2);
        c := input(1);
        d := input(0);

        resultado(3) := (not a and b and d) or (a and b and c) or (b and not c and not d) or (not b and c and not d);
        resultado(2) := (not a and not b and not c) or (not a and not c and d) or (not b and c and d) or (a and not b and c) or (a and c and d) or (a and b and not c and not d);
        resultado(1) := (not b and c) or (a and not d) or (not a and not b and d);
        resultado(0) := (a and d) or (not a and not b and c) or (b and not c and not d);
        return resultado;
    end decodificar;

begin

process(key(0), key(3)) 
    variable tiro: std_logic_vector(3 downto 0);
    variable hit: boolean;
begin
    if(key(0) = '1') then
        q <= q_input_1;
    elsif(key(3)'event and key(3) = '1') then
        case q is
            when q_input_1 =>
                barco1 <= sw(3 downto 0);
                q <= q_input_2;
            when q_input_2 =>
                barco2_1 <= sw(3 downto 0);
                if(sw(4) = '0') then
                    barco2_2 <= codificar(std_logic_vector(unsigned(decodificar(sw(3 downto 0))) + "0001"));
                elsif(sw(4) = '1') then
                    barco2_2 <= codificar(std_logic_vector(unsigned(decodificar(sw(3 downto 0))) + "0100"));
                end if;
                q <= q_gameplay;
            when q_gameplay =>
                ledr <= (others => '0');
                ledg <= (others => '0');

                tiro := codificar(sw(9 downto 6));
                hit := false;

                if(tiro = barco1) then
                    acertos(0) <= '1';
                    hit := true;
                elsif(tiro = barco2_1) then
                    acertos(1) <= '1';
                    hit := true;
                elsif(tiro = barco2_2) then
                    acertos(2) <= '1';
                    hit := true;
                end if;
                
                if(not(tentativas = 1 and hit)) then
                    tentativas <= tentativas - 1;
                end if;

                o_tiro <= tiro;
                q <= q_verificar;
            when q_verificar =>
                if(acertos = vetor_cheio) then
                    q <= q_venceu;
                elsif(tentativas = 0) then
                    q <= q_perdeu;
                else
                    q <= q_gameplay;
                end if;
            when q_perdeu =>
            when q_venceu =>
        end case;
    end if;
end process;

process(q) begin
    o_barco1 <= barco1;
    o_barco2_1 <= barco2_1;
    o_barco2_2 <= barco2_2;
    case q is
        when q_input_1 =>
            q_out <= (others => '0');
            q_out(0) <= '1';
        when q_input_2 =>
            q_out(1) <= '1';
        when q_gameplay =>
            q_out(2) <= '1';
            q_out(3) <= '0';
        when q_verificar =>
            o_acertos <= acertos;
            q_out(3) <= '1';
        when q_venceu =>
            ledG <= (others => '1');
            q_out(4) <= '1';
        when q_perdeu =>
            ledR <= (others => '1');
            q_out(5) <= '1';
    end case;
end process;

process(tentativas) begin
    case tentativas is
        when 6 =>
            hex0 <= "0000010";
        when 5 =>
            hex0 <= "0010010";
        when 4 =>
            hex0 <= "0011001";
        when 3 =>
            hex0 <= "0110000";
        when 2 =>
            hex0 <= "0100100";
        when 1 =>
            hex0 <= "1111001";
        when 0 =>
            hex0 <= "1000000";
        when others =>
    end case;
end process;

end architecture;