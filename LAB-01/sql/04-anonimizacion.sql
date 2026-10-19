-- =====================================================================
-- LAB-01 — Protección y privacidad de datos
-- Archivo : 04-anonimizacion.sql
-- Alumno  : José Fernando Velázquez Espinoza
-- Contenido: Actividad 5 — Anonimización
--            Actividad 6 — Análisis del riesgo de reidentificación
-- Requiere: haber ejecutado 01-clasificacion.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- ACTIVIDAD 5 — Anonimización
-- ---------------------------------------------------------------------

-- 12.1 Generalizar la edad
-- Resultado esperado: 31-45 -> 4 ; 46+ -> 1
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,
    COUNT(*) AS total
FROM clientes
GROUP BY 1;

-- 12.2 Generalizar la región
-- Resultado esperado: 80 -> 3 ; 81 -> 1 ; 82 -> 1
SELECT
    LEFT(codigo_postal, 2) AS region,
    COUNT(*) AS total
FROM clientes
GROUP BY 1;

-- 12.3 Combinar atributos
-- Resultado esperado: (31-45, 80) -> 3 ; (31-45, 81) -> 1 ; (46+, 82) -> 1
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,

    LEFT(codigo_postal, 2) AS region,

    COUNT(*) AS total

FROM clientes

GROUP BY 1, 2;

-- 12.4 Suprimir grupos pequeños (umbral didáctico k = 5)
-- Con 5 registros ningún grupo alcanza el umbral: resultado vacío (0 filas)
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,

    LEFT(codigo_postal, 2) AS region,

    COUNT(*) AS total

FROM clientes

GROUP BY 1, 2

HAVING COUNT(*) >= 5;

-- Nota: cumplir k = 5 NO demuestra que el conjunto sea completamente
-- anónimo; depende del contexto, de otras variables y de fuentes externas.

-- ---------------------------------------------------------------------
-- ACTIVIDAD 6 — Análisis del riesgo de reidentificación
-- ---------------------------------------------------------------------
-- Identificadores directos eliminados : nombre, correo, telefono, rfc
-- Cuasi-identificadores que permanecen: rango de edad, región postal
-- Combinaciones de riesgo             : rango_edad + región (+ ciudad,
--                                       fecha_alta o fuentes externas)
-- Grupos pequeños                     : permiten señalar a una persona
-- Generalizar                         : edad, código postal, fecha_alta
-- Suprimir                            : grupos con menos de k registros
-- ¿100 % anónimo?                     : No; el riesgo se reduce, no se
--                                       elimina.

-- RETO: reducir aún más el riesgo de reidentificación
--   Cambio  : rangos de edad más amplios y región reducida al primer
--             dígito del código postal.
--   Motivo  : formar grupos más grandes que cumplan el umbral k = 5.
--   Riesgo  : identificación de personas en grupos pequeños.
--   Costo   : se pierde detalle y utilidad analítica.
--   Resultado esperado: un grupo (18-49, región 8) con total = 5
--   (confirmar con la ejecución real).
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 49 THEN '18-49'
        ELSE '50+'
    END AS rango_edad,

    LEFT(codigo_postal, 1) AS region,

    COUNT(*) AS total

FROM clientes

GROUP BY 1, 2

HAVING COUNT(*) >= 5;
