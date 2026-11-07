# Evidencia 12 — Altas y bajas (Actividad 13)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

```text
INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');
INSERT 0 1
DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';
DELETE 1
SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
 id_evento | usuario_sesion |   aplicacion   | ip_cliente | operacion | id_cliente |   rfc_antes   |  rfc_despues
-----------+----------------+----------------+------------+-----------+------------+---------------+---------------
         1 | app_ventas     | app-ventas-web | 127.0.0.1  | UPDATE    |          3 | GAMA780912XYZ | GAMA780912ZZZ
         2 | postgres       | psql           |            | INSERT    |          6 |               | RUPE950101AAA
         3 | postgres       | psql           |            | DELETE    |          6 | RUPE950101AAA |
(3 rows)
```

## Respuestas

**1. Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia?** En `auditoria.cambios_clientes`: el evento 2 (`INSERT`) conserva en `valores_despues` la fila completa con la que se dio de alta, y el evento 3 (`DELETE`) conserva en `valores_antes` la fila completa tal como estaba al eliminarse, con quién, cuándo y con qué aplicación. También queda el texto de ambas sentencias en la bitácora (líneas 177 y 179).

**2. ¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?** Porque el administrador se conectó por socket Unix local (`client=[local]`), sin TCP; `inet_client_addr()` devuelve NULL.

**3. Conflicto con la política de retención de la Unidad II. ¿Quién debe resolverlo?** La retención pedía eliminar datos personales cuando ya no fueran necesarios, pero la auditoría conserva una copia completa (nombre, correo, RFC) después de borrarlos. Se enfrentan dos obligaciones: la de suprimir datos personales (derecho de cancelación en la legislación de protección de datos) y la de conservar evidencia (rendición de cuentas, cumplimiento, investigaciones). No debe resolverlo el DBA solo: corresponde al responsable o dueño de los datos, junto con el área legal o de cumplimiento, definir el plazo de conservación de la auditoría, quién autoriza su depuración y si se minimiza su contenido (por ejemplo, guardar solo columnas sensibles o enmascararlas después de cierto tiempo). El DBA implementa la decisión.
