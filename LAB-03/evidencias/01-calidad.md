# Actividad 1 — Calidad de datos desde la operación

**Base:** `comercial` · PostgreSQL 16 · ⟨servidor-pg⟩
**Script:** [`sql/01-verificaciones-calidad.sql`](../sql/01-verificaciones-calidad.sql)
**Fecha de ejecución:** ⟨AAAA-MM-DD HH:MM⟩

> Los identificadores (`id`) corresponden a mi servidor: **1** es el registro original de Ana López, **7** (Ana Lopez) y **8** (Jorge Díaz) son los capturados con error en esta actividad. Si en tu servidor son otros, sustitúyelos.
> Los registros **no se eliminaron**: forman parte de los hallazgos del expediente.

## 1. Verificaciones ejecutadas

| # | Dimensión de calidad | Verificación (consulta en el script) | Resultado |
|---|---|---|---|
| V1 | Unicidad | Correos repetidos sin distinguir mayúsculas | `ana.lopez@example.test` → ids 1, 7 |
| V2 | Validez / completitud | RFC ausente o fuera del patrón `^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$` | id 7 (12 caracteres), id 8 (nulo) |
| V3 | Validez | Correo sin forma `x@y.z` | id 8 (`sin-correo`) |
| V4 | Validez | Edad fuera de 18–120 | id 8 (`-3`) |
| V5 | Completitud | Conteo de nulos en teléfono y RFC | ⟨total⟩ registros; ⟨n⟩ sin teléfono; 1 sin RFC |
| V6 | Validez | Teléfono distinto de 10 dígitos | id 8 (`667`) |
| V7 | Validez | Código postal distinto de 5 dígitos | id 8 (`8000`) |
| V8 | Consistencia | Misma ciudad escrita de varias formas | `Culiacan` (id 7) vs `Culiacán` (resto) |
| V9 | Unicidad | Nombre normalizado repetido | `Ana López` (1) / `Ana Lopez` (7) |

> La expresión regular del RFC es una verificación de **formato** para la práctica: no valida que el RFC exista ni sustituye las reglas oficiales del SAT.

## 2. Registro de hallazgos

| # | Hallazgo | Registros | Regla de calidad | ¿Quién decide la corrección? | Acción propuesta |
|---|---|---|---|---|---|
| C1 | Posible cliente duplicado (mismo correo con distinta capitalización y mismo nombre sin acento) | 1, 7 | Unicidad del correo | **Gerencia Comercial** (propietario) | Confirmar con el cliente si es la misma persona. Si lo es, el propietario decide cuál registro se conserva (propuesta: id 1, el más antiguo) y el DBA ejecuta la fusión con folio de cambio (POL-06). Después, crear índice único sobre `lower(correo)`. |
| C2 | RFC incompleto (12 posiciones; a una persona física le corresponden 13) | 7 | Formato del RFC | **Gerencia Comercial**, con apoyo de Facturación | Solicitar al cliente su constancia de situación fiscal. Mientras no se confirme, no se usa para facturar. El DBA **no** completa la homoclave. |
| C3 | Correo con formato no válido; se usó el texto `sin-correo` como marcador de "no tiene" | 8 | Formato del correo | **Gerencia Comercial** | Obtener el correo real. El propietario decide si `correo` puede ser nulo (hoy es `NOT NULL`, lo que provoca que se capturen marcadores falsos). |
| C4 | Edad imposible (`-3`) | 8 | Rango de edad 18–120 | **Gerencia Comercial** | Confirmar la edad con el cliente; mientras tanto, el propietario decide si se deja nula. Agregar `CHECK`. |
| C5 | RFC ausente | 8 | Completitud del RFC (obligatorio si el cliente factura) | **Gerencia Comercial** + Facturación | Definir si el RFC es obligatorio para todo cliente o solo para quien factura; solicitarlo al cliente. |
| C6 | Teléfono incompleto (`667`, solo la clave de zona) | 8 | Teléfono de 10 dígitos | **Gerencia Comercial** | Solicitar el número completo; agregar `CHECK`. |
| C7 | Código postal de 4 dígitos (`8000`) | 8 | Código postal de 5 dígitos | **Gerencia Comercial** | Confirmar con el cliente. No se asume que sea `80000`: corregir por suposición es inventar un dato. |
| C8 | Ciudad con variantes de escritura (`Culiacan` / `Culiacán`) | 7 | Consistencia (catálogo de ciudades) | **Gerencia Comercial** (define el catálogo) | Usar un catálogo de ciudades o de códigos postales en la captura; normalizar los registros existentes con folio. |
| C9 | Causa raíz: la tabla no tiene restricciones que impidan los errores anteriores; la captura se valida solo (o nada) en la aplicación | `clientes` | Integridad declarativa | Propietario aprueba la regla; **Comité de cambios** aprueba el cambio en producción | Ver tabla de la sección 4. |

## 3. Preguntas

**¿Por qué el DBA no debe corregir por su cuenta el RFC del registro 7?**
Porque el DBA es **custodio**, no propietario (sección 4.2 de la guía). Puede detectar que el RFC no cumple el formato, pero no sabe cuál es el valor correcto: completar la homoclave sería inventar un dato fiscal con efecto en la facturación. Además, si lo hiciera sin solicitud, el cambio aparecería en la conciliación como **no autorizado**, y el DBA estaría actuando como juez y parte: modifica el dato y opera la evidencia que lo registra. La corrección la decide la Gerencia Comercial con la información que proporcione el cliente; el DBA la ejecuta con un folio.

**¿Qué restricción habría evitado cada hallazgo? ¿Quién debe aprobar agregarla?**

| Hallazgo | Restricción | Observación |
|---|---|---|
| C1 | `CREATE UNIQUE INDEX ... ON clientes (lower(correo))` | Solo puede crearse cuando se resuelva el duplicado 1/7. |
| C2 | `CHECK (rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$')` | Con `NOT VALID` aplica a filas nuevas sin fallar por las existentes. |
| C3 | `CHECK (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')` | Conviene decidir también si `correo` admite nulos. |
| C4 | `CHECK (edad BETWEEN 18 AND 120)` | |
| C5 | `NOT NULL` en `rfc` (o `CHECK` condicionado a que el cliente facture) | Decisión de negocio, no técnica. |
| C6 | `CHECK (telefono ~ '^[0-9]{10}$')` | |
| C7 | `CHECK (codigo_postal ~ '^[0-9]{5}$')` | |
| C8 | Llave foránea a un catálogo de ciudades | Requiere crear el catálogo. |

La **regla** (qué es un dato válido) la aprueba el propietario, la Gerencia Comercial. El **cambio en producción** (agregar la restricción) lo aprueba el Comité de cambios mediante folio en `gobierno.solicitudes_cambio` (POL-06), y lo ejecuta el DBA dentro de la ventana. Las propuestas están comentadas al final del script, sin ejecutar.

**Si el DBA corrige un dato, ¿qué mecanismo del LAB-01 (Parte B) deja evidencia?**
El disparador `trg_auditoria_clientes`, que inserta en `auditoria.cambios_clientes` una fila con usuario de sesión, aplicación, momento, operación `UPDATE`, `id_cliente` y los valores antes y después. Además, con `log_statement = 'mod'`, la sentencia `UPDATE` queda en la bitácora del colector. La evidencia solo existe si el disparador está habilitado (`tgenabled = 'O'` en E3): el propio LAB-01 demostró que un superusuario puede desactivarlo.
