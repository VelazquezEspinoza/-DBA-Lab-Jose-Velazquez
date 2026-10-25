# Evidencia 11 — Matriz de gobierno de datos

## Objetivo
Demostrar que el acceso a cada dato se relaciona con una necesidad funcional y que existen responsables, protección, retención y acción final definidos.

## Procedimiento
Se asignó a cada campo un propietario (data owner), usuarios autorizados, controles de protección y ciclo de vida. El DBA actúa como **custodio**, no como propietario.

## Resultado

| Dato | Finalidad | Responsable (data owner) | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| nombre | Atención al cliente y facturación | Dirección de Operaciones / Atención al Cliente | Atención al cliente, Facturación | Rol por función, vista/tabla mínima, auditoría | Relación + plazo legal | Eliminar o anonimizar |
| correo | Contacto y envío de comprobantes | Atención al Cliente | Atención al cliente; Facturación (envío CFDI) | Acceso por rol, TLS en tránsito, auditoría de exportaciones | Relación + 1 año | Eliminar |
| telefono | Contacto en soporte | Atención al Cliente | Atención al cliente | Acceso por rol, enmascaramiento parcial en consultas | Relación + 1 año | Eliminar |
| rfc | Facturación y cumplimiento fiscal | Finanzas / Facturación | Facturación únicamente | `GRANT` por columna, cifrado de columna o disco, auditoría, nunca en entornos de prueba | 5 años (validar) | Eliminar tras plazo; mientras tanto, bloqueo |
| edad | Estadísticas | Analítica / Dirección | Analítica (solo rango vía vista) | Generalización a rangos; sin acceso a valor exacto | Detalle 2 años; agregados sin límite | Eliminar detalle, conservar agregados |
| ciudad | Estadísticas geográficas | Analítica | Analítica (vista) | Vista; umbral mínimo de grupo (k≥5) | Detalle 2 años | Agregar/eliminar |
| codigo_postal | Domicilio fiscal; región analítica | Finanzas (fiscal), Analítica (región) | Facturación (completo); Analítica (2 dígitos) | Reducción a región; `GRANT` por columna | Fiscal 5 años; analítico 2 años | Eliminar/agregar |

### Roles y responsabilidades
| Rol | Responsabilidad |
|---|---|
| Dirección | Aprueba políticas y finalidades; nombra data owners. |
| Responsable de privacidad / Jurídico | Define base jurídica, aviso de privacidad, plazos legales, atiende ARCO. |
| Data owner (área de negocio) | Decide uso y acceso a sus datos; aprueba solicitudes. |
| DBA (data custodian) | Implementa roles, permisos, respaldos, auditoría, borrados; no decide finalidades. |
| Atención al cliente / Facturación / Analítica | Usan los datos solo para su función. |

## Análisis
Ningún rol necesita todos los campos. El acceso administrativo del DBA no justifica usar los datos para cualquier finalidad. Las columnas con mayor riesgo (RFC) tienen el acceso más restringido.

## Conclusión
La matriz vincula cada dato con una finalidad, un responsable y un control técnico, y es la base para configurar los `GRANT` y para auditar accesos.
