-- LAB-02 | Actividades 2 y 3: Cifrado de datos sensibles
-- La clave 'CLAVE-DE-PRUEBA' es FICTICIA y solo sirve para el laboratorio.
\echo '=== 8.1 Cifrado simétrico del RFC ==='
DROP TABLE IF EXISTS clientes_protegidos;
CREATE TABLE clientes_protegidos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    rfc_cifrado BYTEA NOT NULL
);
INSERT INTO clientes_protegidos (nombre, rfc_cifrado)
VALUES ('Ana López', pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA'));
SELECT id, nombre, rfc_cifrado FROM clientes_protegidos;

\echo '=== 8.2 Recuperación con la clave correcta ==='
SELECT id, nombre, pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc
FROM clientes_protegidos;

\echo '=== 8.2 Intento con clave incorrecta (se espera ERROR) ==='
\set ON_ERROR_STOP off
SELECT pgp_sym_decrypt(rfc_cifrado, 'CLAVE-INCORRECTA') FROM clientes_protegidos;
\set ON_ERROR_STOP on

\echo '=== Cifrar el mismo dato dos veces produce textos cifrados distintos ==='
SELECT encode(pgp_sym_encrypt('LOPA900101ABC','CLAVE-DE-PRUEBA'),'hex') = 
       encode(pgp_sym_encrypt('LOPA900101ABC','CLAVE-DE-PRUEBA'),'hex') AS son_iguales;

\echo '=== Qué ve un usuario sin la clave: solo bytes ==='
SELECT nombre, length(rfc_cifrado) AS bytes_cifrados, pg_typeof(rfc_cifrado) AS tipo
FROM clientes_protegidos;
