# Evidencia 10 — Política de retención

## Objetivo
Evaluar la propuesta "conservar todos los datos de clientes indefinidamente porque podrían ser útiles en el futuro".

## Procedimiento
Se contrastó la propuesta con minimización, limitación de finalidad, ciclo de vida y análisis de riesgos.

## Resultado

**P1. ¿Es compatible con minimización?**
No. La minimización incluye limitar el **tiempo** de conservación. "Podrían ser útiles" no es una finalidad determinada ni una necesidad real.

**P2. Riesgos de conservar información innecesaria**
- Mayor superficie de ataque y mayor impacto en una brecha (12 años de datos de 50,000 personas).
- Datos desactualizados o inexactos que afectan la calidad y a los titulares.
- Uso indebido o reutilización para finalidades no informadas.
- Costos de almacenamiento, respaldo y gestión.
- Dificultad para atender ARCO (hay más lugares donde buscar y borrar).
- Incumplimiento normativo y sanciones/reputación.

**P3. Qué debe determinar la organización antes de fijar un periodo**
- La finalidad de cada dato y cuándo se cumple.
- Obligaciones legales (fiscales, contables, mercantiles) y contractuales.
- Plazos de prescripción y necesidades de defensa legal.
- Necesidad operativa real y alternativas (agregación, anonimización).
- Sensibilidad del dato y riesgo asociado.
- Qué ocurre al vencer: eliminación, anonimización, archivo restringido.

**P4. Qué documentar para justificar el periodo**
- Dato/categoría, finalidad y base jurídica.
- Norma o necesidad que fundamenta el plazo (cita específica).
- Periodo, momento en que empieza a contarse y responsable (data owner).
- Acción al vencer y método (borrado, anonimización) y evidencia de ejecución.
- Fecha de aprobación, revisor y periodicidad de revisión.
- Excepciones (litigios, bloqueos).

### Propuesta de calendario (a validar con Jurídico)
| Dato | Plazo propuesto | Fundamento | Acción final |
|---|---|---|---|
| Datos de contacto (nombre, correo, teléfono) | Relación comercial + 1 año | Operación y reclamaciones | Eliminar/anonimizar |
| Datos fiscales (RFC, CP fiscal) | 5 años desde el ejercicio | Obligación fiscal | Eliminar tras plazo |
| edad, ciudad, CP (analítica) | Solo agregados indefinidamente; individuales 2 años | Estadística | Agregar y borrar detalle |
| Clientes inactivos | 24 meses sin actividad | Finalidad cumplida | Anonimizar |

### Implementación técnica de ejemplo
```sql
-- Identificar candidatos a depuración (clientes con más de 5 años de alta y sin actividad)
SELECT id FROM clientes WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';
-- Ejecutar con pg_cron o tarea programada, registrando evidencia de cada corrida.
```

## Análisis
La retención indefinida convierte los datos en un pasivo. La conservación debe ser **finita, justificada y revisable**.

## Conclusión
Se rechaza la política propuesta y se recomienda un calendario de retención por categoría, con responsable y acción al vencimiento, aprobado por Privacidad y Jurídico.
