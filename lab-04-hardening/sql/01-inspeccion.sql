-- LAB-04 | 01-inspeccion.sql
-- Objetivo: identificar la superficie de ataque (Actividades 1, 2, 3, 4, 10, 11, 15)
-- Ejecutar: psql -U <usuario_admin_lab> -d <db_lab> -f sql/01-inspeccion.sql
-- SOLO en entorno académico aislado.

\echo '=== A1: Versión y parámetros de exposición ==='
SELECT version();
SHOW port;
SHOW listen_addresses;
SHOW ssl;
SHOW password_encryption;

\echo '=== A1: Conexiones activas ==='
SELECT pid, usename, datname, client_addr, client_port, application_name
FROM pg_stat_activity
ORDER BY usename, datname;

\echo '=== A2: Archivos y directorios ==='
SHOW config_file;
SHOW hba_file;
SHOW ident_file;
SHOW data_directory;
SHOW log_directory;
SHOW log_connections;
SHOW log_disconnections;

\echo '=== A4: Reglas de pg_hba.conf ==='
SELECT line_number, type, database, user_name, address, netmask, auth_method, error
FROM pg_hba_file_rules
ORDER BY line_number;

\echo '=== A4: Reglas excesivamente amplias o inseguras ==='
SELECT line_number, type, database, user_name, address, netmask, auth_method
FROM pg_hba_file_rules
WHERE (address IN ('0.0.0.0', '::') AND netmask IN ('0.0.0.0', '::'))
   OR address = 'all'
   OR auth_method IN ('trust', 'md5', 'password');

\echo '=== A10: Extensiones ==='
SELECT extname, extversion FROM pg_extension ORDER BY extname;

\echo '=== A11: Parámetros de conexión ==='
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

\echo '=== A15: TLS ==='
SHOW ssl_min_protocol_version;
SELECT pid, usename, client_addr, ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
