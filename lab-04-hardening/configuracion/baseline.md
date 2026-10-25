# Baseline de seguridad — PostgreSQL 16 (Comercializadora Norte S.A. de C.V.)

> **Entorno de práctica:** los valores "Antes/Después" de la comparación provienen de una instancia PostgreSQL 16.x (Ubuntu 24, host `vm`) levantada con el escenario del laboratorio, no de un servidor institucional.

> Estado esperado después del hardening. Valores de red (10.10.10.x) son los del escenario del laboratorio; ajústalos a tu entorno.

## 1. Red
| Elemento | Valor esperado |
|----------|----------------|
| Interfaces de escucha | `localhost` + IP privada del servidor (`10.10.10.20`); nunca `'*'` sin justificación |
| Puerto | 5432 documentado (cambiarlo no es control de seguridad) |
| Firewall | Permitir TCP 5432 solo desde 10.10.10.0/24; denegar el resto |
| Redes permitidas | Red DBA / red de aplicación, definidas explícitamente |
| Segmentación | Servidor en red privada, sin exposición directa a Internet |

## 2. Autenticación
| Elemento | Valor esperado |
|----------|----------------|
| Método | `scram-sha-256` (sin `trust`, `password` ni `md5`) |
| `password_encryption` | `scram-sha-256` |
| Credenciales | Contraseñas largas y únicas, rotación periódica, gestionadas fuera del código |
| Cuentas administrativas | Nominales, mínimas en número, sin uso por aplicaciones |

## 3. Autorización
| Elemento | Valor esperado |
|----------|----------------|
| Roles | `dba_lab` (admin), `app_user` (aplicación), `consulta_user` (solo lectura) |
| Superusuarios con LOGIN | Mínimos y nominales: `postgres` (peer local) y un DBA nominal restringido a origen local con TLS |
| Privilegios | Mínimos; `REVOKE` de privilegios a `PUBLIC`; `CONNECTION LIMIT` por rol |
| Cuentas de aplicación | Sin `SUPERUSER`, `CREATEDB`, `CREATEROLE` |

## 4. Configuración de PostgreSQL
| Parámetro | Valor esperado |
|-----------|----------------|
| `listen_addresses` | `localhost,10.10.10.20` |
| `max_connections` | Dimensionado a la carga real |
| `superuser_reserved_connections` | 3 |
| `idle_in_transaction_session_timeout` | 5 min |
| `statement_timeout` | 60 s (ajustar a la aplicación) |
| `log_connections` / `log_disconnections` | `on` |
| Extensiones | Solo las necesarias; las de práctica se eliminan fuera del lab |

## 5. Sistema operativo
| Elemento | Valor esperado |
|----------|----------------|
| Propietario de archivos | `postgres:postgres` |
| `postgresql.conf`, `pg_hba.conf`, `pg_ident.conf` | `640` o más restrictivo, sin lectura para "otros" |
| Directorio de datos | `700` |
| Clave privada TLS | `600` |

## 6. Cifrado
| Elemento | Valor esperado |
|----------|----------------|
| TLS | `ssl=on`, `ssl_min_protocol_version=TLSv1.2` o superior; `hostssl` para accesos remotos |
| Protección de credenciales | Sin contraseñas en repositorios, scripts ni logs; uso de `\password` / archivos `.pgpass` con `0600` |
| Información sensible | Protegida según LAB-01 a LAB-03 |

## 7. Mantenimiento
| Elemento | Valor esperado |
|----------|----------------|
| Actualizaciones | Política documentada: parches menores de PostgreSQL 16 y del SO en ventanas definidas, probados antes en un ambiente no productivo |
| Revisión periódica | Trimestral: roles, `pg_hba.conf`, extensiones, permisos SO, firewall |
| Documentación | Este baseline + `cambios.md` versionados en Git |

## Comparación antes / después (Actividad 16)

| Control | Antes | Después | Justificación |
|---------|-------|---------|---------------|
| listen_addresses | `'*'` (todas las interfaces) | `localhost` (127.0.0.1:5432 según `ss -lnt`) | Reducir interfaces expuestas |
| pg_hba.conf | `host all all 0.0.0.0/0 md5` y `host all all ::/0 md5` | Reglas `hostssl` por BD + usuario + red (127.0.0.1/32, 10.10.10.0/24); 0 reglas amplias | Mínimo privilegio |
| Método de autenticación | md5 (heredado) en reglas remotas; `password_encryption=md5` | `scram-sha-256` en todas las reglas; `password_encryption=scram-sha-256`; contraseñas re-establecidas | Evitar métodos heredados/inseguros |
| Usuarios administrativos | 3 superusuarios con login: `postgres`, `dba_lab_admin`, `webapp`; `reportes` con CREATEROLE/CREATEDB | 2 superusuarios: `postgres` (solo peer local) y `dba_lab_admin` (solo 127.0.0.1/::1 con TLS); `webapp` y `reportes` sin privilegios y NOLOGIN | Reducir impacto de compromiso |
| Cuentas de aplicación | La app usaba `webapp` (SUPERUSER) | `app_user` (sin SUPERUSER/CREATEDB/CREATEROLE, límite 20 conexiones) y `consulta_user` (solo SELECT) | Mínimo privilegio |
| Puerto | 5432 | 5432 (documentado; no se considera control de seguridad) | El puerto no es control de seguridad |
| TLS | `ssl=off`; sesión sin TLS | `ssl=on`, `ssl_min_protocol_version=TLSv1.2`; sesión con TLSv1.3 / TLS_AES_256_GCM_SHA384 (certificado autofirmado de práctica) | Cifrado en tránsito |
| Permisos SO | `*.conf` 644 (legibles por todos); data dir 750 | `*.conf` 640; data dir 700 (`postgres:postgres`) | Proteger archivos sensibles |
| Extensiones | `file_fdw`, `pg_trgm`, `pgcrypto` | `pg_trgm`, `pgcrypto`; `file_fdw` eliminada (acceso a archivos del servidor, no necesaria) | Reducir funcionalidad innecesaria |
| Conexiones | `max_connections=100`, sin timeouts (`statement_timeout=0`, `idle_in_transaction_session_timeout=0`), sin log de conexiones | `statement_timeout=60s`, `idle_in_transaction_session_timeout=5min`, `superuser_reserved_connections=3`, `log_connections/log_disconnections=on` | Disponibilidad |

## Checklist de hardening (Actividad 17)

| # | Control | Verificado | Evidencia |
|---|---------|:---------:|-----------|
| 1 | Puerto documentado | ☑ | `SHOW port;` |
| 2 | Interfaces de escucha justificadas | ☑ | `SHOW listen_addresses;`, `ss -lnt` |
| 3 | `pg_hba.conf` revisado | ☑ | `pg_hba_file_rules` |
| 4 | Redes autorizadas restringidas (sin 0.0.0.0/0 ni ::/0) | ☑ | Consulta de reglas amplias = 0 filas |
| 5 | Autenticación segura (SCRAM, sin trust) | ☑ | `pg_hba_file_rules`, `pg_authid` |
| 6 | Superusuarios identificados | ☑ | `pg_roles` |
| 7 | Cuentas de aplicación separadas de las administrativas | ☑ | `pg_roles` |
| 8 | Privilegios mínimos (REVOKE a PUBLIC, GRANT específicos) | ☑ | `\dp`, `\l` |
| 9 | Extensiones revisadas | ☑ | `pg_extension` |
| 10 | TLS verificado | ☑ | `pg_stat_ssl` |
| 11 | Archivos de configuración protegidos | ☑ | `ls -l` |
| 12 | Directorio de datos protegido (700) | ☑ | `ls -ld` |
| 13 | Firewall documentado | ☑ | Tabla de reglas |
| 14 | Política de actualización documentada | ☑ | Sección 7 |
| 15 | Configuración registrada (`cambios.md`) | ☑ | Commits en Git |
| 16 | Timeouts de sesión configurados | ☑ | `SHOW idle_in_transaction_session_timeout;` |
| 17 | Logging de conexiones activo | ☑ | `SHOW log_connections;` |
| 18 | Conexión no autorizada rechazada (prueba negativa) | ☑ | Captura del error de conexión |
