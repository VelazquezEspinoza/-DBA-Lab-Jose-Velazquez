# POL-03 — Retención

| Campo | Contenido |
|---|---|
| **Pregunta que responde** | ¿Cuánto tiempo se conservan los datos y las bitácoras, y qué se hace al vencer el plazo? |
| **Objetivo** | Reducir dos riesgos opuestos: conservar datos personales más tiempo del necesario, y perder evidencia antes de que la auditoría o una investigación la necesite (riesgo observado: `system.profile` se sobrescribe sola; la bitácora se pierde al rotar o recrear el servidor). |
| **Alcance** | Datos de clientes (CAT-01, CAT-04), evidencia de auditoría (CAT-02, CAT-05, CAT-09), bitácoras de PostgreSQL y MongoDB (CAT-07, CAT-08) y respaldos de producción. |
| **Regla** | 1. Cada conjunto de datos y cada tipo de bitácora tiene un plazo de conservación registrado en el catálogo, conforme al criterio de `evidencias/05-conservacion.md`; los plazos que dependan de una obligación normativa se marcan **"a confirmar con el área jurídica"** hasta que Jurídico los fije. 2. Al vencer el plazo, el custodio elimina o **seudonimiza** el registro y levanta un acta con lo eliminado (archivo o rango, y su hash). **Ningún registro de auditoría o bitácora se elimina mientras exista un incidente o una investigación abierta que lo involucre (POL-05)**, ni antes que el dato que audita. 3. Los respaldos no pueden conservarse más tiempo que el plazo más largo de los datos que contienen. |
| **Responsable** | Decide el plazo: propietario de cada conjunto (catálogo), con Jurídico. Autoriza la eliminación de evidencia: Auditoría interna. Ejecuta: DBA. |
| **Excepciones** | Retención extendida (suspensión de la eliminación) por incidente, investigación o requerimiento de autoridad: la ordena Auditoría interna o Jurídico por escrito, indicando qué registros y hasta cuándo. |
| **Evidencia** | Columna *Conservación* del catálogo (`04-catalogo.md`) + `05-conservacion.md` + actas de eliminación con hash. **Hoy no existen actas de eliminación**: ningún plazo ha vencido. En la tabla `auditoria.cambios_clientes` no hay hoy un mecanismo que demuestre que se aplicó la seudonimización. |
| **Revisión** | Anual, o cuando Jurídico informe un cambio en las obligaciones de conservación. |

**Conflicto resuelto (LAB-01, Actividad 13):** eliminar los datos personales de un cliente no obliga a borrar su auditoría el mismo día. Al vencer el plazo, la auditoría se seudonimiza: se conservan quién, cuándo, desde dónde, qué operación e `id_cliente`, y se eliminan `valores_antes` / `valores_despues`.
