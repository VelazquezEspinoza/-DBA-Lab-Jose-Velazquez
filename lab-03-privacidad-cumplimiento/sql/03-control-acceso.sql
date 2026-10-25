-- LAB-03 | Actividad 4: Control de acceso por finalidad
-- ============================================================

-- Principio: mínimo privilegio. Nadie hereda acceso por defecto.
REVOKE ALL ON clientes FROM PUBLIC;
REVOKE ALL ON clientes_soporte FROM PUBLIC;

-- 1. Roles funcionales (NOLOGIN: grupos a los que se asignan usuarios)
DROP ROLE IF EXISTS analista;
DROP ROLE IF EXISTS soporte;
DROP ROLE IF EXISTS facturacion;
DROP ROLE IF EXISTS marketing;

CREATE ROLE analista    NOLOGIN;
CREATE ROLE soporte     NOLOGIN;
CREATE ROLE facturacion NOLOGIN;
CREATE ROLE marketing   NOLOGIN;

-- 2. Vista para analítica: sin identificadores directos
CREATE OR REPLACE VIEW v_analitica_clientes
WITH (security_barrier = true) AS
SELECT
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    LEFT(codigo_postal, 2) AS region_cp
FROM clientes;

GRANT USAGE ON SCHEMA public TO analista;
GRANT SELECT ON v_analitica_clientes TO analista;
-- NO se otorga: GRANT SELECT ON clientes TO analista;

-- 3. Soporte: solo la tabla mínima
GRANT USAGE ON SCHEMA public TO soporte;
GRANT SELECT, UPDATE (correo, telefono) ON clientes_soporte TO soporte;

-- 4. Facturación: solo columnas fiscales necesarias
GRANT USAGE ON SCHEMA public TO facturacion;
GRANT SELECT (id, nombre, rfc) ON clientes TO facturacion;

-- 5. Marketing: vista limitada (ejemplo de finalidad secundaria; requiere
--    aprobación previa del responsable de privacidad y excluir a quienes se oponen)
CREATE TABLE IF NOT EXISTS oposiciones_finalidad (
    id_cliente  BIGINT REFERENCES clientes(id),
    finalidad   TEXT NOT NULL,
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_cliente, finalidad)
);

CREATE OR REPLACE VIEW v_marketing_promos
WITH (security_barrier = true) AS
SELECT c.id, c.correo, c.ciudad,
       CASE WHEN c.edad BETWEEN 18 AND 29 THEN '18-29'
            WHEN c.edad BETWEEN 30 AND 44 THEN '30-44'
            WHEN c.edad BETWEEN 45 AND 59 THEN '45-59'
            ELSE 'otro' END AS rango_edad
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM oposiciones_finalidad o
    WHERE o.id_cliente = c.id AND o.finalidad = 'marketing'
);
GRANT USAGE ON SCHEMA public TO marketing;
GRANT SELECT ON v_marketing_promos TO marketing;

-- ============================================================
-- Verificación
-- ============================================================
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista';

-- Pruebas funcionales
SET ROLE analista;
SELECT * FROM v_analitica_clientes LIMIT 5;     -- debe funcionar
-- SELECT * FROM clientes;                      -- debe fallar: permission denied
-- SELECT nombre, correo, rfc FROM clientes;    -- debe fallar
RESET ROLE;

-- ============================================================
-- Actividad 7: trazabilidad de rectificación (soporte a ARCO-R)
-- ============================================================
CREATE TABLE IF NOT EXISTS auditoria_clientes (
    id_auditoria  BIGSERIAL PRIMARY KEY,
    id_cliente    BIGINT NOT NULL,
    columna       TEXT NOT NULL,
    valor_anterior TEXT,
    valor_nuevo    TEXT,
    usuario_bd    TEXT NOT NULL DEFAULT current_user,
    fecha         TIMESTAMPTZ NOT NULL DEFAULT now(),
    referencia_solicitud TEXT   -- folio de la solicitud ARCO autorizada
);

CREATE OR REPLACE FUNCTION fn_audit_clientes() RETURNS trigger AS $$
BEGIN
    IF NEW.correo   IS DISTINCT FROM OLD.correo THEN
        INSERT INTO auditoria_clientes(id_cliente, columna, valor_anterior, valor_nuevo, referencia_solicitud)
        VALUES (OLD.id, 'correo', OLD.correo, NEW.correo, current_setting('app.folio_arco', true));
    END IF;
    IF NEW.telefono IS DISTINCT FROM OLD.telefono THEN
        INSERT INTO auditoria_clientes(id_cliente, columna, valor_anterior, valor_nuevo, referencia_solicitud)
        VALUES (OLD.id, 'telefono', OLD.telefono, NEW.telefono, current_setting('app.folio_arco', true));
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_clientes ON clientes;
CREATE TRIGGER trg_audit_clientes
AFTER UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION fn_audit_clientes();

-- Rectificación (Actividad 7)
SET app.folio_arco = 'ARCO-2026-0001';
UPDATE clientes SET correo = 'nuevo-correo@example.com' WHERE id = 1;
SELECT id, nombre, correo FROM clientes WHERE id = 1;
SELECT * FROM auditoria_clientes ORDER BY id_auditoria DESC LIMIT 5;
