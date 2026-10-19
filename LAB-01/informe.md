# Informe — LAB-01: Protección y privacidad de datos

**Universidad Autónoma de Sinaloa · Facultad de Informática**
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
**Profesor:** Alexis Moisés Montaño Araujo
**Alumno:** José Fernando Velázquez Espinoza
**Motor:** PostgreSQL 16 · pgAdmin
**Fecha:** 2 de octubre de 2026

---

## Introducción

Se implementaron controles de protección sobre la tabla `clientes` de la empresa ficticia Comercializadora Norte S.A. de C.V., considerando las necesidades de cuatro áreas: soporte (identificar al cliente sin ver todos sus datos), analítica (analizar patrones sin conocer la identidad), administración de la base de datos (administrar estructuras y accesos) y dirección (información estadística y agregada).

Scripts: `sql/01` a `sql/05`. Evidencias: `evidencias/01` a `evidencias/05`.

> Nota sobre nombres de roles: en la guía los roles se llaman `soporte` y `analista`. En el entorno de laboratorio se utilizaron nombres personalizados equivalentes (`soporte_jose`, `analista_jose_velazquez`); su función y sus permisos son los mismos.

---

## 19.1 Clasificación

Se analizaron los nueve atributos de la tabla `clientes`. Todos requieren protección, con distinto nivel:

| Campo | ¿Identifica directamente? | ¿Contribuye a identificar? | Protección | Justificación |
|---|---|---|---|---|
| id | No (indirecto) | Sí | Moderada | Identificador técnico; vincula registros entre tablas. |
| nombre | Sí | Sí | Alta | Identificador más directo de una persona física. |
| correo | Sí | Sí | Alta | Suele contener nombre y apellido; permite contacto y cruce entre sistemas. |
| telefono | Sí | Sí | Alta | Permite contactar y localizar; llave de cruce. |
| rfc | Sí | Sí | Muy alta | Contiene iniciales y fecha de nacimiento; útil para fraude y suplantación. |
| edad | No | Sí | Media | Cuasi-identificador; redundante con el RFC. |
| ciudad | No | Sí | Media | Dato geográfico general; reduce candidatos. |
| codigo_postal | No | Sí | Media-alta | Acota la zona de residencia; cuasi-identificador clásico. |
| fecha_alta | No | Sí (limitado) | Baja | Permite correlacionar registros; poco valor identificador por sí sola. |

**Identificadores directos:** nombre, correo, telefono y rfc. **Cuasi-identificadores:** edad, ciudad, codigo_postal, fecha_alta (y el id como vínculo entre registros).

**Combinaciones de mayor riesgo:** `codigo_postal + edad + ciudad` (en esta tabla, «41 años, Culiacán, CP 80000» corresponde a un solo registro); `rfc + edad`; `nombre + codigo_postal`; `correo/telefono` con cualquier otro campo; y `fecha_alta + codigo_postal + edad` en bases pequeñas.

**Sensibilidad jurídica:** ningún campo es dato personal sensible en sentido jurídico (no revelan salud, origen étnico, creencias, etc.), pero todos son datos personales o cuasi-identificadores y deben protegerse según el riesgo. El RFC, aunque no es sensible, puede facilitar fraude y suplantación de identidad, por lo que amerita controles reforzados.

---

## 19.2 Enmascaramiento

- **Qué se ocultó:** parte del correo (se muestran solo los dos primeros caracteres y el dominio), del teléfono (solo los últimos cuatro dígitos) y del RFC (solo los últimos cuatro caracteres).
- **Para quién:** el área de soporte (rol `soporte`).
- **Por qué:** soporte necesita identificar al cliente para atender solicitudes, pero no requiere los datos completos. Se aplica el principio de mínimo privilegio.
- **Mecanismo utilizado:** vista `v_clientes_soporte` (enmascaramiento dinámico), con `GRANT SELECT` solo sobre la vista, `GRANT USAGE` sobre el esquema `public` y `REVOKE ALL` sobre la tabla `clientes`. La vista se ejecuta con los privilegios de su propietario, por lo que el rol puede consultarla sin acceder a la tabla base.

**Resultado observado:** la vista mostró, por ejemplo, `an*****@example.test`, `******4567` y `*********5ABC`. Como rol de soporte, la consulta a la vista funcionó; la consulta directa a `clientes` fue rechazada con `ERROR: permission denied for table clientes` (SQL state 42501).

**Preguntas de la actividad**

- *¿Qué información continúa en la tabla original?* Todos los valores completos; el enmascaramiento solo cambia la presentación.
- *¿Qué ve soporte?* id y nombre completos, y correo, teléfono y RFC parcialmente ocultos. No ve edad, ciudad, código postal ni fecha de alta.
- *¿Por qué no basta ocultar en la aplicación?* Porque quien tenga credenciales de base de datos puede conectarse directamente y evadir la aplicación.
- *¿Y si soporte tuviera acceso a `clientes`?* Vería los datos completos y se anularía el enmascaramiento.

---

## 19.3 Seudonimización

- **Cómo se generaron los tokens:** con `gen_random_uuid()` (extensión `pgcrypto`), un UUID aleatorio por cada cliente, insertado en `pii.mapa_cliente`.
- **Dónde está el mapa de correspondencia:** en la tabla `pii.mapa_cliente`, dentro del esquema `pii`, que relaciona cada `token` con `cliente_id` (clave foránea a `clientes.id`).
- **Quién debería acceder a él:** únicamente el DBA o un rol de protección de datos expresamente autorizado; nunca el área de analítica.
- **Por qué se separaron los permisos:** para que quien analiza los datos no pueda revertir la seudonimización (separación de funciones y mínimo privilegio).

El conjunto para analítica (`analitica.clientes`) contiene `cliente_token`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta`; no contiene nombre, correo, teléfono ni RFC.

**Verificación como rol `analista`:**

| Consulta | Resultado |
|---|---|
| `SELECT * FROM analitica.clientes` | Permitida |
| `SELECT * FROM pii.mapa_cliente` | Rechazada: `permission denied for schema pii` |
| `SELECT * FROM public.clientes` | Rechazada: `permission denied for table clientes` |

**Preguntas de la actividad**

- *¿Qué pasaría si analista consultara el mapa?* Podría relacionar token y cliente_id y, con acceso a `clientes`, recuperar la identidad.
- *¿Qué principio se aplica?* Separación de funciones y mínimo privilegio.
- *¿Por qué no es anonimización?* Porque existe información adicional (el mapa) que permite reidentificar, y los cuasi-identificadores restantes también pueden hacerlo.
- *¿Qué relaciona el token con la persona?* La tabla `pii.mapa_cliente` y, a través de ella, `clientes`.

---

## 19.4 Anonimización

- **Identificadores eliminados:** nombre, correo, telefono y rfc (y el id, sustituido por conteos agregados).
- **Atributos generalizados:** la edad se agrupó en rangos (`18-30`, `31-45`, `46+`) y el código postal se redujo a sus dos primeros dígitos (región).
- **Grupos suprimidos:** con `HAVING COUNT(*) >= 5` (umbral didáctico k = 5) se suprimen los grupos con menos de cinco registros.

**Resultados observados**

| Consulta | Resultado |
|---|---|
| Rango de edad | `31-45` → 4; `46+` → 1 |
| Región | `80` → 3; `81` → 1; `82` → 1 |
| Rango de edad + región | (31-45, 80) → 3; (31-45, 81) → 1; (46+, 82) → 1 |
| Con `HAVING COUNT(*) >= 5` | 0 filas: todos los grupos fueron suprimidos |

Con solo cinco registros ningún grupo alcanza el umbral. Esto muestra que la supresión protege a las personas de grupos pequeños, a costa de perder utilidad estadística.

**Análisis del riesgo de reidentificación (Actividad 6)**

- *Cuasi-identificadores que permanecen:* rango de edad y región.
- *Combinaciones que reducen el anonimato:* rango de edad + región, y cualquier cruce con otras fuentes (ciudad, fecha de alta, datos públicos o filtraciones).
- *Grupos con pocos registros:* un grupo de uno o dos registros equivale a señalar a una persona concreta.
- *Atributos a generalizar:* edad (rangos más amplios), código postal (menos dígitos o solo ciudad/estado) y fecha de alta (año o mes).
- *Información a suprimir:* los grupos por debajo del umbral y los identificadores directos.
- *¿«100 % anónimo»?* No. Cumplir un umbral k no demuestra anonimato completo: depende del contexto, de los atributos disponibles, de las fuentes externas y de los medios razonables de reidentificación. Con cinco registros, el riesgo es especialmente alto.

**Reto: reducir aún más el riesgo**

```sql
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 49 THEN '18-49'
        ELSE '50+'
    END AS rango_edad,
    LEFT(codigo_postal, 1) AS region,
    COUNT(*) AS total
FROM clientes
GROUP BY 1, 2
HAVING COUNT(*) >= 5;
```

| Elemento | Descripción |
|---|---|
| Cambio realizado | Rangos de edad más amplios y región reducida al primer dígito del código postal. |
| Motivo | Formar grupos más grandes que cumplan el umbral de cinco registros. |
| Resultado obtenido | Un grupo (`18-49`, región `8`) con 5 registros. |
| Riesgo que se reduce | La identificación de personas en grupos pequeños. |
| Costo | Se pierde detalle y utilidad analítica: el resultado es casi una cifra total. |

**Riesgo que permanece:** aun con grupos de cinco, la información agregada puede combinarse con fuentes externas; además, un conjunto tan pequeño no permite garantizar anonimato.

---

## 19.5 Retención

- **Criterio utilizado:** antigüedad de `fecha_alta` mayor a cinco años (periodo didáctico).

  ```sql
  SELECT *
  FROM clientes
  WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';
  ```

- **Resultado:** 0 filas, porque los registros de prueba se insertaron con `fecha_alta = CURRENT_DATE`. No se ejecutó ningún `DELETE` sobre la tabla principal.
- **Qué información debería conservarse:** datos con finalidad vigente o con obligación legal, contractual o fiscal de conservación.
- **Qué información podría eliminarse:** datos de clientes que superaron el periodo y ya no tienen finalidad ni obligación que justifique conservarlos.
- **Controles antes de eliminar:**
  - Aprobación escrita del responsable del tratamiento (jurídico o cumplimiento y dueño del dato), verificando que no haya obligación legal, contractual o litigio.
  - Respaldo completo y verificado, con restauración probada y acceso restringido.
  - Evidencia conservada: consulta ejecutada, registros afectados (sin exponer datos innecesarios), autorización, fecha, responsable y resultado.
  - Procedimiento de recuperación: restaurar el respaldo (o recuperación a un punto en el tiempo) en un entorno separado, extraer los registros afectados, reinsertarlos validando integridad y documentar el incidente.

La eliminación física se trabajará en las prácticas de respaldo y recuperación.

---

## 19.6 Conclusiones

**¿Qué técnica utilizaría para un área de soporte?**
Enmascaramiento mediante una vista con acceso restringido: soporte necesita identificar al cliente sin ver todos sus datos, y la vista permite mostrar solo lo necesario sin dar acceso a la tabla original.

**¿Qué técnica utilizaría para un área de analítica?**
Seudonimización con separación del mapa de correspondencia y generalización de cuasi-identificadores: analítica necesita datos por registro, pero no la identidad de las personas.

**¿Qué técnica utilizaría para publicar estadísticas?**
Anonimización mediante agregación, generalización y supresión de grupos pequeños, reconociendo que reduce el riesgo pero no lo elimina.

**¿Por qué ninguna de estas técnicas sustituye al control de acceso?**
Porque todas reducen el riesgo, pero su eficacia depende de que solo los roles autorizados accedan a cada objeto. Sin control de acceso, cualquier usuario podría consultar la tabla original o el mapa de tokens y anular cualquier transformación. En esta práctica el control de acceso (`GRANT`, `REVOKE`, roles y esquemas) fue lo que hizo efectivos el enmascaramiento y la seudonimización.

---

## Preguntas de reflexión

**1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?**
El enmascaramiento oculta la visualización del dato, que sigue existiendo íntegro en la tabla. La seudonimización sustituye el identificador por un token y mantiene aparte la información que permite revertir la relación.

**2. ¿Por qué la seudonimización no significa anonimización?**
Porque existe información adicional (el mapa) que permite reidentificar, y los cuasi-identificadores restantes también pueden hacerlo.

**3. ¿Por qué eliminar nombre y RFC no garantiza que un conjunto de datos sea anónimo?**
Porque edad, ciudad, código postal y otros atributos pueden combinarse entre sí o con fuentes externas para identificar a una persona.

**4. ¿Qué función tienen los cuasi-identificadores?**
No identifican por sí solos, pero en combinación reducen el conjunto de personas posibles y facilitan la reidentificación.

**5. ¿Por qué es importante separar el mapa de seudonimización?**
Porque quien tenga acceso a los datos seudonimizados y al mapa puede recuperar la identidad. Separarlos preserva el valor de la seudonimización.

**6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**
Mínimo privilegio y separación de funciones.

**7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**
Porque permite exponer solo las columnas y las formas necesarias (incluso enmascaradas) sin dar acceso a los datos originales.

**8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**
Proteger la visualización cambia lo que se muestra; proteger contra acceso no autorizado impide que el usuario llegue al dato original. Lo primero, sin lo segundo, se puede evadir.

**9. ¿Por qué la retención forma parte de la protección de datos?**
Porque conservar solo lo necesario y por el tiempo justificado cumple con los principios de minimización y finalidad, y reduce la cantidad de datos expuestos ante un incidente.

**10. ¿Qué riesgo existe si una organización conserva información indefinidamente?**
Aumenta el impacto de una filtración, el riesgo de uso para fines distintos a los originales, el incumplimiento legal y los costos de resguardo.

---

## Lista de verificación de entrega

- [x] La matriz de clasificación está completa.
- [x] Los scripts SQL están incluidos.
- [x] El enmascaramiento funciona.
- [x] El rol de soporte no tiene acceso directo a los datos originales.
- [x] La seudonimización funciona.
- [x] El rol de analista no tiene acceso al mapa de correspondencia.
- [x] El análisis de anonimización está documentado.
- [x] Se identificaron posibles cuasi-identificadores.
- [x] Se estableció una consulta para identificar datos sujetos a retención.
- [x] Las evidencias corresponden a las actividades realizadas.
- [x] El informe contiene las conclusiones y respuestas de reflexión.
