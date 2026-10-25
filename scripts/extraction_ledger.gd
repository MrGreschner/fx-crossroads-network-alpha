extends RefCounted
## Pending successful returns, acknowledged only after the authenticated server commits.
static func pending(l:Node)->Array:
 var s=l.community.state()
 if not s.has("extractions"):s.extractions=[]
 return s.extractions
static func record(l:Node,amount:int,route:String,run_id:String)->void:
 if amount<=0 or amount>1000000 or route not in ["solo","coop"] or not l.community.allowed():return
 if not preload("res://scripts/record_eligibility.gd").damage_allowed(l):return
 var id=(str(l.cosmetics.rankings.scores().profile)+":"+run_id).sha256_text()
 for event in pending(l):
  if event.id==id:return
 var hero=str(l.game.hero_ids.get(l.game.my_id,l.game.selected_hero)) if l.arcade else str(l.game.character_id)
 var entry={"id":id,"amount":amount,"route":route,"hero":hero}
 if route=="coop":entry.party=preload("res://scripts/named_records.gd").party(l)
 pending(l).append(entry)
static func batch(l:Node)->Array:return pending(l).slice(0,32)
static func acknowledge(l:Node,receipts:Variant,sent:Array)->void:
 if not receipts is Array or receipts.size()>32:return
 var allowed=[]
 for event in sent:allowed.append(str(event.id))
 var changed=false
 for i in range(pending(l).size()-1,-1,-1):
  var id=str(pending(l)[i].id)
  if id in receipts and id in allowed:pending(l).remove_at(i);changed=true
 if changed:
  l.save()
  if not pending(l).is_empty():l.community.delay=2
static func valid(events:Variant)->bool:
 if not events is Array or events.size()>20000:return false
 var ids={};var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 for event in events:
  if not event is Dictionary or event.size() not in [4,5] or not event.get("id") is String or event.id.length()!=64 or not event.id.is_valid_hex_number(false) or ids.has(event.id):return false
  if event.get("route") not in ["solo","coop"] or not preload("res://scripts/competitive_progress.gd").integer(event.get("amount"),1000000) or event.amount<1:return false
  if not preload("res://scripts/named_records.gd").record_hero_id(event.get("hero"),manifest.characters):return false
  if event.route=="coop":
   if not preload("res://scripts/named_records.gd").valid_hero_records({"between:all:coop":{"hero":event.hero,"value":event.amount,"party":event.get("party",[])}}) or event.get("party",[]).size()<2:return false
  ids[event.id]=true
 return true
