/* ============================================================
   Ajuste da view vw_jogos_fluminense
   Novo rótulo da passagem: número + técnico + ano(s), único e em ordem.
   Ex.: "01 · C. Borges dos Santos (2014)", "20 · F. Diniz Silva (2022-2024)"
   Motivo: o rótulo antigo repetia "M. de Oliveira (2021-2021)" para duas
   passagens diferentes, e o Power BI juntava as duas numa barra só.
   ============================================================ */

USE brasileirao_flu;

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
),
com_anos AS (
    SELECT
        n.*,
        YEAR(MIN(n.data) OVER (PARTITION BY n.passagem)) AS ano_ini,
        YEAR(MAX(n.data) OVER (PARTITION BY n.passagem)) AS ano_fim
    FROM numerado n
)
SELECT
    c.id_partida,
    c.temporada,
    c.rodada,
    c.data,
    c.mando,
    c.adversario,
    c.gols_pro,
    c.gols_contra,
    c.resultado,
    c.pontos,
    c.tecnico,
    c.tecnico_titular,
    c.passagem,
    CONCAT(LPAD(c.passagem, 2, '0'), ' · ', c.tecnico_titular, ' (',
           CASE WHEN c.ano_ini = c.ano_fim THEN c.ano_ini
                ELSE CONCAT(c.ano_ini, '-', c.ano_fim) END,
           ')') AS passagem_rotulo,
    c.arena
FROM com_anos c;

/* Conferência: 22 linhas, cada rótulo aparece uma vez só */
SELECT passagem_rotulo, COUNT(*) AS jogos
FROM vw_jogos_fluminense
GROUP BY passagem_rotulo
ORDER BY passagem_rotulo;
