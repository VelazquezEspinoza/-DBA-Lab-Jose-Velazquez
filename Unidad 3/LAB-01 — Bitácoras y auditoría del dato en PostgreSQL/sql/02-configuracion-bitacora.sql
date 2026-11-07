-- LAB-01 · Actividades 4, 5 y 7 · Configuración de la bitácora
-- Todos estos parámetros cambian con RECARGA (pg_reload_conf), sin reinicio.

ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

-- La recarga es asíncrona: verificar en una consulta posterior
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;

-- Actividad 5 · accesos desde la red
SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;

-- Actividad 5 · intentos fallidos por usuario y origen (detección de fuerza bruta)
SELECT substring(linea from 'failed for user "([^"]+)"') AS usuario,
       substring(linea from 'client=(\S+)')               AS cliente,
       count(*)                                           AS intentos_fallidos,
       min(left(linea, 23))                               AS primero,
       max(left(linea, 23))                               AS ultimo
FROM dba.bitacora
WHERE linea LIKE '%FATAL:  password authentication failed%'
GROUP BY 1, 2
ORDER BY intentos_fallidos DESC;

-- Actividad 7 · subir el nivel para registrar INSERT/UPDATE/DELETE
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();

SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;
