# Evidencia 08 — Análisis de escenario de seguridad

## Objetivo
Evaluar riesgos y seleccionar controles en una organización con usuarios y roles bien configurados, pero con deficiencias criptográficas.

## Comando o procedimiento
Análisis del escenario de la Actividad 8 (contraseñas y RFC en claro, conexiones sin validación del servidor, claves en archivos SQL, respaldos sin protección).

## Resultado obtenido

### Pregunta 1 — Principales riesgos

| Problema | Riesgo principal |
|---|---|
| Contraseñas en texto claro | Filtración inmediata de credenciales; reutilización de contraseñas en otros sistemas; suplantación de identidad. |
| RFC en texto claro | Exposición de datos personales ante lectura de tablas, respaldos o SQL injection; incumplimiento de normativa de protección de datos. |
| Conexiones sin validación adecuada del servidor | Ataques de intermediario (MITM): un atacante se hace pasar por el servidor, captura credenciales y consultas o las altera. |
| Claves criptográficas en archivos SQL | Cualquiera con acceso a los scripts/repositorio puede descifrar los datos; el cifrado queda anulado. |
| Respaldos sin protección | Un respaldo robado o mal compartido expone toda la base sin pasar por los controles de acceso. |

### Pregunta 2 — Mecanismo por elemento

| Elemento | Mecanismo |
|---|---|
| Nombre, correo | Control de acceso, enmascaramiento en vistas/consultas; cifrado si el riesgo lo justifica |
| Contraseña | Hash con sal (Argon2id/scrypt/bcrypt) |
| RFC | Cifrado de columna (clave fuera de la BD) + control de acceso + enmascaramiento |
| Información financiera | Cifrado de columnas/volumen, mínimo privilegio, auditoría |
| Claves criptográficas | Gestor de secretos/KMS/HSM, rotación y separación de funciones |
| Conexiones | TLS con `sslmode=verify-full` y `hostssl` en `pg_hba.conf` |
| Respaldos | Cifrado del respaldo, claves separadas, acceso restringido y pruebas de restauración |

### Pregunta 3 — Problema más crítico
**Las claves criptográficas en archivos SQL.** Es la falla que invalida los demás controles de cifrado: si la clave está expuesta, el RFC y la información financiera cifrados son legibles para quien tenga el script, y probablemente también para quien tenga el repositorio, un respaldo o el historial de Git. Además, un secreto expuesto no se "arregla" borrándolo: exige rotación y re-cifrado.

*Observación:* las **contraseñas en texto claro** son igual de graves en impacto inmediato (acceso directo a cuentas y efecto en otros sistemas) y se explotan con solo leer la tabla; en un análisis de riesgo real ambos se atienden con prioridad máxima. Elijo las claves porque su compromiso es sistémico (afecta a todos los datos protegidos por ellas) y no puede revertirse sin rotar.

### Pregunta 4 — ¿Usuarios y permisos eliminan estos riesgos?
**No.** El control de acceso decide *quién* puede pedir datos a PostgreSQL, pero no protege cuando:
- el atacante **no pasa por PostgreSQL**: lee archivos de datos, discos o respaldos;
- se observa o altera la red (sin TLS verificado);
- un usuario legítimo o un administrador con acceso amplio ve contraseñas y datos en claro;
- las claves se filtran por scripts o repositorios;
- se explota una vulnerabilidad (SQL injection) con los privilegios de un rol legítimo.

La seguridad es en capas (defensa en profundidad): acceso + cifrado + TLS + gestión de claves + protección de respaldos.

## Análisis
Cada deficiencia está en una capa distinta; corregir una no corrige las demás.

## Conclusión
Los permisos son necesarios pero insuficientes. Se requiere combinar controles de acceso, hash de contraseñas, cifrado de datos y respaldos, TLS verificado y una gestión de claves madura.
