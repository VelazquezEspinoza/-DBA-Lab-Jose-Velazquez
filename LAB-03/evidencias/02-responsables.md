# Actividad 2 — Propietarios, custodios y usuarios

**Insumo:** matriz de gobierno de datos de la Unidad II (LAB-03, Actividad 11), ampliada con las figuras de la sección 4.2 de la guía y con los objetos creados en la Unidad III.

| Figura | Responsabilidad |
|---|---|
| **Propietario** | Decide para qué se usa el dato, quién accede y cuándo se corrige o elimina |
| **Custodio** | Opera y protege el dato según las decisiones del propietario |
| **Usuario** | Usa el dato para una finalidad autorizada |

## 1. Matriz de responsables

| Conjunto de datos | Propietario | Custodio | Usuarios autorizados | Quién aprueba accesos | Quién aprueba correcciones |
|---|---|---|---|---|---|
| `comercial.public.clientes` (PostgreSQL) | Gerencia Comercial | DBA | `app_ventas` (alta y actualización); soporte (`soporte_ana`) solo mediante la vista enmascarada de la U2; analítica, solo agregados | Gerencia Comercial | Gerencia Comercial (ejecuta el DBA con folio, POL-06) |
| `auditoria.cambios_clientes` (PostgreSQL) | Auditoría interna | DBA (operación técnica, sin facultad de modificar filas) | Auditoría interna (lectura); Oficial de protección de datos, solo para atender incidentes | Auditoría interna | **Nadie corrige**: es evidencia. Solo se depura por vencimiento (POL-03) con autorización de Auditoría interna y Jurídico |
| Bitácora de PostgreSQL (archivo del colector) | Seguridad de la información | DBA + administrador del sistema operativo | DBA y Auditoría interna; Seguridad de la información en incidentes | Seguridad de la información | Nadie corrige. En las **copias** exportadas se ocultan secretos (E5), nunca en el original |
| `dba.bitacora` (vista, PostgreSQL) | Seguridad de la información (mismo dueño que la bitácora que expone) | DBA | DBA y Auditoría interna | Seguridad de la información | — (vista de solo lectura) |
| `gobierno.solicitudes_cambio` (PostgreSQL) | Comité de cambios | DBA | Comité de cambios (escritura); Auditoría interna (lectura); DBA (lectura) | Comité de cambios | Comité de cambios. Un folio aprobado no se modifica: se cancela y se emite otro |
| `comercial.clientes` (MongoDB) | Gerencia Comercial (el mismo dueño que en PostgreSQL: es el mismo cliente) | DBA | Aplicación de la tienda en línea; soporte con proyección limitada | Gerencia Comercial | Gerencia Comercial |
| `comercial.system.profile` (MongoDB) | Jefatura de TI / Operaciones | DBA | DBA (análisis de desempeño); Auditoría interna (lectura) | Jefatura de TI | Nadie corrige: se sobrescribe sola (colección limitada) |
| Bitácora de `mongod` | Seguridad de la información | DBA + administrador del SO | DBA, Auditoría interna | Seguridad de la información | Nadie corrige |
| `auditoria.instantaneas_privilegios` (MongoDB) | Auditoría interna | DBA | Auditoría interna, DBA (lectura) | Auditoría interna | Nadie corrige |

> **Propietario técnico ≠ propietario del dato.** En el catálogo (Actividad 4) todas las tablas aparecen con `propietario_tecnico = postgres`: es el rol dueño del objeto en el motor. El propietario del dato es un área de la organización.

## 2. Preguntas

**¿Por qué el propietario de `auditoria.cambios_clientes` no debería ser el mismo que opera `clientes`?**
Por **separación de funciones**. La auditoría sirve para revisar a quienes modifican `clientes`. Si el mismo responsable decide sobre los datos y sobre su evidencia, puede alterar un dato y después borrar o "corregir" su rastro sin que nadie lo detecte. El LAB-01 lo mostró técnicamente: `postgres` desactivó `trg_auditoria_clientes`, modificó y lo volvió a activar. Asignar la propiedad a Auditoría interna hace que cualquier depuración o acceso dependa de alguien que no tiene interés en el resultado.

**¿Quién debería poder leer las bitácoras y la vista `dba.bitacora`?**
Solo el DBA (custodio) y Auditoría interna; Seguridad de la información cuando atiende un incidente. En el LAB-01 la bitácora mostró la contraseña de `CREATE ROLE rol_temporal ... PASSWORD 'Temporal_Practica_2026'` (línea 37) y, con `log_statement = 'mod'`, también guarda los valores de cada `INSERT` y `UPDATE`, es decir, datos personales. Por eso la vista vive en el esquema `dba`, sin privilegios para `PUBLIC`, y toda copia que salga del servidor se revisa y se oculta (E5) antes de compartirse.

**¿Qué ocurre con la responsabilidad sobre un dato cuando nadie la tiene asignada?**
Nadie decide y todos actúan. Si nadie es dueño del RFC, cualquiera con privilegio `UPDATE` lo "corrige" según su criterio, nadie aprueba ni revisa, y ante un cambio indebido no hay contra qué compararlo: sin propietario no hay regla, y sin regla no puede afirmarse que el cambio fue indebido. Ese es el problema inicial de la unidad: la bitácora dice **qué** pasó con el RFC de María García, pero sin responsables asignados no puede decir si estaba **permitido** ni **a quién** corresponde responder.
