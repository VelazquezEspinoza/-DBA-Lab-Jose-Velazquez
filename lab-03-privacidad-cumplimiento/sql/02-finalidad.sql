-- LAB-03 | Actividad 3: Separación por finalidad (analítica)
-- ============================================================

-- 1. Clientes por ciudad (dato agregado)
SELECT ciudad, COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY ciudad
ORDER BY cantidad_clientes DESC;

-- 2. Rangos de edad
SELECT
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    COUNT(*) AS cantidad
FROM clientes
GROUP BY 1
ORDER BY rango_edad;

-- 3. Región por código postal (primeros 2 dígitos) en lugar del CP completo
SELECT LEFT(codigo_postal, 2) AS region_cp, COUNT(*) AS cantidad
FROM clientes
GROUP BY 1
ORDER BY cantidad DESC;

-- 4. Combinación con umbral mínimo (reduce riesgo de reidentificación):
--    se omiten grupos con menos de 5 personas.
SELECT
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    LEFT(codigo_postal, 2) AS region_cp,
    COUNT(*) AS cantidad
FROM clientes
GROUP BY 1, 2, 3
HAVING COUNT(*) >= 5
ORDER BY cantidad DESC;
