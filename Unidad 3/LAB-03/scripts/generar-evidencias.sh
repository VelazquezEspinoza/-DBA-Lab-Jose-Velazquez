#!/usr/bin/env bash
# =====================================================================
# LAB-03 · Actividades 3 y 8 — Genera las evidencias técnicas E1–E6
# Ejecutar DESDE la carpeta LAB-03/:
#     bash scripts/generar-evidencias.sh
#
# Variables opcionales:
#   PSQL     Forma de abrir la sesión de administrador.
#            Por defecto: "psql -U postgres -d comercial"
#            Docker:  PSQL="docker exec -i pg16 psql -U postgres -d comercial"
#   LAB02    Ruta a la carpeta del LAB-02 (para E6). Por defecto: ../LAB-02
#
# pg_read_file() requiere superusuario o el rol pg_read_server_files.
# =====================================================================
set -euo pipefail

PSQL="${PSQL:-psql -U postgres -d comercial}"
LAB02="${LAB02:-../LAB-02}"
EV="evidencias"
mkdir -p "$EV/E6-mongodb"

# Oculta cualquier contraseña literal (PASSWORD '...'), además de la de la guía
read -r -d '' REDACT_TAIL <<'SQL' || true
, '(PASSWORD\s+)''[^'']*''', '\1''<REDACTED>''', 'gi')
SQL
redact() { printf '%s' "regexp_replace($1$REDACT_TAIL"; }

echo "== Diccionario (Actividad 3)"
$PSQL --csv -c "SELECT c.column_name AS columna, c.data_type AS tipo, c.character_maximum_length AS longitud, c.is_nullable AS acepta_nulos, col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion FROM information_schema.columns c WHERE c.table_schema = 'public' AND c.table_name = 'clientes' ORDER BY c.ordinal_position" > "$EV/diccionario-clientes.csv"

echo "== E1 — Configuración de registro vigente"
$PSQL -c "SELECT name, setting, source FROM pg_settings WHERE name IN ('logging_collector', 'log_connections', 'log_disconnections', 'log_statement', 'log_line_prefix', 'log_min_error_statement') ORDER BY name" > "$EV/E1-configuracion-registro.txt"
# Contexto adicional útil para auditoría: archivo vigente y momento de la captura
$PSQL -c "SELECT now() AS capturado_en, pg_current_logfile() AS archivo_vigente, pg_postmaster_start_time() AS servidor_iniciado, current_setting('log_rotation_age') AS rotacion_edad, current_setting('log_rotation_size') AS rotacion_tamano" >> "$EV/E1-configuracion-registro.txt"

echo "== E2 — Privilegios vigentes sobre tablas"
$PSQL -c "SELECT grantee, table_schema, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios FROM information_schema.role_table_grants WHERE table_schema NOT IN ('pg_catalog', 'information_schema') AND grantee <> 'postgres' GROUP BY 1, 2, 3 ORDER BY 1" > "$EV/E2-privilegios.txt"

echo "== E3 — Disparadores (mecanismo de auditoría de datos)"
# tgenabled: O = habilitado, D = deshabilitado, R = réplica, A = siempre
$PSQL -c "SELECT tgname, tgenabled, tgrelid::regclass FROM pg_trigger WHERE NOT tgisinternal" > "$EV/E3-disparadores.txt"

echo "== E4 — Muestra de auditoría (solo metadatos)"
$PSQL -c "SELECT id_evento, momento, usuario_sesion, aplicacion, operacion, id_cliente FROM auditoria.cambios_clientes ORDER BY id_evento DESC LIMIT 10" > "$EV/E4-muestra-auditoria.txt"

echo "== E5 — Bitácora vigente, sin secretos"
EXPR=$(redact "replace(pg_read_file(pg_current_logfile()), 'Temporal_Practica_2026', '<REDACTED>')")
$PSQL -At -c "SELECT $EXPR" > "$EV/E5-bitacora-postgresql.log"

# Archivos rotados anteriores (si los hay)
VIGENTE=$($PSQL -At -c "SELECT pg_current_logfile()" | xargs basename)
for f in $($PSQL -At -c "SELECT name FROM pg_ls_logdir() WHERE name LIKE '%.log' ORDER BY modification"); do
  [ "$f" = "$VIGENTE" ] && continue
  echo "   + archivo rotado: $f"
  EXPR=$(redact "replace(pg_read_file(current_setting('log_directory') || '/$f'), 'Temporal_Practica_2026', '<REDACTED>')")
  $PSQL -At -c "SELECT $EXPR" > "$EV/E5-bitacora-postgresql-$f"
done

# Revisión obligatoria antes de compartir: no debe quedar ninguna contraseña
if grep -Ein "password '[^<]" "$EV"/E5-bitacora-postgresql*.log; then
  echo "!! ATENCIÓN: quedan contraseñas sin ocultar. Revisa antes de compartir." >&2
  exit 1
fi

echo "== E5 — Hash SHA-256"
( cd "$EV" && sha256sum E5-bitacora-postgresql*.log > E5-bitacora-postgresql.sha256 )
cat "$EV/E5-bitacora-postgresql.sha256"

echo "== E6 — Evidencias de MongoDB (copiadas del LAB-02)"
if [ -d "$LAB02/evidencias" ]; then
  for f in system-profile.json bitacora-mongod.log 09-comparacion.md; do
    [ -f "$LAB02/evidencias/$f" ] && cp -p "$LAB02/evidencias/$f" "$EV/E6-mongodb/" || echo "   falta $f en $LAB02/evidencias"
  done
  cp -p "$LAB02"/evidencias/*.sha256 "$EV/E6-mongodb/" 2>/dev/null || true
  # Verifica que las copias conservan el hash calculado en el LAB-02
  ( cd "$EV/E6-mongodb" && ls ./*.sha256 >/dev/null 2>&1 && sha256sum -c ./*.sha256 ) || echo "   (sin hashes del LAB-02 que verificar)"
else
  echo "   No se encontró $LAB02/evidencias. Copia E6 a mano (ver README)."
fi

echo "== Índice de hashes de todas las evidencias"
( cd "$EV" && find . -type f ! -name 'SHA256SUMS' ! -name '*.md' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS )
echo "Listo. Revisa $EV/ y verifica con: (cd $EV && sha256sum -c SHA256SUMS)"
