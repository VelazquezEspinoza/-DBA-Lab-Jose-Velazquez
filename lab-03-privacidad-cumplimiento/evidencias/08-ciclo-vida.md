# Evidencia 08 — Derecho de cancelación y ciclo de vida de los datos

## Objetivo
Entender por qué atender una cancelación autorizada implica más que ejecutar un `DELETE` en la tabla principal.

## Procedimiento
Se identificaron todos los lugares donde puede existir información de un titular antes de eliminar y se construyó un mapa de datos.

## Resultado

### Mapa de dispersión de datos
```
clientes (tabla principal)
   │
   ├── Tablas relacionadas: pedidos, facturas, tickets de soporte, clientes_soporte, auditoria_clientes
   ├── Respaldos (full / incrementales / WAL archivado)
   ├── Réplicas (standby, réplicas de lectura, entornos DR)
   ├── Copias de analítica (data marts, cubos, vistas materializadas)
   ├── Reportes y exportaciones (CSV, Excel, PDF, correos adjuntos)
   ├── Entornos de desarrollo/pruebas con copias reales
   ├── Registros de aplicación y logs (consultas con valores, errores)
   └── Sistemas externos (plataforma de email, CRM, SAT/PAC, proveedores)
```

### Lista de verificación previa
| Pregunta | Acción técnica / decisión |
|---|---|
| ¿Existen otras tablas relacionadas? | Revisar FKs (`information_schema.referential_constraints`) y decidir `ON DELETE`. |
| ¿Hay datos que deben conservarse por ley (facturas)? | Conservar solo lo obligatorio, bloqueado para otros usos. |
| ¿Existen respaldos? | No se editan; se documenta el plazo de expiración y que el dato se eliminará al vencer; si se restaura, reaplicar la cancelación. |
| ¿Existen réplicas? | La replicación propaga el `DELETE`; verificar retrasos y réplicas lógicas filtradas. |
| ¿Registros de auditoría? | Anonimizar/seudonimizar datos personales o conservar solo el mínimo justificado. |
| ¿Copias de analítica? | Ya son agregadas; verificar que no haya granularidad individual. |
| ¿Archivos exportados? | Inventario y borrado seguro; trazabilidad de quién los generó. |
| ¿Sistemas externos? | Solicitar eliminación al encargado/tercero y obtener evidencia. |

### Ejemplo técnico (solo tras autorización y análisis)
```sql
BEGIN;
-- 1. Conservar lo estrictamente obligatorio (p. ej. datos fiscales) y bloquear su uso
-- 2. Anonimizar o eliminar el resto
UPDATE clientes
SET nombre = 'ANONIMIZADO', correo = 'cancelado-' || id || '@invalid',
    telefono = NULL, edad = NULL, ciudad = NULL, codigo_postal = NULL
WHERE id = 1;
-- 3. Registrar la acción con folio ARCO
-- 4. Notificar a réplicas/sistemas externos
COMMIT;
```

## Análisis
¿Por qué un `DELETE` no basta? Porque el dato vive en respaldos, réplicas, logs, copias de desarrollo, exportaciones y sistemas externos, y porque la ley puede obligar a conservar parte de él (bloqueo). Además, el borrado en PostgreSQL deja versiones muertas hasta `VACUUM` y los respaldos no se alteran. La cancelación debe tratarse como un **proceso** con responsables, plazos y evidencias.

## Conclusión
Eliminar un registro de `clientes` no equivale a eliminar a la persona de la organización. El DBA debe conocer el mapa de datos y coordinar con Privacidad, Jurídico y los dueños de los sistemas relacionados.
