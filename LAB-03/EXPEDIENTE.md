# Expediente de auditoría interna — Base comercial

**Organización:** Comercializadora Norte S.A. de C.V.
**Solicitante:** Auditoría interna
**Evidencia oficial de la Unidad III:** "Configuración o diseño de auditoría con bitácora interpretada" (programa oficial, sección 5)

> Convención: las referencias `E1`…`E6` y `evidencias/…` son archivos de esta carpeta; "línea N" es el número `num` de la vista `dba.bitacora`, que coincide con la línea del archivo `E5-bitacora-postgresql.log`. Los valores entre ⟨ ⟩ se completan con los datos de mi servidor.

---

## 1. Alcance

| Elemento | Detalle |
|---|---|
| Sistema 1 | PostgreSQL 16 — ⟨servidor-pg⟩ — base `comercial` — despliegue: ⟨nativo / Docker / máquina virtual⟩ |
| Sistema 2 | MongoDB 7 Community — ⟨servidor-mongo⟩ — base `comercial` — despliegue: ⟨…⟩ |
| Periodo revisado | Del ⟨inicio del LAB-01⟩ al ⟨fecha de generación de E1–E5⟩ |
| Solicitudes atendidas | A1 a A6 (sección 5 de la guía) |
| Responsable del expediente | ⟨nombre⟩, en función de DBA (custodio) |
| Fuera de alcance | Procedimientos de respaldo y restauración (Unidad V); auditoría de lecturas; aplicaciones cliente |

---

## 2. Configuración de auditoría (A3)

| Mecanismo | Configuración | Qué registra | Evidencia |
|---|---|---|---|
| Colector de bitácoras de PostgreSQL | `logging_collector = on` | Archivo en `log_directory` | `E1-configuracion-registro.txt` |
| Accesos | `log_connections = on`, `log_disconnections = on` | Conexión, usuario, base, origen y duración de la sesión | `E1` |
| Sentencias | `log_statement = mod` | DDL, privilegios y `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE` | `E1`; líneas `statement:` de `E5` |
| Contexto de cada línea | `log_line_prefix = ⟨valor de E1⟩` | Momento, proceso, usuario, base, aplicación, cliente | `E1` |
| Sentencias con error | `log_min_error_statement = error` | La sentencia que provocó cada error | `E1`; p. ej., el `ERROR` posterior a la línea 163 |
| Auditoría de datos (LAB-01, Parte B) | Disparador `trg_auditoria_clientes` → `auditoria.cambios_clientes` | Quién, cuándo, aplicación, operación, valores antes y después de cada cambio en `clientes` | `E3-disparadores.txt` (`tgenabled = O`); `E4-muestra-auditoria.txt` |
| Lectura de la bitácora por SQL | Vista `dba.bitacora` | — | `04-catalogo.md` (CAT-06) |
| Perfilador de MongoDB (LAB-02) | `system.profile`, colección limitada de 1 MB | Operaciones con sus filtros y duración | `E6-mongodb/system-profile.json` |
| Bitácora de `mongod` (LAB-02) | `systemLog` | Conexiones, autenticación, eventos del servidor | `E6-mongodb/bitacora-mongod.log` |
| Instantáneas de privilegios (LAB-02) | `auditoria.instantaneas_privilegios` | Estado de usuarios y roles en una fecha | `E6-mongodb/09-comparacion.md` |

**Limitación de E1:** demuestra la configuración **al momento de capturarla** (`capturado_en`), no durante todo el periodo. Lo que sí sabemos del periodo: `log_statement` valió `none` al menos mientras se creó `dba.bitacora` (H-07).

---

## 3. Bitácora interpretada (A3, A5)

Formato del LAB-01, Actividad 17. Fuente: `E5-bitacora-postgresql.log` (hash en `E5-bitacora-postgresql.sha256`) y `E4-muestra-auditoria.txt`.

### Evento 1 — Creación de una cuenta con la contraseña expuesta (línea 37)

| Campo | Interpretación |
|---|---|
| **Quién** | `user=postgres` (superusuario) |
| **Cuándo** | 2026-10-25 22:50:09.375 |
| **Desde dónde** | ⟨`client=` y `app=` de la línea, según `log_line_prefix`⟩ |
| **Qué ocurrió** | `CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>'`: se creó una cuenta con permiso de conexión |
| **Tipo de evento** | Cambio de identidades y privilegios (DDL) |
| **Qué prueba** | Que la cuenta existió y quién la creó. No tiene folio en `gobierno.solicitudes_cambio` (`06-conciliacion.md`). La bitácora original guarda la contraseña **en claro**: cualquiera que lea la bitácora o `dba.bitacora` obtiene una credencial válida. En E5 se ocultó antes de calcular el hash |
| **Hallazgos** | H-04 |

### Evento 2 — Intento de la aplicación de desactivar la auditoría (línea 163)

| Campo | Interpretación |
|---|---|
| **Quién** | `user=app_ventas` (cuenta de la aplicación de ventas) |
| **Cuándo** | 2026-10-25 22:50:53.460 |
| **Desde dónde** | ⟨`client=` / `app=` de la línea⟩. Si `app=` es `psql` y no el nombre de la aplicación, la credencial se usó de forma interactiva |
| **Qué ocurrió** | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes`. La siguiente línea del mismo proceso es `ERROR: must be owner of table clientes`: el motor lo **rechazó** |
| **Tipo de evento** | Intento de manipulación de un control de auditoría; error de autorización |
| **Qué prueba** | Que la credencial de la aplicación se usó para intentar apagar la auditoría y que el control de privilegios lo impidió. No prueba quién era la persona detrás de la credencial |
| **Hallazgos** | H-02 |

### Evento 3 — Incidente del RFC de María García: modificación auditada y ventana sin auditoría (líneas 169–171 y `auditoria.cambios_clientes`)

| Campo | Interpretación |
|---|---|
| **Quién** | Primera modificación: ⟨`usuario_sesion` / `aplicacion` de la fila ⟨id_evento⟩ de `auditoria.cambios_clientes`⟩. Desactivación y modificación sin auditoría: `user=postgres` |
| **Cuándo** | Primera modificación: ⟨momento de la fila de auditoría⟩. Desactivación: 22:50:53.549 (línea 169); reactivación: 22:50:53.554 (línea 171) |
| **Desde dónde** | ⟨`client=` de las líneas 169–171 y `ip_cliente` de la fila de auditoría, si existe⟩ |
| **Qué ocurrió** | 1) El RFC de María García se modificó con el disparador activo: quedó una fila `UPDATE` con `valores_antes`/`valores_despues` en `auditoria.cambios_clientes`. 2) `postgres` desactivó `trg_auditoria_clientes`, ejecutó ⟨el `UPDATE` de las líneas entre 169 y 171⟩ y volvió a activarlo. Ese segundo cambio **no** está en `auditoria.cambios_clientes`, pero **sí** en la bitácora, porque `log_statement = mod` registra el `UPDATE` |
| **Tipo de evento** | Modificación de dato personal (fiscal) + desactivación de un control de auditoría por el administrador |
| **Qué prueba** | Que el estado actual del RFC no puede explicarse solo con la tabla de auditoría: hay que correlacionar dos fuentes independientes. También prueba que el superusuario puede apagar la auditoría de datos, y que ninguno de estos cambios tenía folio |
| **Hallazgos** | H-01, H-05 (el `GRANT UPDATE` de la línea 35 habilitó la modificación por `app_ventas`, si así ocurrió en tu cronología) |

> Completa los ⟨ ⟩ de este evento con `LAB-01/evidencias/` (cronología y evidencias de auditoría del dato y de la manipulación). La secuencia exacta del LAB-01 manda sobre esta redacción.

### Evento 4 — Cambio autorizado (línea 216)

| Campo | Interpretación |
|---|---|
| **Quién** | `user=postgres` |
| **Cuándo** | 2026-10-25 22:54:26.533 |
| **Desde dónde** | ⟨`client=` de la línea⟩ |
| **Qué ocurrió** | `ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20)` y su `COMMENT` |
| **Tipo de evento** | Cambio de estructura en producción |
| **Qué prueba** | Que el cambio coincide con el folio **CAM-2026-014**, aprobado por el Comité de cambios para `produccion`, y que se ejecutó dentro de su ventana. Es el único cambio de la bitácora que cumple POL-06 |
| **Hallazgos** | Ninguno |

---

## 4. Elementos de gobierno (A1, A2)

| Elemento | Contenido | Evidencia |
|---|---|---|
| Responsables | Propietario, custodio, usuarios y quién aprueba accesos y correcciones para 9 conjuntos de datos de ambos motores | `evidencias/02-responsables.md` |
| Catálogo | 9 conjuntos de datos (CAT-01 a CAT-09) con ubicación, propietario, clasificación, datos personales, finalidad y conservación | `evidencias/04-catalogo.md`; `sql/03-inventario-tablas.sql` |
| Diccionario | `COMMENT` en la tabla y en sus 11 columnas (consulta de completitud: 0 columnas sin comentario) + clasificación, finalidad, control y regla de calidad | `evidencias/diccionario-clientes.csv`; `evidencias/03-diccionario.md`; `sql/02-comentarios-diccionario.sql` |
| Calidad de datos | 9 hallazgos (C1–C9) con responsable de la decisión | `evidencias/01-calidad.md`; `sql/01-verificaciones-calidad.sql` |

Respuesta a **A1**: los datos existen en dos motores y nueve conjuntos; el propietario del dato de clientes es la Gerencia Comercial en ambos; la evidencia pertenece a Auditoría interna; el DBA es custodio de todos.
Respuesta a **A2**: todas las columnas de `clientes` están documentadas; son datos personales `nombre`, `correo`, `telefono`, `rfc`, `edad`, `ciudad` y `codigo_postal`; `segmento` es un dato derivado que puede constituir perfilamiento.

---

## 5. Conservación (A3)

Criterio para los siete tipos de registro en `evidencias/05-conservacion.md`. Resumen:

| Registro | Periodo propuesto |
|---|---|
| Accesos de PostgreSQL | 90 días en línea + 1 año archivado |
| Cambios de privilegios y estructura | 3 años (extracto con contraseñas ocultas) |
| Modificaciones de datos (`mod`) | 90 días en línea + 1 año archivado; plazo a confirmar con Jurídico |
| `auditoria.cambios_clientes` | Vida del cliente + plazo a confirmar con Jurídico; después se seudonimiza |
| Bitácora de `mongod` | 90 días en línea + 1 año archivado |
| `system.profile` | Exportar antes de cada revisión; 90 días |
| Instantáneas de privilegios | 3 años |

Integridad: SHA-256 de cada archivo exportado (`E5-bitacora-postgresql.sha256`, `evidencias/SHA256SUMS`), guardado aparte de las bitácoras.

---

## 6. Políticas (A4)

| ID | Política | Regla clave (resumen) | Evidencia que la sostiene | Evidencia faltante |
|---|---|---|---|---|
| POL-01 | Acceso | El propietario aprueba con folio; conciliación mensual de `GRANT`/`REVOKE`; revisión trimestral | Bitácora (líneas 34, 35, 37); `E2`; `gobierno.solicitudes_cambio` | Acta de revisión trimestral |
| POL-02 | Respaldo | Diario; prueba de restauración trimestral por otra persona | — | Toda (Unidad V) |
| POL-03 | Retención | Plazos del catálogo; seudonimizar al vencer; nada se borra con un incidente abierto | `05-conservacion.md`; `04-catalogo.md` | Actas de eliminación |
| POL-04 | Restauración | Propietario + TI autorizan con folio; exportar la evidencia antes de restaurar | — | Toda (Unidad V) |
| POL-05 | Datos sensibles | Acceso por finalidad; disparador siempre activo; extracciones revisadas | `E2`, `E3`, `E4`, `E5` | Registro de lecturas |
| POL-06 | Cambios en producción | Folio aprobado + ventana + conciliación mensual por otra persona | `gobierno.solicitudes_cambio`; `06-conciliacion.md`; línea 216 | Pruebas previas en otro ambiente |

Textos completos en `politicas/POL-01-acceso.md` … `politicas/POL-06-cambios-produccion.md`.

---

## 7. Conciliación de cambios (A5)

Detalle en `evidencias/06-conciliacion.md`; script en `sql/04-registro-cambios.sql`.

| Resultado | Líneas |
|---|---|
| Autorizado (folio, aprobado, dentro de la ventana) | 216 y su `COMMENT` (CAM-2026-014) |
| Sin folio — preparación de los laboratorios | Creación de `auditoria`, `dba`, `gobierno`, disparador, `COMMENT` del diccionario, línea 34 |
| Sin folio — **hallazgo** | 35, 36, 37, 163, 169, 171 |
| No determinable (sin registro) | Creación de `dba.bitacora` (`log_statement = none`) |

Respuesta a **A5**: **no** puede afirmarse que los cambios de producción de las últimas semanas estaban autorizados. Solo uno lo estaba; otros seis no tienen folio, y uno de ellos desactivó la auditoría de datos.

---

## 8. Hallazgos

Ningún hallazgo se corrigió durante la elaboración del expediente: los registros 7 y 8 siguen en `clientes`, no se crearon folios retroactivos y los privilegios de E2 se reportan tal como están.

| ID | Hallazgo | Fuente | Severidad | Impacto | Recomendación | Decisión requerida de |
|---|---|---|---|---|---|---|
| H-01 | El superusuario desactivó y reactivó `trg_auditoria_clientes` sin folio; los cambios intermedios no quedaron en la auditoría de datos | Bitácora, líneas 169–171; `06-conciliacion.md` | **Alta** | Un cambio de un dato fiscal (RFC) sin rastro en la evidencia principal; la auditoría puede apagarse sin que nadie lo apruebe | Prohibir la desactivación salvo folio aprobado por Auditoría (POL-05, POL-06); alertar sobre `DISABLE TRIGGER` en la bitácora; revisar diariamente E3; limitar el uso cotidiano de `postgres` | Auditoría interna; Jefatura de TI |
| H-02 | La cuenta `app_ventas` intentó desactivar la auditoría (rechazado por el motor) | Línea 163 + `ERROR` siguiente | **Media** | Indica uso interactivo de una credencial de aplicación con intención de evadir controles; el control de privilegios funcionó | Investigar quién usó la credencial; rotar su contraseña; restringir el origen de conexión de `app_ventas` en `pg_hba.conf` | Seguridad de la información |
| H-03 | Bitácora y vista `dba.bitacora` contienen datos personales (valores de `INSERT`/`UPDATE` con `log_statement = mod`) | `E5`; `05-conservacion.md` | **Media** | Una copia de la bitácora es una copia de datos personales | Acceso solo DBA/Auditoría; cifrar archivados; aplicar POL-03 | Seguridad de la información; Oficial de protección de datos |
| H-04 | Rol `rol_temporal` creado sin folio y con la contraseña en claro en la bitácora | Línea 37 | **Alta** | Credencial expuesta a cualquiera que lea la bitácora; cuenta sin autorización | Verificar que el rol se eliminó o cambiar la contraseña; crear roles con contraseña ya cifrada o con `\password`; revisar toda extracción antes de compartirla | Seguridad de la información; Jefatura de TI |
| H-05 | Cambios de privilegios sin folio (`REVOKE` a `soporte_ana`, `GRANT UPDATE` a `app_ventas`) | Líneas 34–35; `E2` | **Media** | Privilegios de modificación sin aprobación del propietario; el `GRANT` habilitó cambios sobre `clientes` | Validar con el propietario si `app_ventas` debe tener `UPDATE`; aplicar POL-01 | Gerencia Comercial |
| H-06 | Cambio de estructura sin folio (`ADD COLUMN segmento`) | Línea 36 | **Media** | Columna nueva con posible perfilamiento sin finalidad aprobada | Regularizar mediante revisión del Comité (sin folio retroactivo); documentar la finalidad | Comité de cambios; Gerencia Comercial |
| H-07 | Hueco de evidencia: la creación de `dba.bitacora` no está en la bitácora (`log_statement = none` en ese momento) | `06-conciliacion.md` | **Media** | No puede demostrarse qué más ocurrió en ese periodo | Declarar el periodo sin cobertura; comparar el catálogo contra instantáneas; alertar sobre cambios de `log_statement` | Auditoría interna |
| H-08 | `soporte_ana` tiene `SELECT` directo sobre `clientes`; la matriz de la U2 prevé acceso de soporte mediante vista enmascarada | `E2-privilegios.txt` vs matriz U2 | **Media** *(confirmar contra tu matriz)* | Soporte puede ver RFC, correo y teléfono completos | Revocar `SELECT` sobre la tabla y otorgarlo sobre la vista enmascarada, con folio | Gerencia Comercial |
| H-09 | Posible cliente duplicado (ids 1 y 7) | `01-calidad.md` (C1) | **Media** | Comunicaciones y facturación dobles; conteos inflados | El propietario decide la fusión; después, índice único | Gerencia Comercial |
| H-10 | RFC inválido (id 7) o ausente (id 8) | `01-calidad.md` (C2, C5) | **Media** | Facturas con RFC incorrecto o imposibles de emitir | Solicitar la constancia fiscal al cliente; `CHECK` de formato | Gerencia Comercial; Facturación |
| H-11 | Registro 8 con correo, edad, teléfono y código postal inválidos | `01-calidad.md` (C3, C4, C6, C7) | **Media** | Cliente no contactable; analítica distorsionada | Confirmar los datos con el cliente | Gerencia Comercial |
| H-12 | Ciudad escrita de varias formas | `01-calidad.md` (C8) | **Baja** | Reportes por ciudad incorrectos | Catálogo de ciudades | Gerencia Comercial |
| H-13 | La tabla `clientes` no tiene restricciones `CHECK`/`UNIQUE` que impidan los errores anteriores | `01-calidad.md` (C9); `sql/01-verificaciones-calidad.sql` | **Media** | Los errores se repetirán | Aprobar las restricciones propuestas (con `NOT VALID`) | Gerencia Comercial; Comité de cambios |
| H-14 | `system.profile` (1 MB) y `getLog` pierden información sin intervención | `05-conservacion.md` | **Media** | Evidencia de MongoDB incompleta para periodos pasados | Exportación periódica; `systemLog.path` en disco con rotación | Jefatura de TI |
| H-15 | No hay respaldos ni restauraciones verificados | POL-02, POL-04 | **Media** | Riesgo de pérdida de datos y de evidencia | Implementar en la Unidad V | Jefatura de TI |
| H-16 | La conciliación depende de asociar manualmente sentencias y folios; las sentencias de varias líneas solo muestran la primera | `sql/04-registro-cambios.sql` | **Baja** | Riesgo de clasificar mal un cambio | Agregar al folio un campo con el objeto afectado; revisar las sentencias multilínea en `E5` | DBA; Auditoría interna |

---

## 9. Limitaciones conocidas y riesgos aceptados (A6)

| # | Limitación | Estado | Riesgo que se acepta | Debe aceptarlo formalmente |
|---|---|---|---|---|
| L1 | El superusuario puede desactivar el disparador, cambiar `log_statement`, borrar filas de `auditoria.cambios_clientes` y el archivo de bitácora | **Verificado** (LAB-01, Act. 14; líneas 169–171) | Manipulación de evidencia por el custodio | Dirección / Comité de riesgos, con Auditoría interna |
| L2 | No se auditan **lecturas**: sin `pgaudit`, `log_statement = mod` no registra `SELECT` | **Verificado** (configuración E1) | Consulta indebida de datos personales sin rastro | Oficial de protección de datos; Gerencia Comercial |
| L3 | MongoDB Community no tiene auditoría nativa; se usan perfilador, bitácora e instantáneas | **Verificado** (LAB-02, `09-comparacion.md`) | Cambios de privilegios entre instantáneas sin registro | Jefatura de TI; Auditoría interna |
| L4 | La auditoría nativa de MongoDB Enterprise (`auditLog`) y `pgaudit` | **Documentado, no practicado** | — (posible tratamiento de L2 y L3) | — |
| L5 | E1 demuestra la configuración solo al momento de capturarla; hubo un periodo con `log_statement = none` | **Verificado** (H-07) | Huecos de evidencia no detectados | Auditoría interna |
| L6 | El perfilador de MongoDB se sobrescribe y `getLog` vive en memoria | **Verificado** (LAB-02) | Pérdida de evidencia de desempeño | Jefatura de TI |
| L7 | La bitácora guarda secretos y datos personales | **Verificado** (línea 37; `mod`) | Exposición si se comparte sin revisar | Seguridad de la información |
| L8 | Respaldo, restauración y retención automática | **Documentado, no practicado** (Unidad V) | Pérdida de datos o conservación excesiva | Jefatura de TI; Jurídico |
| L9 | Un solo servidor para todos los ambientes; no hay ambiente de pruebas separado | **Verificado** (diseño de los laboratorios) | Cambios no probados antes de producción | Comité de cambios |
| L10 | Los plazos de conservación no están validados por Jurídico | **Documentado** | Plazos insuficientes o excesivos | Jurídico |

Documentar estas limitaciones no las resuelve, pero permite que quien tiene la autoridad decida si las acepta, las mitiga o asigna presupuesto para resolverlas. Una limitación oculta es un riesgo que nadie aceptó.

---

## 10. Índice de evidencias

Los hashes SHA-256 de todos los archivos de `evidencias/` están en `evidencias/SHA256SUMS` (generado por `scripts/generar-evidencias.sh`). Verificación: `cd evidencias && sha256sum -c SHA256SUMS`.

| Archivo | Contenido | Actividad | Hash SHA-256 |
|---|---|---|---|
| `evidencias/01-calidad.md` | Hallazgos de calidad C1–C9 | 1 | — |
| `evidencias/02-responsables.md` | Matriz de responsables | 2 | — |
| `evidencias/03-diccionario.md` | Diccionario completado | 3 | — |
| `evidencias/diccionario-clientes.csv` | Diccionario exportado del motor | 3 | ⟨SHA256SUMS⟩ |
| `evidencias/04-catalogo.md` | Catálogo CAT-01 a CAT-09 | 4 | — |
| `evidencias/05-conservacion.md` | Criterio de conservación | 5 | — |
| `evidencias/06-conciliacion.md` | Conciliación bitácora ↔ folios | 7 | — |
| `evidencias/E1-configuracion-registro.txt` | Parámetros de registro vigentes | 8 | ⟨SHA256SUMS⟩ |
| `evidencias/E2-privilegios.txt` | Privilegios vigentes sobre tablas | 8 | ⟨SHA256SUMS⟩ |
| `evidencias/E3-disparadores.txt` | Disparadores y su estado | 8 | ⟨SHA256SUMS⟩ |
| `evidencias/E4-muestra-auditoria.txt` | Últimos 10 eventos de auditoría (solo metadatos) | 8 | ⟨SHA256SUMS⟩ |
| `evidencias/E5-bitacora-postgresql.log` | Bitácora exportada, contraseñas ocultas | 8 | ⟨valor de `E5-bitacora-postgresql.sha256`⟩ |
| `evidencias/E5-bitacora-postgresql.sha256` | Hash de E5 | 8 | — |
| `evidencias/E6-mongodb/system-profile.json` | Perfilador de MongoDB | LAB-02 | ⟨hash del LAB-02⟩ |
| `evidencias/E6-mongodb/bitacora-mongod.log` | Bitácora de `mongod` | LAB-02 | ⟨hash del LAB-02⟩ |
| `evidencias/E6-mongodb/09-comparacion.md` | Comparación PostgreSQL / MongoDB | LAB-02 | — |
| `politicas/POL-01…POL-06` | Políticas prácticas | 6 | — |
| `sql/01…04` | Scripts que generan las evidencias | 1, 3, 4, 7 | — |
