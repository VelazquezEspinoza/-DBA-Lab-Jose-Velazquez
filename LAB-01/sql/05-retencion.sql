-- =====================================================================
-- LAB-01 — Protección y privacidad de datos
-- Archivo : 05-retencion.sql
-- Alumno  : José Fernando Velázquez Espinoza
-- Contenido: Actividad 7 — Retención de datos
-- Requiere: haber ejecutado 01-clasificacion.sql
-- =====================================================================

-- Periodo de conservación didáctico: 5 años.
-- Identificar los registros que hipotéticamente exceden el periodo.
-- NO SE EJECUTA DELETE sobre la tabla principal.
--
-- Nota: los registros de prueba se insertaron con fecha_alta =
-- CURRENT_DATE, por lo que se espera un resultado vacío (0 filas).
SELECT *
FROM clientes
WHERE fecha_alta <
      CURRENT_DATE - INTERVAL '5 years';

-- Consulta de apoyo: cuántos registros serían afectados
SELECT COUNT(*) AS registros_a_eliminar
FROM clientes
WHERE fecha_alta <
      CURRENT_DATE - INTERVAL '5 years';

-- ---------------------------------------------------------------------
-- Diseño del procedimiento (documentar en informe.md)
-- ---------------------------------------------------------------------
-- Registros afectados : clientes con fecha_alta anterior a 5 años.
-- Justificación       : periodo didáctico que cubre la finalidad
--                       comercial y obligaciones contractuales/fiscales;
--                       conservar más aumenta el riesgo sin valor.
-- Aprobación previa   : autorización escrita del responsable del
--                       tratamiento (jurídico/cumplimiento y dueño del
--                       dato), verificando que no haya obligación legal
--                       o litigio que exija conservarlos.
-- Respaldo            : respaldo completo verificado antes de eliminar,
--                       con restauración probada y acceso restringido.
-- Evidencia           : consulta ejecutada, listado de registros
--                       afectados, autorización, fecha, responsable y
--                       resultado.
-- Recuperación        : restaurar el respaldo (o recuperación a un
--                       punto en el tiempo) en un entorno separado,
--                       extraer los registros y reinsertarlos validando
--                       integridad; documentar el incidente.
--
-- La eliminación física se trabajará en las prácticas de respaldo y
-- recuperación.
