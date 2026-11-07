// =====================================================================
// LAB-02 — Trazabilidad en MongoDB Community
// Comandos de mongosh usados en el laboratorio, en orden de ejecución.
// Servidor: MongoDB 7.0.34 Community · /etc/mongod.conf · 127.0.0.1:27017
//
// Sesión del DBA:
//   mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin"
// Sesión de la aplicación:
//   mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web"
// Las líneas "$ ..." en comentarios son comandos de terminal.
// =====================================================================

// ---------------------------------------------------------------------
// 6.3 Usuarios y datos (mongosh SIN credenciales, excepción de localhost)
//   $ mongosh "mongodb://127.0.0.1:27017"
// ---------------------------------------------------------------------
use admin
db.createUser({ user: "admin", pwd: "<REDACTED>", roles: ["root"] })
db.auth("admin", "<REDACTED>")

use comercial
db.createUser({
  user: "app_ventas",
  pwd: "<REDACTED>",
  roles: [{ role: "readWrite", db: "comercial" }]
})

db.clientes.insertMany([
  { _id: 1, nombre: "Ana López", correo: "ana.lopez@example.test", telefono: "6671234567", rfc: "LOAA850315ABC", edad: 41, ciudad: "Culiacán", codigo_postal: "80000" },
  { _id: 2, nombre: "Carlos Pérez", correo: "carlos.perez@example.test", telefono: "6672345678", rfc: "PECA900720DEF", edad: 35, ciudad: "Culiacán", codigo_postal: "80100" },
  { _id: 3, nombre: "María García", correo: "maria.garcia@example.test", telefono: "6673456789", rfc: "GAMA780912GHI", edad: 47, ciudad: "Mazatlán", codigo_postal: "82000" },
  { _id: 4, nombre: "Luis Torres", correo: "luis.torres@example.test", telefono: "6674567890", rfc: "TOLU920201JKL", edad: 34, ciudad: "Los Mochis", codigo_postal: "81200" },
  { _id: 5, nombre: "Laura Sánchez", correo: "laura.sanchez@example.test", telefono: "6675678901", rfc: "SALA880525MNO", edad: 38, ciudad: "Culiacán", codigo_postal: "80200" }
])
// exit

// ---------------------------------------------------------------------
// 6.4 Función auxiliar (definir en cada sesión del DBA)
// ---------------------------------------------------------------------
function bitacora() {
  return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
}

// ---------------------------------------------------------------------
// Actividad 1 — Edición y configuración de arranque
// ---------------------------------------------------------------------
db.version()
db.adminCommand({ buildInfo: 1 }).modules          // [] => Community (Enterprise incluiría "enterprise")
db.serverCmdLineOpts().parsed                      // config, systemLog, security...
db.adminCommand({ getCmdLineOpts: 1 }).argv        // cómo se arrancó el proceso

// ---------------------------------------------------------------------
// Actividad 2 — El incidente sin perfilado
// ---------------------------------------------------------------------
db.getProfilingStatus()
//   $ mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })'
db.system.profile.countDocuments()
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => ({ t: e.t, c: e.c, ctx: e.ctx, msg: e.msg }))

// Vista compacta de las conexiones de la aplicación (una línea por evento)
const c = ["conn27", "conn28", "conn29", "conn30"]   // sustituir por las conexiones propias
bitacora().filter(e => c.includes(e.ctx) || (e.c === "NETWORK" && e.msg === "Connection accepted" && c.includes("conn" + e.attr.connectionId))).map(e => [e.t.$date.slice(11, 23), e.ctx, e.msg, (e.attr.user || ""), (e.attr.doc && e.attr.doc.application ? e.attr.doc.application.name : ""), (e.attr.remote || e.attr.client || "")].join(" | "))

// ---------------------------------------------------------------------
// Actividad 3 — Perfilador nivel 2
// ---------------------------------------------------------------------
db.setProfilingLevel(2)
db.getProfilingStatus()
//   $ mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XYZ" } }); db.clientes.deleteOne({ _id: 2 });'
db.system.profile.find(
  { ns: "comercial.clientes" },
  { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }
).sort({ ts: 1 })
// Exportación previa al borrado de la Actividad 4 (evidencias/system-profile-actividad3.json):
//   $ mongosh "<sesión DBA>" --quiet --eval 'EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, "command.q": 1, "command.u": 1, "command.filter": 1 }).toArray(), null, 2)' > evidencias/system-profile-actividad3.json

// ---------------------------------------------------------------------
// Actividad 4 — Filtro de perfilado
// ---------------------------------------------------------------------
db.setProfilingLevel(0)
db.system.profile.drop()
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
db.getProfilingStatus()
//   $ mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: "6670000000" } })'
db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 })

// Filtro alternativo: solo modificaciones sobre la colección clientes
// db.setProfilingLevel(1, { filter: { ns: "comercial.clientes", op: { $in: ["insert", "update", "remove"] } } })

// ---------------------------------------------------------------------
// Actividad 5 — Accesos en la bitácora de mongod
// ---------------------------------------------------------------------
//   $ mongosh "mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
//   $ mongosh "mongodb://usuario_inexistente:x@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
bitacora()
  .filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client, error: e.attr.error, result: e.attr.result, isSpeculative: e.attr.isSpeculative, app: e.attr.doc.application.name }))

bitacora()
  .filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas")
  .slice(-1)
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc.application.name }))

// Intentos fallidos por usuario: una conexión (ctx) = un intento, aunque genere varias líneas
bitacora()
  .filter(e => e.msg === "Failed to authenticate")
  .reduce((acc, e) => { const k = e.attr.user; acc[k] = acc[k] || new Set(); acc[k].add(e.ctx); return acc }, {})
// → convertir a conteo:  Object.fromEntries(Object.entries(<resultado>).map(([u, s]) => [u, s.size]))

// ---------------------------------------------------------------------
// Actividad 6 — Correlación de un cambio de configuración con su autor
// ---------------------------------------------------------------------
bitacora()
  .filter(e => e.msg === "Profiler settings changed")
  .map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))

bitacora()
  .filter(e => e.ctx === "conn62" && e.msg === "Successfully authenticated")     // sustituir conn62
  .map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client, app: e.attr.doc.application.name }))

bitacora()
  .filter(e => e.ctx === "conn62" || (e.ctx === "listener" && e.attr.connectionId === 62))
  .map(e => e.t.$date.slice(11, 23) + " | " + e.ctx + " | " + e.msg)

// ---------------------------------------------------------------------
// Actividad 7 — Privilegios: instantáneas como control compensatorio
// ---------------------------------------------------------------------
db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
  momento: new Date(),
  tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
  usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
})
db.setProfilingLevel(2)
db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })   // 0
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length                // 0
db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
  momento: new Date(),
  tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
  usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
})
db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 })
db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })

// Comparación automática de las dos últimas instantáneas (roles agregados / retirados)
const s = db.getSiblingDB("auditoria").instantaneas_privilegios.find().sort({ momento: -1 }).limit(2).toArray().reverse()
const roles = snap => Object.fromEntries(snap.usuarios.map(u => [u.user + "@" + u.db, u.roles.map(r => r.role + "@" + r.db)]))
const [a, b] = [roles(s[0]), roles(s[1])]
Object.keys({ ...a, ...b }).map(k => ({ usuario: k, agregados: (b[k] || []).filter(r => !(a[k] || []).includes(r)), retirados: (a[k] || []).filter(r => !(b[k] || []).includes(r)) })).filter(x => x.agregados.length || x.retirados.length)

// ---------------------------------------------------------------------
// Actividad 8 — Conservación
// ---------------------------------------------------------------------
// Exportar ANTES de reiniciar:
//   $ mongosh "<sesión DBA>" --quiet --eval 'EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, "command.q": 1, "command.u": 1 }).toArray(), null, 2)' > evidencias/system-profile.json
//   $ mongosh "<sesión DBA>" --quiet --eval 'db.adminCommand({ getLog: "global" }).log.join("\n")' > evidencias/bitacora-mongod.log
//   $ cp /var/log/mongodb/mongod.log evidencias/mongod.log
//   $ (cd evidencias && sha256sum bitacora-mongod.log mongod.log system-profile.json system-profile-actividad3.json > hashes.sha256)
// Reinicio:
//   $ sudo mongod --config /etc/mongod.conf --shutdown && sudo mongod --config /etc/mongod.conf --fork
db.getProfilingStatus()                 // was: 0 (el nivel no sobrevive)
db.system.profile.countDocuments()      // los documentos sí
bitacora().length                       // menor: la memoria de getLog se vació

// Configuración persistente aplicada en /etc/mongod.conf:
//   operationProfiling:
//     mode: slowOp
//     filter: '{ "op": { "$in": ["insert", "update", "remove"] } }'
db.getProfilingStatus()
db.serverCmdLineOpts().parsed.operationProfiling
db.getSiblingDB("auditoria").getProfilingStatus()   // aplica a todas las bases
