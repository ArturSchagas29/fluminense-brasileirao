USE brasileirao_flu;

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
           SUM(pontos)  OVER w AS pontos,
           SUM(vitoria) OVER w AS vitorias,
           SUM(saldo)   OVER w AS saldo,
           SUM(gols)    OVER w AS gols
    FROM completo
    WINDOW w AS (PARTITION BY temporada, id_time ORDER BY rodada)
),
tabela AS (
    SELECT *,
           RANK() OVER (PARTITION BY temporada, rodada
                        ORDER BY pontos DESC, vitorias DESC, saldo DESC, gols DESC) AS posicao
    FROM acumulado
)
SELECT tb.temporada, tb.rodada, tb.pontos, tb.posicao
FROM tabela tb
JOIN dim_time d ON d.id_time = tb.id_time
WHERE d.nome = 'Fluminense'
ORDER BY tb.temporada, tb.rodada;