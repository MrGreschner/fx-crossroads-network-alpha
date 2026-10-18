from pathlib import Path
import json,re,sys
root=Path(__file__).resolve().parents[1];web=Path(sys.argv[1]).resolve()
config={'args':[],'canvasResizePolicy':2,'emscriptenPoolSize':8,'ensureCrossOriginIsolationHeaders':False,'executable':'index','experimentalVK':True,'fileSizes':{n:(web/n).stat().st_size for n in ['index.pck','index.wasm']},'focusCanvas':True,'gdextensionLibs':[],'godotPoolSize':4}
head=json.loads(re.search(r'^html/head_include=(.*)$',(root/'export_presets.cfg').read_text(),re.M).group(1))
s=(root/'web/town_shell.html').read_text().replace('$GODOT_HEAD_INCLUDE',head).replace('$GODOT_CONFIG',json.dumps(config,separators=(',',':')))
assert '$GODOT_' not in s
(web/'index.html').write_text(s)
