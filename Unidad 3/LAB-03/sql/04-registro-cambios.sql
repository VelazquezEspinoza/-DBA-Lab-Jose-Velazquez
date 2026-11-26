-- =====================================================================
-- LAB-03 · Actividad 7 — Registro de cambios y conciliación
-- Base: comercial · Sesión de administrador
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Registro mínimo de solicitudes de cambio (evidencia de POL-06)
-- ---------------------------------------------------------------------
CREATE SCHEMA gobierno;
REVOKE ALL ON SCHEMA gobierno FROM PUBLIC;

CREATE TABLE gobierno.solicitudes_cambio (
    folio            TEXT PRIMARY KEY,
    descripcion      TEXT NOT NULL,
    solicitado_por   TEXT NOT NULL,
    aprobado_por     TEXT,
    ambiente         TEXT NOT NULL CHECK (ambiente IN ('desarrollo', 'pruebas', 'produccion')),
    fecha_aprobacion TIMESTAMPTZ,
    ventana_inicio   TIMESTAMPTZ,
    ventana_fin      TIMESTAMPTZ
);

COMMENT ON TABLE gobierno.solicitudes_cambio IS 'Registro de solicitudes de cambio en la base comercial. Propietario: Comité de cambios. Custodio: DBA. Evidencia de POL-06.';
COMMENT ON SCHEMA gobierno IS 'Registros de gobierno de datos (solicitudes de cambio). Propietario: Comité de cambios. Custodio: DBA.';

-- ---------------------------------------------------------------------
-- 2. Solicitud aprobada y cambio ejecutado dentro de su ventana
-- ---------------------------------------------------------------------
INSERT INTO gobierno.solicitudes_cambio VALUES
('CAM-2026-014', 'Agregar columna canal_alta a clientes', 'Gerencia Comercial',
 'Comité de cambios', 'produccion', now() - interval '1 day',
 now() - interval '5 minutes', now() + interval '1 hour');

ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20);
COMMENT ON COLUMN clientes.canal_alta IS 'Canal por el que se registró el cliente. Cambio CAM-2026-014.';

-- Verificación de la ventana (al momento de ejecutar)
SELECT folio, aprobado_por,
       ventana_inicio <= now() AND now() <= ventana_fin AS dentro_de_ventana
FROM gobierno.solicitudes_cambio;

-- ---------------------------------------------------------------------
-- 3. Extracción de la bitácora: cambios de estructura y privilegios
--    (consulta de la guía, vista dba.bitacora del LAB-01)
--    ¡OJO! La salida puede contener contraseñas (CREATE ROLE ... PASSWORD)
--    y debe revisarse antes de compartirse.
-- ---------------------------------------------------------------------
SELECT num,
       substr(linea, 1, 23)                     AS momento,
       substring(linea from 'user=([^ ]*)')     AS usuario,
       substring(linea from 'statement: (.*)$') AS sentencia
FROM dba.bitacora
WHERE linea ~ 'statement: (CREATE|ALTER|DROP|GRANT|REVOKE)'
ORDER BY num;

-- ---------------------------------------------------------------------
-- 4. Conciliación asistida: bitácora  vs  solicitudes aprobadas
--
--   * folio_patron relaciona cada folio con un patrón de la sentencia
--     (la tabla de la guía no tiene un campo para ello; se declara aquí).
--   * Un cambio se considera AUTORIZADO solo si coincide el patrón Y su
--     momento cae dentro de la ventana Y la solicitud está aprobada.
--   * resultado = 'ERROR' indica que el motor rechazó la sentencia
--     (la siguiente línea del mismo proceso es un ERROR). Distingue,
--     por ejemplo, un intento fallido de app_ventas de un cambio efectivo
--     de postgres.
--   * Las contraseñas se ocultan en la salida.
--   * NO se registran folios retroactivos para "regularizar" cambios:
--     lo que no tenga folio es un hallazgo y se reporta como tal.
-- ---------------------------------------------------------------------
WITH folio_patron (folio, patron) AS (
    VALUES ('CAM-2026-014', 'ADD COLUMN canal_alta'),
           ('CAM-2026-014', 'COLUMN clientes.canal_alta')   -- su COMMENT
),
lineas AS (
    SELECT num,
           linea,
           substring(linea from '\[([0-9]+)\]')        AS pid,
           substring(linea from 'user=([^ ]*)')       AS usuario,
           substring(linea from 'client=([^ ]*)')     AS cliente,
           substring(linea from 'app=(.*?) client=')  AS aplicacion
    FROM dba.bitacora
),
cambios AS (
    SELECT l.*,
           (substr(l.linea, 1, 23)::timestamp
               AT TIME ZONE current_setting('log_timezone'))       AS momento,
           regexp_replace(substring(l.linea from 'statement: (.*)$'),
                          '(PASSWORD\s+)''[^'']*''', '\1''<REDACTED>''', 'gi') AS sentencia
    FROM lineas l
    WHERE l.linea ~* 'statement: (CREATE|ALTER|DROP|GRANT|REVOKE|COMMENT|TRUNCATE)'
)
SELECT c.num,
       to_char(c.momento, 'YYYY-MM-DD HH24:MI:SS.MS') AS momento,
       c.usuario,
       c.cliente,
       c.aplicacion,
       c.sentencia,
       CASE WHEN sig.linea ~ 'ERROR:' THEN 'ERROR' ELSE 'ejecutada' END AS resultado,
       s.folio,
       CASE
         WHEN s.folio IS NOT NULL AND s.aprobado_por IS NOT NULL
              AND c.momento BETWEEN s.ventana_inicio AND s.ventana_fin
           THEN 'Sí'
         WHEN s.folio IS NOT NULL
           THEN 'Folio existe, pero fuera de ventana o sin aprobación'
         ELSE 'No (sin folio)'
       END AS autorizado
FROM cambios c
LEFT JOIN folio_patron fp ON c.sentencia ILIKE '%' || fp.patron || '%'
LEFT JOIN gobierno.solicitudes_cambio s ON s.folio = fp.folio
LEFT JOIN LATERAL (
    SELECT l2.linea FROM lineas l2
    WHERE l2.pid = c.pid AND l2.num > c.num
    ORDER BY l2.num LIMIT 1
) sig ON true
ORDER BY c.num;

-- ---------------------------------------------------------------------
-- 5. Resumen para el expediente
-- ---------------------------------------------------------------------
WITH c AS (
    SELECT substring(linea from 'statement: (.*)$') AS sentencia
    FROM dba.bitacora
    WHERE linea ~* 'statement: (CREATE|ALTER|DROP|GRANT|REVOKE|COMMENT|TRUNCATE)'
)
SELECT count(*)                                                  AS cambios_en_bitacora,
       count(*) FILTER (WHERE sentencia ILIKE '%canal_alta%')     AS con_folio_cam_2026_014,
       count(*) FILTER (WHERE sentencia NOT ILIKE '%canal_alta%') AS sin_folio
FROM c;
