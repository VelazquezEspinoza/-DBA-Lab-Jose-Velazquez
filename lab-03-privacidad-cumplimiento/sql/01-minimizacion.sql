-- LAB-03 | Actividad 2: Minimización de datos | PostgreSQL 16
-- ============================================================
-- 0. Preparación: tabla de origen y datos ficticios
-- ============================================================
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    id            BIGSERIAL PRIMARY KEY,
    nombre        VARCHAR(120) NOT NULL,
    correo        VARCHAR(150) NOT NULL UNIQUE,
    telefono      VARCHAR(20),
    rfc           VARCHAR(13),
    edad          INTEGER,
    ciudad        VARCHAR(80),
    codigo_postal VARCHAR(10),
    fecha_alta    DATE DEFAULT CURRENT_DATE
);

-- Datos ficticios (200 clientes) para poder ejecutar el laboratorio
INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta)
SELECT
    'Cliente ' || g,
    'cliente' || g || '@example.com',
    '667' || LPAD((1000000 + g)::text, 7, '0'),
    'XAXX' || LPAD(g::text, 6, '0') || 'AB1',
    16 + (g * 7) % 60,
    (ARRAY['Culiacán','Mazatlán','Los Mochis','Guadalajara','Monterrey','CDMX'])[1 + g % 6],
    LPAD((80000 + (g * 13) % 900)::text, 5, '0'),
    DATE '2014-01-01' + (g * 11) % 3000
FROM generate_series(1, 200) AS g;

-- Cliente de prueba usado en las actividades de ARCO
UPDATE clientes SET nombre = 'Ana Pérez', correo = 'ana@example.com' WHERE id = 1;

-- ============================================================
-- 1. Solicitud ORIGINAL de soporte (NO se implementa)
--    Viola minimización: RFC, edad, ciudad, CP y fecha_alta
--    no son necesarios para atender a un cliente.
-- ============================================================
-- CREATE TABLE clientes_soporte (
--     id BIGSERIAL, nombre VARCHAR(120), correo VARCHAR(150),
--     telefono VARCHAR(20), rfc VARCHAR(13), edad INTEGER,
--     ciudad VARCHAR(80), codigo_postal VARCHAR(10), fecha_alta DATE
-- );

-- ============================================================
-- 2. Estructura mínima (8.1)
-- ============================================================
DROP TABLE IF EXISTS clientes_soporte;

CREATE TABLE clientes_soporte (
    id       BIGINT PRIMARY KEY,
    nombre   VARCHAR(120) NOT NULL,
    correo   VARCHAR(150) NOT NULL,
    telefono VARCHAR(20)
);

INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono
FROM clientes;

SELECT * FROM clientes_soporte LIMIT 10;

-- Verificación: la tabla no contiene columnas innecesarias
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'clientes_soporte'
ORDER BY ordinal_position;
