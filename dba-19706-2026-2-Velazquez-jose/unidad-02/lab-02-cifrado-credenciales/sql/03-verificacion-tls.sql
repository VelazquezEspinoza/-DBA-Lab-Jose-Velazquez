-- LAB-02 | Actividades 5 y 6: Verificación de TLS
\echo '=== Parámetros del servidor ==='
SHOW ssl;
SHOW ssl_min_protocol_version;
SHOW port;
SHOW listen_addresses;

\echo '=== Cliente actual ==='
SELECT inet_client_addr(), inet_client_port();

\echo '=== ¿La sesión actual usa TLS? ==='
SELECT ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
