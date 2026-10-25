# Evidencias

Generadas con `generar_evidencias.py` desde la ejecución real de los comandos en la instancia de práctica (host `vm`).

| Archivo | Contenido |
|---------|-----------|
| `01-superficie-ataque.png` | Estado inicial: versión, puerto, `listen_addresses`, ssl, `password_encryption`, `pg_stat_activity` |
| `02-listen-addresses.png` | Después: `listen_addresses=localhost` y `ss -lnt` en 127.0.0.1:5432 |
| `03-pg-hba.png` | Después: `pg_hba_file_rules` endurecido |
| `04-roles.png` | Después: roles DBA / APP / CONSULTA |
| `05-tls.png` | Después: `ssl=on`, TLS mínimo y sesión TLSv1.3 |
| `06-verificacion.png` | Después: parámetros, 0 reglas amplias, pruebas negativas y permisos del SO |

Las variantes `*_antes.png` / `*_despues.png` sirven para la comparación del baseline.
Para repetirlo en otro servidor: ver instrucciones en `generar_evidencias.py`.
