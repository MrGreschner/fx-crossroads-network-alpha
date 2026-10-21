extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const G=preload("res://scripts/garden_ui.gd")
static func build(parent:Node,l:Node,n:Dictionary,category:String)->void:
 if n.is_empty():return
 if category=="heroes":
  for e in [["ALL-TIME DAMAGE","damage_all","rank_all_damage"],["WEEKLY DAMAGE • VANGUARD COMETS","damage_week","rank_week_damage"]]:
   var card=UI.card(parent,e[0],"Top 10 connected accounts • Monday reset • top 5: Vanguard Comets" if e[1]=="damage_week" else "Top 10 connected accounts • top 5: Eternal Constellation")
   if e[1]=="damage_week" and not n.has("damage_week"):
    G.label(card,"Server update required • weekly damage is stored, but this older server cannot send the new board. Deploy the matching server ZIP.",16);continue
   preload("res://scripts/records_hall_ui.gd").damage_leaders(card,n.get(e[1],[]),e[2],"Server update needed" if not l.community.snapshot.is_empty() and not l.community.compatible(l.community.snapshot) else "No named record yet")
 if category=="times":
  G.label(parent,"REALM TIMES • SPEED RECORDS",23);G.label(parent,"Fastest recorded completion • hero shown when recorded with the run. Weekly results reset Monday.",15)
  for id in l.game.manifest.regions:
   var rows=[]
   for entry in [["All time","realm_times_all"],["This week","realm_times_week"]]:
    for row in n.get(entry[1],[]):
     if str(row.key)==str(id):rows.append({"title":entry[0],"record":row})
   if not rows.is_empty():
    var card=UI.card(parent,str(l.game.realms.get(id,{}).get("name",id)),"")
    for row in rows:preload("res://scripts/records_hall_ui.gd").run_row(card,l,row.record,row.title,clock(float(row.record.value)))
 if category=="streak":
  for e in [["LONGEST LIFE • ALL TIME","streak_all"],["LONGEST LIFE • THIS WEEK","streak_week"]]:
   var card=UI.card(parent,e[0],"Realms completed without a defeat • counted from v188 onward")
   list(card,n.get(e[1],[])," realm clears")
 if category=="between":
  for e in [["SOLO • TOP EXTRACTORS","between_solo"],["CO-OP • TOP EXTRACTORS","between_coop"]]:
   var card=UI.card(parent,e[0],"Successful solo extractions • raw shards before trial bonuses" if e[1]=="between_solo" else "Successful co-op extractions • shared haul listed for each participating account")
   var rows=n.get(e[1],[])
   if rows.is_empty():G.label(card,"No named extractions yet.",16)
   for i in rows.size():preload("res://scripts/records_hall_ui.gd").run_row(card,l,rows[i],str(i+1)+". Best extraction",String.num(float(rows[i].value),0)+" Waylight Shards")
 if category=="relic":
  var card=UI.card(parent,"RAREST RELIC FIND","Conclave finds, then overcharge tier, then natural roll quality. Upgrading a relic does not improve this record.")
  var row=n.get("relic")
  if not row is Dictionary:G.label(card,"No named relic finds yet.");return
  var c=preload("res://scripts/waylight_catalog.gd")
  if not c.RELICS.has(row.get("type")):return
  var art=preload("res://scripts/waylight_ui.gd").RelicIcon.new();art.type=row.type;art.custom_minimum_size=Vector2(110,110);card.add_child(art)
  G.label(card,str(c.RELICS[row.type].name),24);G.label(card,str(row.username)+" • Tier "+str(row.tier)+" • "+str(roundf(float(row.percentile)*100))+"% natural roll"+(" • Conclave-forged" if row.conclave else ""),19)
static func list(parent:Node,rows:Array,suffix:String)->void:
 if rows.is_empty():G.label(parent,"No named records yet. Sign in and play to take a place here.",16)
 var i=0
 for row in rows:
  i+=1;G.label(parent,str(i)+". "+str(row.username)+"   "+String.num(float(row.value),0)+suffix,20)
static func clock(value:float)->String:return "%d:%02d.%02d" % [int(value)/60,int(value)%60,int(value*100)%100]
