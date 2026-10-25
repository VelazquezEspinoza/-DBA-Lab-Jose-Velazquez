# Registro de cambios — LAB-04

> Entorno: instancia PostgreSQL 16 de práctica (host `vm`, 25-oct-2026). Respaldos en `pg_hba.antes.conf` / `pg_hba.despues.conf`.

> Un hardening que no se documenta no se puede reproducir ni verificar.
> Completa **Antes** con lo que observaste realmente (salida de `01-inspeccion.sql`) antes de cambiar nada.

| # | Fecha | Componente | Antes | Después | Comando / archivo | Justificación | Verificación | Reversión |
|---|-------|-----------|-------|---------|-------------------|---------------|--------------|-----------|
| 1 | 2026-10-25 | `listen_addresses` | `'*'` | `'localhost'` (en el lab real: `'localhost,10.10.10.20'`) | `ALTER SYSTEM` + reinicio | Escuchar solo en interfaces necesarias | `SHOW listen_addresses;` / `ss -lnt` | `ALTER SYSTEM RESET listen_addresses;` + reinicio |
| 2 | 2026-10-25 | `pg_hba.conf` regla amplia | `host all all 0.0.0.0/0 md5` y `::/0 md5` | Regla específica (ver abajo) | Edición de `pg_hba.conf` + `pg_reload_conf()` | Mínimo privilegio: BD + usuario + origen + método | `pg_hba_file_rules`; prueba desde origen no autorizado | Restaurar respaldo `pg_hba.conf.bak` |
| 3 | 2026-10-25 | `password_encryption` | `md5` | `scram-sha-256` | `ALTER SYSTEM` + `pg_reload_conf()` | Evitar md5 heredado | `SHOW`; tipo en `pg_authid` | `RESET` |
| 4 | 2026-10-25 | Roles | `webapp` SUPERUSER usada por la app; `reportes` con CREATEROLE/CREATEDB | `app_user` sin privilegios admin | `sql/02-roles.sql` | Limitar impacto si la app es comprometida | Consulta de `pg_roles` | `ALTER ROLE ...` |
| 5 | 2026-10-25 | Timeouts | `0` / `0` | `idle_in_transaction_session_timeout=5min`, `statement_timeout=60s` | `ALTER SYSTEM` | Disponibilidad / consumo de recursos | `SHOW` | `RESET` |
| 6 | 2026-10-25 | Logging | `off` | `log_connections=on`, `log_disconnections=on` | `ALTER SYSTEM` | Trazabilidad y monitoreo | Revisar log del servidor | `RESET` |
| 7 | 2026-10-25 | TLS | `ssl=off` | `ssl=on`, `ssl_min_protocol_version=TLSv1.2` | `ALTER SYSTEM` + reinicio (certificado snakeoil de práctica; en producción usar certificado de una CA) | Cifrado en tránsito (ver LAB-02) | `pg_stat_ssl` | `RESET` |
| 8 | 2026-10-25 | Permisos SO | `*.conf` 644, data dir 750 | `0600/0640` archivos, `0700` data dir | `chmod` / `chown` | Evitar lectura por otros usuarios del SO | `ls -l`, `ls -ld` | |
| 9 | — | Firewall (diseño) | No aplicable en la instancia de práctica | Permitir 10.10.10.0/24 → 5432; denegar resto | Solo documentado | Defensa en profundidad | Prueba de conexión desde otra red | |

## Regla de pg_hba.conf — antes y después

```conf
# ANTES (insegura: todas las BD, todos los usuarios, cualquier IPv4)
host    all             all             0.0.0.0/0               scram-sha-256

# DESPUÉS (ajustar al entorno real del laboratorio)
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   basedatos_app   app_user                                scram-sha-256
host    basedatos_app   app_user        10.10.10.0/24           scram-sha-256
host    basedatos_app   consulta_user   10.10.10.0/24           scram-sha-256
hostssl all             dba_lab         10.10.10.0/24           scram-sha-256
# Todo lo demás queda denegado implícitamente (no hay regla que coincida)
```

Procedimiento seguro:

```bash
sudo cp <hba_file> <hba_file>.bak          # respaldo
sudo -u postgres nano <hba_file>           # editar
psql -c "SELECT * FROM pg_hba_file_rules WHERE error IS NOT NULL;"   # validar sintaxis
psql -c "SELECT pg_reload_conf();"         # aplicar sin reiniciar
```

> Ojo: mantén una sesión de `psql` abierta mientras recargas, para poder revertir si te quedas sin acceso.

## Permisos del sistema operativo

```bash
# Rutas reales: SHOW config_file; SHOW hba_file; SHOW ident_file; SHOW data_directory;
sudo chown postgres:postgres <config_file> <hba_file> <ident_file>
sudo chmod 640 <config_file> <hba_file> <ident_file>   # (en Debian/Ubuntu están en /etc/postgresql y pueden ser 644: revisar)
sudo chmod 700 <data_directory>
sudo chmod 600 <ssl_key_file>
```

## Cambio adicional
| Extensión `file_fdw` | Instalada | Eliminada (`DROP EXTENSION file_fdw;`) | Permite leer archivos del servidor; no necesaria |
