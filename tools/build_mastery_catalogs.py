"""Regenerate both mastery tables from the current numbered hero roster."""
from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]
m=json.loads((p/'content/manifest.json').read_text())['characters']
for filename,title,kind in [('MASTERY_CATALOG.md','Hero mastery catalogue','technique'),('FINAL_MASTERY_CATALOG.md','Final mastery ability catalogue','final_technique')]:
 f=p/filename;intro=f.read_text().split('\n\n')[1]
 text=f'# {title} — {len(m)} heroes\n\n'+intro+'\n\n| # | Hero | Master title | Changes | Technique | Behaviour and trade-off |\n|---|---|---|---|---|---|\n'
 for n,id in enumerate(m,1):
  h=json.loads((p/'content/characters'/f'{id}.json').read_text());ms=h.get('mastery',{});t=ms.get(kind,{})
  row=[n,h['name'],ms.get('title',''),t.get('ability',''),t.get('name',''),t.get('description','')]
  text+='| '+' | '.join(str(v).replace('|','/').replace('\n',' ') for v in row)+' |\n'
 f.write_text(text)
