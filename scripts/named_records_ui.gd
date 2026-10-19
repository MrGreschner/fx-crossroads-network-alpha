extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const G=preload("res://scripts/garden_ui.gd")
static func build(parent:Node,l:Node,n:Dictionary,category:String)->void:
 if n.is_empty():return
 if category=="heroes":
  for e in [["FIVE STARS • ALL-TIME DAMAGE","damage_all"],["CROWN CHASE • ROLLING SEVEN DAYS","damage_rolling"]]:
   var card=UI.card(parent,e[0],"Named cloud accounts • current rolling window matches damage crowns" if e[1]=="damage_rolling" else "Top five connected accounts")
   list(card,n.get(e[1],[])," damage")
 if category=="times":
  G.label(parent,"REALM SPEED RECORDS",23);G.label(parent,"Each realm’s fastest recorded completion. Co-op clears count for each participant. Weekly runs reset Monday; damage above uses a rolling seven-day window.",15)
  for id in l.game.manifest.regions:
   var rows=[]
   for entry in [["All time","realm_times_all"],["This week","realm_times_week"]]:
    for row in n.get(entry[1],[]):
     if str(row.key)==str(id):rows.append(entry[0]+" • "+str(row.username)+" • "+clock(float(row.value)))
   if not rows.is_empty():
    var card=UI.card(parent,str(l.game.realms.get(id,{}).get("name",id)),"")
    for row in rows:G.label(card,row,18)
 if category=="streak":
  for e in [["LONGEST LIFE • ALL TIME","streak_all"],["LONGEST LIFE • THIS WEEK","streak_week"]]:
   var card=UI.card(parent,e[0],"Realms completed without a defeat • counted from v188 onward")
   list(card,n.get(e[1],[])," realm clears")
 if category=="between":
  for e in [["SOLO • TOP EXTRACTORS","between_solo"],["CO-OP • TOP EXTRACTORS","between_coop"]]:
   var card=UI.card(parent,e[0],"Successful single-run extractions • shared co-op haul is listed for each participating account")
   list(card,n.get(e[1],[])," Waylight Shards")
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
