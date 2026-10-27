"""Technical atlas registration only: translate existing art; no painted pixels or resampling.
All four poses receive padding and the renderer compensates exactly for the canvas.
"""
from pathlib import Path
from PIL import Image
import numpy as np,json,shutil,re
r=Path(__file__).resolve().parents[1];base=r
settings=json.loads((r/'tools/enemy_walk_registration229.json').read_text());registration=settings['registration'];out=r/'assets/enemy229';out.mkdir(exist_ok=True);stage=Path('/tmp/cr229/import');(stage/'assets').mkdir(parents=True,exist_ok=True)
(stage/'project.godot').write_text('config_version=5\n[application]\nconfig/name="V229 atlas import"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
manifest={}
for h,data in registration.items():
 offsets=[[0,0]]+[p[:2] for p in data['offsets']]+[[0,0]]
 # The old two-column source crop used cell centres. On these two sheets,
 # the centre gutter was 12/17 px away from the anatomical centre.
 centre=(-6,0) if h=='imp' else (-3,0) if h=='warlock' else (0,0)
 if h=='imp':offsets[3]=[12,0]
 if h=='warlock':offsets[3]=[16,0]
 outputs=[]
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  version=220 if h in json.loads((base/'assets/enemy220/manifest220.json').read_text()) else 227 if h in json.loads((base/'assets/enemy227/manifest227.json').read_text()) else 228
  source=Image.open(base/f'assets/enemy{version}/{h}_{n:02}.png').convert('RGBA');dx=8+centre[0]+offsets[n][0];dy=15+centre[1]+offsets[n][1]
  dest=Image.new('RGBA',(80,80));dest.alpha_composite(source,(dx,dy))
  # No crop, no blur, no generated artwork: preserve all existing opaque pixels.
  assert np.count_nonzero(np.array(source)[:,:,3])==np.count_nonzero(np.array(dest)[:,:,3]),(h,n,'clipped')
  target=out/f'{h}_{n:02}.png';dest.save(target);outputs.append(target)
 for alias,n in {'idle':0,'0':0,'1':1,'2':2,'walk1':1,'walk2':2,'attack':3,'attack2':3,'special':3}.items():
  target=r/f'assets/{h}_{alias}.png';shutil.copy2(outputs[n],target);shutil.copy2(target,stage/'assets'/target.name)
  meta=Path(str(target)+'.import')
  if meta.exists():shutil.copy2(meta,stage/'assets'/meta.name)
 target=r/f'assets/{h}.png';shutil.copy2(outputs[0],target);shutil.copy2(target,stage/'assets'/target.name)
 if Path(str(target)+'.import').exists():shutil.copy2(str(target)+'.import',stage/'assets'/ (target.name+'.import'))
 manifest[h]={'canvas':[80,80],'padding':[8,15],'centre':list(centre),'walk_translation':offsets[1:3],'attack_translation':offsets[3],'visible_size_multiplier':1.2 if h=='warlock' else 1.0,'reference_region':data['region']}
(out/'manifest229.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Compensate new padding around the SAME body pixels (64/80): no size drift.
p=r/'scripts/enemy_visual227.gd';s=p.read_text();m=re.search(r'const FACTORS=(\{.*\})',s);factors=settings['original_factors'].copy()
for h in manifest:factors[h]=round(float(factors.get(h,1))*1.25*(1.2 if h=='warlock' else 1),7)
s=s[:m.start(1)]+json.dumps(factors,separators=(',',':'))+s[m.end(1):];p.write_text(s)
print('Registered',len(manifest),'creatures /',len(manifest)*4,'poses. All opaque pixels preserved. Warlock +20% only.')
