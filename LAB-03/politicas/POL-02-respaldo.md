# POL-02 — Respaldo

| Campo | Contenido |
|---|---|
| **Pregunta que responde** | ¿Qué se respalda, con qué frecuencia y quién verifica que el respaldo sirve? |
| **Objetivo** | Reducir el riesgo de perder datos de clientes o evidencia de auditoría por falla, error humano o recreación del servidor (riesgo observado: la bitácora y los objetos se pierden si se recrea el servidor o el contenedor). |
| **Alcance** | Producción: bases `comercial` de PostgreSQL y MongoDB, incluidos los esquemas `auditoria` y `gobierno`, la base `auditoria` de MongoDB y la configuración de ambos servidores (`postgresql.conf`, `mongod.conf`). Las bitácoras exportadas no se respaldan: se **conservan** según POL-03. |
| **Regla** | 1. Las bases de producción se respaldan **diariamente** y se conserva al menos un respaldo completo semanal fuera del servidor de base de datos. 2. El custodio verifica el **resultado** de cada respaldo (terminado sin error) el mismo día, y una persona distinta de quien lo ejecuta hace una **prueba de restauración** en un ambiente de pruebas al menos **trimestralmente** (POL-04). 3. Los respaldos que contienen datos personales se cifran y su acceso se limita al DBA y a quien autorice POL-04. |
| **Responsable** | Decide qué se respalda y la pérdida tolerable: propietario del dato (Gerencia Comercial) con la Jefatura de TI. Ejecuta y vigila: DBA. Verifica la restauración: un segundo administrador o Auditoría interna. |
| **Excepciones** | Ninguna para producción. Desarrollo y pruebas pueden no respaldarse si no contienen datos únicos; lo decide la Jefatura de TI por escrito. |
| **Evidencia** | Registro de ejecución de cada respaldo (fecha, hora, tamaño, hash) + acta de la prueba trimestral de restauración. **Hoy no existe ninguna de las dos**: los LAB-01 a LAB-03 no practicaron respaldos. |
| **Revisión** | Anual, o después de cualquier restauración real. |

**El procedimiento técnico se definirá en la Unidad V.**

**Coherencia con otras políticas:** un respaldo conserva copias de datos que POL-03 puede ordenar eliminar; el plazo de los respaldos no puede extender indefinidamente la vida de los datos personales (ver POL-03, regla 3). Restaurar un respaldo sigue POL-04.
