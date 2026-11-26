# Actividad 7 — Registro de cambios y conciliación

**Script:** [`sql/04-registro-cambios.sql`](../sql/04-registro-cambios.sql)
**Registro de solicitudes:** `gobierno.solicitudes_cambio` (CAT-03)
**Fuente de lo ocurrido:** bitácora del colector, leída con `dba.bitacora` (LAB-01); copia íntegra en `E5-bitacora-postgresql.log`

## 1. Registro de cambios

| Folio | Descripción | Solicitó | Aprobó | Ambiente | Ventana | ¿Ejecutado dentro de la ventana? |
|---|---|---|---|---|---|---|
| CAM-2026-014 | Agregar columna `canal_alta` a `clientes` | Gerencia Comercial | Comité de cambios | produccion | ⟨inicio⟩ – ⟨fin⟩ | Sí (`dentro_de_ventana = t`; la hora de la línea 216 cae dentro de la ventana) |

No se registraron folios retroactivos para los demás cambios: hacerlo sería **corregir silenciosamente** los hallazgos.

## 2. Método

1. Se extraen de la bitácora todas las sentencias `CREATE | ALTER | DROP | GRANT | REVOKE` (consulta de la guía). La consulta 4 del script agrega `COMMENT` y `TRUNCATE`, oculta contraseñas y marca como `ERROR` las sentencias que el motor rechazó (la siguiente línea del mismo proceso es un `ERROR`).
2. Cada sentencia se busca en `gobierno.solicitudes_cambio`. Se considera **autorizada** solo si existe un folio aprobado, para el ambiente de producción, y la hora de la bitácora cae dentro de `ventana_inicio`–`ventana_fin`.
3. Lo que no tiene folio se clasifica como **preparación del laboratorio** o como **hallazgo**.

> Números de línea y horas tomados del servidor con el LAB-01 completo (fragmento de la guía). Si los tuyos difieren, sustitúyelos con la salida de la consulta 4 del script.

## 3. Tabla de conciliación

| Línea | Momento (bitácora) | Usuario | Sentencia | Folio que lo autoriza | ¿Autorizado? | Hallazgo |
|---|---|---|---|---|---|---|
| 34 | 2026-10-25 22:50:09.341 | postgres | `REVOKE UPDATE ON clientes FROM soporte_ana` | — | No | Preparación del LAB-01 (corrige un exceso de privilegio). En producción: cambio de privilegios sin folio → **H-05 (Baja)** |
| 35 | 2026-10-25 22:50:09.367 | postgres | `GRANT UPDATE ON clientes TO app_ventas` | — | No | **H-05 (Media)**: se otorga un privilegio de modificación sin solicitud del propietario. Es el privilegio con el que después se modificó el RFC |
| 36 | 2026-10-25 22:50:09.372 | postgres | `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` | — | No | **H-06 (Media)**: cambio de estructura en producción sin folio (compárese con la línea 216, que sí lo tiene) |
| 37 | 2026-10-25 22:50:09.375 | postgres | `CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>'` | — | No | **H-04 (Alta)**: cuenta con acceso creada sin autorización **y** contraseña en texto claro en la bitácora |
| 163 | 2026-10-25 22:50:53.460 | app_ventas | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` | — | No | **H-02 (Media)**: la cuenta de la aplicación intentó desactivar la auditoría. El motor la rechazó (`must be owner of table clientes`, siguiente línea del mismo proceso) |
| 169 | 2026-10-25 22:50:53.549 | postgres | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` | — | No | **H-01 (Alta)**: el superusuario desactivó la auditoría de datos |
| 171 | 2026-10-25 22:50:53.554 | postgres | `ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes` | — | No | Parte de H-01: cierra la ventana sin auditoría. Lo ejecutado entre las líneas 169 y 171 **no** está en `auditoria.cambios_clientes`, pero sí en la bitácora |
| — | *(no aparece)* | postgres | `CREATE VIEW dba.bitacora ...` | — | No determinable | **H-07 (Media)**: hueco de evidencia. Cuando se creó, `log_statement` valía `none` |
| ⟨n⟩ | ⟨momento⟩ | postgres | `CREATE SCHEMA gobierno`, `REVOKE ALL ON SCHEMA gobierno FROM PUBLIC`, `CREATE TABLE gobierno.solicitudes_cambio (...)` y los `COMMENT ON ...` de las Actividades 3 y 7 | — | No | Preparación del LAB-03. En producción también requerirían folio: crear el registro de cambios es en sí un cambio |
| 216 | 2026-10-25 22:54:26.533 | postgres | `ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20)` | CAM-2026-014 | **Sí** | — |
| ⟨n+1⟩ | ⟨momento⟩ | postgres | `COMMENT ON COLUMN clientes.canal_alta IS '... Cambio CAM-2026-014.'` | CAM-2026-014 | Sí | — (forma parte del mismo cambio) |

Agrega las demás líneas que devuelva tu bitácora (las marcadas con `...` en la guía): creación del esquema `auditoria`, de la función y del disparador del LAB-01, roles, etc.

**Resumen:** de los cambios de estructura y privilegios de la bitácora, **solo los de CAM-2026-014 están autorizados**. El resto no tiene folio: la mayoría es preparación de los laboratorios, pero las líneas 35, 36, 37, 163 y 169–171 son hallazgos que se reportan en el expediente (sección 8).

## 4. Preguntas

**¿Qué cambios de la bitácora no tienen folio? Clasifícalos.**

| Clase | Líneas | Por qué |
|---|---|---|
| Preparación del laboratorio | Creación de esquemas `auditoria`, `dba` y `gobierno`, función y disparador de auditoría, `COMMENT` del diccionario, `REVOKE` de la línea 34 | Construyen los controles que se evalúan. Aun así, en producción requerirían folio; se declaran, no se ocultan |
| Hallazgo — privilegios | 35 (`GRANT UPDATE` a `app_ventas`), 37 (`CREATE ROLE rol_temporal`) | Dan capacidad de modificar datos o de entrar al servidor sin aprobación del propietario |
| Hallazgo — estructura | 36 (`segmento`) | Cambio en producción sin aprobación |
| Hallazgo — manipulación de controles | 163, 169, 171 | Intento y desactivación efectiva de la auditoría de datos |

**La desactivación del disparador, ¿qué tan grave es? ¿Qué distingue la línea 163 de la 169?**
Es el hallazgo **más grave** del expediente (**Alta**). No es un cambio indebido más: apaga el control que debería registrar los cambios indebidos. Durante la ventana entre 169 y 171, cualquier modificación de `clientes` (en el LAB-01, la del RFC de María García) quedó **fuera** de `auditoria.cambios_clientes` (en el LAB-01, la modificación del RFC de María García; confírmalo con tu cronología). Solo se detecta porque una segunda fuente independiente, la bitácora con `log_statement = 'mod'`, registró tanto el `ALTER` como el `UPDATE`. Si la bitácora también se hubiera desactivado, la manipulación sería invisible.

- **Línea 163:** la ejecuta **`app_ventas`**, cuenta de aplicación que no es dueña de la tabla. El motor la **rechaza** (`ERROR: must be owner of table clientes`, en la línea siguiente del mismo proceso; la consulta 4 la marca como `resultado = ERROR`). El control de privilegios funcionó. Aun así es un hallazgo: una aplicación nunca debería ejecutar DDL, y menos contra la auditoría. Indica que alguien usa la credencial de la aplicación de forma interactiva.
- **Línea 169:** la ejecuta **`postgres`**, superusuario, y **tiene éxito**. El control quedó desactivado de verdad. Muestra que la auditoría basada en disparadores no protege contra el administrador: quien custodia la evidencia puede apagarla.

**¿Qué limitación tiene la conciliación si `log_statement` estuvo en `none` durante algún periodo?**
La conciliación solo puede comparar lo que quedó registrado. Un cambio hecho mientras `log_statement = 'none'` no deja línea, así que **la ausencia de una sentencia en la bitácora no prueba que el cambio no ocurrió**. Ejemplo concreto: la creación de `dba.bitacora` existe en el motor pero no en la bitácora. Mitigaciones: comparar el estado actual del catálogo (objetos, privilegios, disparadores: E2, E3) con instantáneas anteriores para detectar diferencias sin línea que las explique; vigilar en la bitácora los mensajes de recarga de configuración (`parameter "log_statement" changed to ...`) y los `ALTER SYSTEM`; y declarar los periodos sin cobertura como limitación (expediente, sección 9).

**¿Quién debería realizar la conciliación?**
**Otra persona**, no el DBA que hizo los cambios: Auditoría interna, o un segundo administrador sin participación en los cambios revisados. Si quien ejecuta los cambios también decide cuáles estaban autorizados, puede dejar fuera los propios; es el mismo principio de separación de funciones de la Actividad 2. El DBA puede preparar el extracto, pero quien concilia debe poder obtenerlo por sí mismo (lectura de `dba.bitacora` o del archivo con hash) y firmar el acta.
