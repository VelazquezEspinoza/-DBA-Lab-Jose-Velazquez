-- LAB-04 | 03-configuracion.sql
-- Objetivo: aplicar parámetros de hardening (A3, A7, A11, A15)
-- ALTER SYSTEM escribe en postgresql.auto.conf (no edita postgresql.conf).
-- Antes de aplicar, anota el valor ANTERIOR en configuracion/cambios.md.
-- Los cambios de pg_hba.conf se hacen en el archivo (ver configuracion/cambios.md).

-- Red: escuchar solo donde sea necesario (requiere REINICIO)
-- Opción 1: solo local
ALTER SYSTEM SET listen_addresses = 'localhost';
-- Opción 2: interfaz privada del servidor (ejemplo del lab: 10.10.10.20)
-- ALTER SYSTEM SET listen_addresses = 'localhost,10.10.10.20';

-- Autenticación: almacenamiento de contraseñas nuevas (recarga)
ALTER SYSTEM SET password_encryption = 'scram-sha-256';

-- TLS (requiere ssl_cert_file / ssl_key_file válidos; ssl requiere REINICIO)
-- ALTER SYSTEM SET ssl = 'on';
ALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.2';

-- Auditoría de conexiones (recarga)
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';

-- Control de recursos / disponibilidad (recarga)
ALTER SYSTEM SET superuser_reserved_connections = 3;
ALTER SYSTEM SET idle_in_transaction_session_timeout = '5min';
ALTER SYSTEM SET statement_timeout = '60s';   -- valor de ejemplo; ajustar a la carga real

-- Aplicar los que no requieren reinicio
SELECT pg_reload_conf();

-- Contraseñas existentes en md5: re-establecerlas para que se guarden en SCRAM
-- (ejecutar tras confirmar password_encryption = 'scram-sha-256')
-- \password app_user
-- \password consulta_user
-- \password dba_lab

-- Reinicio necesario para listen_addresses / ssl (desde la terminal del servidor):
--   sudo systemctl restart postgresql
