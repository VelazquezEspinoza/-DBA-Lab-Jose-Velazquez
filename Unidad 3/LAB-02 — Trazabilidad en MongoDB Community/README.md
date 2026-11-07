# LAB-02 — Trazabilidad en MongoDB Community

**Estudiante:** `<Velazquez Espinoza Jose Fernando>` · **Matrícula:** `<16531711>`
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · Unidad III · Temas 3.1 y 3.2

## Despliegue del servidor

| Elemento | Valor |
|---|---|
| Forma de despliegue | Instalación nativa en Linux (Ubuntu 24.04): binarios de **MongoDB 7.0.34 Community** (paquete `mongodb` de conda-forge, sin módulo Enterprise), con usuario de servicio `mongodb` y archivo de configuración `/etc/mongod.conf` con la misma estructura que el paquete oficial |
| Versión | `db.version()` → 7.0.34 · `buildInfo.modules` → `[]` |
| Cliente | mongosh 2.14.1 |
| Arranque | `mongod --config /etc/mongod.conf --fork` (argv verificado con `getCmdLineOpts`) |
| Reinicio | `mongod --config /etc/mongod.conf --shutdown` y nuevo arranque (en un paquete con systemd: `sudo systemctl restart mongod`) |
| Bitácora | `systemLog.destination: file`, `path: /var/log/mongodb/mongod.log`, `logAppend: true` |
| Control de acceso | `security.authorization: enabled`; usuarios creados con la excepción de localhost |
| Red | `bindIp: 127.0.0.1`, puerto 27017 |

Configuración inicial (`/etc/mongod.conf`):

```yaml
storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
net:
  port: 27017
  bindIp: 127.0.0.1
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
security:
  authorization: enabled
```

Al final de la Actividad 8 se agregó, para que el perfilado sea persistente (evidencia 08):

```yaml
operationProfiling:
  mode: slowOp
  filter: '{ "op": { "$in": ["insert", "update", "remove"] } }'
```

## Contenido

```
LAB-02/
├── README.md
├── evidencias/
│   ├── 01-edicion-y-limitacion.md               Actividad 1 (y sección 6.3)
│   ├── 02-incidente-sin-perfilado.md            Actividad 2
│   ├── 03-perfilador.md                         Actividad 3
│   ├── 04-filtro.md                             Actividad 4
│   ├── 05-accesos-mongod.md                     Actividad 5
│   ├── 06-correlacion.md                        Actividad 6
│   ├── 07-privilegios-control-compensatorio.md  Actividad 7
│   ├── 08-conservacion.md                       Actividad 8
│   ├── 09-comparacion.md                        Actividad 9
│   ├── 10-respuesta-direccion.md                Actividad 10
│   ├── system-profile.json                      Actividad 8 (exportación de la guía)
│   ├── system-profile-actividad3.json           Exportación previa al drop() de la Actividad 4
│   ├── bitacora-mongod.log                      Actividad 8 (getLog, eventos en memoria)
│   ├── mongod.log                               Actividad 8 (archivo systemLog.path, historia completa)
│   ├── hashes.sha256                            SHA-256 de los cuatro archivos exportados
│   └── capturas/                                Capturas de apoyo de los pasos principales
├── scripts/
│   └── comandos-mongosh.js
└── informe.md
```

Las capturas complementan, no sustituyen, las exportaciones y la interpretación escrita. Todas las contraseñas visibles se sustituyeron por `<REDACTED>`.

## Verificación de integridad

```
$ cd evidencias && sha256sum -c hashes.sha256
bitacora-mongod.log: OK
mongod.log: OK
system-profile.json: OK
system-profile-actividad3.json: OK
```

## Verificación final (sección 17)

| Punto | Dónde |
|---|---|
| Auditoría nativa inexistente en Community, con evidencia de la edición | 01 (`modules: []` y `unrecognised option '--auditDestination'`) |
| Destino de la bitácora identificado | 01 (`/var/log/mongodb/mongod.log`) |
| `system.profile` con `query`, `update` y `remove` de `app_ventas` | 03 y `system-profile-actividad3.json` |
| Usuario, cliente, aplicación y momento interpretados | 03 (tabla 9.1) |
| Filtro aplicado y evidencia perdida explicada | 04 |
| Acceso fallido y exitoso interpretados | 05 |
| Cambio de configuración correlacionado con su autor por `ctx` | 06 |
| Control compensatorio de privilegios | 07 |
| `system.profile` y bitácora exportados con hash | 08 y `hashes.sha256` |
