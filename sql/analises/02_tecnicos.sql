WITH base AS (
    SELECT
        *,
        CASE tecnico
            WHEN 'E. de Barros' THEN 'F. Diniz Silva'
            WHEN 'S. Lobo'      THEN 'L. Venker de Menezes'
            ELSE tecnico
        END AS tecnico_titular
    FROM vw_partidas_fluminense
),
marcado AS (
    SELECT
        *,
        CASE WHEN tecnico_titular = LAG(tecnico_titular) OVER (ORDER BY data, id_partida)
             THEN 0 ELSE 1 END AS trocou
    FROM base
),
numerado AS (
    SELECT
        *,
        SUM(trocou) OVER (ORDER BY data, id_partida) AS passagem
    FROM marcado
)
SELECT
    passagem,
    tecnico_titular,
    COUNT(*)                                     AS jogos,
    MIN(data)                                    AS primeiro_jogo,
    MAX(data)                                    AS ultimo_jogo,
    SUM(pontos)                                  AS pontos,
    ROUND(SUM(pontos) / (COUNT(*) * 3) * 100, 1) AS aproveitamento
FROM numerado
GROUP BY passagem, tecnico_titular
ORDER BY passagem;