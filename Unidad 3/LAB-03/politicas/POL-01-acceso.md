# POL-01 — Acceso a datos

| Campo | Contenido |
|---|---|
| **Pregunta que responde** | ¿Quién puede solicitar acceso, quién lo aprueba y cada cuánto se revisa? |
| **Objetivo** | Reducir el riesgo de que una persona o aplicación tenga más privilegios de los que su función requiere, o los conserve después de dejar de necesitarlos (casos observados: `soporte_ana` con `UPDATE` sobre `clientes`, `GRANT UPDATE` a `app_ventas` y `CREATE ROLE rol_temporal` sin solicitud). |
| **Alcance** | Todos los roles, usuarios y privilegios sobre las bases `comercial` de PostgreSQL 16 y MongoDB 7, en el ambiente de **producción**. Los ambientes de desarrollo y pruebas que contengan copias de datos personales se rigen por las mismas reglas. |
| **Regla** | 1. Todo acceso o cambio de privilegios lo solicita el jefe del área usuaria y lo **aprueba el propietario del dato** (catálogo, Actividad 4) mediante un folio en `gobierno.solicitudes_cambio`; el DBA solo lo ejecuta. 2. Los privilegios se otorgan a roles por función (matriz de la Unidad II), nunca directamente a personas, y las cuentas de aplicación no tienen privilegios de DDL. 3. El DBA concilia **mensualmente** la bitácora de `GRANT`/`REVOKE`/`CREATE ROLE` con los folios aprobados, y el propietario revisa **trimestralmente** los privilegios vigentes (E2) contra la matriz de roles. |
| **Responsable** | Decide: propietario del dato. Ejecuta: DBA (custodio). Revisa: Auditoría interna. |
| **Excepciones** | Acceso de emergencia para atender una falla en producción: lo autoriza la Jefatura de TI, dura como máximo 24 horas y debe regularizarse con un folio dentro de los dos días hábiles siguientes, que indique que fue de emergencia. No se permiten excepciones a la regla 2 para cuentas de aplicación. |
| **Evidencia** | Líneas `statement: GRANT/REVOKE/CREATE ROLE` de la bitácora (LAB-01, Actividad 6; extracto de la Actividad 7 del LAB-03) + folios en `gobierno.solicitudes_cambio` + `E2-privilegios.txt` + acta de la revisión trimestral firmada por el propietario. **Hoy no existe** el acta de revisión trimestral; en MongoDB, la evidencia es `auditoria.instantaneas_privilegios` (LAB-02), no una bitácora nativa. |
| **Revisión** | Anual, o antes si cambia la matriz de roles o se detecta un hallazgo de acceso. |

**Coherencia con otras políticas:** el acceso a datos sensibles tiene requisitos adicionales en POL-05; los cambios de privilegios son cambios en producción y siguen POL-06.
