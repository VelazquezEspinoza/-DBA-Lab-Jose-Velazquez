# POL-05 — Uso de datos sensibles

| Campo | Contenido |
|---|---|
| **Pregunta que responde** | ¿Quién accede a datos sensibles, con qué justificación y cómo se registra? |
| **Objetivo** | Reducir el riesgo de consulta, copia o modificación indebida de datos personales (nombre, correo, teléfono, RFC, edad, ubicación), y de que se expongan en bitácoras, exportaciones o ambientes no productivos. |
| **Alcance** | Columnas clasificadas como dato personal en el diccionario (`03-diccionario.md`), en `clientes` de PostgreSQL y MongoDB, y todas las copias que los contienen: `auditoria.cambios_clientes`, `system.profile`, bitácoras, exportaciones y respaldos. |
| **Regla** | 1. Solo acceden a datos personales completos los roles autorizados por el propietario para una finalidad registrada en el diccionario; soporte usa la vista enmascarada de la Unidad II y analítica usa agregados. 2. Toda **modificación** de un dato personal queda registrada en `auditoria.cambios_clientes` con el disparador habilitado; desactivar el disparador en producción está prohibido salvo con folio aprobado por Auditoría interna (POL-06). 3. Ninguna extracción de bitácora o de auditoría sale del servidor sin revisión: se ocultan secretos y se entregan solo los metadatos necesarios (como E4 y E5), con hash. |
| **Responsable** | Decide quién accede: propietario del dato. Ejecuta los controles: DBA. Investiga incidentes: Seguridad de la información con Auditoría interna. |
| **Excepciones** | Investigación de un incidente: Auditoría interna puede autorizar por escrito el acceso a los valores completos (`valores_antes` / `valores_despues`) a quien investiga, por un plazo definido. |
| **Evidencia** | Privilegios vigentes (`E2-privilegios.txt`) contra la matriz de la U2 + disparador habilitado (`E3-disparadores.txt`, `tgenabled = 'O'`) + filas de `auditoria.cambios_clientes` (`E4-muestra-auditoria.txt`) + líneas de `UPDATE` de la bitácora con `log_statement = 'mod'`. **Hoy no existe evidencia de las lecturas**: sin `pgaudit` (PostgreSQL) ni auditoría nativa (MongoDB Community) no se registra quién **consultó** un dato personal. |
| **Revisión** | Semestral, por la sensibilidad de los datos. |

**Coherencia con otras políticas:** para investigar un incidente, la evidencia debe existir; por eso POL-03 prohíbe eliminar auditoría o bitácoras relacionadas con un incidente abierto. Los accesos se solicitan según POL-01.
