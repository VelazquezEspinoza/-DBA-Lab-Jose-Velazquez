# Actividad 4 — Catálogo mínimo de datos

**Script:** [`sql/03-inventario-tablas.sql`](../sql/03-inventario-tablas.sql) (tablas, vistas, columnas candidatas a dato personal, ubicación del servidor)

## 1. Insumo técnico obtenido del motor

Salida de la consulta de la guía, tras `ANALYZE` (pega la tuya):

```
⟨pegar salida de la consulta 1 del script: esquema | tabla | propietario_tecnico | filas_estimadas | tamano | descripcion⟩
```

Observaciones:

- `propietario_tecnico` es `postgres` en todas las tablas: es el rol dueño del objeto en el motor, **no** el propietario del dato en la organización.
- La consulta de la guía filtra `relkind = 'r'`, así que `dba.bitacora` (vista) no aparece. La consulta 2 del script incluye vistas (`relkind = 'v'`) para inventariarla.
- La bitácora del colector, la de `mongod` y los archivos exportados no son objetos del motor y **ninguna consulta los lista**: se agregan a mano (CAT-06 a CAT-09).

## 2. Catálogo

Ubicación: `servidor / base / esquema.objeto`.

| ID | Conjunto de datos | Motor | Ubicación | Propietario | Custodio | Clasificación | Contiene datos personales | Finalidad | Conservación | Diccionario |
|---|---|---|---|---|---|---|---|---|---|---|
| CAT-01 | Clientes | PostgreSQL 16 | ⟨servidor-pg⟩ / comercial / public.clientes | Gerencia Comercial | DBA | Confidencial | Sí | Operación comercial, facturación y contacto | Mientras exista la relación comercial + plazo a confirmar con Jurídico (POL-03) | `diccionario-clientes.csv`, `03-diccionario.md` |
| CAT-02 | Auditoría de clientes | PostgreSQL 16 | ⟨servidor-pg⟩ / comercial / auditoria.cambios_clientes | Auditoría interna | DBA | Confidencial — evidencia | Sí (`valores_antes` / `valores_despues`, usuario, IP) | Demostrar quién cambió qué dato de cliente y cuándo | Ver `05-conservacion.md` (al menos lo que dure el dato auditado + periodo de investigación) | `COMMENT` de la tabla; columnas definidas en LAB-01 Parte B |
| CAT-03 | Registro de cambios | PostgreSQL 16 | ⟨servidor-pg⟩ / comercial / gobierno.solicitudes_cambio | Comité de cambios | DBA | Interno | No (solo nombres de áreas y descripciones) | Evidencia de autorización de cambios (POL-06) | Igual que la bitácora de cambios de privilegios y estructura (3 años) | `COMMENT` de la tabla; definición en `sql/04-registro-cambios.sql` |
| CAT-04 | Clientes (tienda) | MongoDB 7 | ⟨servidor-mongo⟩ / comercial / clientes | Gerencia Comercial | DBA | Confidencial | Sí | Operación de la tienda en línea | Igual que CAT-01 | Pendiente: MongoDB no tiene `COMMENT`; el diccionario se documenta fuera del motor (validador `$jsonSchema` con `description`, si se usa) |
| CAT-05 | Perfilado | MongoDB 7 | ⟨servidor-mongo⟩ / comercial / system.profile | Jefatura de TI / Operaciones | DBA | Interno — sensible | Sí (los filtros de las consultas incluyen valores: correos, nombres, RFC) | Análisis de desempeño de consultas | Colección limitada de 1 MB: se sobrescribe sola. Exportar antes de cada revisión (ver `05-conservacion.md`) | Estructura documentada por MongoDB; evidencia en `E6-mongodb/system-profile.json` |
| CAT-06 | Vista de bitácora | PostgreSQL 16 | ⟨servidor-pg⟩ / comercial / dba.bitacora | Seguridad de la información | DBA | Restringido | Sí (expone la bitácora) | Consulta de la bitácora por SQL | No guarda datos: depende del archivo vigente del colector | `COMMENT` de la vista |
| CAT-07 | Bitácora de PostgreSQL | PostgreSQL 16 | ⟨servidor-pg⟩ / `log_directory` (archivo de `pg_current_logfile()`) | Seguridad de la información | DBA + administrador del SO | Restringido | Sí (valores de `INSERT`/`UPDATE`; secretos en `CREATE ROLE ... PASSWORD`) | Evidencia de accesos, cambios y errores | Ver `05-conservacion.md` | Formato definido por `log_line_prefix` (E1) |
| CAT-08 | Bitácora de `mongod` | MongoDB 7 | ⟨servidor-mongo⟩ / `systemLog.path` o salida estándar | Seguridad de la información | DBA + administrador del SO | Restringido | Posible (consultas lentas con sus filtros) | Evidencia de accesos y eventos del servidor | Ver `05-conservacion.md` | Formato JSON estructurado de MongoDB |
| CAT-09 | Instantáneas de privilegios | MongoDB 7 | ⟨servidor-mongo⟩ / auditoria / instantaneas_privilegios | Auditoría interna | DBA | Interno | Sí (nombres de usuario) | Comparar privilegios entre fechas (sustituto de la auditoría nativa) | 3 años | Estructura definida en LAB-02 |

## 3. Preguntas

**¿Por qué CAT-02 y CAT-05 contienen datos personales aunque su propósito sea la auditoría?**
Porque para demostrar qué cambió hay que guardar **el dato mismo**. `cambios_clientes` copia la fila completa antes y después (nombre, correo, RFC), además del usuario y la IP de quien hizo el cambio. `system.profile` guarda el comando completo, incluidos los valores de los filtros (`{correo: "..."}`). La finalidad de auditoría no cambia la naturaleza del dato: siguen siendo datos personales, con las mismas obligaciones de acceso restringido y retención. Por eso E4 muestra solo metadatos.

**¿Qué pasa si CAT-01 y CAT-04 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?**
No existe una **fuente de verdad**: cada propietario puede sostener que su valor es el correcto y nadie tiene autoridad para decidir. La factura puede emitirse con un RFC y la tienda mostrar otro. Además, una corrección aprobada en un motor no obliga al otro, así que la inconsistencia se repite. Por eso propongo un solo propietario para el dato "cliente" (Gerencia Comercial) en ambos motores, declarar cuál es el sistema maestro del RFC (PostgreSQL, porque de ahí sale la facturación) y agregar una verificación periódica de consistencia entre ambos.

**¿Qué información del catálogo cambia con más frecuencia y quién debe actualizarla?**
Lo técnico: filas estimadas, tamaño, ubicación (si cambia el servidor o la forma de despliegue) y los objetos nuevos (como `canal_alta` o `gobierno.solicitudes_cambio`). Lo actualiza el **custodio (DBA)**, de preferencia regenerándolo con `03-inventario-tablas.sql` como parte del cierre de cada cambio aprobado (POL-06). Lo de gobierno (propietario, clasificación, finalidad, conservación) cambia poco y solo puede modificarlo el **propietario**; el DBA registra la decisión.
