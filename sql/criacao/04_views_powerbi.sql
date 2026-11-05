/* ============================================================
   Projeto Fluminense no Brasileirão - views para o Power BI
   Cada view entrega uma tabela pronta; o Power BI só lê.
   ============================================================ */

USE brasileirao_flu;

/* ---------- 1. Jogos do Fluminense com técnico e passagem ---------- */
-- Uma linha por jogo (2014+). Base das páginas de visão geral, casa x fora e técnicos.

CREATE OR REPLACE VIEW vw_jogos_fluminense AS
WITH base AS (
    SELECT
        v.*,
        CASE v.tecnico
            WHEN 'E. de Barros' THEN 'F. Diniz Silva'        -- auxiliar do Diniz
            WHEN 'S. Lobo'      THEN 'L. Venker de Menezes'  -- auxiliar do Mano
            ELSE v.tecnico
        END AS tecnico_titular
    FROM vw_partidas_fluminense v
),
marcado AS (
    SELECT
        b.*,
        CASE WHEN b.tecnico_titular = LAG(b.tecnico_titular) OVER (ORDER BY b.data, b.id_partida)
             THEN 0 ELSE 1 END AS trocou
    FROM base b
),
numerado AS (
    SELECT
        m.*,
        SUM(m.trocou) OVER (ORDER BY m.data, m.id_partida) AS passagem
    FROM marcado m
)
SELECT
    n.id_partida,
    n.temporada,
    n.rodada,
    n.data,
    n.mando,
    n.adversario,
    n.gols_pro,
    n.gols_contra,
    n.resultado,
    n.pontos,
    n.tecnico,
    n.tecnico_titular,
    n.passagem,
    CONCAT(n.tecnico_titular, ' (',
           YEAR(MIN(n.data) OVER (PARTITION BY n.passagem)), '-',
           YEAR(MAX(n.data) OVER (PARTITION BY n.passagem)), ')') AS passagem_rotulo,
    n.arena
FROM numerado n;

/* ---------- 2. Gols em jogos do Fluminense ---------- */
-- Uma linha por gol (pró e contra). Base das páginas de momento dos gols e artilheiros.

CREATE OR REPLACE VIEW vw_gols_fluminense AS
SELECT
    g.id_gol,
    v.id_partida,
    v.temporada,
    v.mando,
    CASE WHEN t.nome = 'Fluminense' THEN 'Pró' ELSE 'Contra' END AS lado,
    g.atleta,
    g.minuto,
    g.acrescimo,
    g.tipo_gol,
    CASE
        WHEN g.minuto <= 15 THEN '01-15'
        WHEN g.minuto <= 30 THEN '16-30'
        WHEN g.minuto <= 45 THEN '31-45'
        WHEN g.minuto <= 60 THEN '46-60'
        WHEN g.minuto <= 75 THEN '61-75'
        ELSE '76-90'
    END AS faixa
FROM fato_gol g
JOIN vw_partidas_fluminense v ON v.id_partida = g.id_partida
JOIN dim_time t               ON t.id_time    = g.id_time;

/* ---------- 3. Posição do Fluminense rodada a rodada ---------- */

CREATE OR REPLACE VIEW vw_posicao_rodada AS
WITH jogos_time AS (
    SELECT temporada, rodada, id_mandante AS id_time,
           gols_mandante AS gp, gols_visitante AS gc
    FROM fato_partida WHERE temporada >= 2014
    UNION ALL
    SELECT temporada, rodada, id_visitante,
           gols_visitante, gols_mandante
    FROM fato_partida WHERE temporada >= 2014
),
grade AS (
    SELECT t.temporada, t.id_time, r.rodada
    FROM (SELECT DISTINCT temporada, id_time FROM jogos_time) t
    JOIN (SELECT DISTINCT temporada, rodada  FROM jogos_time) r
      ON r.temporada = t.temporada
),
completo AS (
    SELECT g.temporada, g.rodada, g.id_time,
           CASE WHEN j.gp > j.gc THEN 3 WHEN j.gp = j.gc THEN 1 ELSE 0 END AS pontos,
           CASE WHEN j.gp > j.gc THEN 1 ELSE 0 END                         AS vitoria,
           COALESCE(j.gp - j.gc, 0)                                        AS saldo,
           COALESCE(j.gp, 0)                                               AS gols
    FROM grade g
    LEFT JOIN jogos_time j
      ON j.temporada = g.temporada AND j.rodada = g.rodada AND j.id_time = g.id_time
),
acumulado AS (
    SELECT temporada, rodada, id_time,
           SUM(pontos)  OVER (PARTITION BY temporada, id_time ORDER BY rodada) AS pontos,
           SUM(vitoria) OVER (PARTITION BY temporada, id_time ORDER BY rodada) AS vitorias,
           SUM(saldo)   OVER (PARTITION BY temporada, id_time ORDER BY rodada) AS saldo,
           SUM(gols)    OVER (PARTITION BY temporada, id_time ORDER BY rodada) AS gols
    FROM completo
),
tabela AS (
    SELECT a.*,
           RANK() OVER (PARTITION BY temporada, rodada
                        ORDER BY pontos DESC, vitorias DESC, saldo DESC, gols DESC) AS posicao
    FROM acumulado a
)
SELECT tb.temporada, tb.rodada, tb.pontos, tb.vitorias, tb.saldo, tb.gols, tb.posicao
FROM tabela tb
JOIN dim_time d ON d.id_time = tb.id_time
WHERE d.nome = 'Fluminense';

/* ---------- 4. Conferência ---------- */

SELECT 'vw_jogos_fluminense' AS view_nome, COUNT(*) AS linhas FROM vw_jogos_fluminense  -- esperado: 418
UNION ALL SELECT 'vw_gols_fluminense', COUNT(*) FROM vw_gols_fluminense                 -- esperado: 994
UNION ALL SELECT 'vw_posicao_rodada',  COUNT(*) FROM vw_posicao_rodada;                 -- esperado: 418

SELECT passagem, passagem_rotulo, COUNT(*) AS jogos                                     -- esperado: 22 linhas
FROM vw_jogos_fluminense
GROUP BY passagem, passagem_rotulo
ORDER BY passagem;
