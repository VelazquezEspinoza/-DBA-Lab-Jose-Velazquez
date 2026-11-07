-- LAB-01 · Actividad 10 · Esquema y tabla de auditoría a nivel de dato
-- Ejecutar en la sesión de administrador, base comercial.

CREATE SCHEMA auditoria;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY,
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,
    aplicacion       TEXT        DEFAULT current_setting('application_name'),
    ip_cliente       INET        DEFAULT inet_client_addr(),
    operacion        TEXT        NOT NULL,
    id_cliente       BIGINT,
    valores_antes    JSONB,
    valores_despues  JSONB
);

-- Verificación: PUBLIC no tiene privilegios sobre el esquema
SELECT nspname, nspacl FROM pg_namespace WHERE nspname = 'auditoria';
