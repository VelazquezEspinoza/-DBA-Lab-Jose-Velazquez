-- =====================================================================
-- LAB-03 · Actividad 1 — Calidad de datos desde la operación
-- Base: comercial (PostgreSQL 16) · Sesión de administrador
-- Ejecutar con:  \i sql/01-verificaciones-calidad.sql
-- IMPORTANTE: los registros de prueba NO se eliminan; son hallazgos del
-- expediente. Los ids dependen de lo hecho en LAB-01/LAB-02.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Simulación de captura con errores (ejecutar UNA sola vez)
--    Con log_statement = 'mod' estos INSERT quedan en la bitácora y el
--    disparador trg_auditoria_clientes los registra en
--    auditoria.cambios_clientes.
-- ---------------------------------------------------------------------
INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal) VALUES
('Ana Lopez', 'ANA.LOPEZ@example.test', '6671234567', 'LOAA850315AB', 41, 'Culiacan', '80000'),
('Jorge Díaz', 'sin-correo', '667', NULL, -3, 'Culiacán', '8000');

-- ---------------------------------------------------------------------
-- V1. Unicidad: posibles duplicados por correo (sin distinguir mayúsculas)
-- ---------------------------------------------------------------------
SELECT lower(correo)                    AS correo_normalizado,
       count(*)                         AS registros,
       string_agg(id::text, ', ' ORDER BY id) AS ids
FROM clientes
GROUP BY lower(correo)
HAVING count(*) > 1;

-- ---------------------------------------------------------------------
-- V2. Validez: RFC con formato no válido o ausente
--     (verificación de formato para la práctica; no valida ante el SAT)
-- ---------------------------------------------------------------------
SELECT id, nombre, rfc,
       CASE WHEN rfc IS NULL THEN 'ausente'
            ELSE 'formato no válido (' || length(rfc) || ' caracteres)' END AS problema
FROM clientes
WHERE rfc IS NULL
   OR rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$'
ORDER BY id;

-- ---------------------------------------------------------------------
-- V3. Validez: correo con formato no válido
-- ---------------------------------------------------------------------
SELECT id, nombre, correo
FROM clientes
WHERE correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
ORDER BY id;

-- ---------------------------------------------------------------------
-- V4. Validez: edad fuera de rango (regla de negocio: 18 a 120 años)
-- ---------------------------------------------------------------------
SELECT id, nombre, edad
FROM clientes
WHERE edad IS NOT NULL AND (edad < 18 OR edad > 120)
ORDER BY id;

-- ---------------------------------------------------------------------
-- V5. Completitud
-- ---------------------------------------------------------------------
SELECT count(*)                                     AS total,
       count(*) FILTER (WHERE telefono IS NULL)     AS sin_telefono,
       count(*) FILTER (WHERE rfc IS NULL)          AS sin_rfc,
       count(*) FILTER (WHERE edad IS NULL)         AS sin_edad,
       count(*) FILTER (WHERE codigo_postal IS NULL) AS sin_cp
FROM clientes;

-- ---------------------------------------------------------------------
-- Verificaciones adicionales (hallazgos C5 en adelante)
-- ---------------------------------------------------------------------

-- V6. Validez: teléfono que no tiene 10 dígitos (numeración nacional MX)
SELECT id, nombre, telefono
FROM clientes
WHERE telefono IS NOT NULL AND telefono !~ '^[0-9]{10}$'
ORDER BY id;

-- V7. Validez: código postal que no tiene 5 dígitos
SELECT id, nombre, codigo_postal
FROM clientes
WHERE codigo_postal IS NOT NULL AND codigo_postal !~ '^[0-9]{5}$'
ORDER BY id;

-- V8. Consistencia: la misma ciudad escrita de varias formas
--     (sin acentos y sin distinguir mayúsculas). translate() evita
--     depender de la extensión unaccent.
SELECT lower(translate(ciudad, 'ÁÉÍÓÚáéíóúÜüÑñ', 'AEIOUaeiouUuNn')) AS ciudad_normalizada,
       string_agg(DISTINCT ciudad, ' | ')                              AS variantes,
       count(*)                                                        AS registros
FROM clientes
WHERE ciudad IS NOT NULL
GROUP BY 1
HAVING count(DISTINCT ciudad) > 1;

-- V9. Consistencia: posible duplicado por nombre normalizado
SELECT lower(translate(nombre, 'ÁÉÍÓÚáéíóúÜüÑñ', 'AEIOUaeiouUuNn')) AS nombre_normalizado,
       string_agg(id::text || '=' || nombre, ', ' ORDER BY id)          AS registros
FROM clientes
GROUP BY 1
HAVING count(*) > 1;

-- ---------------------------------------------------------------------
-- Resumen de hallazgos en una sola consulta (útil para 01-calidad.md)
-- ---------------------------------------------------------------------
WITH h AS (
  SELECT 'Unicidad del correo'  AS regla, id FROM clientes
   WHERE lower(correo) IN (SELECT lower(correo) FROM clientes GROUP BY 1 HAVING count(*) > 1)
  UNION ALL SELECT 'Formato/presencia de RFC', id FROM clientes
   WHERE rfc IS NULL OR rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$'
  UNION ALL SELECT 'Formato de correo', id FROM clientes
   WHERE correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  UNION ALL SELECT 'Rango de edad (18-120)', id FROM clientes
   WHERE edad IS NOT NULL AND (edad < 18 OR edad > 120)
  UNION ALL SELECT 'Teléfono de 10 dígitos', id FROM clientes
   WHERE telefono IS NOT NULL AND telefono !~ '^[0-9]{10}$'
  UNION ALL SELECT 'Código postal de 5 dígitos', id FROM clientes
   WHERE codigo_postal IS NOT NULL AND codigo_postal !~ '^[0-9]{5}$'
)
SELECT regla, count(*) AS registros, string_agg(id::text, ', ' ORDER BY id) AS ids
FROM h GROUP BY regla ORDER BY regla;

-- ---------------------------------------------------------------------
-- Restricciones que habrían evitado los hallazgos.
-- NO SE EJECUTAN: son una PROPUESTA que debe aprobar el propietario del
-- dato (Gerencia Comercial) mediante una solicitud de cambio (POL-06).
-- Con datos inválidos existentes, ADD CONSTRAINT fallaría; por eso se
-- proponen con NOT VALID (aplican a filas nuevas) y VALIDATE posterior,
-- una vez que el propietario decida la corrección de los registros.
-- ---------------------------------------------------------------------
-- (Un índice único no admite NOT VALID: solo puede crearse después de
--  que el propietario resuelva el duplicado de los registros 1 y 7.)
-- CREATE UNIQUE INDEX ux_clientes_correo_lower ON clientes (lower(correo));
-- ALTER TABLE clientes ADD CONSTRAINT ck_clientes_rfc_formato
--   CHECK (rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$') NOT VALID;
-- ALTER TABLE clientes ADD CONSTRAINT ck_clientes_correo_formato
--   CHECK (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') NOT VALID;
-- ALTER TABLE clientes ADD CONSTRAINT ck_clientes_edad_rango
--   CHECK (edad BETWEEN 18 AND 120) NOT VALID;
-- ALTER TABLE clientes ADD CONSTRAINT ck_clientes_telefono
--   CHECK (telefono ~ '^[0-9]{10}$') NOT VALID;
-- ALTER TABLE clientes ADD CONSTRAINT ck_clientes_cp
--   CHECK (codigo_postal ~ '^[0-9]{5}$') NOT VALID;
-- (La obligatoriedad del RFC —NOT NULL— depende de si todo cliente
--  factura; es decisión del propietario, no técnica.)
