# LAB-04 — Hardening y configuración segura de PostgreSQL

## Objetivo
Aplicar un proceso básico de hardening a PostgreSQL 16: identificar configuraciones inseguras, reducir la superficie de exposición y establecer controles de acceso, autenticación y configuración segura, comparando el estado antes y después y justificando cada cambio.

## Entorno
| Elemento | Valor |
|----------|-------|
| Motor | PostgreSQL 16 (paquete `postgresql-16`, Ubuntu 24) |
| Host | `vm` — instancia de práctica aislada (no institucional ni productiva) |
| Base de datos de laboratorio | `basedatos_app` (tabla `clientes`) |
| Usuario administrativo del lab | `dba_lab_admin` |
| Fecha | 2026-10-25 |
| Modalidad | Individual, entorno académico aislado |

## Superficie de ataque inicial
Evidencia: `evidencias/01-superficie-ataque.png` (y `_antes` de las demás).

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|----------|---------------|----------------|--------|
| Puerto PostgreSQL | 5432 | Sí (servicio estándar) | Bajo por sí mismo; el puerto no es control de seguridad |
| Interfaces de escucha | `listen_addresses='*'` (0.0.0.0:5432) | No: la app solo necesita una red privada | Alto: servicio alcanzable desde cualquier interfaz |
| Conexiones remotas | Regla `0.0.0.0/0` y `::/0` con md5 para todas las BD y usuarios | Solo desde la red de la aplicación/DBA | Alto: cualquier IP puede intentar autenticarse |
| Usuarios administrativos | Superusuarios con login: `postgres`, `dba_lab_admin`, `webapp`; `reportes` con CREATEROLE/CREATEDB | Solo DBA nominales | Alto: la aplicación usa un SUPERUSER |
| SSL/TLS | `ssl=off`, sesión sin cifrar | Sí | Alto: credenciales y datos en claro |
| Métodos de autenticación | md5 (heredado) y `password_encryption=md5` | No: debe usarse SCRAM | Medio |

Otros hallazgos: archivos `*.conf` con permisos 644 y directorio de datos 750; extensión `file_fdw` instalada; sin `statement_timeout` ni `idle_in_transaction_session_timeout`; sin log de conexiones.

## Hallazgos
1. `listen_addresses='*'`: escucha en todas las interfaces.
2. `pg_hba.conf` con `host all all 0.0.0.0/0 md5` y `::/0 md5`.
3. La aplicación (`webapp`) es SUPERUSER; `reportes` tiene CREATEROLE y CREATEDB.
4. Contraseñas almacenadas en md5 y método md5 en reglas remotas.
5. Sin TLS; sin timeouts de sesión; sin logging de conexiones.
6. Archivos de configuración legibles por todos; `file_fdw` instalada sin necesidad.

## Cambios realizados
Detalle completo (antes, después, comando y reversión) en [`configuracion/cambios.md`](configuracion/cambios.md); reglas en `configuracion/pg_hba.antes.conf` y `pg_hba.despues.conf`.

| # | Cambio | Script / archivo |
|---|--------|------------------|
| 1 | `listen_addresses='localhost'` | `sql/03-configuracion.sql` |
| 2 | `pg_hba.conf` con reglas `hostssl` por BD + usuario + red, SCRAM, sin reglas amplias | `configuracion/pg_hba.despues.conf` |
| 3 | Cuentas `dba_lab`, `app_user`, `consulta_user`; `webapp` y `reportes` sin privilegios y NOLOGIN | `sql/02-roles.sql` |
| 4 | SCRAM, TLS ≥ 1.2 (`ssl=on`), timeouts, logging, reservas de conexión | `sql/03-configuracion.sql` |
| 5 | Permisos SO: `*.conf` 640, directorio de datos 700 | `configuracion/cambios.md` |
| 6 | Eliminación de `file_fdw` | `configuracion/cambios.md` |

## Justificación de los cambios
- **`listen_addresses` y `pg_hba.conf`:** reducen quién puede alcanzar el servicio y autenticarse (allowlist y mínimo privilegio).
- **Cuentas separadas:** una aplicación comprometida ya no hereda privilegios de superusuario.
- **SCRAM y TLS:** protegen la verificación de credenciales y el tráfico en tránsito.
- **Timeouts y límites:** evitan agotar `max_connections` por sesiones colgadas (disponibilidad).
- **Permisos SO y extensiones:** impiden lectura por otros usuarios del sistema y retiran funcionalidad innecesaria.

## Verificación
`sql/04-verificacion.sql` y pruebas de terminal (evidencia `evidencias/06-verificacion.png`):
- `ss -lnt` muestra `127.0.0.1:5432`.
- 0 reglas amplias o con md5/trust en `pg_hba_file_rules`; 0 errores de sintaxis.
- Conexión desde una IP no autorizada: `Connection refused`.
- `app_user` hacia otra base: `no pg_hba.conf entry`; `webapp` (NOLOGIN) rechazada.
- Sesión con TLSv1.3 (`TLS_AES_256_GCM_SHA384`) en `evidencias/05-tls.png`.
- `*.conf` en 640 y directorio de datos en 700.

## Checklist de hardening
Ver [`configuracion/baseline.md`](configuracion/baseline.md) (18 controles y línea base).

## Conclusiones
El mayor riesgo era la combinación de escucha en todas las interfaces, una regla `0.0.0.0/0` y una aplicación con cuenta SUPERUSER. Restringir interfaces y reglas de acceso fue lo que más redujo la exposición, y separar cuentas limitó el impacto de un compromiso. Quedan pendientes en un entorno real: reglas de firewall equivalentes (aquí solo documentadas), un certificado emitido por una CA, y la política de actualización y revisión periódica.

## Nota sobre las evidencias
Las capturas fueron generadas con `evidencias/generar_evidencias.py` a partir de la ejecución real de los comandos en la instancia de práctica (el encabezado de cada imagen muestra fecha y host). Las variantes `_antes` y `_despues` documentan el cambio; los archivos sin sufijo son las entregas con el nombre pedido (01 = estado inicial, 02 a 06 = estado final).

## Estructura
```
lab-04-hardening/
├── README.md
├── sql/            01-inspeccion, 02-roles, 03-configuracion, 04-verificacion
├── configuracion/  baseline.md, cambios.md, pg_hba.antes.conf, pg_hba.despues.conf
├── evidencias/     PNG + generar_evidencias.py
└── informe.md
```
