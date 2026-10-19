-- =====================================================================
-- LAB-01 — Protección y privacidad de datos
-- Archivo : 03-seudonimizacion.sql
-- Alumno  : José Fernando Velázquez Espinoza
-- Contenido: Actividad 3 — Seudonimización
--            Actividad 4 — Separación de funciones
-- Requiere: haber ejecutado 01-clasificacion.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- ACTIVIDAD 3 — Seudonimización
-- ---------------------------------------------------------------------

-- 9.1 Crear los esquemas
CREATE SCHEMA pii;

CREATE SCHEMA analitica;

-- 9.2 Crear la tabla de correspondencia
CREATE TABLE pii.mapa_cliente (
    token UUID PRIMARY KEY,
    cliente_id BIGINT UNIQUE
        REFERENCES public.clientes(id)
);

-- 9.3 Generar los tokens
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO pii.mapa_cliente
(token, cliente_id)
SELECT
    gen_random_uuid(),
    id
FROM clientes;

-- Verificar
SELECT *
FROM pii.mapa_cliente;

-- 10. Crear el conjunto de datos para analítica
--     (sin nombre, correo, telefono ni rfc)
CREATE TABLE analitica.clientes AS
SELECT
    m.token AS cliente_token,
    c.edad,
    c.ciudad,
    c.codigo_postal,
    c.fecha_alta
FROM pii.mapa_cliente m
JOIN clientes c
    ON c.id = m.cliente_id;

-- Verificar
SELECT *
FROM analitica.clientes;

-- ---------------------------------------------------------------------
-- ACTIVIDAD 4 — Separación de funciones
-- ---------------------------------------------------------------------

CREATE ROLE analista NOLOGIN;

-- Conceder acceso únicamente al conjunto de datos analítico
GRANT USAGE
ON SCHEMA analitica
TO analista;

GRANT SELECT
ON analitica.clientes
TO analista;

-- NO se concede acceso a pii.mapa_cliente ni a public.clientes

-- 11.1 Verificar los permisos como rol analista
SET ROLE analista;

-- Debe funcionar
SELECT *
FROM analitica.clientes;

-- Debe fallar: ERROR: permission denied for schema pii
SELECT *
FROM pii.mapa_cliente;

-- Debe fallar: ERROR: permission denied for table clientes
SELECT *
FROM public.clientes;

RESET ROLE;

-- Preguntas (respuestas en informe.md):
-- 1) ¿Qué ocurriría si analista pudiera consultar pii.mapa_cliente?
-- 2) ¿Qué principio de seguridad se aplica al separar ambos accesos?
-- 3) ¿Por qué la seudonimización no equivale a anonimización?
-- 4) ¿Qué información permite volver a relacionar el token con una persona?
