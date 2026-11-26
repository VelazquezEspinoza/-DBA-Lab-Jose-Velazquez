# Actividad 5 — Criterio de conservación de bitácoras

**Referencia:** NIST SP 800-92, *Guide to Computer Security Log Management* (REF-U3-03): planear la gestión de bitácoras, incluida su conservación, según la utilidad de cada registro y las obligaciones de la organización.

**Supuestos del criterio**

- La auditoría interna revisa **trimestralmente** y hace una revisión **anual**. Ningún registro se conserva en línea menos de un trimestre más un margen para investigar lo que aparezca en la revisión.
- "En línea" = en el servidor, consultable. "Archivado" = copia exportada, con hash SHA-256, en un repositorio de solo escritura fuera del servidor de base de datos.
- Ningún plazo de esta tabla se presenta como obligación legal. Donde puede existir una, se indica **"Plazo a confirmar con el área jurídica"** y qué obligación revisar.

## 1. Criterio por tipo de registro

| Registro | Ubicación actual | Riesgo de pérdida observado | Sensibilidad | Periodo propuesto | Justificación | Dónde se conserva | Quién puede leerlo | Acción al vencer |
|---|---|---|---|---|---|---|---|---|
| **Accesos de PostgreSQL** (`log_connections` / `log_disconnections`) | Archivo del colector (`pg_current_logfile()`) | Rotación del archivo; reinstalación o recreación del servidor (o del contenedor) | Media: usuarios, IP, horarios | **90 días** en línea + **1 año** archivado | Cubre la revisión trimestral con margen y permite reconstruir accesos en la revisión anual | Servidor (en línea); repositorio de evidencias con hash (archivado) | DBA, Auditoría interna, Seguridad de la información | Eliminación segura, registrada en un acta con el nombre del archivo y su hash |
| **Cambios de privilegios y estructura** (`GRANT`, `REVOKE`, `CREATE`, `ALTER`, `DROP`, `COMMENT`) | Archivo del colector (mezclados con todo lo demás) | Igual que el anterior; además, comparten archivo con eventos de poco valor y se pierden al rotar | **Alta**: muestran quién obtuvo poder sobre los datos y pueden contener contraseñas (línea 37) | **3 años** archivado (extracto filtrado y con contraseñas ocultas); 90 días en línea | Un privilegio indebido puede usarse meses después de otorgarse; para investigarlo hay que saber desde cuándo existía. Es la evidencia de POL-01 y POL-06 | Extracto mensual (consulta de la Actividad 7) en el repositorio de evidencias, con hash | Auditoría interna y Seguridad de la información; el DBA solo genera el extracto | Revisión de Auditoría interna antes de eliminar: se conserva si está ligado a un hallazgo abierto |
| **Modificaciones de datos** (`log_statement = 'mod'`) | Archivo del colector | Rotación; el volumen crece con la operación | **Alta**: contiene los valores de `INSERT`/`UPDATE` (datos personales) | **90 días** en línea; **1 año** archivado | Su valor de evidencia lo cubre en gran parte `auditoria.cambios_clientes`; guardarla más tiempo multiplica copias de datos personales | Servidor; archivado cifrado | DBA, Auditoría interna | Eliminación segura con acta. **Plazo a confirmar con el área jurídica**: obligaciones de la ley de protección de datos personales en posesión de particulares (minimización y supresión) |
| **`auditoria.cambios_clientes`** | Tabla en `comercial` | El superusuario puede desactivar el disparador (LAB-01, Act. 14) o borrar filas; se pierde si se recrea la base sin respaldo | **Contiene datos personales** (`valores_antes` / `valores_despues`) | Mientras exista el cliente + **plazo a confirmar con el área jurídica** después de su baja | Debe durar al menos lo que pueda reclamarse un cambio del dato (por ejemplo, una factura emitida con un RFC alterado). Ver el conflicto de la sección 2 | En la base (en línea); en los respaldos de la base (Unidad V) | Auditoría interna; el DBA solo opera la tabla | **Seudonimizar** `valores_antes` / `valores_despues` (conservar metadatos: quién, cuándo, operación, `id_cliente`) y eliminar el resto con autorización de Auditoría y Jurídico. Revisar el plazo de conservación de comprobantes fiscales (Código Fiscal de la Federación) si el cambio afectó la facturación |
| **Bitácora de `mongod`** | `systemLog.path` o salida estándar; `getLog` solo en memoria | `getLog` guarda solo los eventos recientes en memoria y se pierden al reiniciar; si se escribe a la salida estándar de un contenedor, se pierde al recrearlo | Media | **90 días** en línea + **1 año** archivado | Mismo criterio que los accesos de PostgreSQL | `systemLog.path` en disco con rotación (`logRotate`); copias archivadas con hash | DBA, Auditoría interna, Seguridad de la información | Eliminación segura con acta |
| **`system.profile`** | Colección limitada de 1 MB | **Se sobrescribe sola**: en horas o minutos de carga se pierde lo anterior | Media-alta: los filtros contienen valores personales | **Exportar antes de cada revisión** (y semanalmente si el perfilador está activo); conservar exportaciones **90 días** | Es información de desempeño, no de seguridad; solo se guarda lo necesario para analizar consultas lentas | Exportación JSON con hash (como `E6-mongodb/system-profile.json`) | DBA; Auditoría interna (lectura) | Eliminar la exportación |
| **Instantáneas de privilegios (MongoDB)** | `auditoria.instantaneas_privilegios` | Se pierden si se elimina la base `auditoria`; dependen de que alguien las genere | Media-alta: describen quién puede hacer qué | **3 años** | Es el sustituto, en Community, de la auditoría nativa de cambios de privilegios: debe durar lo mismo que la bitácora de `GRANT`/`REVOKE` de PostgreSQL | Colección en la base `auditoria` + exportación archivada con hash | Auditoría interna, DBA | Revisión de Auditoría interna y eliminación con acta |

## 2. Conflicto entre conservación y eliminación (LAB-01, Actividad 13)

La política de retención (POL-03) exige eliminar los datos personales de un cliente cuando vence su plazo; la auditoría guarda copias de esos datos en `valores_antes` / `valores_despues`. Si se borra el cliente pero no la auditoría, el dato sobrevive; si se borra la auditoría, se pierde la evidencia.

**Criterio adoptado:**

1. La auditoría de un cliente **no se elimina antes** que el propio dato, ni mientras exista un incidente o una investigación abierta (POL-05 manda sobre POL-03).
2. Al vencer el plazo, se **seudonimiza**: se conservan los metadatos del evento (quién, cuándo, desde dónde, operación, `id_cliente`) y se eliminan los valores personales.
3. La decisión la autorizan **Auditoría interna** (propietaria de la evidencia) y **Jurídico** (plazo), no el DBA.

## 3. Preguntas

**¿Por qué la bitácora de cambios de privilegios merece más tiempo de conservación que la de consultas rutinarias?**
Porque un privilegio tiene **efecto duradero**: un `GRANT UPDATE` otorgado hoy permite cambios dentro de seis meses, y para investigarlos hay que saber cuándo, quién y con qué autorización se otorgó. Una consulta rutinaria tiene efecto inmediato y pierde valor rápido. Además, los cambios de privilegios son pocos (poco volumen, mucho valor) y son la evidencia de POL-01 y POL-06; las modificaciones de datos son muchas y contienen datos personales, así que conservarlas más tiempo aumenta el riesgo.

**¿Qué control de integridad aplicarás a las bitácoras exportadas?**
- Hash **SHA-256** de cada archivo al momento de exportarlo (`E5-bitacora-postgresql.sha256` y `evidencias/SHA256SUMS`).
- El archivo de hashes se guarda **separado** de las bitácoras (otra ubicación u otro responsable, por ejemplo Auditoría interna) y se registra en el índice del expediente, porque quien puede cambiar la bitácora también podría recalcular el hash si están juntos.
- Copia en un almacenamiento de **solo escritura** o con versiones, fuera del servidor de base de datos.
- Verificación con `sha256sum -c` en cada revisión, registrada en el acta.
- Las contraseñas se ocultan **antes** de calcular el hash de la copia que se comparte. El original no se modifica.

**¿Qué diferencia hay entre conservar una bitácora y respaldar una base de datos?**
Conservar una bitácora es guardar **evidencia de lo que ocurrió**, inmutable, durante un plazo definido por su valor probatorio; nunca se "restaura" sobre nada. Respaldar una base es guardar **una copia del estado de los datos** para recuperarlo tras una falla; se sobrescribe con respaldos más recientes y su plazo lo marca la recuperación (POL-02). Un respaldo no sustituye a la bitácora (no dice quién cambió qué) y la bitácora no sustituye al respaldo (no permite reconstruir los datos). Además, restaurar un respaldo puede **traer de vuelta** datos y auditoría que la retención ya había eliminado, y eso debe considerarse en POL-03 y POL-04. El mecanismo técnico de respaldo se estudia en la Unidad V.
