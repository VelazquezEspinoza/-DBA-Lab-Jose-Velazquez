# Evidencia 01 — Protección de credenciales

## Objetivo
Demostrar por qué una contraseña en texto claro es una mala práctica y cómo almacenarla como hash con sal usando `pgcrypto` (`crypt()` + `gen_salt('bf')`), verificando que la contraseña original no puede leerse desde la tabla.

## Comando o procedimiento
Script: [`sql/01-credenciales.sql`](../sql/01-credenciales.sql)  
Ejecución: `psql -d lab02 -f sql/01-credenciales.sql`  
Entorno: PostgreSQL 16.15, extensión `pgcrypto` 1.3. Todos los valores son ficticios.

## Resultado obtenido

**Tabla insegura (texto claro):**
```
 id | usuario |  password
----+---------+-------------
  1 | juan    | Password123
```

**`crypt('Password123', gen_salt('bf'))` ejecutado dos veces:**
```
hash_1: $2a$06$TtIbD5jqDXJV9.PkgyicHuOizhynt6bI.jxsPlVWN.RhkfMcaxBXe
hash_2: $2a$06$5h5EbJtDierK1RTZZHPQj.GQGVRZvMTSuf.IwoZKMAz0K7nNebAN2
```

**Tabla `usuarios_segura`:**
```
 id | usuario |                        password_hash
----+---------+--------------------------------------------------------------
  1 | juan    | $2a$06$D33M/uFFTG3jfhMP470VN.SO0aSyyE5QK6NAkH6jgPxjkyqbntQZe
```

**Verificación:**
```
-- con 'Password123'
 usuario | contraseña_correcta
---------+---------------------
 juan    | t

-- con 'OtraPassword'
 usuario | contraseña_correcta
---------+---------------------
 juan    | f
```

**Observación adicional (costo del algoritmo):** `gen_salt('bf')` usa por defecto costo 6 (`$2a$06$`). Con `gen_salt('bf', 12)`:
```
$2a$12$cVDZeE.pSmkUpAVLmK0mjORkm1b.RPG2BvQgGALFt73PBdRbqwXTG
```
Tiempo medido: ~4.9 ms con costo 6 vs. ~278.8 ms con costo 12.

## Análisis

**¿Qué ocurriría si alguien obtiene acceso de lectura a `usuarios_insegura`?**
Obtiene `juan / Password123` de inmediato, sin ningún esfuerzo. Como muchas personas reutilizan contraseñas, el daño se extiende a otros sistemas (correo, VPN, otras aplicaciones). Una filtración de la base (respaldo, SQL injection, DBA curioso) se convierte directamente en filtración de credenciales.

**¿Los dos hashes son iguales?** No.

**¿Por qué?** Porque `gen_salt('bf')` genera una **sal aleatoria nueva** en cada llamada y `crypt()` la combina con la contraseña. La misma contraseña produce hashes distintos, lo que impide detectar usuarios con la misma contraseña y vuelve inútiles las tablas precalculadas (rainbow tables).

**¿Qué hace `gen_salt()`?** Genera la cadena de configuración: algoritmo (`$2a$` = bcrypt), costo (`06`) y sal aleatoria.

**¿Qué hace `crypt()`?** Calcula el hash de la contraseña usando la sal y el costo contenidos en el segundo argumento. Por eso, para verificar, se le pasa el hash almacenado como "sal": reutiliza la sal y el costo originales y el resultado debe ser idéntico al hash guardado.

**¿Es cifrado reversible?** No. Es un hash de una sola vía; no existe una función que recupere la contraseña. Solo se puede **verificar** una candidata recalculando el hash.

**¿Por qué no es necesario recuperar la contraseña original?** Porque el sistema solo necesita responder "¿esta contraseña coincide?". Con contraseña correcta devolvió `t` y con incorrecta `f`.

**¿Por qué hash ≠ cifrado?** El cifrado está diseñado para ser revertido con una clave (se necesita recuperar el dato). El hash está diseñado para no ser revertido; no hay clave ni "descifrado".

**Sobre el costo:** el costo 6 por defecto es bajo para estándares actuales. Subirlo a 12 multiplicó el tiempo ~57×, que es justamente lo que encarece un ataque de fuerza bruta (a costa de CPU en cada login). En una aplicación real se usa el mecanismo del framework (Argon2id, scrypt o bcrypt con costo adecuado), nunca un algoritmo propio.

## Conclusión
Las contraseñas deben guardarse como hash con sal mediante un algoritmo diseñado para contraseñas, nunca en texto claro ni cifradas con una clave fija. `pgcrypto` permite demostrar el concepto, pero en producción el hash normalmente se calcula en la aplicación con Argon2id/scrypt/bcrypt y un costo ajustado.
