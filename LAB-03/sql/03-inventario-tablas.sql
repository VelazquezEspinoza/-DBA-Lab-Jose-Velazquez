-- =====================================================================
-- LAB-03 · Actividad 4 — Catálogo mínimo de datos (insumo técnico)
-- Base: comercial · Sesión de administrador
-- =====================================================================

-- ANALYZE actualiza estadísticas; sin él, reltuples puede valer -1 en
-- tablas recién creadas. (ANALYZE no se registra con log_statement=mod.)
ANALYZE;

-- ---------------------------------------------------------------------
-- 1. Inventario de tablas (consulta de la guía)
-- ---------------------------------------------------------------------
SELECT n.nspname                                     AS esquema,
       c.relname                                     AS tabla,
       pg_get_userbyid(c.relowner)                   AS propietario_tecnico,
       c.reltuples::bigint                           AS filas_estimadas,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS tamano,
       obj_description(c.oid, 'pg_class')            AS descripcion
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

-- ---------------------------------------------------------------------
-- 2. Inventario ampliado: tablas, vistas y vistas materializadas
--    (la guía advierte que dba.bitacora no aparece con relkind = 'r')
-- ---------------------------------------------------------------------
SELECT n.nspname                                   AS esquema,
       c.relname                                   AS objeto,
       CASE c.relkind WHEN 'r' THEN 'tabla'
                      WHEN 'v' THEN 'vista'
                      WHEN 'm' THEN 'vista materializada'
                      WHEN 'p' THEN 'tabla particionada' END AS tipo,
       pg_get_userbyid(c.relowner)                 AS propietario_tecnico,
       CASE WHEN c.relkind IN ('r','m','p') THEN c.reltuples::bigint END AS filas_estimadas,
       CASE WHEN c.relkind IN ('r','m','p')
            THEN pg_size_pretty(pg_total_relation_size(c.oid)) END       AS tamano,
       obj_description(c.oid, 'pg_class')          AS descripcion
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'v', 'm', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname NOT LIKE 'pg_toast%'
ORDER BY 1, 2;

-- ---------------------------------------------------------------------
-- 3. Columnas candidatas a dato personal por su nombre (apoyo para la
--    columna "Contiene datos personales" del catálogo). Es una
--    heurística: la clasificación final la decide el propietario.
-- ---------------------------------------------------------------------
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND column_name ~* '(nombre|correo|email|telefono|rfc|curp|edad|ciudad|codigo_postal|direccion|valores_antes|valores_despues|usuario|ip)'
ORDER BY 1, 2, 3;

-- ---------------------------------------------------------------------
-- 4. Ubicación técnica para el campo "Ubicación" del catálogo
-- ---------------------------------------------------------------------
SELECT inet_server_addr()                AS ip_servidor,
       inet_server_port()                AS puerto,
       current_database()                AS base,
       current_setting('server_version') AS version,
       current_setting('data_directory') AS directorio_datos;
