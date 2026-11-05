USE brasileirao_flu;

SELECT 
	g.atleta,
    COUNT(*)                                         AS gols,
    SUM(g.tipo_gol = 'Penalti')                      AS penaltis,
    COUNT(DISTINCT v.temporada)                      AS temporadas,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct_dos_gols
FROM fato_gol g 
JOIN vw_partidas_fluminense v ON v.id_partida = g.id_partida
JOIN dim_time t               ON t.id_time    = g.id_time
WHERE t.nome = 'Fluminense'
	AND g.tipo_gol <> 'Gol Contra'
    GROUP BY g.atleta
    ORDER BY gols DESC 
    LIMIT 10;