# Evidencia 07 — Protección en reposo vs. en tránsito

## Objetivo
Asociar cada situación con el mecanismo adecuado y el aspecto que protege.

## Comando o procedimiento
Análisis conceptual apoyado en lo realizado en las evidencias 01, 02 y 04.

## Resultado obtenido

| Situación | Mecanismo apropiado | ¿Qué protege? |
|---|---|---|
| Contraseña de usuario | Hash con sal mediante derivación de claves para contraseñas (Argon2id, scrypt o bcrypt) | Confidencialidad de la credencial: aunque se filtre la tabla, no se obtiene la contraseña directamente. **Datos en reposo.** |
| RFC almacenado en una tabla | Cifrado (simétrico, p. ej. `pgp_sym_encrypt`) con clave gestionada fuera de la BD; complementado con control de acceso y enmascaramiento en vistas | Confidencialidad del dato almacenado frente a lectura directa de tablas, archivos o respaldos. **Datos en reposo.** |
| Consulta enviada desde un cliente al servidor | TLS (preferentemente 1.2/1.3) con `sslmode=verify-full` | Confidencialidad e integridad de la comunicación, y autenticación del servidor. **Datos en tránsito.** |
| Respaldo de una base de datos | Cifrado del respaldo (p. ej. GPG/age o cifrado del almacenamiento), con claves separadas y control de acceso al archivo | Confidencialidad de la información en copias fuera del servidor. **Datos en reposo.** |
| Clave criptográfica | Gestión segura de claves: KMS/HSM/gestor de secretos, rotación, respaldo, revocación, acceso mínimo | Evita que se comprometan todos los datos que dependen de esa clave. **Transversal.** |

## Análisis
- **En reposo:** protege lo almacenado (tablas, discos, respaldos). **En tránsito:** protege lo que viaja por la red. Ninguno cubre al otro: una BD con TLS puede tener contraseñas en claro, y una con columnas cifradas puede aceptar conexiones sin TLS.
- Una contraseña usa **hash** (no se recupera); un RFC usa **cifrado** (se recupera cuando hay justificación).
- Todos los mecanismos de cifrado dependen de la **gestión de claves**.

## Conclusión
No existe un único mecanismo que cubra todo: cada riesgo requiere su control y todos se apoyan en una buena gestión de claves.
