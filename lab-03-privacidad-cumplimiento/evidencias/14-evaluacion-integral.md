# Evidencia 14 — Evaluación integral de riesgos

## Objetivo
Identificar al menos 10 problemas de privacidad y gobierno de datos en el escenario de 50,000 clientes y proponer controles.

## Procedimiento
Se analizó cada afirmación del escenario y se asoció con un principio vulnerado, su riesgo y un control técnico y/o administrativo.

## Resultado

| # | Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|---|
| 1 | Analítica consulta directamente la tabla `clientes` | Mínimo privilegio, limitación de finalidad | Acceso a nombre, correo, RFC sin necesidad | Rol `analista` con acceso solo a `v_analitica_clientes`; `REVOKE` sobre `clientes` |
| 2 | Analítica solo requiere estadísticas mensuales | Minimización / proporcionalidad | Exposición de identificadores directos | Datos agregados o vista generalizada, tabla resumen mensual |
| 3 | Datos conservados por 12 años | Limitación de conservación / minimización | Mayor impacto de una brecha y datos obsoletos | Calendario de retención, depuración y anonimización programadas |
| 4 | No existe política documentada de retención | Responsabilidad proactiva / gobierno | Imposibilidad de justificar plazos; incumplimiento | Política aprobada por Privacidad/Jurídico con responsables |
| 5 | Desarrolladores reciben copias completas de la base | Seguridad, mínimo privilegio, confidencialidad | Fuga desde entornos poco protegidos | Entornos con datos sintéticos o enmascarados; prohibir copias productivas |
| 6 | Copias de desarrollo contienen datos reales | Finalidad (uso para pruebas no informado), minimización | Exposición de 50,000 titulares, uso indebido | Enmascaramiento/anonimización (ver LAB-01), generación de datos de prueba |
| 7 | Marketing usa correos para campañas | Limitación de finalidad, consentimiento, aviso | Tratamiento sin base jurídica; derecho de oposición ignorado | Verificar aviso/consentimiento; vista `v_marketing_promos` con filtro de oposición |
| 8 | No hay documentación de finalidad por dato | Transparencia, responsabilidad | Usos arbitrarios, imposibilidad de auditar | Catálogo de datos y matriz de gobierno |
| 9 | Sin registro de auditoría del acceso a datos personales | Trazabilidad / integridad | No se detectan consultas indebidas ni se puede investigar incidentes | `pgaudit`, logs de conexión, auditoría en tablas sensibles |
| 10 | RFC visible para roles que no facturan | Mínimo privilegio, necesidad | Fraude de identidad / fuga de datos fiscales | `GRANT` por columna, acceso a RFC solo a facturación, cifrado de columna |
| 11 | Sin procedimiento para derechos ARCO | Derechos del titular | Respuesta tardía o incompleta; sanciones | Procedimiento, formulario, responsables y plazos; consultas de localización de datos |
| 12 | No se sabe dónde están las copias (respaldos, exportaciones) | Gobierno / ciclo de vida | Datos no eliminables ni rastreables | Inventario de copias, política de respaldos con expiración |
| 13 | Datos sin clasificación | Gobierno de datos | Protección inconsistente | Esquema de clasificación (público/interno/confidencial/restringido) |
| 14 | Sin responsables definidos (data owner/custodio) | Rendición de cuentas | Nadie decide ni responde | Asignar roles y documentar en matriz de gobierno |

## Análisis
Los problemas combinan fallas técnicas (permisos, copias, auditoría) y administrativas (retención, finalidad, responsables). Corregir solo la parte técnica no resuelve el incumplimiento.

## Conclusión
Se identificaron 14 riesgos. Las prioridades inmediatas son: retirar acceso directo de analítica, dejar de usar datos reales en desarrollo, documentar finalidades y definir retención.
