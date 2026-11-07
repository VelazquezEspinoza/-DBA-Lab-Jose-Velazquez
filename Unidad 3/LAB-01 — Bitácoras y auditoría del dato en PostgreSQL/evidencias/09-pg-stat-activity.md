# Evidencia 09 — Sesiones activas con `pg_stat_activity` (Actividad 9)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

Para agilizar la prueba se usó `pg_sleep(20)` en lugar de `pg_sleep(90)`; el comportamiento es el mismo.

```text
$ psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial?application_name=reporte-mensual" -c "SELECT pg_sleep(20)"
```

## Mientras el reporte se ejecuta

```text
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid  |   usename   | application_name | client_addr |         backend_start         | state  |             query
------+-------------+------------------+-------------+-------------------------------+--------+--------------------------------
 3059 | postgres    | psql             |             | 2026-11-07 03:12:55.512671+00 | active | SELECT pid, usename, applicati
 3055 | soporte_ana | reporte-mensual  | 127.0.0.1   | 2026-11-07 03:12:52.506089+00 | active | SELECT pg_sleep(20)
(2 rows)
```

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[3055]%' ORDER BY num;
                                                                                                                                   linea
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-07 03:12:52.506 UTC [3055] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36784
 2026-11-07 03:12:52.515 UTC [3055] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="soporte_ana" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-07 03:12:52.515 UTC [3055] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
(3 rows)
```

## Después de que terminó

```text
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid  | usename  | application_name | client_addr |         backend_start         | state  |             query
------+----------+------------------+-------------+-------------------------------+--------+--------------------------------
 3072 | postgres | psql             |             | 2026-11-07 03:13:17.825107+00 | active | SELECT pid, usename, applicati
(1 row)

SELECT linea FROM dba.bitacora WHERE linea LIKE '%[3055]%' ORDER BY num;
                                                                                                                                   linea
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-07 03:12:52.506 UTC [3055] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=36784
 2026-11-07 03:12:52.515 UTC [3055] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="soporte_ana" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-07 03:12:52.515 UTC [3055] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
 2026-11-07 03:13:12.537 UTC [3055] user=soporte_ana db=comercial app=reporte-mensual client=127.0.0.1 LOG:  could not receive data from client: Connection reset by peer
 2026-11-07 03:13:12.537 UTC [3055] user=soporte_ana db=comercial app=reporte-mensual client=127.0.0.1 LOG:  disconnection: session time: 0:00:20.031 user=soporte_ana database=comercial host=127.0.0.1 port=36784
(5 rows)
```

La sesión 3055 ya no existe en `pg_stat_activity`, pero la bitácora conserva su conexión, su autenticación y su desconexión con la duración (`session time: 0:00:20.031`). La línea `could not receive data from client: Connection reset by peer` indica que el cliente cerró la conexión TCP sin enviar el mensaje de terminación del protocolo (el proceso `psql` lo cerró el entorno de pruebas al terminar). Esa línea también es evidencia: una sesión que termina así puede indicar una caída del cliente o una interrupción de red.

## Respuestas

**1. ¿Qué columna relaciona una sesión con sus líneas de bitácora?** `pid` de `pg_stat_activity`, que coincide con el `%p` entre corchetes del prefijo (`[3055]`). Como los PID se reutilizan con el tiempo, la relación se confirma también con el momento: `backend_start` (`03:12:52.506`) coincide con la línea `connection received` del mismo PID.

**2. Después de que termina el reporte, ¿qué fuente conserva evidencia?** Solo la bitácora. `pg_stat_activity` es una fotografía del momento: cuando la sesión termina, su fila desaparece.

**3. ¿Por qué `client_addr` está vacío en la sesión del administrador?** Porque se conecta por el socket Unix local (`client=[local]` en la bitácora), no por TCP. Las conexiones por socket no tienen dirección IP; en ese caso `client_addr` es NULL.
