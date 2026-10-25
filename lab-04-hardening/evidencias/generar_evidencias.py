#!/usr/bin/env python3
"""
Genera las evidencias PNG del LAB-04 a partir de la ejecución REAL de comandos
en tu servidor de laboratorio. Cada imagen muestra fecha, host, comando y salida.

Requisitos:  pip install pillow   |  psql y ss disponibles en el servidor
Uso:
  export PGHOST=localhost PGPORT=5432 PGUSER=<admin_lab> PGDATABASE=<db_lab>
  export PGPASSWORD=...      # o usa ~/.pgpass
  python3 generar_evidencias.py            # genera 01..06 en esta carpeta
  python3 generar_evidencias.py antes      # añade sufijo _antes (ejecútalo ANTES del hardening)
  python3 generar_evidencias.py despues    # añade sufijo _despues
"""
import os, sys, getpass, subprocess, socket, datetime, textwrap
from PIL import Image, ImageDraw, ImageFont

SUFIJO = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
OUT = os.path.dirname(os.path.abspath(__file__))

def psql(sql):
    return ["psql", "-X", "-P", "pager=off", "-c", sql]

# Archivo -> lista de comandos (lista argv). Ajusta rutas si tu servidor difiere.
EVIDENCIAS = {
    "01-superficie-ataque": [
        psql("SELECT version();"), psql("SHOW port;"), psql("SHOW listen_addresses;"),
        psql("SHOW ssl;"), psql("SHOW password_encryption;"),
        psql("SELECT pid, usename, datname, client_addr, client_port, application_name FROM pg_stat_activity;"),
    ],
    "02-listen-addresses": [
        psql("SHOW listen_addresses;"),
        ["bash", "-c", "ss -lnt | grep -E 'State|5432'"],
    ],
    "03-pg-hba": [
        psql("SELECT line_number, type, database, user_name, address, netmask, auth_method FROM pg_hba_file_rules ORDER BY line_number;"),
    ],
    "04-roles": [
        psql("SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles WHERE rolname NOT LIKE 'pg\\_%' ORDER BY rolname;"),
    ],
    "05-tls": [
        psql("SHOW ssl;"), psql("SHOW ssl_min_protocol_version;"),
        psql("SELECT pid, usename, client_addr, ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"),
    ],
    "06-verificacion": [
        psql("SELECT name, setting, pending_restart FROM pg_settings WHERE name IN ('listen_addresses','ssl','ssl_min_protocol_version','password_encryption','log_connections','log_disconnections','idle_in_transaction_session_timeout','statement_timeout') ORDER BY name;"),
        psql("SELECT line_number, type, address, netmask, auth_method FROM pg_hba_file_rules WHERE (address IN ('0.0.0.0','::') AND netmask IN ('0.0.0.0','::')) OR auth_method IN ('trust','md5','password');"),
        psql("SELECT rolname FROM pg_roles WHERE rolsuper AND rolcanlogin;"),
        ["bash", "-c", "ss -lnt | grep -E 'State|5432'"],
        # Pruebas negativas: deben FALLAR si el hardening funciona
        ["bash", "-c", "IP=$(hostname -I | awk '{print $1}'); echo \"# Conexion desde IP no autorizada ($IP):\"; PGPASSWORD=x psql -X -h $IP -U app_user -d basedatos_app -c 'SELECT 1' 2>&1 | head -3"],
        ["bash", "-c", "echo '# app_user hacia otra BD (sin regla en pg_hba):'; PGSSLMODE=require PGPASSWORD=x psql -X -h 127.0.0.1 -U app_user -d postgres -c 'SELECT 1' 2>&1 | head -3"],
        ["bash", "-c", "echo '# cuenta heredada webapp (NOLOGIN):'; PGSSLMODE=require PGPASSWORD='WebApp#2026' psql -X -h 127.0.0.1 -U webapp -d basedatos_app -c 'SELECT 1' 2>&1 | head -3"],
        ["bash", "-c", "ls -l $(psql -X -At -c 'SHOW config_file;') $(psql -X -At -c 'SHOW hba_file;'); ls -ld $(psql -X -At -c 'SHOW data_directory;')"],
    ],
}

def fuente(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
              "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
              "/System/Library/Fonts/Menlo.ttc", "C:/Windows/Fonts/consola.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def ejecutar(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return (r.stdout + r.stderr).replace('\t', '    ').replace('\u2018',"'").replace('\u2019',"'").rstrip()

def renderizar(nombre, bloques):
    f = fuente(15)
    host = socket.gethostname()
    ahora = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lineas = [f"# {ahora}  host={host}  usuario_so={getpass.getuser()}", ""]
    for cmd, salida in bloques:
        txt = cmd[-1] if cmd[0] == "psql" else " ".join(cmd[2:] if cmd[0]=="bash" else cmd)
        prefijo = "postgres=# " if cmd[0] == "psql" else "$ "
        for i, l in enumerate(textwrap.wrap(txt, 120) or [""]):
            lineas.append((prefijo if i == 0 else "    ") + l)
        lineas += salida.splitlines() + [""]
    w = max(len(l) for l in lineas) * 9 + 40
    h = len(lineas) * 20 + 30
    img = Image.new("RGB", (max(w, 600), h), (24, 26, 31))
    d = ImageDraw.Draw(img)
    for i, l in enumerate(lineas):
        color = (130, 200, 130) if l.startswith(("postgres=#", "$")) else \
                (150, 150, 160) if l.startswith("#") else (225, 225, 225)
        d.text((20, 15 + i * 20), l, font=f, fill=color)
    ruta = os.path.join(OUT, f"{nombre}{SUFIJO}.png")
    img.save(ruta)
    print("OK ->", ruta)

if __name__ == "__main__":
    for nombre, cmds in EVIDENCIAS.items():
        renderizar(nombre, [(c, ejecutar(c)) for c in cmds])
