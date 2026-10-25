-- LAB-04 | 02-roles.sql
-- Objetivo: revisar roles (A8) y separar cuentas DBA / APP / CONSULTA (A9)
-- Los nombres (basedatos_app, dba_lab, app_user, consulta_user) son de ejemplo:
-- ajústalos al entorno real del laboratorio.

\echo '=== A8: Inventario de roles ==='
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname NOT LIKE 'pg\_%'
ORDER BY rolname;

\echo '=== A8: Superusuarios con LOGIN ==='
SELECT rolname FROM pg_roles WHERE rolsuper AND rolcanlogin;

\echo '=== A8: Roles con CREATEROLE o CREATEDB ==='
SELECT rolname, rolcreaterole, rolcreatedb
FROM pg_roles
WHERE (rolcreaterole OR rolcreatedb) AND rolname NOT LIKE 'pg\_%';

-- ---------------------------------------------------------------
-- A9: Diseño de cuentas (aplicar solo en el servidor de laboratorio)
-- Las contraseñas NO se escriben en este archivo: usar \password
-- ---------------------------------------------------------------

-- Cuenta DBA nominal (no SUPERUSER si no es estrictamente necesario)
CREATE ROLE dba_lab LOGIN CREATEROLE CREATEDB;
-- \password dba_lab

-- Cuenta de aplicación: privilegios mínimos
CREATE ROLE app_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
-- \password app_user

-- Cuenta de consulta: solo lectura
CREATE ROLE consulta_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
-- \password consulta_user

-- Límite de conexiones por cuenta (ejemplo)
ALTER ROLE app_user      CONNECTION LIMIT 20;
ALTER ROLE consulta_user CONNECTION LIMIT 5;

-- Quitar privilegios por defecto de PUBLIC
REVOKE CONNECT ON DATABASE basedatos_app FROM PUBLIC;
\c basedatos_app
REVOKE ALL ON SCHEMA public FROM PUBLIC;

GRANT CONNECT ON DATABASE basedatos_app TO app_user, consulta_user, dba_lab;
GRANT USAGE ON SCHEMA public TO app_user, consulta_user;

-- app_user: CRUD sobre el esquema de la aplicación
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- consulta_user: solo lectura
GRANT SELECT ON ALL TABLES IN SCHEMA public TO consulta_user;

-- Privilegios por defecto para objetos futuros (creados por dba_lab)
ALTER DEFAULT PRIVILEGES FOR ROLE dba_lab IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE dba_lab IN SCHEMA public
    GRANT SELECT ON TABLES TO consulta_user;
