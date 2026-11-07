# Evidencia 14 — Límites: lecturas y volumen (Actividad 15)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

## Lectura de datos sensibles por `soporte_ana`

```text
$ psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
    nombre    |      rfc      |  telefono
--------------+---------------+------------
 María García | GAMA780912GHI | 6679990000
(1 row)
```

## Cambio masivo y conteos

```text
UPDATE clientes SET segmento = 'regular';
UPDATE 5
SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%statement: UPDATE clientes SET segmento%';
 lineas_bitacora
-----------------
               1
(1 row)

SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
 operacion | count
-----------+-------
 DELETE    |     1
 INSERT    |     1
 UPDATE    |     6
(3 rows)

SELECT count(*) AS lecturas_soporte FROM dba.bitacora
WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
 lecturas_soporte
------------------
                0
(1 row)
```

- El `UPDATE` masivo produjo **1** línea en la bitácora y **5** filas nuevas en la auditoría (eventos 4–8), una por cada cliente.
- Las cinco filas tienen el mismo `momento` (`03:14:03.976393+00`), porque `now()` devuelve la hora de inicio de la transacción.
- La lectura del RFC por `soporte_ana` dejó **0** líneas de sentencia: solo su conexión y desconexión (líneas 198–201). Se puede probar que se conectó, no qué leyó.

## Respuestas

**1. Si `clientes` tuviera un millón de registros, ¿qué ocurriría tras un `UPDATE` sin `WHERE`?** La bitácora seguiría teniendo una sola línea, pero la auditoría recibiría un millón de filas, cada una con dos documentos JSONB completos. El `UPDATE` tardaría bastante más (un `INSERT` extra por fila dentro de la misma transacción), generaría mucho más WAL y espacio en disco y en respaldos, y la tabla de auditoría crecería de golpe. Opciones de mitigación: guardar solo las columnas sensibles, usar disparadores por sentencia con tablas de transición, particionar la auditoría por fecha y vigilar su crecimiento.

**2. ¿Quién podría autorizar la depuración de `auditoria.cambios_clientes`?** El dueño o responsable de los datos junto con el área de cumplimiento o auditoría interna, nunca el DBA por sí solo, porque es a quien la auditoría vigila. La depuración debería seguir una política escrita de retención, quedar registrada (quién, cuándo, qué rango de fechas) y, preferentemente, ir precedida de un archivo externo de lo que se elimina.

**3. ¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?** Porque registra el texto de todas las consultas, y las consultas llevan datos: `WHERE rfc = '...'`, `WHERE correo = '...'`, búsquedas por nombre. La bitácora acumularía datos personales de forma desordenada, en archivos de texto plano, fuera de los controles de acceso de las tablas, rotados, copiados y respaldados, y difíciles de depurar para cumplir la retención o un derecho de cancelación.
