# Evidencia 02 — Cifrado de información sensible (RFC)

## Objetivo
Proteger un dato que **sí debe poder recuperarse** (RFC) mediante cifrado simétrico con `pgp_sym_encrypt()`, y contrastarlo con el hash de contraseñas.

## Comando o procedimiento
Script: [`sql/02-cifrado-datos.sql`](../sql/02-cifrado-datos.sql)  
Ejecución: `psql -d lab02 -f sql/02-cifrado-datos.sql`  
La clave `CLAVE-DE-PRUEBA` es ficticia y exclusiva del laboratorio.

## Resultado obtenido

**Dato almacenado (columna `bytea`, 79 bytes):**
```
 id |  nombre   | rfc_cifrado
----+-----------+-------------------------------------------------------------
  1 | Ana López | \xc30d04070302aa73f9e4a03b83e16bd23e014cae21032130592711483b6a4a2b...
```

**Recuperación con la clave correcta:**
```
 id |  nombre   |      rfc
----+-----------+---------------
  1 | Ana López | LOPA900101ABC
```

**Clave incorrecta:**
```
ERROR:  Wrong key or corrupt data
```

**Cifrar dos veces el mismo RFC con la misma clave:**
```
 son_iguales
-------------
 f
```

## Análisis

**¿Diferencia entre `crypt()` y `pgp_sym_encrypt()`?**

| | `crypt()` | `pgp_sym_encrypt()` |
|---|---|---|
| Tipo | Hash con sal (una vía) | Cifrado simétrico (ida y vuelta) |
| Necesita clave | No (la sal va dentro del hash) | Sí |
| Recuperable | No | Sí, con la clave |
| Uso adecuado | Contraseñas | Datos que deben recuperarse (RFC) |

**¿Cuál permite recuperar el dato original?** `pgp_sym_encrypt()`/`pgp_sym_decrypt()`, siempre que se tenga la clave.

**¿Qué ocurre con clave incorrecta?** PostgreSQL devuelve `Wrong key or corrupt data` y no revela el dato.

**¿Por qué el texto cifrado cambia en cada ejecución?** PGP incluye datos aleatorios (sal de la clave y vector de inicialización) por operación; así, dos registros con el mismo RFC no son identificables como iguales. Consecuencia práctica: **no se puede buscar ni indexar por igualdad** sobre la columna cifrada (`WHERE rfc_cifrado = ...` no funciona).

**¿Qué problema representa poner la clave en la consulta?** La clave queda en el script, en el historial de `psql`, en los logs de PostgreSQL (`log_statement`, errores que muestran la consulta), en `pg_stat_activity`, en el repositorio Git, etc. Además, **PostgreSQL recibe la clave junto con los datos**: quien administre el servidor puede capturarla. Ver [03-gestion-claves.md](03-gestion-claves.md).

**Enmascaramiento vs. seudonimización vs. cifrado:**
- *Enmascaramiento:* oculta parte del dato para mostrarlo (`LOPA*******`); normalmente no se puede revertir.
- *Seudonimización:* sustituye el identificador por otro valor; se puede revincular con información adicional guardada aparte.
- *Cifrado:* transforma el dato completo y se recupera con la clave.

## Conclusión
El RFC dejó de ser legible desde un `SELECT *`, pero la protección depende por completo de dónde se guarde la clave. El cifrado de columna **complementa** al control de acceso, no lo sustituye: un rol con la clave y permiso de lectura vuelve a ver el dato en claro. Costo: se pierde la búsqueda por igualdad directa.
