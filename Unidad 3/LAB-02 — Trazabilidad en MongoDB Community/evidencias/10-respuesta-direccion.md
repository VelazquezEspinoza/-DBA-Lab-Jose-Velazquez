# Evidencia 10 — Respuesta a Dirección (Actividad 10)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-02**  
**Servidor:** MongoDB 7.0.34 Community · `/etc/mongod.conf` · 127.0.0.1:27017 · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la noche, hora de Culiacán, UTC−7)  
**Sesión del DBA:** `mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin"`  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

Fuentes: `evidencias/mongod.log` (L = número de línea), `evidencias/system-profile-actividad3.json`, `evidencias/system-profile.json` y la colección `auditoria.instantaneas_privilegios`. Horas en UTC del 2026-11-07; en Culiacán (UTC−7) corresponden a la noche del 6 de noviembre.

## Estado final verificado

```text
comercial> db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
...   momento: new Date(),
...   tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
...   usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
... })
{
  acknowledged: true,
  insertedId: ObjectId('6aeea3cc602d03f7d1f91e9a')
}
comercial> db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0, momento: 1, "usuarios.user": 1, "usuarios.roles.role": 1 }).sort({ momento: 1 })
[
  {
    momento: ISODate('2026-11-07T04:00:54.286Z'),
    usuarios: [ { user: 'app_ventas', roles: [ { role: 'readWrite' } ] } ]
  },
  {
    momento: ISODate('2026-11-07T04:00:54.479Z'),
    usuarios: [
      {
        user: 'app_ventas',
        roles: [ { role: 'readWrite' }, { role: 'dbAdmin' } ]
      }
    ]
  },
  {
    momento: ISODate('2026-11-07T04:06:36.098Z'),
    usuarios: [ { user: 'app_ventas', roles: [ { role: 'readWrite' } ] } ]
  }
]
comercial> db.clientes.find({ _id: { $in: [2, 3] } }, { nombre: 1, rfc: 1 })
[ { _id: 3, nombre: 'María García', rfc: 'GAMA780912XYZ' } ]
```

## 1. ¿Quién cambió el RFC de María García?

**Actividad 2 (a `GAMA780912XXX`): No hay evidencia con esta edición.** El perfilador estaba en nivel 0 (`system.profile` vacío) y MongoDB Community no tiene auditoría nativa de operaciones; la bitácora no contiene la operación ni el valor. Solo hay un **indicio**: entre 03:59:44.163 y 03:59:44.322 se autenticó `app_ventas`, desde 127.0.0.1, declarando `app-ventas-web`, en conn28, conn29 y conn30 (L205, L217–L218). Que la cuenta se conectara no prueba que hiciera el cambio, ni que la persona o el programa detrás fuera la aplicación.

**Actividad 3 (a `GAMA780912XYZ`): `app_ventas@comercial`.** Documento `op: 'update'` de `system.profile` (exportado en `system-profile-actividad3.json`): `q: { _id: 3 }`, `u: { $set: { rfc: 'GAMA780912XYZ' } }`, `nModified: 1`. Coincide con las autenticaciones de `app_ventas` de las 04:00:09 (L315, L325–L326).

## 2. ¿Cuándo y desde qué aplicación?

| Cambio | Momento | Origen | Aplicación declarada |
|---|---|---|---|
| Actividad 2 | **No hay evidencia con esta edición** del momento de la operación. Solo de las conexiones: 03:59:44 UTC | 127.0.0.1 (conexiones) | `app-ventas-web` (conexiones) |
| Actividad 3 | 2026-11-07 **04:00:09.636 UTC** (21:00:09 del 6-nov en Culiacán) | 127.0.0.1 | `app-ventas-web` |

El `appName` lo declara el cliente; identifica qué programa dice ser, no lo demuestra.

## 3. ¿Qué valor tenía antes?

**No hay evidencia con esta edición, en ninguno de los dos cambios.** El perfilador registra el comando (`$set: { rfc: ... }`), no el documento antes ni después, y MongoDB Community no tiene un mecanismo equivalente al disparador del LAB-01 (los *change streams* con *pre-images* requieren un conjunto de réplicas y un proceso que consuma y guarde los eventos, lo que no existe en este servidor). El valor actual, verificado, es `GAMA780912XYZ`. El valor original `GAMA780912GHI` solo consta en el script de carga, que no es evidencia del servidor.

Lo mismo ocurre con el cliente eliminado: el perfilador prueba que `app_ventas` eliminó el documento `_id: 2` a las 04:00:09.639 UTC, pero no conserva sus datos. El documento ya no existe (consulta anterior).

## 4. ¿Cambió alguien los privilegios de `app_ventas`?

**Sí cambiaron; quién: no hay evidencia con esta edición.**

- **Qué:** se agregó el rol `dbAdmin@comercial` (comparación de instantáneas, evidencia 07).
- **Cuándo:** entre las instantáneas de 04:00:54.286 y 04:00:54.479 UTC. No hay una hora exacta.
- **Después:** la instantánea de cierre (04:06:36.098) muestra de nuevo solo `readWrite`. El rol se retiró en algún momento entre 04:00:54.479 y 04:06:36.098; **no hay evidencia** de quién lo retiró ni cuándo.
- **Quién:** `grantRolesToUser` y `revokeRolesFromUser` no dejan rastro en el perfilador (aun en nivel 2) ni en la bitácora. Como indicio, la única sesión activa en la ventana del cambio fue de `admin` (conn88–conn90, L543–L552), pero eso no prueba la autoría.
- **Límite del control:** si el rol se hubiera otorgado y retirado entre dos instantáneas, **ningún** mecanismo de este servidor lo habría detectado.

## Resumen para Dirección

Con MongoDB Community y el perfilador activo podemos demostrar **quién** modificó un documento, **cuándo** y desde dónde. No podemos demostrar **qué valor tenía antes**, ni **quién cambió los privilegios** de una cuenta. Lo ocurrido antes de activar el perfilador no tiene evidencia y no puede reconstruirse.
