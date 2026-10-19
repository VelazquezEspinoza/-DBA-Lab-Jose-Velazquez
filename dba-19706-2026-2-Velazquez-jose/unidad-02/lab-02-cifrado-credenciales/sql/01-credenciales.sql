-- LAB-02 | Actividad 1: Protección de credenciales
-- Todos los valores son FICTICIOS (solo laboratorio).
\echo '=== 7.1 Implementación INCORRECTA (texto claro) ==='
DROP TABLE IF EXISTS usuarios_insegura;
CREATE TABLE usuarios_insegura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL
);
INSERT INTO usuarios_insegura (usuario, password) VALUES ('juan', 'Password123');
SELECT * FROM usuarios_insegura;

\echo '=== 7.3 crypt() + gen_salt(bf) ejecutado dos veces ==='
SELECT crypt('Password123', gen_salt('bf')) AS hash_1;
SELECT crypt('Password123', gen_salt('bf')) AS hash_2;

\echo '=== 7.4 Tabla con credenciales protegidas ==='
DROP TABLE IF EXISTS usuarios_segura;
CREATE TABLE usuarios_segura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);
INSERT INTO usuarios_segura (usuario, password_hash)
VALUES ('juan', crypt('Password123', gen_salt('bf')));
SELECT * FROM usuarios_segura;

\echo '=== 7.5 Verificación: contraseña correcta ==='
SELECT usuario, password_hash = crypt('Password123', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';

\echo '=== 7.5 Verificación: contraseña incorrecta ==='
SELECT usuario, password_hash = crypt('OtraPassword', password_hash) AS contraseña_correcta
FROM usuarios_segura WHERE usuario = 'juan';
