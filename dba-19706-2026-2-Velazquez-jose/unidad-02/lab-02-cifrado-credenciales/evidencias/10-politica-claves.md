# Evidencia 10 — Política mínima de protección de claves criptográficas

## Objetivo
Definir reglas básicas para el ciclo de vida de las claves criptográficas de la organización ficticia Comercializadora Norte S.A. de C.V.

## Comando o procedimiento
Redacción de una política de 9 reglas que cubre: generación, almacenamiento, acceso, rotación, respaldo, revocación, exposición accidental y eliminación.

## Resultado obtenido

1. **Generación.** Las claves se generan con generadores aleatorios criptográficamente seguros (KMS, HSM o herramientas estándar como `openssl rand`), nunca con frases inventadas por una persona, y con la longitud mínima que exige el algoritmo (p. ej. 256 bits para AES). Cada propósito (datos, respaldos, TLS) usa una clave distinta.
2. **Almacenamiento.** Las claves se guardan únicamente en un gestor de secretos/KMS/HSM. No se guardan en repositorios Git, scripts SQL, tablas de la misma base que protegen, tickets, chats ni documentación.
3. **Separación.** La clave no se almacena junto a los datos que protege ni junto a sus respaldos; los datos cifrados y la clave viven en sistemas distintos con administradores o permisos distintos.
4. **Acceso.** Acceso por mínimo privilegio, con identidad individual o de servicio, autenticación fuerte y registro de cada uso. Quien administra la base de datos no tiene por defecto acceso a las claves de descifrado.
5. **Rotación.** Las claves se rotan con una periodicidad definida (p. ej. anual para claves de datos) y de inmediato ante sospecha de compromiso, baja de personal con acceso o fin de proyecto. Debe existir un procedimiento probado de re-cifrado.
6. **Respaldo.** Existe copia de las claves en un lugar seguro y separado, cifrada y con acceso dual (dos personas). Se prueba periódicamente la recuperación, porque perder la clave equivale a perder los datos.
7. **Revocación.** Cuando una clave deja de ser confiable se revoca, se bloquea su uso y se sustituye por una nueva; los datos se re-cifran y se documenta la fecha y el motivo.
8. **Exposición accidental.** Toda clave publicada por error (repositorio, log, correo, captura) se considera **comprometida**: se rota inmediatamente, se reporta como incidente y se revisa qué datos y qué periodo estuvieron afectados. Borrar el commit no es suficiente; se habilita escaneo de secretos antes de cada push.
9. **Eliminación.** Al terminar su vida útil, la clave se destruye de forma segura en todas sus copias y se conserva únicamente el registro de auditoría (sin el material de la clave), conservando versiones antiguas solo mientras existan datos que las necesiten.

## Análisis
Las reglas 2, 3 y 4 evitan que una sola filtración exponga datos y clave a la vez; 5 a 7 limitan el tiempo y el daño de un compromiso; 8 define la respuesta ante el error humano más común; 6 y 9 aseguran disponibilidad y cierre del ciclo de vida.

## Conclusión
Una política breve pero concreta cubre el ciclo completo de la clave. El algoritmo es tan fuerte como lo sea la forma en que se gestiona su clave.
