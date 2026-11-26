# LAB-03 — Políticas prácticas, gobierno de datos y evidencias

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
**Unidad III:** Auditoría, trazabilidad y gobierno práctico de datos (temas 3.2.5, 3.3, 3.4)
**Motores:** PostgreSQL 16 (servidor del LAB-01) · MongoDB 7 (referencia del LAB-02)
**Alumno:** ⟨nombre⟩ · **Fecha:** ⟨fecha⟩

El documento principal es **[EXPEDIENTE.md](EXPEDIENTE.md)**, la evidencia oficial de la Unidad III.

## Estructura

```
LAB-03/
├── EXPEDIENTE.md                     Expediente de auditoría interna (A1–A6)
├── README.md
├── scripts/
│   └── generar-evidencias.sh         Genera el diccionario CSV, E1–E5, hashes y copia E6
├── sql/
│   ├── 01-verificaciones-calidad.sql Act. 1: inserciones con error + 9 verificaciones
│   ├── 02-comentarios-diccionario.sql Act. 3: COMMENT de la tabla y de todas las columnas
│   ├── 03-inventario-tablas.sql      Act. 4: inventario de tablas y vistas
│   └── 04-registro-cambios.sql       Act. 7: gobierno.solicitudes_cambio + conciliación
├── politicas/                        Act. 6: POL-01 a POL-06
└── evidencias/
    ├── 01-calidad.md … 06-conciliacion.md
    ├── diccionario-clientes.csv      (lo genera el script)
    ├── E1 … E5, E5 .sha256, SHA256SUMS (los genera el script)
    └── E6-mongodb/                   (copias del LAB-02)
```

## Orden de ejecución

Previo (sección 6 de la guía), en la sesión de administrador:

```sql
\dn                              -- public, auditoria, dba
SHOW log_statement;              -- mod
SELECT count(*) FROM dba.bitacora;  -- > 0
```

| Paso | Dónde | Comando |
|---|---|---|
| 1 | psql | `\i sql/01-verificaciones-calidad.sql` (las inserciones van una sola vez) |
| 2 | psql | `\i sql/02-comentarios-diccionario.sql` |
| 3 | psql | `\i sql/03-inventario-tablas.sql` |
| 4 | psql | `\i sql/04-registro-cambios.sql` (crea `gobierno`, folio CAM-2026-014, `canal_alta`) |
| 5 | terminal, en `LAB-03/` | `bash scripts/generar-evidencias.sh` |

Si tu sesión de administrador no es `psql -U postgres -d comercial` (por ejemplo, Docker), indícalo al script:

```bash
PSQL="docker exec -i <contenedor> psql -U postgres -d comercial" LAB02=../LAB-02 bash scripts/generar-evidencias.sh
```

El script oculta **cualquier** `PASSWORD '...'` (no solo la de la guía), exporta también los archivos de bitácora rotados, se detiene si queda alguna contraseña visible y genera `evidencias/SHA256SUMS`.

> Todos los scripts se probaron en PostgreSQL 16 contra una réplica de los objetos del LAB-01 (`clientes`, `auditoria.cambios_clientes` con `trg_auditoria_clientes`, `dba.bitacora`, roles `app_ventas` y `soporte_ana`, `log_statement = mod`).

## Qué debes completar con los datos de tu servidor

Busca los marcadores `⟨ ⟩`:

```bash
grep -rn "⟨" --include=*.md .
```

- Nombre, fecha, `⟨servidor-pg⟩`, `⟨servidor-mongo⟩` y forma de despliegue.
- **Ids** de los registros de calidad (en los documentos: 1, 7 y 8).
- **Números de línea y horas** de la bitácora: los documentos usan los del fragmento de la guía (34, 35, 36, 37, 163, 169, 171, 216). Sustitúyelos con la salida de la consulta 4 de `sql/04-registro-cambios.sql`.
- Evento 3 del expediente (incidente del RFC de María García): usa tu cronología del LAB-01.
- Salida del inventario (`04-catalogo.md`, sección 1) y `log_line_prefix` de E1.
- H-08: confirma contra tu matriz de roles de la Unidad II si soporte debía usar solo la vista enmascarada.
- POL-06: la definición de ambiente con la redacción exacta de tu Unidad I.

## Verificación final (sección 16 de la guía)

- [x] Hallazgos de calidad registrados con responsable de la decisión — `evidencias/01-calidad.md`
- [x] Matriz de responsables con propietario, custodio y usuarios — `evidencias/02-responsables.md`
- [x] Comentarios en la tabla y en todas las columnas de `clientes` — `sql/02-…` (consulta de completitud = 0 filas)
- [ ] Diccionario exportado en CSV *(se genera al correr el script)* y completado con clasificación y finalidad — `evidencias/03-diccionario.md`
- [x] Catálogo con al menos cinco conjuntos de datos de los dos motores — 9 en `evidencias/04-catalogo.md`
- [x] Criterio de conservación para los siete tipos de registro — `evidencias/05-conservacion.md`
- [x] Seis políticas con regla verificable y evidencia nombrada — `politicas/`
- [x] Registro de cambios creado y conciliación con la bitácora — `sql/04-…`, `evidencias/06-conciliacion.md`
- [ ] Evidencias E1 a E6 generadas *(se generan al correr el script en tu servidor)*
- [x] `EXPEDIENTE.md` completo, con al menos tres eventos interpretados — 4 eventos

## Commits sugeridos

```bash
git add evidencias/01-calidad.md sql/01-verificaciones-calidad.sql
git commit -m "docs: registra hallazgos de calidad de datos"
git add evidencias/02-responsables.md
git commit -m "docs: agrega matriz de responsables"
git add sql/02-comentarios-diccionario.sql evidencias/03-diccionario.md evidencias/diccionario-clientes.csv
git commit -m "feat: documenta diccionario de datos con COMMENT"
git add sql/03-inventario-tablas.sql evidencias/04-catalogo.md
git commit -m "docs: agrega catalogo minimo de datos"
git add evidencias/05-conservacion.md
git commit -m "docs: agrega criterio de conservacion de bitacoras"
git add politicas/
git commit -m "docs: agrega politicas practicas de datos"
git add sql/04-registro-cambios.sql
git commit -m "feat: agrega registro de solicitudes de cambio"
git add evidencias/06-conciliacion.md evidencias/E* evidencias/SHA256SUMS scripts/
git commit -m "docs: agrega conciliacion y evidencias tecnicas"
git add EXPEDIENTE.md README.md
git commit -m "docs: integra expediente de auditoria interna"
```

Antes de subir `E5-bitacora-postgresql.log` a un repositorio, revísalo: aunque las contraseñas estén ocultas, contiene datos personales de prueba (valores de los `INSERT`/`UPDATE`). Si el repositorio es público, entrega E5 por otro medio y versiona solo su hash.

---

## Preguntas de reflexión (sección 18)

**¿Por qué el gobierno de datos no es "burocracia" en el contexto del problema inicial de la unidad?**
Porque sin él la evidencia técnica no alcanza para concluir nada. La bitácora y la tabla de auditoría mostraron que el RFC de María García cambió, quién lo cambió y cuándo. Pero no podían decir si el cambio estaba permitido (no había política), si debía haberse aprobado (no había registro de cambios) ni a quién le correspondía decidir el valor correcto (no había propietario). Cada elemento de gobierno de este laboratorio responde una de esas preguntas y es mínimo: una tabla de folios, unos comentarios, una matriz. La burocracia es el trámite que no produce evidencia; esto es lo que convierte un registro en una prueba.

**¿Qué diferencia hay entre el propietario técnico de una tabla en PostgreSQL y el propietario del dato?**
El propietario técnico (`relowner`, `postgres` en todo el catálogo) es el **rol** que puede alterar, eliminar u otorgar privilegios sobre el objeto: una facultad del motor. El propietario del dato es un **área de la organización** (Gerencia Comercial) que decide para qué se usa, quién accede y cuándo se corrige o elimina: una responsabilidad. El primero ejecuta; el segundo decide. Confundirlos lleva a que el DBA, por tener el poder técnico, tome decisiones que no le corresponden, como corregir el RFC del registro 7.

**¿Por qué una política sin evidencia no supera una auditoría?**
Porque el auditor no evalúa lo que la organización dice que hace, sino lo que puede **demostrar** que hizo. "Todo cambio requiere autorización" es una afirmación; la línea 216 de la bitácora junto al folio CAM-2026-014, con la hora dentro de su ventana, es evidencia. Si la política no nombra qué registro prueba su cumplimiento, no hay forma de distinguir una organización que la cumple de una que solo la escribió. Por eso cada política del expediente dice qué evidencia la sostiene y declara cuándo esa evidencia hoy no existe.

**¿Qué parte del expediente sería la más difícil de mantener actualizada? ¿Cómo lo resolverías?**
La **conciliación de cambios**. Crece con cada cambio, depende de asociar a mano sentencias con folios, la bitácora rota y se pierde, y exige que alguien distinto del DBA la haga cada mes. La resolvería así: agregar al registro de cambios un campo con el objeto o patrón afectado, para automatizar la consulta 4 de `04-registro-cambios.sql`; programar la extracción mensual de la bitácora con hash antes de que rote; y entregar a Auditoría interna acceso de lectura para que la ejecute por sí misma. El catálogo y el diccionario se mantienen mejor porque viven en el motor (`COMMENT`) y se regeneran con un script.

**¿Qué hallazgo de tu expediente tiene mayor impacto y por qué?**
**H-01**, la desactivación de `trg_auditoria_clientes` por el superusuario sin autorización. Los demás hallazgos son fallas que la auditoría permite detectar; este **apaga la capacidad de detectar**. Afectó un dato fiscal, quedó fuera de la evidencia principal y solo se descubrió porque existía una segunda fuente independiente (la bitácora con `log_statement = mod`). Además muestra una limitación de diseño (L1): el custodio de la evidencia puede manipularla. Por eso no se resuelve solo con una regla, sino con separación de funciones y con alertas que el DBA no controle.

**¿Por qué documentar una limitación es preferible a ocultarla ante una auditoría?**
Porque una limitación documentada se convierte en un **riesgo aceptado** por quien tiene autoridad para aceptarlo, y una limitación oculta se convierte en un **hallazgo** cuando el auditor la descubre, junto con la pérdida de confianza en todo lo demás. Si el expediente afirmara que se auditan todos los accesos a datos personales, bastaría una consulta `SELECT` sin rastro para invalidarlo. Al declarar que las lecturas no se auditan sin `pgaudit` (L2), la organización decide con información si invierte en ese control o acepta el riesgo, y el expediente conserva su credibilidad.
