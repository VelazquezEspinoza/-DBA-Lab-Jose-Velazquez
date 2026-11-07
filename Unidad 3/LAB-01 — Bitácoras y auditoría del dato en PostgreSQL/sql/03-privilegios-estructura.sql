-- LAB-01 · Actividades 6 y 8 · Cambios de privilegios, de estructura y errores
-- Con log_statement = 'ddl'

REVOKE UPDATE ON clientes FROM soporte_ana;            -- privilegio (revocación preventiva)
GRANT UPDATE ON clientes TO app_ventas;                -- privilegio
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);  -- estructura

-- Demostración: un secreto escrito en la sentencia queda en la bitácora.
-- (En el archivo exportado se sustituyó por <REDACTED>.)
CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
DROP ROLE rol_temporal;

SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;

-- Actividad 8 · error de dependencia al dar de baja un rol
DROP ROLE soporte_ana;   -- falla: tiene privilegios sobre clientes

SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|STATEMENT|DETAIL):  (permission|privileges|role|DELETE|DROP)'
ORDER BY num;

-- Orden correcto para dar de baja a un usuario (NO ejecutado: el LAB-03 continúa con soporte_ana):
-- REVOKE ALL ON clientes FROM soporte_ana;
-- REASSIGN OWNED BY soporte_ana TO postgres;
-- DROP OWNED BY soporte_ana;
-- DROP ROLE soporte_ana;
