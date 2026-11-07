-- LAB-01 · Actividad 12 · Qué campo cambió en cada UPDATE auditado
-- Compara valores_antes y valores_despues campo por campo.

SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a
CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'
  AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;

-- Sentencia de restauración del valor anterior (evento 1):
-- UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
-- Forma genérica, tomando el valor desde la auditoría:
-- UPDATE clientes c
-- SET rfc = a.valores_antes ->> 'rfc'
-- FROM auditoria.cambios_clientes a
-- WHERE a.id_evento = 1 AND c.id = a.id_cliente;
