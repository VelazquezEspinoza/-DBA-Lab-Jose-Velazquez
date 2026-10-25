# Evidencia 12 — Privacidad por diseño

## Objetivo
Evaluar el diseño propuesto por un desarrollador que guarda "todos los datos por si después se necesitan" y proponer una alternativa respetuosa de la privacidad.

## Procedimiento
Se analizó la tabla propuesta (nombre, correo, telefono, rfc, edad, direccion, ciudad, codigo_postal, fecha_nacimiento, ocupacion, salario, estado_civil, ...) contra los principios de minimización, finalidad y privacidad por defecto.

## Resultado

**1. Problemas identificados**
- Recolección excesiva sin finalidad definida.
- `salario`, `ocupacion`, `estado_civil` y `fecha_nacimiento` son datos de mayor riesgo/perfilamiento; el salario puede ser financiero o patrimonial.
- Redundancia: `edad` y `fecha_nacimiento` (la edad se calcula).
- Todo como `TEXT`, sin restricciones, `PRIMARY KEY` ni validaciones (calidad e integridad).
- Sin separación entre datos operativos y analíticos.
- Sin retención, responsables ni control de acceso.
- Mayor impacto en caso de brecha y mayor dificultad para ARCO.

**2. Principio ignorado**
Minimización de datos (y limitación de finalidad, proporcionalidad y privacidad por diseño/por defecto).

**3. Preguntas antes de aprobar**
- ¿Cuál es la finalidad de la aplicación y de cada campo?
- ¿Qué proceso falla si no se guarda este dato?
- ¿Cuál es la base jurídica y qué dice el aviso de privacidad?
- ¿Quién es el propietario del dato y quién podrá consultarlo?
- ¿Cuánto tiempo se conservará y cómo se eliminará?
- ¿Se puede obtener el dato más adelante, solo cuando se necesite?
- ¿Se puede usar un rango o un dato derivado en lugar del valor exacto?

**4. Datos que eliminaría (de la propuesta)**
`salario`, `estado_civil`, `ocupacion`, `fecha_nacimiento` (o `edad`, nunca ambos) y `direccion` completa si no hay envíos. También `edad` si no hay finalidad estadística.

**5. Datos que requieren justificación adicional**
`rfc` (solo si se factura), `direccion` (solo si hay entrega física), `codigo_postal`, `telefono`, `fecha_nacimiento` (si hay requisito legal de edad mínima, almacenar solo "mayor de edad: sí/no").

**6. Privacidad por defecto**
- Esquema mínimo: solo campos necesarios; opcionales sin llenar por defecto.
- Sin permisos para nadie hasta que se otorguen (`REVOKE ALL ... FROM PUBLIC`).
- Vistas por rol y datos generalizados para analítica.
- Campos de consentimiento por finalidad, con valor por defecto "no".
- Retención definida desde el diseño; entornos de prueba con datos sintéticos.

### Diseño alternativo
```sql
CREATE TABLE clientes (
    id            BIGSERIAL PRIMARY KEY,
    nombre        VARCHAR(120) NOT NULL,
    correo        VARCHAR(150) NOT NULL UNIQUE,
    telefono      VARCHAR(20),                  -- opcional
    fecha_alta    DATE NOT NULL DEFAULT CURRENT_DATE,
    acepta_marketing BOOLEAN NOT NULL DEFAULT FALSE
);

-- Datos fiscales separados: solo se llenan si el cliente solicita factura
CREATE TABLE clientes_fiscal (
    id_cliente  BIGINT PRIMARY KEY REFERENCES clientes(id) ON DELETE CASCADE,
    rfc         VARCHAR(13) NOT NULL,
    codigo_postal_fiscal VARCHAR(5) NOT NULL
);
```

## Análisis
"Guardar por si acaso" transfiere el costo al titular y a la organización. Separar datos fiscales y operativos permite aplicar permisos y retención distintos.

## Conclusión
Se rechaza el diseño original. La privacidad por diseño implica decidir en el modelado qué datos nacen, quién los ve y cuándo mueren.
