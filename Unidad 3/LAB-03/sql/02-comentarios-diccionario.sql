-- =====================================================================
-- LAB-03 · Actividad 3 — Diccionario de datos operativo dentro del motor
-- Base: comercial · Sesión de administrador
-- COMMENT es una sentencia DDL: con log_statement = 'mod' (que incluye
-- 'ddl') cada COMMENT queda en la bitácora del colector.
-- =====================================================================

-- Tabla
COMMENT ON TABLE clientes IS 'Clientes de Comercializadora Norte. Propietario: Gerencia Comercial. Custodio: DBA. Clasificación: confidencial (contiene datos personales).';

-- Columnas dadas por la guía
COMMENT ON COLUMN clientes.id IS 'Identificador interno del cliente. Generado por el sistema.';
COMMENT ON COLUMN clientes.nombre IS 'Nombre completo. Dato personal identificador directo.';
COMMENT ON COLUMN clientes.correo IS 'Correo de contacto. Dato personal. Uso: notificaciones al cliente.';
COMMENT ON COLUMN clientes.rfc IS 'RFC del cliente. Dato personal. Uso: facturación. Cambios auditados en auditoria.cambios_clientes.';
COMMENT ON COLUMN clientes.edad IS 'Edad en años cumplidos. Dato personal. Uso: analítica agregada.';

-- Columnas completadas por el alumno
COMMENT ON COLUMN clientes.telefono IS 'Teléfono de contacto a 10 dígitos. Dato personal. Uso: contacto y soporte. Se muestra enmascarado al rol de soporte (U2).';
COMMENT ON COLUMN clientes.ciudad IS 'Ciudad de residencia o de entrega. Dato personal de localización (identificador indirecto). Uso: logística y analítica por zona.';
COMMENT ON COLUMN clientes.codigo_postal IS 'Código postal de 5 dígitos. Dato personal de localización (identificador indirecto). Uso: logística, cobertura y facturación.';
COMMENT ON COLUMN clientes.fecha_alta IS 'Fecha en que el cliente se registró. Generada por el sistema (valor por defecto). Uso: antigüedad del cliente y cómputo de plazos de retención (POL-03).';
COMMENT ON COLUMN clientes.segmento IS 'Segmento comercial asignado por la Gerencia Comercial (agregado en LAB-01). Dato interno derivado; puede constituir perfilamiento. Uso: campañas y analítica.';

-- Otros activos de la unidad (para que el catálogo muestre descripción)
COMMENT ON SCHEMA auditoria IS 'Evidencia de auditoría de datos. Propietario: Auditoría interna. Custodio: DBA.';
COMMENT ON TABLE auditoria.cambios_clientes IS 'Auditoría de cambios en clientes generada por trg_auditoria_clientes (LAB-01 Parte B). Contiene datos personales en valores_antes/valores_despues. Propietario: Auditoría interna. Custodio: DBA. Conservación: ver evidencias/05-conservacion.md.';
COMMENT ON SCHEMA dba IS 'Objetos de apoyo del DBA. Acceso restringido.';
COMMENT ON VIEW dba.bitacora IS 'Lectura de la bitácora vigente del colector (pg_current_logfile). Puede contener secretos y datos personales: acceso solo DBA y Auditoría interna.';

-- ---------------------------------------------------------------------
-- Consulta del diccionario: metadatos estructurales + significado
-- ---------------------------------------------------------------------
SELECT c.ordinal_position          AS pos,
       c.column_name               AS columna,
       c.data_type                 AS tipo,
       c.character_maximum_length  AS longitud,
       c.is_nullable               AS acepta_nulos,
       c.column_default            AS valor_por_defecto,
       col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
ORDER BY c.ordinal_position;

-- ---------------------------------------------------------------------
-- Control de completitud del diccionario: debe devolver 0 filas
-- (si se eliminó alguna columna en LAB-01, ordinal_position puede tener
--  huecos; col_description usa el número de atributo, por eso funciona)
-- ---------------------------------------------------------------------
SELECT c.column_name AS columna_sin_comentario
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
  AND col_description('public.clientes'::regclass, c.ordinal_position) IS NULL;

-- ---------------------------------------------------------------------
-- ¿Quedaron los COMMENT en la bitácora? (pregunta 2 de la actividad)
-- ---------------------------------------------------------------------
SELECT num, substr(linea, 1, 23) AS momento,
       substring(linea from 'statement: (.*)$') AS sentencia
FROM dba.bitacora
WHERE linea ~ 'statement: COMMENT ON'
ORDER BY num;

-- ---------------------------------------------------------------------
-- Exportación (en la TERMINAL, desde la carpeta LAB-03/):
-- psql -U postgres -d comercial --csv -c "SELECT c.column_name AS columna, c.data_type AS tipo, c.character_maximum_length AS longitud, c.is_nullable AS acepta_nulos, col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion FROM information_schema.columns c WHERE c.table_schema = 'public' AND c.table_name = 'clientes' ORDER BY c.ordinal_position" > evidencias/diccionario-clientes.csv
-- ---------------------------------------------------------------------
