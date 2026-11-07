# Evidencia 10 — Diseño del registro de auditoría (Actividad 10)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

Script: `sql/04-esquema-auditoria.sql`

## Diseño de campos

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| `id_evento` | BIGSERIAL | Orden de los eventos; permite citar un evento concreto en el informe | No. Es la llave primaria |
| `momento` | TIMESTAMPTZ | ¿Cuándo? | No. Todo evento ocurre en un instante; se llena con `now()` |
| `usuario_sesion` | TEXT | ¿Quién hizo el cambio? (rol autenticado, `session_user`) | No. Toda sesión tiene un rol autenticado |
| `usuario_efectivo` | TEXT | ¿Con qué privilegios se ejecutó? (`current_user`) | No. Siempre existe; permite detectar `SET ROLE` y funciones `SECURITY DEFINER` |
| `aplicacion` | TEXT | ¿Desde qué aplicación? | Sí. `application_name` es opcional y lo declara el cliente |
| `ip_cliente` | INET | ¿Desde qué equipo? | Sí. En conexiones por socket local no hay IP (`inet_client_addr()` es NULL) |
| `operacion` | TEXT | ¿Qué se hizo? (INSERT, UPDATE, DELETE) | No. Todo evento tiene una operación |
| `id_cliente` | BIGINT | ¿Qué registro se afectó? | Sí en el diseño, por flexibilidad (por ejemplo, una futura auditoría de `TRUNCATE`, que no tiene fila); con el disparador actual siempre se llena |
| `valores_antes` | JSONB | ¿Qué valor tenía el dato antes? | Sí. En un INSERT no hay estado anterior |
| `valores_despues` | JSONB | ¿Qué valor quedó? | Sí. En un DELETE no hay estado posterior |

## Creación

```text
-- LAB-01 · Actividad 10 · Esquema y tabla de auditoría a nivel de dato
-- Ejecutar en la sesión de administrador, base comercial.
CREATE SCHEMA auditoria;
CREATE SCHEMA
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;
REVOKE
CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY,
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,
    aplicacion       TEXT        DEFAULT current_setting('application_name'),
    ip_cliente       INET        DEFAULT inet_client_addr(),
    operacion        TEXT        NOT NULL,
    id_cliente       BIGINT,
    valores_antes    JSONB,
    valores_despues  JSONB
);
CREATE TABLE
-- Verificación: PUBLIC no tiene privilegios sobre el esquema
SELECT nspname, nspacl FROM pg_namespace WHERE nspname = 'auditoria';
  nspname  |         nspacl
-----------+------------------------
 auditoria | {postgres=UC/postgres}
(1 row)
```

`nspacl = {postgres=UC/postgres}`: solo el propietario tiene privilegios sobre el esquema; `PUBLIC` no aparece.

## Respuestas

**1. ¿Por qué `momento` usa TIMESTAMPTZ y no TIMESTAMP?** `TIMESTAMPTZ` guarda un instante absoluto (internamente en UTC) y lo muestra en la zona de quien consulta; `TIMESTAMP` guarda una fecha y hora “de reloj de pared” sin saber a qué zona corresponde. Con `TIMESTAMP` no podría compararse con certeza la auditoría con la bitácora (en UTC), con la aplicación o con un reporte en hora de Culiacán, y el cambio de zona del servidor alteraría el significado de los datos ya guardados.

**2. ¿Por qué el registro completo en JSONB y no solo la columna que cambió?** Porque conserva el estado completo de la fila en ese instante (contexto para la investigación y para restaurar), funciona igual para INSERT, UPDATE y DELETE, no obliga a programar qué columna cambió, y sigue funcionando si `clientes` cambia de estructura: la columna `segmento`, agregada después, aparece sola en los eventos posteriores sin modificar la tabla de auditoría. Las diferencias se calculan al consultar (`sql/06-campos-modificados.sql`). El costo es más almacenamiento.

**3. La auditoría también contiene RFC. ¿Qué implica?** Que tiene la **misma clasificación** de sensibilidad que `clientes` (datos personales), o mayor, porque además guarda historia: valores que ya se corrigieron o se eliminaron. Requiere el mismo o más control de acceso (esquema sin `PUBLIC`, solo auditoría y DBA), cifrado en respaldos, política de retención propia y su inclusión en el inventario de datos personales.
