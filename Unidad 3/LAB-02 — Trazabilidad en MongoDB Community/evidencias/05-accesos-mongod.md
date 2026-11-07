# Evidencia 05 — Accesos en la bitácora de mongod (Actividad 5)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-02**  
**Servidor:** MongoDB 7.0.34 Community · `/etc/mongod.conf` · 127.0.0.1:27017 · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la noche, hora de Culiacán, UTC−7)  
**Sesión del DBA:** `mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin"`  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

## Intentos fallidos

```text
$ mongosh "mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
MongoServerError: Authentication failed.
$ mongosh "mongodb://usuario_inexistente:x@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
MongoServerError: Authentication failed.
```

## Bitácora: fallos y último acceso exitoso

```text
comercial> function bitacora() {
...   return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
... }
[Function: bitacora]
comercial> bitacora()
...   .filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
...   .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client, error: e.attr.error, result: e.attr.result, isSpeculative: e.attr.isSpeculative, app: e.attr.doc.application.name }))
[
  {
    t: { '$date': '2026-11-07T04:00:34.713+00:00' },
    id: 5286307,
    ctx: 'conn72',
    user: 'app_ventas',
    client: '127.0.0.1:43752',
    error: 'AuthenticationFailed: SCRAM authentication failed, storedKey mismatch',
    result: 18,
    isSpeculative: true,
    app: 'mongosh 2.14.1'
  },
  {
    t: { '$date': '2026-11-07T04:00:35.446+00:00' },
    id: 5286307,
    ctx: 'conn74',
    user: 'usuario_inexistente',
    client: '127.0.0.1:43770',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    isSpeculative: true,
    app: 'mongosh 2.14.1'
  },
  {
    t: { '$date': '2026-11-07T04:00:35.448+00:00' },
    id: 5286307,
    ctx: 'conn74',
    user: 'usuario_inexistente',
    client: '127.0.0.1:43770',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    isSpeculative: false,
    app: 'mongosh 2.14.1'
  }
]
comercial> bitacora()
...   .filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas")
...   .slice(-1)
...   .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc.application.name }))
[
  {
    t: { '$date': '2026-11-07T04:00:27.415+00:00' },
    id: 5286306,
    ctx: 'conn66',
    client: '127.0.0.1:43686',
    result: 0,
    app: 'app-ventas-web'
  }
]
```

![Accesos en la bitácora de mongod](capturas/05-accesos.png)

## Conteo de intentos, no de líneas

| Usuario | Líneas `Failed to authenticate` | Conexiones (`ctx`) | Intentos reales |
|---|---|---|---|
| app_ventas | 1 (`isSpeculative: true`) | conn72 | 1 |
| usuario_inexistente | 2 (`isSpeculative: true` y `false`) | conn74 | 1 |

Con la autenticación especulativa, el cliente envía el primer paso de SCRAM junto con el saludo inicial (`hello`). Si falla, puede reintentar de forma normal en la misma conexión. Con la contraseña incorrecta, el cliente no reintentó; con el usuario inexistente, sí. Por eso la forma correcta de contar es por conexión (`ctx`) o por cliente y puerto, no por líneas. En `scripts/comandos-mongosh.js` se incluye la consulta que agrupa por usuario y cuenta conexiones distintas.

## Lectura del primer evento

| Campo | Valor | Significado |
|---|---|---|
| `t` | 2026-11-07T04:00:34.713+00:00 | Momento, en UTC con zona explícita (21:00:34 del 6-nov en Culiacán) |
| `id` | 5286307 | Tipo de mensaje “Failed to authenticate” (el éxito es 5286306) |
| `ctx` | conn72 | Conexión que lo produjo |
| `user` | app_ventas | Nombre que **presentó** el cliente |
| `client` | 127.0.0.1:43752 | IP y puerto de origen |
| `error` | AuthenticationFailed: … storedKey mismatch | La prueba SCRAM no coincide: contraseña incorrecta |
| `result` | 18 | Código de error `AuthenticationFailed` |
| `app` | mongosh 2.14.1 | Nombre de aplicación declarado por el cliente |

## Respuestas

**1. ¿Qué campo distingue un acceso fallido de uno exitoso?** `result`: **0** en el exitoso y un código de error distinto de 0 en el fallido (18 = `AuthenticationFailed`, 11 = `UserNotFound`). También lo indican `msg` (“Failed to authenticate” frente a “Successfully authenticated”) e `id` (5286307 frente a 5286306); para filtrar por programa conviene usar `id` o `result`, que no dependen del texto.

**2. Diferencia entre contraseña incorrecta y usuario inexistente. ¿Por qué el cliente recibe el mismo mensaje?** En la bitácora, la contraseña incorrecta aparece como `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` (`result: 18`): el usuario existe y la prueba criptográfica no coincide. El usuario inexistente aparece como `UserNotFound: Could not find user "usuario_inexistente" for db "comercial"` (`result: 11`). El cliente recibe en ambos casos solo `Authentication failed.` para impedir la **enumeración de usuarios**: un atacante no puede averiguar qué cuentas existen probando nombres. El DBA sí necesita la diferencia, y la obtiene de la bitácora, que solo él puede leer.

**3. ¿Por qué la aplicación del intento fallido es `mongosh 2.14.1` y no `app-ventas-web`?** Porque esas cadenas de conexión no incluyeron `?appName=app-ventas-web`, y mongosh usa su nombre y versión por defecto. El nombre de aplicación lo declara el cliente libremente: identifica qué programa dice ser, pero no es evidencia de identidad. Cualquiera puede escribir `appName=app-ventas-web`.
