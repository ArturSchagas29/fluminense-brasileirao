/* ============================================================
   Projeto Fluminense no Brasileirão - MySQL
   PARTE 1: cria o banco e as tabelas de staging (tudo texto).
   Depois de rodar, importe os CSVs pelo assistente do Workbench.
   ============================================================ */

CREATE DATABASE IF NOT EXISTS brasileirao_flu
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE brasileirao_flu;

CREATE TABLE stg_partida (
    ID                 VARCHAR(20),
    rodata             VARCHAR(20),   -- o CSV traz "rodata" (erro de digitação de "rodada")
    data               VARCHAR(20),
    hora               VARCHAR(20),
    mandante           VARCHAR(100),
    visitante          VARCHAR(100),
    formacao_mandante  VARCHAR(50),
    formacao_visitante VARCHAR(50),
    tecnico_mandante   VARCHAR(100),
    tecnico_visitante  VARCHAR(100),
    vencedor           VARCHAR(100),
    arena              VARCHAR(150),
    mandante_Placar    VARCHAR(20),
    visitante_Placar   VARCHAR(20),
    mandante_Estado    VARCHAR(20),
    visitante_Estado   VARCHAR(20)
);

CREATE TABLE stg_gol (
    partida_id  VARCHAR(20),
    rodata      VARCHAR(20),
    clube       VARCHAR(100),
    atleta      VARCHAR(150),
    minuto      VARCHAR(20),
    tipo_de_gol VARCHAR(50)
);
