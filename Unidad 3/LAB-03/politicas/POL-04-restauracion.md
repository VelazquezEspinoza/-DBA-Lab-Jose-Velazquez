# POL-04 — Restauración

| Campo | Contenido |
|---|---|
| **Pregunta que responde** | ¿Quién autoriza y quién ejecuta una restauración, y en qué condiciones? |
| **Objetivo** | Reducir el riesgo de que una restauración sobrescriba datos válidos, reviva datos ya eliminados por retención, borre evidencia de un incidente o exponga datos personales en un ambiente no autorizado. |
| **Alcance** | Cualquier restauración, total o parcial, de respaldos de las bases `comercial` (PostgreSQL y MongoDB), sea sobre producción o hacia otro ambiente. |
| **Regla** | 1. Una restauración **sobre producción** la autoriza el propietario del dato afectado junto con la Jefatura de TI, mediante un folio en `gobierno.solicitudes_cambio` que indique el respaldo a usar y la pérdida de datos aceptada; la ejecuta el DBA. 2. Antes de restaurar sobre producción, el DBA conserva la bitácora vigente y exporta `auditoria.cambios_clientes` con hash, para que la restauración no borre la evidencia de lo ocurrido. 3. Una restauración hacia desarrollo o pruebas solo se permite con datos personales enmascarados o con autorización expresa del propietario (POL-05). |
| **Responsable** | Autoriza: propietario del dato + Jefatura de TI. Ejecuta: DBA. Verifica el resultado: el área usuaria (Gerencia Comercial) confirma que los datos son correctos. |
| **Excepciones** | Falla total de producción fuera de horario: el DBA puede restaurar el último respaldo verificado con autorización verbal de la Jefatura de TI, registrada en un folio de emergencia dentro de las 24 horas siguientes. La regla 2 no tiene excepción. |
| **Evidencia** | Folio de la restauración + bitácora y auditoría exportadas antes de restaurar (con hash) + acta de verificación del área usuaria + acta de las pruebas trimestrales (POL-02). **Hoy no existe**: no se ha practicado ninguna restauración. |
| **Revisión** | Anual, y después de cada restauración real. |

**El procedimiento técnico se definirá en la Unidad V.**

**Coherencia con otras políticas:** si el respaldo contiene datos cuyo plazo de retención ya venció, deben volver a eliminarse o seudonimizarse después de restaurar (POL-03). Restaurar durante un incidente requiere el visto bueno de quien lo investiga (POL-05).
