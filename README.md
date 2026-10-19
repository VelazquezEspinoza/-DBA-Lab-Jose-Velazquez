# LAB-01 — Protección y privacidad de datos

**Universidad Autónoma de Sinaloa · Facultad de Informática**

| Dato | Detalle |
|---|---|
| Materia | Gestión de Seguridad y Desempeño de Bases de Datos |
| Unidad | II — Seguridad, privacidad y control de acceso |
| Tema | 2.3 — Datos sensibles, privacidad y protección de la información |
| Profesor | Alexis Moisés Montaño Araujo |
| Alumno | José Fernando Velázquez Espinoza |
| Motor | PostgreSQL 16 (administrado con pgAdmin) |
| Modalidad | Práctica individual |
| Fecha | 2 de octubre de 2026 |

## Descripción

Laboratorio en el que se aplican mecanismos de protección de datos en PostgreSQL de acuerdo con el propósito y el nivel de acceso de distintas áreas de una organización ficticia (Comercializadora Norte S.A. de C.V.): soporte, analítica, administración de la base de datos y dirección.

Se trabajan seis mecanismos: clasificación de datos, enmascaramiento, seudonimización, anonimización, control de acceso y retención de datos. La idea central es que no existe una única técnica adecuada para todos los escenarios y que ninguna sustituye al control de acceso.

> Todos los datos son **ficticios** (correos con dominio `example.test`). No se utilizó información personal real.

## Estructura del repositorio

```
LAB-01/
├── README.md
├── informe.md
├── sql/
│   ├── 01-clasificacion.sql
│   ├── 02-enmascaramiento.sql
│   ├── 03-seudonimizacion.sql
│   ├── 04-anonimizacion.sql
│   └── 05-retencion.sql
└── evidencias/
    ├── 01-clasificacion.pdf
    ├── 02-enmascaramiento.pdf
    ├── 03-seudonimizacion.pdf
    ├── 04-anonimizacion.pdf
    └── 05-retencion.pdf
```

## Contenido por actividad

| # | Script SQL | Evidencia | Actividad | Qué se implementa |
|---|---|---|---|---|
| 1 | `sql/01-clasificacion.sql` | `evidencias/01-clasificacion.pdf` | Preparación y Actividad 1 | Tabla `clientes`, datos de prueba y matriz de clasificación |
| 2 | `sql/02-enmascaramiento.sql` | `evidencias/02-enmascaramiento.pdf` | Actividad 2 | Rol `soporte` y vista `v_clientes_soporte` con datos enmascarados |
| 3 | `sql/03-seudonimizacion.sql` | `evidencias/03-seudonimizacion.pdf` | Actividades 3 y 4 | Tokens (UUID), esquema `pii` con el mapa, esquema `analitica` y rol `analista` |
| 4 | `sql/04-anonimizacion.sql` | `evidencias/04-anonimizacion.pdf` | Actividades 5 y 6 | Generalización, agregación, supresión de grupos pequeños y análisis de riesgo |
| 5 | `sql/05-retencion.sql` | `evidencias/05-retencion.pdf` | Actividad 7 | Consulta de retención a 5 años (sin `DELETE`) |

El análisis completo, las decisiones tomadas, las conclusiones y las respuestas de reflexión están en [`informe.md`](informe.md).

## Requisitos

- PostgreSQL 16.
- pgAdmin (Query Tool) o `psql`.
- Un usuario con privilegios para crear roles, esquemas y extensiones (administrador de la base de datos).
- La extensión `pgcrypto` (se habilita en el script 03; `gen_random_uuid()` también está disponible de forma nativa desde PostgreSQL 13).

## Cómo reproducir el laboratorio

1. Crear o seleccionar una base de datos de práctica y conectarse como administrador.
2. Ejecutar los scripts **en orden**, ya que todos dependen de la tabla `clientes` creada en el primero:

   ```
   sql/01-clasificacion.sql
   sql/02-enmascaramiento.sql
   sql/03-seudonimizacion.sql
   sql/04-anonimizacion.sql
   sql/05-retencion.sql
   ```

3. Los roles `soporte` y `analista` se crean con `NOLOGIN`, por lo que las pruebas de acceso se hacen desde la sesión del administrador con `SET ROLE` y se cierran con `RESET ROLE`:

   ```sql
   SET ROLE soporte;
   SELECT * FROM v_clientes_soporte;   -- permitido
   SELECT * FROM clientes;             -- ERROR: permission denied for table clientes
   RESET ROLE;
   ```

4. Los scripts no son idempotentes: si se repite la ejecución, PostgreSQL indicará que tablas, roles y esquemas ya existen. Para empezar de cero, eliminar primero los objetos creados (`DROP VIEW`, `DROP SCHEMA ... CASCADE`, `DROP ROLE`, `DROP TABLE`).

## Resumen de controles implementados

| Área | Mecanismo | Acceso concedido | Acceso denegado |
|---|---|---|---|
| Soporte | Enmascaramiento mediante vista | `SELECT` sobre `v_clientes_soporte` | Tabla `clientes` |
| Analítica | Seudonimización con tokens | `SELECT` sobre `analitica.clientes` | `pii.mapa_cliente` y `public.clientes` |
| Dirección | Agregación, generalización y supresión | Consultas agregadas sin identificadores directos | — |
| Retención | Consulta de registros vencidos | Solo identificación (sin eliminación) | — |

## Evidencias

Cada PDF de `evidencias/` incluye: estudiante, actividad, consulta o comando ejecutado, resultado obtenido y fecha o contexto de ejecución. Cuando se demuestra un acceso rechazado, se muestra el intento y el mensaje de error (`permission denied`, SQL state `42501`). Las capturas complementan, pero no sustituyen, a los scripts SQL ni a la explicación técnica del informe.

## Historial de commits sugerido

```
feat: agrega clasificación de datos
feat: implementa vista de enmascaramiento
feat: implementa seudonimización
feat: agrega análisis de anonimización
docs: agrega evidencias y conclusiones
```

## Limitaciones

- El conjunto de datos tiene solo cinco registros, por lo que casi cualquier combinación de atributos es única y el riesgo de reidentificación es alto.
- El umbral `k = 5` es un parámetro didáctico; no demuestra por sí mismo que los datos sean anónimos.
- La eliminación física de datos no se ejecuta en esta práctica; se aborda en los laboratorios de respaldo y recuperación.
