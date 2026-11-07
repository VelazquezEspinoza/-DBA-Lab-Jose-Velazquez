-- LAB-01 · Actividad 2 · Colector de bitácora y vista dba.bitacora
-- Sesión de administrador (sudo -u postgres psql -d comercial)

-- 1) Activar el colector (requiere REINICIO)
ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';
-- Reiniciar el servicio:  sudo pg_ctlcluster 16 main restart

-- 2) Comprobar tras el reinicio
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

-- 3) Leer el archivo vigente desde el motor
SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;

-- 4) Vista de uso exclusivo del administrador
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

-- 5) Consultas de uso
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;      -- últimas 10 líneas
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';         -- texto sin distinguir mayúsculas
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';        -- expresión regular
SELECT * FROM pg_ls_logdir();                                        -- todos los archivos de bitácora
