SELECT 
	temporada,
    mando,
    COUNT(*)                                     AS jogos,
    SUM(pontos)                                  AS pontos,
    ROUND(SUM(pontos) / (COUNT(*) * 3) * 100, 1) AS aproveitamento 
FROM vw_partidas_fluminense
GROUP BY temporada, mando 
ORDER BY temporada, mando;