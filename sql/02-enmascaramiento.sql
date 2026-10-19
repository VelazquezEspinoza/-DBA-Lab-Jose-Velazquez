-- =====================================================================
-- LAB-01 — Protección y privacidad de datos
-- Archivo : 02-enmascaramiento.sql
-- Alumno  : José Fernando Velázquez Espinoza
-- Contenido: Actividad 2 — Enmascaramiento (masking)
-- Requiere: haber ejecutado 01-clasificacion.sql
-- =====================================================================

-- 8.1 Crear el rol
CREATE ROLE soporte NOLOGIN;

-- 8.2 Crear una vista de acceso restringido
CREATE VIEW v_clientes_soporte AS
SELECT
    id,
    nombre,

    CONCAT(
        LEFT(correo, 2),
        '*****',
        SUBSTRING(correo FROM POSITION('@' IN correo))
    ) AS correo,

    CONCAT(
        '******',
        RIGHT(telefono, 4)
    ) AS telefono,

    CONCAT(
        '*********',
        RIGHT(rfc, 4)
    ) AS rfc

FROM clientes;

-- Consultar la vista (como administrador)
SELECT *
FROM v_clientes_soporte;

-- 8.3 Conceder acceso a la vista
GRANT USAGE
ON SCHEMA public
TO soporte;

GRANT SELECT
ON v_clientes_soporte
TO soporte;

-- Revocar el acceso directo a la tabla
REVOKE ALL
ON clientes
FROM soporte;

-- Evidencia: permisos aplicados
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'soporte'
ORDER BY table_name, privilege_type;

-- 8.4 Verificar el resultado como rol soporte
-- (el rol es NOLOGIN, por lo que se usa SET ROLE desde la sesión
--  del administrador)
SET ROLE soporte;

-- Debe funcionar: muestra los datos enmascarados
SELECT *
FROM v_clientes_soporte;

-- Debe fallar: ERROR: permission denied for table clientes
SELECT *
FROM clientes;

RESET ROLE;

-- Preguntas (respuestas en informe.md):
-- 1) ¿Qué información continúa en la tabla original?
-- 2) ¿Qué información puede visualizar soporte?
-- 3) ¿Por qué no basta ocultar datos solo en la aplicación?
-- 4) ¿Qué ocurriría si soporte tuviera acceso directo a clientes?
