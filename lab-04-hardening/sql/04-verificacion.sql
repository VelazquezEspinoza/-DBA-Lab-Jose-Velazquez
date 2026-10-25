-- LAB-04 | 04-verificacion.sql
-- Objetivo: comprobar que los cambios realmente se aplicaron.

\echo '=== Parámetros clave (valor actual, origen y si requiere reinicio) ==='
SELECT name, setting, source, pending_restart
FROM pg_settings
WHERE name IN ('listen_addresses','port','ssl','ssl_min_protocol_version',
               'password_encryption','log_connections','log_disconnections',
               'superuser_reserved_connections','statement_timeout',
               'idle_in_transaction_session_timeout','max_connections')
ORDER BY name;

\echo '=== Cambios pendientes de reinicio ==='
SELECT name, setting FROM pg_settings WHERE pending_restart;

\echo '=== pg_hba.conf: sintaxis y reglas cargadas ==='
SELECT line_number, type, database, user_name, address, netmask, auth_method, error
FROM pg_hba_file_rules
ORDER BY line_number;

\echo '=== pg_hba.conf: debe devolver 0 filas (sin reglas amplias/inseguras) ==='
SELECT line_number, type, address, netmask, auth_method
FROM pg_hba_file_rules
WHERE (address IN ('0.0.0.0','::') AND netmask IN ('0.0.0.0','::'))
   OR auth_method IN ('trust','md5','password');

\echo '=== Roles: superusuarios con login ==='
SELECT rolname FROM pg_roles WHERE rolsuper AND rolcanlogin;

\echo '=== Roles de aplicación sin privilegios administrativos (esperado: todo f) ==='
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb
FROM pg_roles WHERE rolname IN ('app_user','consulta_user');

\echo '=== Tipo de contraseña almacenada (requiere superusuario) ==='
SELECT rolname,
       CASE WHEN rolpassword LIKE 'SCRAM-SHA-256$%' THEN 'scram-sha-256'
            WHEN rolpassword LIKE 'md5%'            THEN 'md5 (heredado)'
            WHEN rolpassword IS NULL                THEN 'sin contraseña'
            ELSE 'otro' END AS tipo_password
FROM pg_authid
WHERE rolcanlogin
ORDER BY rolname;

\echo '=== Extensiones ==='
SELECT extname, extversion FROM pg_extension ORDER BY extname;

\echo '=== TLS de la sesión actual ==='
SELECT pid, usename, client_addr, ssl, version, cipher
FROM pg_stat_ssl WHERE pid = pg_backend_pid();

\echo '=== Conexiones actuales por origen ==='
SELECT usename, datname, client_addr, count(*) AS conexiones
FROM pg_stat_activity
WHERE client_addr IS NOT NULL
GROUP BY 1,2,3 ORDER BY conexiones DESC;

-- Verificación desde terminal (fuera de psql):
--   ss -lnt | grep 5432
--   ls -l  <config_file> <hba_file> <ident_file>
--   ls -ld <data_directory>      -- esperado: drwx------ postgres postgres
--   psql -h <ip> -U app_user -d basedatos_app   -- desde un origen NO autorizado: debe fallar
