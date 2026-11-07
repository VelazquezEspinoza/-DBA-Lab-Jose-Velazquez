# Evidencia 04 — Configurar la bitácora (Actividad 4)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

Script: `sql/02-configuracion-bitacora.sql`

## Cambio de parámetros (recarga, sin reinicio)

```text
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 row)
```

## Verificación del origen y últimas líneas

```text
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');
      name       |                 setting                 |       source       |                    sourcefile
-----------------+-----------------------------------------+--------------------+--------------------------------------------------
 log_connections | on                                      | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
 log_line_prefix | %m [%p] user=%u db=%d app=%a client=%h  | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
 log_statement   | ddl                                     | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
(3 rows)

SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;
 num |                                                                                                linea
-----+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  13 | 2026-11-07 03:12:32.175 UTC [2997] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authorized: user=postgres database=comercial application_name=psql
  12 | 2026-11-07 03:12:32.175 UTC [2997] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authenticated: identity="postgres" method=peer (/etc/postgresql/16/main/pg_hba.conf:118)
  11 | 2026-11-07 03:12:32.175 UTC [2997] user=[unknown] db=[unknown] app=[unknown] client=[local] LOG:  connection received: host=[local]
  10 | 2026-11-07 03:12:31.133 UTC [2952] user= db= app= client= LOG:  parameter "log_statement" changed to "ddl"
   9 | 2026-11-07 03:12:31.133 UTC [2952] user= db= app= client= LOG:  parameter "log_line_prefix" changed to "%m [%p] user=%u db=%d app=%a client=%h "
   8 | 2026-11-07 03:12:31.133 UTC [2952] LOG:  parameter "log_disconnections" changed to "on"
(6 rows)
```

Los tres parámetros provienen de `/var/lib/postgresql/16/main/postgresql.auto.conf`, el archivo que escribe `ALTER SYSTEM`.

## Análisis

- Las sentencias `ALTER SYSTEM` **no** aparecen: cuando se ejecutaron, `log_statement` todavía valía `none`.
- Sí aparecen las líneas `parameter "..." changed to "..."` (líneas 7–10 del archivo exportado), escritas por el PID **2952**, que es el proceso principal del servidor (el mismo que escribió `starting PostgreSQL` al arrancar). Son el registro del cambio de configuración.
- Las líneas 8 y 7 todavía no tienen `user= db=...` porque el prefijo nuevo se aplicó a partir de su propia línea (9).
- Las líneas 11–13 son mi propia sesión de administrador: consultar la bitácora también deja rastro. En este servidor, además, se registra `connection authenticated ... method=peer (pg_hba.conf:118)`.

## Respuestas

**1. ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?** `pg_reload_conf()` solo envía la señal `SIGHUP` al proceso principal (postmaster). Es ese proceso el que vuelve a leer `postgresql.conf` y `postgresql.auto.conf`, compara los valores y escribe qué cambió; después reenvía la señal a los demás procesos. La sesión no aplica el cambio, solo lo solicita. Consecuencia para la auditoría: la línea `changed to` dice *qué* cambió y *cuándo*, pero no *quién*; ese dato solo existe si la sentencia `ALTER SYSTEM` quedó registrada (lo que ocurre con `log_statement` en `ddl` o superior, como se vio en la Actividad 7).

**2. ¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?** Con el nivel actual quedarían dos rastros: la propia sentencia `ALTER SYSTEM` (con usuario, IP y aplicación) y la línea del proceso principal `parameter "log_statement" changed to "none"`. A partir de ahí ya no se registrarían las sentencias siguientes. Hay formas de dejar menos rastro: editar `postgresql.auto.conf` a mano y recargar (solo queda la línea `changed to`, sin autor), o que un superusuario ejecute `SET log_statement = 'none'` solo en su sesión, lo cual no cambia la configuración del servidor y no se registra con `ddl`/`mod`. Por eso la bitácora interna no basta para auditar al administrador.

**3. ¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?** El archivo lo administra el servidor: el propio archivo lo advierte en su encabezado, `ALTER SYSTEM` lo reescribe completo (y puede perder o duplicar lo editado), un error de sintaxis puede impedir que el servidor arranque, y la edición manual no deja registro de la sentencia ni de quién la hizo. `ALTER SYSTEM` valida el valor antes de escribirlo y deja rastro.
