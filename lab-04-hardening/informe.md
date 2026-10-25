# Informe — LAB-04 Hardening y configuración segura de PostgreSQL

**Estudiante:** Jose Fernando Velazquez Espinoza  **Fecha:** 25-oct-2026

> Los datos provienen de una instancia de práctica PostgreSQL 16 (host `vm`), no de un servidor institucional.


## 1. ¿Cuál era la principal superficie de ataque?
El servicio PostgreSQL expuesto en red: puerto 5432 escuchando en todas las interfaces (`listen_addresses='*'`), alcanzable desde una red demasiado amplia y con reglas de `pg_hba.conf` permisivas. En la instancia de práctica: `listen_addresses='*'`, `ss -lnt` mostraba `0.0.0.0:5432`, y `pg_hba_file_rules` tenía `host all all 0.0.0.0/0 md5` y `::/0 md5` (evidencias `01`, `02`, `03`).

## 2. ¿Qué configuración representaba el mayor riesgo?
La combinación de `listen_addresses='*'`, una regla `host all all 0.0.0.0/0` y cuentas administrativas usadas por la aplicación: cualquier origen puede intentar autenticarse contra cualquier base de datos, y un compromiso de la aplicación o de una credencial otorga control total. En la instancia de práctica, `webapp` (usada por la aplicación) era SUPERUSER con acceso desde cualquier IP vía md5, sin TLS ni timeouts (evidencia `04`).

## 3. ¿Qué cambio produjo la mayor reducción de exposición?
Reemplazar la regla `all/all/0.0.0.0/0` por reglas específicas (base de datos + usuario + red + método) y limitar `listen_addresses` a las interfaces necesarias, porque reducen quién puede siquiera intentar conectarse. Resultado: el puerto pasó de `0.0.0.0:5432` a `127.0.0.1:5432` y `pg_hba_file_rules` dejó de contener reglas amplias (evidencias `02`, `03`, `06`); una conexión desde la IP no autorizada fue rechazada (`Connection refused`) y `app_user` hacia otra BD recibió `no pg_hba.conf entry`.

## 4. ¿Qué diferencia existe entre firewall y pg_hba.conf?
El firewall actúa a nivel de red/transporte (IP origen, destino, puerto) y bloquea el tráfico antes de que llegue a PostgreSQL. `pg_hba.conf` actúa dentro de PostgreSQL, ya con la conexión recibida, y decide por tipo de conexión, base de datos, usuario, origen y método de autenticación. No son equivalentes: el firewall no conoce usuarios ni bases de datos, y `pg_hba.conf` no evita que el servicio reciba tráfico ni consume recursos del servidor ante un escaneo o ataque. Se complementan (defensa en profundidad).

## 5. ¿Qué diferencia existe entre autenticación y autorización?
Autenticación verifica **quién** es el usuario (contraseña, certificado). Autorización determina **qué puede hacer** esa identidad (GRANT/REVOKE, atributos de rol). Una contraseña fuerte no limita lo que la cuenta puede hacer.

## 6. ¿Por qué una cuenta de aplicación no debe ser SUPERUSER?
Porque una aplicación comprometida (inyección SQL, credenciales filtradas) heredaría todas las capacidades de la cuenta: leer o borrar cualquier dato, crear roles, desactivar controles y, según la configuración, interactuar con el sistema operativo del servidor. Con mínimo privilegio el daño queda acotado a lo que la aplicación necesita.

## 7. ¿Por qué cambiar el puerto no constituye hardening suficiente?
Solo reduce el ruido de escaneos automatizados; el servicio sigue siendo descubrible (un escaneo de puertos lo encuentra) y no reemplaza autenticación, autorización, `pg_hba.conf` ni firewall. Es seguridad por oscuridad.

## 8. ¿Por qué listen_addresses='*' puede ser innecesario?
Porque abre el servicio en todas las interfaces (incluidas públicas o de redes que no lo necesitan) aunque solo una aplicación en una red privada deba conectarse. Escuchar solo en `localhost` o en la IP privada necesaria reduce la superficie. Por sí solo no permite acceso (intervienen `pg_hba.conf` y la red), pero elimina una capa de protección.

## 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?
Es la base de la pila: protege los archivos de configuración, el directorio de datos y las claves TLS mediante propietario y permisos; controla qué usuarios locales pueden leerlos; aloja el firewall y los parches. Si un usuario del SO puede leer los archivos de datos o configuración, los GRANT/REVOKE de PostgreSQL pueden eludirse.

## 10. ¿Qué controles deberían revisarse periódicamente?
- Roles, superusuarios y privilegios (cuentas innecesarias o con privilegios excesivos).
- Reglas de `pg_hba.conf` y redes permitidas.
- `listen_addresses`, puertos expuestos y reglas de firewall.
- Métodos de autenticación y rotación de credenciales.
- Extensiones instaladas.
- Permisos de archivos y del directorio de datos.
- Vigencia de certificados y versión mínima de TLS.
- Parches y versión de PostgreSQL y del SO.
- Logs de conexión y accesos fallidos.
- Coherencia entre ambientes (desarrollo, pruebas, producción).

---

## Anexo A — Caso integral (Actividad 18)

| # | Problema | Riesgo | Control propuesto |
|---|----------|--------|-------------------|
| 1 | `pg_hba.conf` permite all/all desde 0.0.0.0/0 | Cualquier host IPv4 puede intentar autenticarse en cualquier BD | Reglas por BD + usuario + red específica |
| 2 | El firewall permite 5432 desde cualquier origen | Servicio expuesto a Internet; escaneo, fuerza bruta, explotación de vulnerabilidades | Allowlist: solo la red necesaria, denegar el resto |
| 3 | `listen_addresses='*'` | Escucha en interfaces innecesarias | Limitar a localhost / IP privada |
| 4 | La aplicación usa una cuenta con privilegios administrativos | Compromiso de la app = compromiso total de la BD | Cuenta de aplicación con mínimo privilegio |
| 5 | Una sola credencial concentra acceso y privilegio | Fuga de la credencial es de alto impacto | Cuentas separadas DBA / APP / CONSULTA |
| 6 | Dependencia exclusiva de contraseñas fuertes | Sin defensa si se filtran, se reutilizan o se obtienen por phishing | Defensa en profundidad: red, autorización, monitoreo |
| 7 | Posible tráfico sin cifrar / TLS no exigido | Intercepción de credenciales y datos | `hostssl`, TLS ≥ 1.2, `ssl=on` |
| 8 | Sin monitoreo de conexiones (`log_connections` no verificado) | Intrusiones o fuerza bruta no detectadas | Logging de conexiones y alertas sobre fallos |
| 9 | Sin límites de conexión ni timeouts | Agotamiento de `max_connections`; denegación de servicio | `CONNECTION LIMIT`, `idle_in_transaction_session_timeout`, `statement_timeout` |
| 10 | Archivos de configuración y directorio de datos sin revisar | Lectura de configuración/datos por usuarios del SO | `postgres:postgres`, 640/700 |
| 11 | Sin política de actualización documentada | Vulnerabilidades conocidas sin parchear | Política de parches y revisión periódica |
| 12 | Sin documentación ni línea base | Configuración no reproducible ni auditable | `baseline.md`, `cambios.md`, checklist |
| 13 | Sin segmentación de red | Movimiento lateral desde otros equipos | Red privada/VLAN dedicada para la BD |

**¿Es suficiente tener contraseñas fuertes?** No. Una contraseña fuerte solo cubre una parte de la **autenticación**. No limita qué puede hacer la cuenta (**autorización**), no reduce quién puede alcanzar el servicio (**red**), no corrige reglas permisivas ni parámetros inseguros (**configuración**), no protege archivos si el **sistema operativo** es débil, y no permite detectar abusos sin **monitoreo**. Las credenciales además pueden filtrarse, reutilizarse o capturarse sin TLS; la seguridad depende de capas independientes que se compensen entre sí.

## Anexo B — Reflexión
**¿Qué cambiarías primero en un servidor PostgreSQL en producción?**

Primero haría un **inventario sin modificar nada** (conexiones reales, orígenes, cuentas y reglas activas) y luego cerraría la exposición de red más amplia: sustituir la regla `0.0.0.0/0` y las reglas de firewall abiertas por una allowlist de los orígenes que realmente se conectan. Lo haría antes que otros cambios porque:

- **Riesgo y exposición:** es lo que más reduce la probabilidad de ataque, ya que limita quién puede intentar conectarse.
- **Impacto y disponibilidad:** se hace con el inventario previo, así que no se bloquean orígenes legítimos; `pg_hba.conf` se recarga sin reinicio (`pg_reload_conf()`), con respaldo y una sesión abierta para revertir.
- **Continuidad:** cambios como `listen_addresses` o TLS requieren reinicio, por lo que se programan en una ventana de mantenimiento.
- **Privilegios y autenticación:** después se migra la aplicación a una cuenta de mínimo privilegio y se pasa a SCRAM, de forma gradual para no romper clientes antiguos.
- **Red:** finalmente se alinea el firewall con `pg_hba.conf` como segunda capa.

El orden sigue la lógica: descubrir → priorizar por riesgo y bajo impacto operativo → aplicar → verificar → documentar.
