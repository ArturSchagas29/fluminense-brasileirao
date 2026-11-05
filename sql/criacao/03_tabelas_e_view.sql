/* ============================================================
   Projeto Fluminense no Brasileirão - MySQL
   PARTE 2: rode DEPOIS de importar os dois CSVs no staging.
   ============================================================ */

USE brasileirao_flu;

/* ---------- 0. Conferência da importação ---------- */
-- Esperado: 8785 e 9861. Se der diferente, pare aqui.
SELECT (SELECT COUNT(*) FROM stg_partida) AS partidas_importadas,
       (SELECT COUNT(*) FROM stg_gol)     AS gols_importados;

/* ---------- 1. Tabelas finais ---------- */

CREATE TABLE dim_time (
    id_time INT AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL UNIQUE,
    estado  CHAR(2)      NOT NULL
);

CREATE TABLE fato_partida (
    id_partida         INT PRIMARY KEY,
    temporada          INT  NOT NULL,
    rodada             INT  NOT NULL,
    data               DATE NOT NULL,
    hora               TIME NULL,
    id_mandante        INT  NOT NULL,
    id_visitante       INT  NOT NULL,
    gols_mandante      INT  NOT NULL,
    gols_visitante     INT  NOT NULL,
    tecnico_mandante   VARCHAR(100) NULL,   -- só preenchido de 2014 em diante
    tecnico_visitante  VARCHAR(100) NULL,
    formacao_mandante  VARCHAR(50)  NULL,
    formacao_visitante VARCHAR(50)  NULL,
    arena              VARCHAR(150) NOT NULL,
    FOREIGN KEY (id_mandante)  REFERENCES dim_time(id_time),
    FOREIGN KEY (id_visitante) REFERENCES dim_time(id_time)
);

CREATE TABLE fato_gol (
    id_gol      INT AUTO_INCREMENT PRIMARY KEY,
    id_partida  INT NOT NULL,
    id_time     INT NOT NULL,          -- time que GANHOU o gol
    atleta      VARCHAR(150) NOT NULL,
    minuto      INT NOT NULL,          -- "90+2" vira 90
    acrescimo   INT NOT NULL,          -- "90+2" vira 2
    tipo_gol    VARCHAR(20) NOT NULL,  -- Normal, Penalti, Gol Contra
    FOREIGN KEY (id_partida) REFERENCES fato_partida(id_partida),
    FOREIGN KEY (id_time)    REFERENCES dim_time(id_time)
);

/* ---------- 2. Carga ---------- */

INSERT INTO dim_time (nome, estado)
SELECT TRIM(mandante), MAX(TRIM(mandante_Estado))
FROM stg_partida
GROUP BY TRIM(mandante);

INSERT INTO fato_partida
SELECT
    CAST(s.ID AS UNSIGNED),
    -- A temporada 2020 terminou em fevereiro de 2021 (pandemia)
    CASE WHEN s.dt BETWEEN '2021-01-01' AND '2021-02-28' THEN 2020 ELSE YEAR(s.dt) END,
    CAST(s.rodata AS UNSIGNED),
    s.dt,
    STR_TO_DATE(s.hora, '%H:%i'),
    m.id_time,
    v.id_time,
    CAST(s.mandante_Placar  AS UNSIGNED),
    CAST(s.visitante_Placar AS UNSIGNED),
    NULLIF(TRIM(s.tecnico_mandante), ''),
    NULLIF(TRIM(s.tecnico_visitante), ''),
    NULLIF(TRIM(s.formacao_mandante), ''),
    NULLIF(TRIM(s.formacao_visitante), ''),
    TRIM(s.arena)
FROM (SELECT *, STR_TO_DATE(data, '%d/%m/%Y') AS dt FROM stg_partida) s
JOIN dim_time m ON m.nome = TRIM(s.mandante)
JOIN dim_time v ON v.nome = TRIM(s.visitante);

INSERT INTO fato_gol (id_partida, id_time, atleta, minuto, acrescimo, tipo_gol)
SELECT
    CAST(s.partida_id AS UNSIGNED),
    t.id_time,
    TRIM(s.atleta),
    CAST(SUBSTRING_INDEX(s.minuto, '+', 1) AS UNSIGNED),
    CASE WHEN LOCATE('+', s.minuto) > 0
         THEN CAST(SUBSTRING_INDEX(s.minuto, '+', -1) AS UNSIGNED)
         ELSE 0 END,
    CASE TRIM(REPLACE(IFNULL(s.tipo_de_gol, ''), '\r', ''))
         WHEN 'Penalty'    THEN 'Penalti'
         WHEN 'Gol Contra' THEN 'Gol Contra'
         ELSE 'Normal' END
FROM stg_gol s
JOIN dim_time t ON t.nome = TRIM(s.clube);

/* ---------- 3. View base: uma linha por jogo do Fluminense (2014+) ---------- */

CREATE OR REPLACE VIEW vw_partidas_fluminense AS
SELECT
    j.id_partida, j.temporada, j.rodada, j.data, j.mando, j.adversario,
    j.gols_pro, j.gols_contra,
    CASE WHEN j.gols_pro > j.gols_contra THEN 'V'
         WHEN j.gols_pro = j.gols_contra THEN 'E' ELSE 'D' END AS resultado,
    CASE WHEN j.gols_pro > j.gols_contra THEN 3
         WHEN j.gols_pro = j.gols_contra THEN 1 ELSE 0 END AS pontos,
    j.tecnico, j.arena
FROM (
    SELECT
        p.id_partida, p.temporada, p.rodada, p.data, p.arena,
        CASE WHEN m.nome = 'Fluminense' THEN 'Casa' ELSE 'Fora' END AS mando,
        CASE WHEN m.nome = 'Fluminense' THEN v.nome ELSE m.nome END AS adversario,
        CASE WHEN m.nome = 'Fluminense' THEN p.gols_mandante  ELSE p.gols_visitante END AS gols_pro,
        CASE WHEN m.nome = 'Fluminense' THEN p.gols_visitante ELSE p.gols_mandante  END AS gols_contra,
        CASE WHEN m.nome = 'Fluminense' THEN p.tecnico_mandante ELSE p.tecnico_visitante END AS tecnico
    FROM fato_partida p
    JOIN dim_time m ON m.id_time = p.id_mandante
    JOIN dim_time v ON v.id_time = p.id_visitante
    WHERE 'Fluminense' IN (m.nome, v.nome)
      AND p.temporada >= 2014
) j;

/* ---------- 4. Conferência final ---------- */

SELECT 'fato_partida' AS tabela, COUNT(*) AS linhas FROM fato_partida   -- esperado: 8785
UNION ALL SELECT 'fato_gol', COUNT(*) FROM fato_gol                     -- esperado: 9861
UNION ALL SELECT 'vw_partidas_fluminense', COUNT(*) FROM vw_partidas_fluminense;  -- esperado: 418

SELECT temporada, COUNT(*) AS jogos, SUM(pontos) AS pontos   -- esperado: 38 jogos por temporada
FROM vw_partidas_fluminense
GROUP BY temporada
ORDER BY temporada;
