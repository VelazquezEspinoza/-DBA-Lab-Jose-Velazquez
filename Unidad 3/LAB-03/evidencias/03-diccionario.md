# Actividad 3 — Diccionario de datos operativo

**Script:** [`sql/02-comentarios-diccionario.sql`](../sql/02-comentarios-diccionario.sql)
**Exportación del motor:** [`diccionario-clientes.csv`](diccionario-clientes.csv) (columna, tipo, longitud, nulos, descripción)

El diccionario tiene dos partes:

1. **Dentro del motor**: estructura (`information_schema.columns`) + significado (`COMMENT`, leído con `col_description`). Se exporta a CSV.
2. **Fuera del motor**: lo que el SGBD no sabe (clasificación, finalidad, controles, regla de calidad). Está en la tabla de la sección 2.

Control de completitud: la consulta *"columna_sin_comentario"* del script devuelve **0 filas**, así que la tabla y todas sus columnas tienen comentario (incluida `canal_alta`, comentada en la Actividad 7 con su folio).

## 1. Comentarios registrados

| Columna | `COMMENT` |
|---|---|
| *(tabla)* | Clientes de Comercializadora Norte. Propietario: Gerencia Comercial. Custodio: DBA. Clasificación: confidencial (contiene datos personales). |
| `id` | Identificador interno del cliente. Generado por el sistema. |
| `nombre` | Nombre completo. Dato personal identificador directo. |
| `correo` | Correo de contacto. Dato personal. Uso: notificaciones al cliente. |
| `telefono` | Teléfono de contacto a 10 dígitos. Dato personal. Uso: contacto y soporte. Se muestra enmascarado al rol de soporte (U2). |
| `rfc` | RFC del cliente. Dato personal. Uso: facturación. Cambios auditados en auditoria.cambios_clientes. |
| `edad` | Edad en años cumplidos. Dato personal. Uso: analítica agregada. |
| `ciudad` | Ciudad de residencia o de entrega. Dato personal de localización (identificador indirecto). Uso: logística y analítica por zona. |
| `codigo_postal` | Código postal de 5 dígitos. Dato personal de localización (identificador indirecto). Uso: logística, cobertura y facturación. |
| `fecha_alta` | Fecha en que el cliente se registró. Generada por el sistema (valor por defecto). Uso: antigüedad del cliente y cómputo de plazos de retención (POL-03). |
| `segmento` | Segmento comercial asignado por la Gerencia Comercial (agregado en LAB-01). Dato interno derivado; puede constituir perfilamiento. Uso: campañas y analítica. |
| `canal_alta` | Canal por el que se registró el cliente. Cambio CAM-2026-014. |

## 2. Diccionario completado (información que el motor no conoce)

| Columna | Clasificación (Unidad II) | Finalidad | Control aplicado | ¿Cambios auditados? | Regla de calidad |
|---|---|---|---|---|---|
| `id` | Dato interno (identificador técnico) | Identificar al cliente entre sistemas | Generado por secuencia; nadie lo captura | Sí (aparece como `id_cliente` en la auditoría) | Único y no nulo (llave primaria) |
| `nombre` | Dato personal — identificador directo | Identificar al cliente, facturación | Privilegios por rol (U2) | Sí, LAB-01 Parte B | No vacío; sin duplicados normalizados (V9) |
| `correo` | Dato personal — contacto | Notificaciones al cliente | Privilegios por rol; enmascarado para soporte (U2) | Sí, LAB-01 Parte B | Formato `x@y.z` (V3); único sin distinguir mayúsculas (V1) |
| `telefono` | Dato personal — contacto | Contacto y soporte | Enmascarado para soporte (U2) | Sí, LAB-01 Parte B | 10 dígitos (V6) |
| `rfc` | Dato personal — fiscal | Facturación | Vista enmascarada para soporte (U2) | Sí, LAB-01 Parte B | Formato RFC (V2); obligatorio si factura (a decidir por el propietario) |
| `edad` | Dato personal | Analítica agregada (nunca individual) | Solo se publica agregada | Sí, LAB-01 Parte B | 18 a 120 (V4) |
| `ciudad` | Dato personal — localización (identificador indirecto) | Logística, analítica por zona | Privilegios por rol (U2) | Sí, LAB-01 Parte B | Valor de un catálogo de ciudades (V8) |
| `codigo_postal` | Dato personal — localización (identificador indirecto) | Logística, cobertura, facturación | Privilegios por rol (U2) | Sí, LAB-01 Parte B | 5 dígitos (V7) |
| `fecha_alta` | Dato interno | Antigüedad; base para plazos de retención | Valor por defecto del sistema | Sí, LAB-01 Parte B | No futura; no nula para clientes nuevos |
| `segmento` | Dato interno derivado (posible perfilamiento) | Campañas y analítica | Privilegios por rol | Sí: el disparador registra la fila completa (`to_jsonb`) | Valor de una lista cerrada definida por la Gerencia Comercial |
| `canal_alta` | Dato interno | Medir canales de registro | Privilegios por rol | Sí: el disparador registra la fila completa | Valor de una lista cerrada (p. ej., tienda, sucursal, teléfono) — por definir |

> Ajusta la columna *Clasificación* a las etiquetas exactas que usaste en la matriz de la Unidad II. La auditoría cubre las columnas nuevas porque el disparador del LAB-01 guarda la fila completa; si tu disparador lista columnas explícitamente, `segmento` y `canal_alta` **no** estarían auditadas y eso sería un hallazgo.

## 3. Preguntas

**¿Qué ventaja tiene guardar el significado en `COMMENT` y no solo en un documento aparte?**
El significado viaja con el objeto: lo ve cualquiera que consulte el motor (`\d+ clientes`, `col_description`, herramientas de administración), se incluye en `pg_dump` y en los respaldos, y se puede consultar y exportar por SQL, como se hizo con el CSV. Un documento aparte se desactualiza sin que nadie lo note; el comentario está junto a la columna y su cambio queda en la bitácora. También permite verificarlo automáticamente: la consulta de completitud detecta columnas sin documentar.

**¿Quedaron registrados los `COMMENT` en la bitácora? ¿Con qué nivel de `log_statement`?**
Sí. `COMMENT` es una sentencia de definición (DDL), y `log_statement = 'mod'` registra todo lo de `ddl` más `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` y `COPY FROM`. La última consulta del script (`linea ~ 'statement: COMMENT ON'`) lo muestra: cada comentario aparece con su usuario y su hora. Con `none` no quedarían registrados; con `ddl`, sí.

**¿Qué información del diccionario debe mantenerse fuera del motor? ¿Por qué?**
La clasificación formal, la finalidad autorizada, la base legal del tratamiento, el plazo de conservación, la regla de calidad en lenguaje de negocio y el historial de aprobaciones. Son decisiones del propietario, no propiedades técnicas de la columna. Varias aplican a más de un motor (el mismo RFC vive en PostgreSQL y en MongoDB). Además, deben poder consultarlas personas que no tienen acceso al servidor, como Auditoría y Jurídico, y no deben depender de que la base esté disponible. El `COMMENT` guarda un resumen; el documento es la fuente de la decisión.
