# Evidencia 03 — Gestión de claves

## Objetivo
Identificar por qué una clave escrita en un script es una mala práctica, y verificar que el repositorio no contiene secretos antes de publicarlo en GitLab.

## Comando o procedimiento
1. Se creó temporalmente `sql/ejemplo-mala-practica.sql` con el siguiente contenido **demostrativo**:
   ```sql
   SELECT pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA')
   FROM clientes_protegidos;
   ```
2. Se analizó y **se eliminó antes del commit** (no forma parte de la entrega).
3. Se revisó el repositorio con:
   ```bash
   grep -RniE 'password|passwd|secret|token|api_key|clave' .
   grep -Rni 'postgresql://' .
   ```

## Resultado obtenido
- El archivo temporal mostraba la clave en texto claro, legible por cualquiera con acceso al archivo.
- Búsqueda de secretos: ver sección "Revisión previa al commit" del [README](../README.md). Las coincidencias corresponden a **documentación y a valores ficticios de laboratorio** (`Password123`, `CLAVE-DE-PRUEBA`, `OtraPassword`); no hay contraseñas, tokens ni cadenas `postgresql://usuario:clave@...` reales.

## Análisis

**¿Qué pasaría si esta clave fuera real y el archivo se publicara en Git?**
- Cualquiera con acceso al repositorio (compañeros, ex-empleados, CI, un fork, un token filtrado) podría descifrar todos los datos protegidos con esa clave.
- Borrar el archivo en un commit posterior **no basta**: el secreto queda en el historial (`git log -p`, clones, forks, cachés).
- El cifrado pierde todo su valor: es como cerrar con llave y dejar la llave pegada a la puerta.
- Respuesta correcta: hay que **rotar la clave**, **re-cifrar** los datos con la nueva y considerar el secreto como comprometido definitivamente.

**¿Es correcto subir una clave real a un repositorio privado?** No. Un repositorio privado reduce la exposición, pero tiene muchos lectores, clones locales, copias de seguridad e historial; no es un almacén de secretos.

**¿Dónde debería almacenarse una clave en un entorno real?** En un gestor de secretos/KMS/HSM (p. ej. HashiCorp Vault, AWS KMS/Secrets Manager, Azure Key Vault, GCP KMS), inyectada a la aplicación en tiempo de ejecución con permisos mínimos, **separada de los datos que protege** y de los scripts. Idealmente el cifrado se hace en la aplicación o en una capa con KMS, para que la clave no viaje al servidor de base de datos.

**Pérdida de la clave:** si se pierde sin respaldo seguro, los datos cifrados son irrecuperables. Por eso la gestión incluye respaldo, rotación y revocación (ver [10-politica-claves.md](10-politica-claves.md)).

## Conclusión
La seguridad del cifrado recae en la gestión de la clave. Este laboratorio utilizó únicamente claves ficticias, y el repositorio se revisó antes de publicarse.
