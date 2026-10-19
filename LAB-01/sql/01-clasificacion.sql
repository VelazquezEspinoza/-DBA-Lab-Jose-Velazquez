-- =====================================================================
-- LAB-01 — Protección y privacidad de datos
-- Archivo : 01-clasificacion.sql
-- Alumno  : José Fernando Velázquez Espinoza
-- Materia : Gestión de Seguridad y Desempeño de Base de Datos
-- Motor   : PostgreSQL 16
-- Contenido: Preparación de la base de datos y Actividad 1
--            (Clasificación de los datos)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 6.1 Crear la tabla de clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    rfc VARCHAR(13),
    edad INTEGER,
    ciudad VARCHAR(80),
    codigo_postal VARCHAR(10),
    fecha_alta DATE DEFAULT CURRENT_DATE
);

-- Verificar la estructura
-- En psql:  \d clientes
-- En pgAdmin (equivalente):
SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'clientes'
ORDER BY ordinal_position;

-- ---------------------------------------------------------------------
-- 6.2 Insertar datos de prueba (datos ficticios)
-- ---------------------------------------------------------------------
INSERT INTO clientes
(nombre, correo, telefono, rfc, edad, ciudad, codigo_postal)
VALUES
('Ana López',
 'ana.lopez@example.test',
 '6671234567',
 'LOAA850315ABC',
 41,
 'Culiacán',
 '80000'),

('Carlos Pérez',
 'carlos.perez@example.test',
 '6672345678',
 'PECA900720DEF',
 35,
 'Culiacán',
 '80100'),

('María García',
 'maria.garcia@example.test',
 '6673456789',
 'GAMA780912GHI',
 47,
 'Mazatlán',
 '82000'),

('Luis Torres',
 'luis.torres@example.test',
 '6674567890',
 'TOLU920201JKL',
 34,
 'Los Mochis',
 '81200'),

('Laura Sánchez',
 'laura.sanchez@example.test',
 '6675678901',
 'SALA880525MNO',
 38,
 'Culiacán',
 '80200');

-- Verificar
SELECT *
FROM clientes;

-- =====================================================================
-- ACTIVIDAD 1 — Clasificación de los datos
-- =====================================================================
-- Matriz de clasificación
--
-- Campo          | Identifica     | Contribuye a   | Requiere        | Justificación
--                | directamente   | identificar    | protección      |
-- ---------------+----------------+----------------+-----------------+-----------------------------------------------
-- id             | No (indirecto) | Sí             | Sí (moderada)   | Identificador técnico; vincula registros entre
--                |                |                |                 | tablas y permite cruces con otras fuentes.
-- nombre         | Sí             | Sí             | Sí (alta)       | Identificador más directo de una persona física.
-- correo         | Sí             | Sí             | Sí (alta)       | Suele contener nombre y apellido; único; permite
--                |                |                |                 | contacto y cruce entre sistemas.
-- telefono       | Sí             | Sí             | Sí (alta)       | Permite contactar y localizar; llave de cruce.
-- rfc            | Sí             | Sí             | Sí (muy alta)   | Contiene iniciales y fecha de nacimiento; útil
--                |                |                |                 | para fraude y suplantación de identidad.
-- edad           | No             | Sí             | Sí (media)      | Cuasi-identificador; redundante con el RFC.
-- ciudad         | No             | Sí             | Sí (media)      | Dato geográfico general; reduce candidatos.
-- codigo_postal  | No             | Sí             | Sí (media-alta) | Acota la zona de residencia; cuasi-identificador
--                |                |                |                 | clásico.
-- fecha_alta     | No             | Sí (limitado)  | Sí (baja)       | Permite correlacionar registros; poco valor
--                |                |                |                 | identificador por sí sola.
--
-- Respuestas resumidas:
-- 1) Identifican directamente: nombre, correo, telefono y rfc.
-- 2) Cuasi-identificadores: edad, ciudad, codigo_postal, fecha_alta
--    (y el id como vínculo entre registros).
-- 3) Combinaciones de mayor riesgo: codigo_postal + edad + ciudad;
--    rfc + edad; nombre + codigo_postal; correo/telefono + cualquier
--    otro campo; fecha_alta + codigo_postal + edad.
-- 4) No: ningún campo es dato personal sensible en sentido jurídico,
--    pero todos son datos personales o cuasi-identificadores y deben
--    protegerse según el riesgo (p. ej. el RFC facilita fraude).

-- Consulta de apoyo: unicidad de combinaciones de cuasi-identificadores
-- (un conteo = 1 indica que el registro es único y fácil de reidentificar)
SELECT edad, ciudad, codigo_postal, COUNT(*) AS registros
FROM clientes
GROUP BY edad, ciudad, codigo_postal
ORDER BY registros;
