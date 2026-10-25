# Evidencia 05 — Análisis de finalidad secundaria

## Objetivo
Analizar si la empresa puede utilizar los datos de clientes para "enviar promociones personalizadas basadas en edad, ciudad y comportamiento de compra".

## Procedimiento
Se evaluó la propuesta con los principios de limitación de finalidad, finalidad compatible, minimización, consentimiento/aviso de privacidad y mínimo privilegio, y se diseñaron controles técnicos.

## Resultado

**1. ¿Tener los datos permite usarlos para cualquier finalidad?**
No. Los datos se recopilaron para una finalidad informada en el aviso de privacidad (atención, facturación). Un uso nuevo debe ser compatible con esa finalidad o contar con base jurídica propia (por ejemplo, consentimiento) y reflejarse en el aviso. La posesión técnica no equivale a autorización.

**2. Preguntas previas a implementar**
- ¿El aviso de privacidad actual menciona la mercadotecnia? ¿Es una finalidad que requiere consentimiento?
- ¿Se informó al titular y existe mecanismo para negarse (oposición) sin afectar el servicio?
- ¿Es una finalidad compatible con la original? ¿Quién lo determina (Privacidad/Jurídico)?
- ¿Quién es el propietario del tratamiento y quién lo autoriza?
- ¿Qué datos mínimos se requieren? ¿Se puede lograr con datos agregados o seudonimizados?
- ¿Cómo se excluirá a quienes se opongan? ¿Cuánto se conservará el perfil generado?
- ¿Se transferirán datos a terceros (plataformas de email, publicidad)? ¿Hay contrato con el encargado?
- ¿Cómo se registrará quién consulta y exporta la lista (trazabilidad)?

**3. Datos realmente necesarios**
- `correo` (canal de envío) y un identificador (`id`).
- `ciudad` y **rango de edad** (no la edad exacta).
- Segmento de comportamiento de compra (ej. categoría preferida, frecuencia), preferiblemente calculado por otra área y no el historial detallado.
- No necesarios: `rfc`, `telefono`, `nombre completo` (salvo personalizar saludo), `codigo_postal` completo.

**4. ¿Marketing necesita acceso directo a `clientes`?**
No. Debe acceder a una vista o tabla derivada con las columnas mínimas y filtrada para excluir a quienes no consintieron o se opusieron.

**5. Controles técnicos**
- Rol `marketing` sin permisos sobre `clientes`; `SELECT` solo sobre `v_marketing_promos` (ver `sql/03-control-acceso.sql`).
- Tabla `oposiciones_finalidad` y filtro `NOT EXISTS` en la vista.
- Generalización: rango de edad y región en lugar de valores exactos.
- Seudonimización: exportar `id` en lugar de nombre cuando sea posible.
- Auditoría de consultas/exportaciones; límites de filas; entrega mediante canal controlado.
- Caducidad de extracciones (borrado de archivos exportados).

## Análisis
El riesgo no está en la técnica sino en el cambio de propósito: sin base jurídica y aviso, el tratamiento sería indebido aunque la base de datos esté perfectamente protegida. El DBA implementa el filtro, pero no decide si la finalidad procede.

## Conclusión
La finalidad secundaria solo puede implementarse si Privacidad/Jurídico confirma la base jurídica y se actualiza el aviso. Técnicamente debe entregarse a marketing una vista mínima, con exclusión de opositores y con trazabilidad.
