"""Extract the V343 native authority pack from the matching web release."""
import hashlib,json,sys,zipfile
from pathlib import Path
with zipfile.ZipFile(sys.argv[1]) as z:
 m=json.loads(z.read('pack/manifest.json'));digest=hashlib.sha256()
 dest=Path(sys.argv[2]);temp=dest.with_suffix('.partial')
 try:
  with temp.open('wb') as out:
   for part in m['parts']:
    blob=z.read('pack/'+part['file'])
    assert hashlib.sha256(blob).hexdigest()==part['sha256']
    out.write(blob);digest.update(blob)
  assert digest.hexdigest()==m['sha256'] and temp.stat().st_size==m['size']
  temp.replace(dest)
 finally:temp.unlink(missing_ok=True)
