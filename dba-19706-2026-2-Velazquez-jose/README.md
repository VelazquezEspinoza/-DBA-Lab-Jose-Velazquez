# LAB-02 — Cifrado, credenciales y comunicaciones seguras

**Motor:** PostgreSQL 16 · **Modalidad:** individual · **Unidad II, tema 2.4**
**Alumno:** _Apellido Nombre_

## Contenido
```
sql/
├── 00-preparacion.sql        # pgcrypto y tabla clientes
├── 01-credenciales.sql       # Actividad 1
├── 02-cifrado-datos.sql      # Actividades 2 y 3
└── 03-verificacion-tls.sql   # Actividades 5 y 6
evidencias/                   # 01, 02, 03, 04, 07, 08, 10
docs/generar-certificados-lab.md
```
Ejecución en orden: `psql -d TU_BASE -f sql/00-preparacion.sql` y después 01, 02 y 03 (este último con `sslmode=require` o superior). Los scripts son re-ejecutables.

## 1. Introducción
Aunque los usuarios, roles y permisos estén bien configurados, una base de datos sigue expuesta si las contraseñas están en claro, los datos sensibles no se protegen, las conexiones no están cifradas ni verificadas, las claves viven en scripts o los respaldos no se protegen. Este laboratorio aborda esos riesgos con `pgcrypto`, TLS y buenas prácticas de gestión de claves.

## 2. Protección de credenciales
- **Texto claro:** el valor legible se guarda tal cual (`Password123`); cualquiera con lectura de la tabla lo obtiene.
- **Hash:** transformación de una vía con sal; no existe función inversa. La contraseña se **verifica**, no se recupera. Con `crypt()` + `gen_salt('bf')` la misma contraseña produjo hashes distintos (`$2a$06$TtIb…` y `$2a$06$5h5E…`).
- **Cifrado:** transformación reversible con una clave; adecuada para datos que se deben recuperar, **no** para contraseñas.

Evidencia: [01-credenciales.md](evidencias/01-credenciales.md).

## 3. Protección de datos sensibles
Se protegió el **RFC** con `pgp_sym_encrypt()` en una columna `BYTEA`, porque es un dato que la organización puede necesitar recuperar. Un `SELECT *` solo muestra bytes y una clave incorrecta produce `Wrong key or corrupt data`. Evidencia: [02-cifrado-datos.md](evidencias/02-cifrado-datos.md).

## 4. TLS
TLS protege confidencialidad, integridad y autenticación del servidor en tránsito. Se verificó `ssl=on`, `ssl_min_protocol_version=TLSv1.2` y, mediante `pg_stat_ssl`, que la sesión usa **TLSv1.3 / TLS_AES_256_GCM_SHA384**. Se comparó `disable`, `require`, `verify-ca` y `verify-full`: solo `verify-full` rechazó un nombre de servidor que no coincide con el certificado. Evidencia: [04-tls.md](evidencias/04-tls.md).

## 5. Gestión de claves
Una clave en un script termina en Git (con historial), logs, respaldos y capturas; quien tenga el script puede descifrar los datos. Las claves deben vivir en un gestor de secretos/KMS, separadas de los datos y del código. Evidencias: [03](evidencias/03-gestion-claves.md) y [10](evidencias/10-politica-claves.md).

## 6. Resultados
| Verificación | Resultado |
|---|---|
| Contraseña en `usuarios_segura` | Solo hash bcrypt; correcta → `t`, incorrecta → `f` |
| RFC cifrado | `bytea` ilegible; recuperable solo con la clave |
| TLS de la sesión | `t` / TLSv1.3 / TLS_AES_256_GCM_SHA384 |
| `verify-full` con nombre incorrecto | Falla (comportamiento esperado) |
| Revisión de secretos | Sin credenciales reales (ver abajo) |

### Revisión previa al commit
Se ejecutó `grep -RniE 'password|passwd|secret|token|api_key|clave' .` y `grep -Rni 'postgresql://' .`. Las coincidencias están en documentación y en los valores ficticios `Password123`, `OtraPassword` y `CLAVE-DE-PRUEBA`. No hay archivos `.key`/`.pem`, ni cadenas de conexión con credenciales, y `sql/ejemplo-mala-practica.sql` fue eliminado. `.gitignore` bloquea llaves y archivos `.env`. Esta búsqueda no garantiza detectar todos los secretos; es un hábito mínimo (en proyectos reales conviene una herramienta de escaneo de secretos).

## 7. Problemas encontrados
- `gen_salt('bf')` usa costo 6 por defecto, bajo para hoy; con costo 12 el cálculo pasó de ~4.9 ms a ~278.8 ms.
- `sslmode=verify-full` falló al conectar a `127.0.0.1` porque el certificado era para `localhost`; hay que conectar por el nombre del certificado.
- `verify-ca` sí aceptó `127.0.0.1`, porque no valida el nombre.
- Un cifrado con sal aleatoria impide `WHERE rfc_cifrado = …` (no se puede buscar por igualdad).
- Las pruebas de este paquete se ejecutaron en un PostgreSQL 16.15 local de laboratorio con certificados autofirmados y puerto 5433. **Vuelve a ejecutar los scripts en tu servidor y sustituye en las evidencias lo que cambie** (host, versión de TLS, cifrado, hashes, puerto).

## 8. Conclusiones
El control de acceso es necesario pero no suficiente. Cada riesgo tiene su mecanismo: hash para contraseñas, cifrado para datos recuperables, TLS con `verify-full` para tránsito y gestión de claves para sostener todo lo anterior. En producción aplicaría: Argon2id/bcrypt con costo adecuado en la aplicación, cifrado con claves en KMS, `hostssl` con `scram-sha-256` y `verify-full`, respaldos cifrados y escaneo de secretos en el repositorio.

## 9. Preguntas de reflexión
1. **¿Por qué no texto claro?** Una filtración o lectura de la tabla expone directamente las credenciales, que además suelen reutilizarse en otros sistemas.
2. **¿Hash ≠ cifrado?** El hash es de una vía y no tiene descifrado; el cifrado es reversible con una clave. Uno verifica, el otro protege datos que hay que recuperar.
3. **¿Cifrar una columna sustituye al control de acceso?** No. Quien tenga permiso y la clave verá el dato en claro, y el control de acceso limita quién puede intentarlo; además protege otros datos no cifrados.
4. **¿TLS sustituye la autorización?** No. TLS protege el canal; PostgreSQL sigue decidiendo qué puede hacer cada rol. Un usuario con privilegios excesivos los conserva aunque la conexión sea cifrada.
5. **¿Pérdida de la clave?** Los datos cifrados quedan irrecuperables de forma práctica; por eso se requieren respaldos seguros de claves.
6. **¿Clave publicada en GitLab?** Se considera comprometida: hay que rotarla, re-cifrar los datos y tratarlo como incidente; borrarla del archivo no basta por el historial.
7. **¿Repositorio privado ≠ almacén de secretos?** Tiene muchos lectores, clones, forks, historial y copias; reduce exposición pero no está diseñado para custodiar, rotar ni auditar secretos.
8. **¿Reposo vs. tránsito?** Reposo protege lo almacenado (tablas, discos, respaldos); tránsito protege lo que viaja por la red. Se resuelven con mecanismos distintos y ninguno cubre al otro.
9. **¿Gestión de claves tan importante como el algoritmo?** Un algoritmo fuerte con una clave expuesta, perdida o mal rotada no protege nada.
10. **¿Mecanismo adicional para respaldos?** Cifrado de los respaldos (p. ej. GPG/age o cifrado del almacenamiento) con claves en un KMS separado, acceso restringido, copia fuera del sitio y pruebas periódicas de restauración.

## 10. Evidencias
[01](evidencias/01-credenciales.md) · [02](evidencias/02-cifrado-datos.md) · [03](evidencias/03-gestion-claves.md) · [04](evidencias/04-tls.md) · [07](evidencias/07-comparacion.md) · [08](evidencias/08-analisis-escenario.md) · [10](evidencias/10-politica-claves.md)
