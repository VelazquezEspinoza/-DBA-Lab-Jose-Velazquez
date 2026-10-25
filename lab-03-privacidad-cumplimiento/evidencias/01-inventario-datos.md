# Evidencia 01 — Inventario y finalidad de los datos

## Objetivo
Identificar qué datos de la tabla `clientes` son personales, para qué se usan, si son necesarios, quién debe acceder a ellos y cuánto tiempo conservarlos.

## Procedimiento
1. Se revisó la estructura de `clientes` (id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta).
2. Se relacionó cada campo con los procesos del escenario: Atención al cliente, Facturación y Analítica.
3. Se evaluó necesidad y proporcionalidad por finalidad.
4. Se propuso nivel de acceso y retención (los plazos son **propuestas** que deben validarse con Jurídico/Privacidad).

## Resultado

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención (propuesta) |
|---|---|---|---|---|---|
| id | Sí, indirecto (seudónimo): permite vincular el registro con una persona | Identificador interno y llave para relacionar tablas | Sí | Interno: soporte, facturación, DBA (técnico) | Mientras exista el registro |
| nombre | Sí, directo | Atención al cliente y emisión de facturas | Sí (soporte y facturación) | Soporte, Facturación | Relación comercial + plazo legal |
| correo | Sí, directo | Contacto con el cliente / envío de comprobantes | Sí (soporte) | Soporte; Facturación solo si envía CFDI | Relación comercial + 1 año |
| telefono | Sí, directo | Contacto en atención al cliente | Sí, pero opcional | Soporte | Relación comercial + 1 año |
| rfc | Sí, directo (identifica al contribuyente; no es "sensible" pero tiene riesgo alto de fraude) | Facturación (obligación fiscal) | Sí **solo** para facturación | Facturación únicamente | 5 años desde el último ejercicio (ref. CFF art. 30; validar con Jurídico) |
| edad | Sí, indirecto (combinada con otros datos identifica) | Estadísticas (analítica) | No para soporte ni facturación; sí agregada para analítica | Analítica solo como rango (vista) | Mientras sirva a la finalidad estadística; mejor almacenar rango |
| ciudad | Sí, indirecto (cuasi-identificador) | Analítica geográfica; logística si aplica | No para soporte; sí para analítica | Analítica (vista), DBA técnico | Igual que edad |
| codigo_postal | Sí, indirecto (muy granular; cuasi-identificador) | Región para analítica; dato fiscal si el CFDI lo requiere | No para soporte; sí para facturación (domicilio fiscal) y analítica por región | Facturación (completo); Analítica solo región (2 dígitos) | CP fiscal: 5 años; analítico: como edad |
| fecha_alta | Sí, indirecto (describe la relación con una persona) | Antigüedad del cliente, retención y cálculo de plazos | Sí, para gestión del ciclo de vida | DBA/Dirección; Analítica como antigüedad agregada | Mientras exista el registro |

### Justificaciones clave
- **Dato personal ≠ dato sensible.** Ninguno de estos campos es sensible en el sentido legal (salud, origen étnico, religión, etc.), pero el conjunto permite identificar y perfilar a una persona.
- **Cuasi-identificadores:** edad + ciudad + código postal pueden reidentificar a alguien aunque no aparezca el nombre. Por ello analítica solo recibe rangos y regiones.
- **RFC:** su necesidad existe únicamente en facturación; en soporte aumenta el riesgo sin aportar valor.

## Análisis
Cada campo tiene una finalidad distinta y ningún proceso necesita todos. Un único acceso a la tabla completa viola minimización y mínimo privilegio. El inventario es el punto de partida del catálogo de datos y de la matriz de gobierno.

## Conclusión
Los 9 campos son datos personales (directos o indirectos). Solo `id`, `nombre`, `correo`, `telefono`, `rfc` y `fecha_alta` están justificados para operación; `edad`, `ciudad` y `codigo_postal` deben exponerse de forma agregada a analítica y no a soporte.
