   USE brasileirao_flu;
SELECT 
	CASE 
		WHEN g.minuto <= 15 THEN '01-15'
        WHEN g.minuto <= 30 THEN '16-30'
        WHEN g.minuto <= 45 THEN '31-45'
        WHEN g.minuto <= 60 THEN '46-60'
        WHEN g.minuto <= 75 THEN '61-75'
        ELSE '76-90'
	END                      AS faixa,
    SUM(t.nome = 'Fluminense') AS gols_pro,
    SUM(t.nome <> 'Fluminense') AS gols_contra
FROM fato_gol g 
JOIN vw_partidas_fluminense v ON v.id_partida = g.id_partida
JOIN dim_time t               ON t.id_time    = g.id_time
GROUP BY faixa
ORDER BY faixa;