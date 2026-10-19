# Evidencia 04 — Configuración y verificación de TLS

## Objetivo
Comprobar el estado real de TLS en PostgreSQL 16, verificar que una sesión lo utiliza y comparar el comportamiento de los distintos `sslmode`.

## Comando o procedimiento
Script: [`sql/03-verificacion-tls.sql`](../sql/03-verificacion-tls.sql)

Configuración del servidor usada en el laboratorio (`postgresql.conf`):
```conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file  = 'server.key'          # permisos 0600, propietario postgres
ssl_min_protocol_version = 'TLSv1.2'
listen_addresses = 'localhost'
port = 5433
```
Certificados de laboratorio: una CA propia (`CN=LAB02-CA`) firmó un certificado de servidor con `CN=localhost` y `subjectAltName=DNS:localhost`. Ver [`docs/generar-certificados-lab.md`](../docs/generar-certificados-lab.md).

Conexión:
```bash
psql "host=localhost port=5433 dbname=lab02 user=postgres sslmode=require" -f sql/03-verificacion-tls.sql
```

## Resultado obtenido

**Parámetros del servidor**
```
ssl                       = on
ssl_min_protocol_version  = TLSv1.2
port                      = 5433
listen_addresses          = localhost
inet_client_addr / port   = 127.0.0.1 / 60484
```

**Sesión actual (`pg_stat_ssl`)**
```
 ssl | version |         cipher
-----+---------+------------------------
 t   | TLSv1.3 | TLS_AES_256_GCM_SHA384
```

**Comparación de `sslmode` (host `localhost`)**

| sslmode | Resultado | ssl / versión / cifrado |
|---|---|---|
| `disable` | Conecta | `f` / — / — (sin TLS) |
| `require` | Conecta | `t` / TLSv1.3 / TLS_AES_256_GCM_SHA384 |
| `verify-ca` + `sslrootcert=ca.crt` | Conecta | `t` / TLSv1.3 / TLS_AES_256_GCM_SHA384 |
| `verify-full` + `sslrootcert=ca.crt` | Conecta | `t` / TLSv1.3 / TLS_AES_256_GCM_SHA384 |

**Pruebas negativas**
```
verify-full contra host=127.0.0.1 (el certificado es para "localhost"):
  psql: error: ... server certificate for "localhost" (and 1 other name)
        does not match host name "127.0.0.1"

verify-ca contra host=127.0.0.1:
  conecta (ssl = t)  -> verify-ca NO revisa el nombre

verify-full con una CA que no firmó el certificado (bundle del sistema):
  psql: error: ... SSL error: certificate verify failed

Conexión por socket Unix (sin red):
  ssl = f  (TLS no aplica en sockets locales)
```

## Análisis

**¿La conexión actual usa TLS?** Sí (`ssl = t`).
**¿Versión?** TLSv1.3. **¿Algoritmo?** `TLS_AES_256_GCM_SHA384` (AES-256 en modo GCM, que además autentica los datos).

**Con TLS vs. sin TLS:** sin TLS (`sslmode=disable`) consultas, resultados y el intercambio de autenticación viajan en claro o con protección débil; quien observe la red puede leerlos o alterarlos. Con TLS se obtiene confidencialidad, integridad y (con certificados verificados) autenticación del servidor.

**`require` vs. `verify-ca` vs. `verify-full`:**
- `require` cifra, pero **no valida** quién está al otro lado: un atacante en medio (MITM) con cualquier certificado pasaría.
- `verify-ca` valida que el certificado lo firmó una CA confiable, pero **no el nombre** (la prueba contra `127.0.0.1` conectó).
- `verify-full` valida CA **y** nombre: rechazó `127.0.0.1` y rechazó una CA no confiable. Es el modo que debe usarse cuando se requiere identificar al servidor.

**Aviso:** `sslmode=prefer` (el valor por defecto de libpq) **vuelve a texto claro** si el servidor no ofrece TLS; no es una garantía de seguridad.

**Limitaciones:** TLS protege la comunicación; no sustituye roles, permisos ni `pg_hba.conf`. Para **forzar** TLS en el servidor se usan líneas `hostssl` (y se evitan `host`) en `pg_hba.conf`. En el entorno de práctica la autenticación era `trust` sólo por ser un laboratorio local aislado; en producción se usa `scram-sha-256`.

## Conclusión
Se verificó con `pg_stat_ssl` que la sesión viaja por TLS 1.3 y se comprobó empíricamente que solo `verify-full` detecta un nombre de servidor incorrecto. Cifrar la conexión no es lo mismo que verificar con quién se establece.

> Nota: estos resultados se obtuvieron en un servidor local de laboratorio. Si tu servidor de la materia difiere (host, versión de TLS, cifrado), reemplaza los valores con los de tu ejecución.
