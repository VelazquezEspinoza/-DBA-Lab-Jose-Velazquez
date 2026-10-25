# Evidencia 15 — Arquitectura conceptual de datos protegidos

## Objetivo
Traducir los principios de privacidad en una arquitectura que separe los datos según su finalidad.

## Procedimiento
Se definieron zonas (operación, analítica, auditoría, no productivo) y se asignaron controles para acceso, minimización, protección, retención, trazabilidad, eliminación y atención de solicitudes.

## Resultado

### Diagrama
```
                       BASE DE DATOS / PLATAFORMA
                                  │
     ┌───────────────┬────────────┼─────────────┬─────────────────┐
     ▼               ▼            ▼             ▼                 ▼
 OPERACIÓN        FISCAL       ANALÍTICA     AUDITORÍA      NO PRODUCTIVO
 (clientes,   (rfc, cp_fiscal) (agregados,   (log de         (desarrollo/
  soporte)                      vistas)       accesos y       pruebas con
     │               │             │          cambios)        datos sintéticos)
     ▼               ▼             ▼             ▼
 Soporte         Facturación   Analista    DBA seguridad /
 (mínimo)        (columna)     (vista)     Auditoría (solo lectura)
```

### Controles por dimensión

| Dimensión | Control técnico | Control administrativo |
|---|---|---|
| **Acceso** | Roles por función, `REVOKE` a `PUBLIC`, `GRANT` por vista/columna, mínimo privilegio; Row-Level Security si hay multi-área | Política de control de acceso, revisión trimestral de permisos |
| **Minimización** | Tablas/vistas con solo las columnas necesarias; generalización de edad y CP | Revisión de nuevos campos por Privacidad antes de crearlos |
| **Información sensible** | Cifrado en reposo (disco/columna con `pgcrypto`), TLS, enmascaramiento en no productivo | Clasificación de datos; prohibición de datos reales en desarrollo |
| **Retención** | Particionado por fecha, tareas de depuración (`pg_cron`), marcas de caducidad | Calendario de retención aprobado y revisado anualmente |
| **Trazabilidad** | `pgaudit`, triggers de auditoría, `log_connections`, registro de exportaciones | Revisión periódica de bitácoras, resguardo de evidencias |
| **Eliminación** | Procedimiento de borrado/anonimización con transacción y folio; limpieza de réplicas y exportaciones; expiración de respaldos | Procedimiento de cancelación, certificado de eliminación |
| **Atención de solicitudes (ARCO)** | Consultas preparadas por titular (acceso), `UPDATE` auditado (rectificación), tabla de oposiciones (oposición), proceso de bloqueo/borrado (cancelación) | Responsable de privacidad, formato de solicitud, plazos y verificación de identidad |

### Flujo de datos
1. El dato entra a **Operación** solo si tiene finalidad.
2. Se deriva a **Analítica** ya agregado/generalizado mediante vistas o procesos ETL.
3. Cada acceso o cambio relevante se escribe en **Auditoría**.
4. **No productivo** se alimenta de datos sintéticos o enmascarados, nunca de copias reales.
5. Al vencer la retención, un proceso programado elimina o anonimiza y deja evidencia.

## Análisis
La separación física/lógica por finalidad reduce la superficie de exposición y facilita cada control. No es necesario implementar toda la arquitectura físicamente; lo importante es demostrar la correspondencia entre principio y decisión técnica.

## Conclusión
La arquitectura propuesta aplica privacidad por diseño y por defecto: cada zona recibe solo lo necesario, con trazabilidad y ciclo de vida definido.
