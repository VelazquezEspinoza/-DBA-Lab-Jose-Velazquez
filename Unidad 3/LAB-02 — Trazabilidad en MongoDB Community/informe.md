# Informe — LAB-02 · Trazabilidad en MongoDB Community

**Estudiante:** `<Velazquez Espinoza Jose Fernando>` · **Matrícula:** `<16531711>`
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · Unidad III
**Fecha de ejecución:** 2026-11-07 UTC (2026-11-06 por la noche, hora de Culiacán)

## 1. Despliegue, edición y limitación

El servidor es MongoDB **7.0.34 Community**, instalado de forma nativa en Ubuntu 24.04, con `/etc/mongod.conf`, autorización habilitada, escucha solo en 127.0.0.1 y bitácora en `/var/log/mongodb/mongod.log` con `logAppend: true`. Los usuarios `admin` (`root`) y `app_ventas` (`readWrite` en `comercial`) se crearon con la excepción de localhost.

**Qué no existe:** la auditoría nativa (REF-U3-04), que solo está en Enterprise y Atlas (M10 o superior). Se verificó de dos formas: `buildInfo.modules` es `[]` (en Enterprise incluiría `"enterprise"`), y al intentar arrancar `mongod` con `--auditDestination` el binario respondió `unrecognised option`. La función no está apagada: no existe en esta edición. Siguiendo la regla del laboratorio, no se simuló; donde una pregunta solo podría responderse con ella, la respuesta es “No hay evidencia con esta edición”.

## 2. Perfilador

**Configuración.** Por defecto, nivel 0 (apagado). Se usó nivel 2 en `comercial` (Actividad 3), luego nivel 1 con el filtro `op ∈ {insert, update, remove}` (Actividad 4) y, al final, la misma configuración en forma persistente en `/etc/mongod.conf` (`operationProfiling.mode: slowOp` con `filter`), que se aplica desde el arranque a todas las bases.

**Interpretación.** Con nivel 2 quedaron registradas las tres operaciones de `app_ventas`. Cada documento indica tipo (`op`), colección (`ns`), comando completo, usuario (`app_ventas@comercial`: el usuario se identifica con su base), cliente (127.0.0.1), aplicación declarada (`app-ventas-web`), momento (`ts`) y efecto (`nreturned: 3`, `nModified: 1`, `ndeleted: 1`). Esto permitió atribuir el cambio del RFC a `GAMA780912XYZ` a `app_ventas` a las 04:00:09.636 UTC. **No** registra el documento antes ni después: el valor anterior del RFC y los datos del cliente eliminado no se pueden recuperar. Tampoco registró `grantRolesToUser`, ni siquiera en nivel 2.

**Costo.** Cada operación perfilada genera una escritura adicional, y en nivel 2 eso incluye todas las lecturas. La documentación advierte la degradación de desempeño, en especial en nivel 2 (REF-U3-05). Además, `system.profile` es una colección limitada de 1 MB: más volumen significa que la evidencia se sobrescribe antes. El nivel 2 también copia al perfilador los filtros de las consultas, que pueden contener datos personales. El filtro reduce el costo y prolonga la ventana de evidencia de las modificaciones, a cambio de perder toda evidencia de lecturas y comandos.

## 3. Bitácora de mongod

**Dónde se escribe.** En `/var/log/mongodb/mongod.log`, según `serverCmdLineOpts().parsed.systemLog`. `getLog` (función `bitacora()`) da acceso a los últimos 1024 eventos en memoria; se usó para interpretar, pero se vació al reiniciar (de 600 a 60 eventos). El archivo conservó los tres arranques del laboratorio.

**Accesos.** Las autenticaciones se registran por defecto. El éxito (`Successfully authenticated`, id 5286306, `result: 0`) incluye usuario, base, mecanismo, IP:puerto y `appName`. El fallo (`Failed to authenticate`, id 5286307) distingue en `error`/`result` la contraseña incorrecta (`storedKey mismatch`, 18) del usuario inexistente (`UserNotFound`, 11), mientras que el cliente recibe en ambos casos el mismo `Authentication failed.` para evitar la enumeración de usuarios. Un mismo intento puede producir varias líneas (autenticación especulativa y reintento), así que se cuentan conexiones, no líneas. También se observó que una sola ejecución de mongosh abre varias conexiones (monitoreo sin autenticar y conexiones del *pool* autenticadas), y que sus comprobaciones de arranque generan `Checking authorization failed` para una cuenta sin privilegios en `admin`.

**Cambios de configuración.** `Profiler settings changed` registra `from`, `to` y la base, pero **no** el usuario. El autor se obtuvo correlacionando el `ctx` (conn62) con la autenticación de la misma conexión (`admin@admin`). Esa correlación solo es válida dentro de un mismo arranque, porque los números de conexión se reinician: `conn2` aparece en tres arranques distintos del archivo. La bitácora registró también el `drop` de `system.profile` y las creaciones de colecciones, con su `ctx`.

## 4. Privilegios

**Evidencia disponible: ninguna sobre la operación.** `grantRolesToUser` no dejó rastro en `system.profile` (con nivel 2) ni en la bitácora. **Control compensatorio:** instantáneas de `getUsers()` en `auditoria.instantaneas_privilegios`, con el momento y quién la tomó. Su comparación detectó que `app_ventas` ganó `dbAdmin@comercial` entre 04:00:54.286 y 04:00:54.479 UTC, y una instantánea de cierre mostró que el rol ya no estaba a las 04:06:36.

**Límite.** El control detecta que hubo un cambio, pero no lo atribuye ni lo fecha con exactitud: un privilegio otorgado y retirado entre dos instantáneas es invisible. Además, quien tenga `root` puede alterar la colección de instantáneas. Es una medida compensatoria y así debe documentarse: no equivale a auditoría.

## 5. Conservación

**Riesgos observados.**

- El nivel del perfilador se perdió al reiniciar (de 1 con filtro a 0).
- `getLog` se vació (de 600 a 60 eventos).
- El `drop()` de la Actividad 4 eliminó las operaciones de la Actividad 3.
- `system.profile` de 1 MB se sobrescribe solo según el tráfico.

**Exportación realizada.**

| Archivo | Contenido |
|---|---|
| `system-profile.json` | El comando de la guía |
| `system-profile-actividad3.json` | Exportación previa al `drop()` |
| `bitacora-mongod.log` | `getLog` |
| `mongod.log` | Copia del archivo completo |

Los cuatro tienen SHA-256 en `hashes.sha256`, verificado con `sha256sum -c`, y no contienen contraseñas. Como en el LAB-01, el hash permite demostrar que un archivo no cambió, pero no impide que cambie, y solo es útil si se guarda fuera del control de quien podría alterar la evidencia.

## 6. Comparación

| Evento | PostgreSQL | MongoDB Community | Enterprise/Atlas |
|---|---|---|---|
| Acceso exitoso / fallido | Sí | Sí (por defecto) | Documentado |
| Cambio de privilegios | Sí | **No** (solo detección por instantáneas) | Documentado |
| Cambio de estructura | Sí | Parcial (vía `ctx`) | Documentado |
| Modificación de datos | Sí | Parcial (si el perfilador estaba activo) | Documentado |
| Valor anterior | Sí (disparador) | **No** | No consta |
| Lectura de datos sensibles | Parcial (pgaudit) | Parcial (nivel 2) | Documentado |
| Cambio de configuración del registro | Sí | Parcial (sin usuario; vía `ctx`) | Documentado |

“Documentado” significa “Documentado, no practicado”. El detalle está en la evidencia 09.

## 7. Recomendación

Para una organización que necesite auditar cambios de privilegios en MongoDB:

**Hechos verificados en este laboratorio.** Community no registra `grantRolesToUser` ni `revokeRolesFromUser` en ningún mecanismo: ni el perfilador en nivel 2 ni la bitácora. Las instantáneas detectan el cambio pero no lo atribuyen. La correlación por `ctx` solo existe para los eventos que la bitácora sí registra.

**Recomendación.**

1. **Si se exige atribución (quién y cuándo exactamente):** usar MongoDB Enterprise o Atlas M10+ con auditoría nativa, filtrada a eventos de autenticación, usuarios, roles y DDL (no CRUD completo, por su costo). Que su destino sea un sistema externo custodiado por otra área.
2. **Mientras tanto, o si el costo no se justifica:**
   - Reducir el número de cuentas con `userAdmin`/`root` a cuentas nominales de uso excepcional, nunca compartidas.
   - Canalizar todo cambio de privilegios por un procedimiento con solicitud y aprobación registradas fuera de la base de datos.
   - Automatizar instantáneas frecuentes (usuarios y roles) enviadas a otro sistema, con alerta ante cualquier diferencia no aprobada.
   - Conservar `mongod.log` con `logAppend` y enviarlo a un repositorio central.
3. **Para el valor anterior de los datos:** Enterprise tampoco lo resolvería según su documentación. Se requeriría un registro de cambios en la aplicación o *change streams* con *pre-images* en un conjunto de réplicas.

**Supuestos no verificados.**

- El comportamiento exacto de la auditoría de Enterprise/Atlas (formato, eventos, costo) se basa solo en su documentación; no se practicó.
- Que el costo de licencia supere al riesgo depende de cada organización.
- La frecuencia de 15 minutos para las instantáneas es una propuesta, no un estándar.

## 8. Reflexión

**1. ¿Por qué el perfilador no debe presentarse como auditoría de seguridad?** Porque fue diseñado para desempeño, y sus características lo muestran:

- Viene apagado.
- Se configura por base y se pierde al reiniciar.
- Lo puede cambiar o borrar cualquiera con `dbAdmin` (incluso `app_ventas`, si obtiene ese rol).
- Su colección se sobrescribe sola.
- No registra privilegios ni el valor anterior.

Presentarlo como auditoría daría a Dirección una garantía que no existe.

**2. ¿Por qué sí aporta trazabilidad?** Porque, mientras está activo, liga cada operación a un usuario autenticado, un cliente, una aplicación declarada y un momento, con su efecto. Eso respondió quién cambió el RFC en la Actividad 3 y quién eliminó un cliente.

**3. ¿Qué riesgo introduce el nivel 2 con filtros que contienen datos personales?** Copia al perfilador los valores buscados (RFC, correo, nombre) fuera de los controles de la colección original, y los expone a cualquiera con `dbAdmin`. Convierte una herramienta de diagnóstico en un depósito de datos personales sin política de retención, como `log_statement = all` en PostgreSQL.

**4. ¿Qué diferencia hay entre detectar un cambio y atribuirlo?** Detectar es saber que algo cambió y qué; las instantáneas lo lograron. Atribuir es demostrar quién lo hizo y cuándo, con evidencia que lo ligue a una identidad. Sin atribución no puede exigirse responsabilidad ni distinguir un error de un abuso.

**5. ¿Por qué reconocer una limitación técnica es parte del trabajo del DBA?** Porque las decisiones de riesgo se toman sobre lo que el DBA afirma que puede demostrarse. Simular una capacidad, o callar su ausencia, produce falsa seguridad y evidencia que no resistirá una revisión. Declarar “No hay evidencia con esta edición”, con su motivo técnico, permite a la organización decidir: aceptar el riesgo, compensarlo o invertir para cerrarlo.
