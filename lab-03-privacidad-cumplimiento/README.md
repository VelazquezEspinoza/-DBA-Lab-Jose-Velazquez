# LAB-03 — Privacidad, cumplimiento y gobierno de los datos

**Unidad II · Tema 2.5** · Motor: PostgreSQL 16 · Modalidad: individual
Repositorio: `dba-19706-2026-2-apellido-nombre/unidad-02/lab-03-privacidad-cumplimiento/`

> Nota: los scripts están en `sql/`. Las evidencias están en `evidencias/`. Ejecuta los scripts en orden (01 → 02 → 03) y agrega tus capturas solo donde aporten evidencia relevante.

---

## 1. Introducción
La empresa ficticia *Comercializadora Norte S.A. de C.V.* almacena datos de clientes (id, nombre, correo, teléfono, RFC, edad, ciudad, código postal, fecha de alta). Aunque la base de datos pueda estar bien configurada técnicamente, existen riesgos de privacidad: recolección excesiva, usos para finalidades no informadas, retención indefinida, acceso amplio y copias en desarrollo con datos reales. Este laboratorio traduce los principios de la LFPDPPP (finalidad, minimización, proporcionalidad, responsabilidad, derechos ARCO) en decisiones concretas de administración de PostgreSQL. Se trata de una referencia conceptual; las decisiones jurídicas corresponden a Privacidad/Jurídico.

## 2. Inventario de datos
Todos los campos son datos personales (directos o indirectos); ninguno es sensible en sentido legal. Detalle en [`evidencias/01-inventario-datos.md`](evidencias/01-inventario-datos.md).

| Campo | Clasificación | Tipo |
|---|---|---|
| id | Personal indirecto (seudónimo) | Interno |
| nombre, correo, telefono | Personal directo | Confidencial |
| rfc | Personal directo, riesgo alto | Restringido |
| edad, ciudad, codigo_postal | Personal indirecto (cuasi-identificadores) | Confidencial |
| fecha_alta | Personal indirecto | Interno |

## 3. Finalidades
- **Atención al cliente:** id, nombre, correo, teléfono.
- **Facturación:** id, nombre, RFC, código postal fiscal.
- **Analítica:** ciudad, rango de edad y región de CP, siempre agregados.
- **Marketing (secundaria):** solo con base jurídica, aviso y exclusión de opositores (ver evidencia 05).

## 4. Minimización
- Se rechazó la tabla `clientes_soporte` con 9 campos. Soporte **no necesita** RFC, edad, ciudad, CP ni fecha de alta.
- Se creó `clientes_soporte(id, nombre, correo, telefono)` (`sql/01-minimizacion.sql`).

**Actividad 2 — respuestas:**
1. No, no todos los campos son necesarios.
2. Soporte no necesita el RFC: es un dato fiscal; su exposición no aporta a la atención y facilita fraude.
3. La edad no es necesaria para atender solicitudes.
4. El código postal tampoco; salvo que exista una finalidad logística específica.
5. Principio: **minimización** (también necesidad y proporcionalidad).

**Actividad 3 — pregunta:** La información agregada es más apropiada porque analítica solo necesita estadísticas, no identificar personas. Entregar la tabla completa expondría nombre, correo y RFC sin necesidad, aumentaría el impacto de una fuga y violaría limitación de finalidad y minimización.

## 5. Control de acceso
Se aplicó mínimo privilegio (`sql/03-control-acceso.sql`):

| Rol | Acceso | Justificación |
|---|---|---|
| `analista` | `SELECT` sobre `v_analitica_clientes` | Solo estadísticas |
| `soporte` | `clientes_soporte` (`UPDATE` en correo/teléfono) | Atención y rectificación |
| `facturacion` | `SELECT (id, nombre, rfc)` sobre `clientes` | Emisión de facturas |
| `marketing` | `v_marketing_promos` (filtrada) | Finalidad secundaria controlada |

**Actividad 4 — preguntas:**
- *¿Qué puede consultar `analista`?* Solo ciudad, rango de edad y región de CP vía la vista.
- *¿Puede consultar `clientes` directamente?* No (permiso denegado).
- *¿Puede obtener nombre, correo y RFC?* No.
- *Principio de privacidad:* minimización y limitación de finalidad.
- *Principio de seguridad:* mínimo privilegio y segregación de funciones (confidencialidad).

## 6. Derechos ARCO
| Derecho | Implicación técnica |
|---|---|
| **Acceso** | Localizar al titular (p. ej. por correo) en todas las tablas y sistemas; entregar datos y además informar finalidades, transferencias, origen, plazo de conservación y destinatarios (no solo el resultado del `SELECT`). Verificar identidad. |
| **Rectificación** | `UPDATE` solo del campo indicado y autorizado; registrar quién, cuándo, valor anterior/nuevo y folio (trigger de auditoría); propagar a réplicas, analítica y sistemas externos. |
| **Cancelación** | Analizar tablas relacionadas, respaldos, réplicas, logs, exportaciones y terceros; conservar solo lo legalmente obligatorio (bloqueo) y anonimizar/eliminar el resto (evidencia 08). |
| **Oposición** | No siempre implica borrar: se marca la oposición (`oposiciones_finalidad`) y se excluye de esa finalidad mediante vistas/filtros; se conservan los datos necesarios para la relación o por ley. |

**Actividad 6/7 — preguntas:**
- *Información adicional en acceso:* finalidades, base jurídica, destinatarios/transferencias, plazo de conservación, origen de los datos y cómo ejercer otros derechos.
- *¿Cómo comprobar que el cambio fue autorizado?* Mediante folio de solicitud ARCO, verificación de identidad y la tabla `auditoria_clientes`.
- *¿Debe registrarse quién hizo el cambio?* Sí.
- *Importancia de la trazabilidad:* permite demostrar cumplimiento, detectar cambios indebidos y reconstruir lo ocurrido en un incidente.

**Actividad 9 — Oposición**
- *¿Eliminar todo?* No. Solo debe dejarse de usar el dato para la finalidad secundaria.
- *Qué debe mantenerse:* datos necesarios para la relación contractual, facturación y obligaciones legales.
- *Qué debe dejar de usarse:* correo/perfil para promociones.
- *Mecanismos técnicos:* tabla de oposiciones, vistas filtradas, banderas de consentimiento por finalidad, esquemas separados.
- *Por qué no decide solo el DBA:* la procedencia de la oposición es una decisión jurídica y de negocio, no técnica.

## 7. Retención
La retención debe determinarse con base en finalidad, obligaciones legales/contractuales, riesgo y necesidad real; debe documentarse y ejecutarse con una acción final (eliminar/anonimizar). Se propuso un calendario (ver [`evidencias/10-retencion.md`](evidencias/10-retencion.md)). La retención indefinida es incompatible con la minimización.

## 8. Gobierno de datos
Resumen (matriz completa en [`evidencias/11-gobierno-datos.md`](evidencias/11-gobierno-datos.md)):

| Dato | Responsable | Usuarios autorizados | Retención |
|---|---|---|---|
| nombre | Atención al Cliente | Soporte, Facturación | Relación + plazo legal |
| correo | Atención al Cliente | Soporte, Facturación (CFDI) | Relación + 1 año |
| telefono | Atención al Cliente | Soporte | Relación + 1 año |
| rfc | Finanzas | Facturación | 5 años (validar) |
| edad | Analítica | Analítica (rango) | Detalle 2 años |
| ciudad | Analítica | Analítica (vista) | Detalle 2 años |
| codigo_postal | Finanzas / Analítica | Facturación; Analítica (región) | 5 años fiscal / 2 años analítico |

### Actividad 13 — Controles técnicos vs administrativos
| Medida | Técnico | Administrativo | Justificación |
|---|---|---|---|
| Crear roles de PostgreSQL | ✔ | | Se implementa en el motor; su diseño depende de una política. |
| Política de retención | | ✔ | Es una regla organizacional; su ejecución puede automatizarse. |
| Cifrado de datos | ✔ | | Tecnología; la gestión de llaves requiere procedimientos. |
| Procedimiento para solicitudes ARCO | | ✔ | Proceso y responsabilidades; usa consultas técnicas. |
| Vista con información limitada | ✔ | | Mecanismo técnico de minimización; deriva de una decisión administrativa. |
| Clasificación de información | | ✔ | Política de etiquetado, aunque puede apoyarse en metadatos. |
| Registro de auditoría | ✔ | ✔ | Técnico al generar logs; administrativo al revisar y resguardarlos. |
| Política de control de acceso | | ✔ | Define quién debe acceder; se implementa con roles y `GRANT`. |

## 9. Evaluación integral
Se identificaron 14 riesgos (ver [`evidencias/14-evaluacion-integral.md`](evidencias/14-evaluacion-integral.md)). Principales: acceso directo de analítica a `clientes`, 12 años de retención sin política, copias reales en desarrollo, uso de correos para marketing sin finalidad documentada y falta de auditoría. La arquitectura propuesta está en [`evidencias/15-arquitectura.md`](evidencias/15-arquitectura.md); el análisis de privacidad por diseño en [`evidencias/12-privacidad-diseno.md`](evidencias/12-privacidad-diseno.md).

## 10. Conclusiones
La seguridad protege los datos de accesos indebidos; la privacidad determina si deben existir, para qué se usan y por cuánto tiempo. Una base de datos puede ser segura y aun así incumplir principios de privacidad. El DBA es custodio: implementa minimización, mínimo privilegio, auditoría y eliminación, pero las finalidades y bases jurídicas se deciden con Privacidad, Jurídico y los propietarios de los datos.

---

## Verificación final
- **Seguridad vs privacidad:** la seguridad protege confidencialidad, integridad y disponibilidad; la privacidad regula el tratamiento legítimo de datos personales y los derechos del titular.
- **Finalidad:** se recopilaron para fines informados; otros usos requieren compatibilidad o base jurídica.
- **Minimización:** más datos significan más riesgo, costo y obligaciones sin beneficio.
- **ARCO:** requieren localizar, corregir, bloquear/eliminar y excluir datos en todos los sistemas, con trazabilidad.
- **Retención:** aumenta la exposición y contradice la minimización.
- **Gobierno:** los propietarios de datos, con Privacidad y Jurídico, deciden finalidades.
- **DBA:** implementa controles y custodia; escala decisiones jurídicas y de finalidad.

## Preguntas de reflexión
1. **No.** Seguridad ≠ privacidad: puede haber acceso legítimo pero finalidad no permitida, exceso de datos o retención indebida.
2. El mínimo privilegio reduce quién ve datos personales y cuántos, limitando usos no autorizados y el impacto de errores o abusos internos.
3. Porque la finalidad es una decisión de negocio y jurídica (base jurídica, aviso, consentimiento); el DBA es custodio, no responsable del tratamiento.
4. Porque amplía innecesariamente el acceso a datos reales, los entornos de desarrollo suelen tener menos controles y no existe finalidad que lo justifique.
5. Porque contiene datos reales, se copia fácilmente, puede filtrarse y suele salir del alcance de los controles productivos.
6. Porque los datos deben tener un inicio y un final; sin retención definida se acumulan datos innecesarios y se pierde control sobre su eliminación.
7. El diseño de la base decide qué datos existen, cómo se separan y quién accede; si no se piensa en privacidad desde el modelado, después es costoso corregirlo.
8. Roles y `GRANT` mínimos, vistas, permisos por columna, cifrado en reposo y tránsito, enmascaramiento, auditoría (`pgaudit`), RLS, datos sintéticos en desarrollo, retención automatizada y respaldos cifrados.
9. Dónde residen los datos del titular (tablas, respaldos, réplicas, exportaciones, terceros), cómo identificarlo, qué debe conservarse por ley, quién autoriza y cómo registrar la acción.
10. **DBA:** implementar y operar controles, extraer/modificar/eliminar técnicamente, auditar. **Responsable de privacidad:** gestionar solicitudes, aviso y cumplimiento. **Jurídico:** interpretar la ley, plazos y excepciones. **Propietario de datos:** decidir uso, acceso y finalidad de sus datos.
