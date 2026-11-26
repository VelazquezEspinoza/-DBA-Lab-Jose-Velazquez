# E6 — Evidencias de MongoDB (copiadas del LAB-02)

`scripts/generar-evidencias.sh` copia aquí, desde `../LAB-02/evidencias/`:

- `system-profile.json`
- `bitacora-mongod.log`
- sus archivos `.sha256` (y verifica que los hashes sigan coincidiendo)
- `09-comparacion.md` (comparación de la Actividad 9)

Si tu LAB-02 está en otra ruta: `LAB02=/ruta/al/LAB-02 bash scripts/generar-evidencias.sh`.
Si los copias a mano, conserva la fecha original (`cp -p`) y verifica con `sha256sum -c *.sha256`.
