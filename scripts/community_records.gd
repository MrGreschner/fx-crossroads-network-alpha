extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const FISH=preload("res://scripts/fishing_catalog.gd")
const ENTRY=Vector2(1035,600)
const WALL=Rect2(957,403,156,192)
var legacy:Node
var sync_request:HTTPRequest
var read_request:HTTPRequest
var snapshot:Dictionary={}
var category="heroes"
var status="Connect to see community records"
var delay:float=8
var read_delay:float=0
var busy=false
var reading=false
var endpoint=""
func setup(owner:Node)->void:
 legacy=owner;state();endpoint=preload("res://scripts/brand.gd").insights_http().trim_suffix("/")
 sync_request=HTTPRequest.new();sync_request.timeout=8;sync_request.body_size_limit=4096;legacy.add_child(sync_request);sync_request.request_completed.connect(synced)
 read_request=HTTPRequest.new();read_request.timeout=8;read_request.body_size_limit=131072;legacy.add_child(read_request);read_request.request_completed.connect(received)
func state()->Dictionary:
 if not legacy.data.has("community_records"):legacy.data.community_records={"version":1,"solo":0,"coop":0}
 return legacy.data.community_records
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()>4 or v.get("version")!=1:return false
 for key in ["solo","coop"]:
  if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or float(v[key])<0 or float(v[key])>1000000 or float(v[key])!=floor(float(v[key])):return false
 if v.has("rare_week"):
  var r=v.rare_week
  if not r is Dictionary or not r.get("week") is String or r.week.length()!=10 or not FISH.fish().has(r.get("species")) or not (r.get("kg") is int or r.get("kg") is float) or not is_finite(float(r.kg)) or float(r.kg)<=0 or float(r.kg)>float(FISH.fish()[r.species].max_kg)*4+.01:return false
 return true
func allowed()->bool:return not bool(legacy.data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").progression_blocked() and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func record_between(amount:int,route:String)->void:
 if not allowed() or route not in ["solo","coop"]:return
 state()[route]=maxi(int(state()[route]),clampi(amount,0,1000000));delay=1
static func rarer(a:Dictionary,b:Dictionary)->bool:
 if a.is_empty() or not FISH.fish().has(a.get("species")):return false
 if b.is_empty() or not FISH.fish().has(b.get("species")):return true
 var grades=["Common","Uncommon","Rare","Very rare","Legendary","Mystical"];var fa=FISH.fish()[a.species];var fb=FISH.fish()[b.species];var ga=grades.find(fa.rarity);var gb=grades.find(fb.rarity)
 if ga!=gb:return ga>gb
 if float(fa.chance)!=float(fb.chance):return float(fa.chance)<float(fb.chance)
 if a.species!=b.species:return str(a.species)<str(b.species)
 return float(a.kg)>float(b.kg)
func note_fish(catch:Dictionary)->void:
 if not allowed():return
 var week=legacy.cosmetics.rankings.week();var r:Dictionary=state().get("rare_week",{})
 if r.get("week","")!=week or rarer(catch,r):state().rare_week={"week":week,"species":catch.species,"kg":catch.kg};delay=1
func payload()->Dictionary:
 var scores=legacy.cosmetics.rankings.scores();var hero_damage={};var realm_clears={};var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 for id in legacy.data.heroes:
  if id in manifest.characters:hero_damage[id]=minf(1e12,float(legacy.data.heroes[id].get("damage",0)))
 for id in legacy.data.realm_counts:
  if id in manifest.regions:realm_clears[id]=mini(1000000,int(legacy.data.realm_counts[id]))
 var best={"species":"","kg":0.0};var rare={};var trophies=[]
 for id in legacy.fishing_records.state().journal:
  var weight=float(legacy.fishing_records.state().journal[id].get("kg",0))
  var entry={"species":id,"kg":weight}
  if FISH.is_trophy(entry):trophies.append(entry)
  if weight>0 and rarer(entry,rare):rare=entry
  if weight>float(best.kg):best={"species":id,"kg":weight}
 return {"trophies":trophies,"named":preload("res://scripts/named_records.gd").payload(legacy),"rarest_all":rare,"rarest_week":state().get("rare_week",{}) if state().get("rare_week",{}).get("week","")==scores.week else {},"garden_records":legacy.gardening.fair.payload(),"version":1,"profile":scores.profile,"hero_damage":hero_damage,"realm_clears":realm_clears,"fish_all":best,"week":scores.week,"fish_week":{"species":scores.fish_species,"kg":scores.fish},"between":{"solo":int(state().solo),"coop":int(state().coop)}}
func step(delta:float)->void:
 if not allowed() or endpoint.is_empty() or not legacy.get_tree().root.get_node("FXActivity").enabled:return
 delay-=delta;read_delay=maxf(0,read_delay-delta)
 if delay<=0 and not busy:
  delay=120+randf()*15;busy=sync_request.request(endpoint+"/community/sync",legacy.get_node("/root/FXAccount").record_headers(),HTTPClient.METHOD_POST,JSON.stringify(payload()))==OK
  if not busy:delay=30
func synced(result:int,code:int,_headers:PackedStringArray,_body:PackedByteArray)->void:
 busy=false
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200:delay=45
func open()->void:legacy.open_page("community");fetch()
func fetch()->void:
 if reading or endpoint.is_empty() or read_delay>0:return
 status="Loading community records…";reading=read_request.request(endpoint+"/community/records")==OK;read_delay=30
 if not reading:status="Community records unavailable • try again when connected"
func received(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 reading=false
 var parsed=JSON.parse_string(body.get_string_from_utf8())
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or not parsed is Dictionary or parsed.get("version")!=1:
  status="Community records unavailable • deploy the matching server, then try again";redraw();return
 for key in ["heroes","realms","between"]:
  if not parsed.get(key) is Array or parsed[key].size()>5:status="Invalid community response";return
 for key in ["fish_all","fish_week","rarest_all","rarest_week"]:
  var f=parsed.get(key)
  if f!=null and (not f is Dictionary or not FISH.fish().has(f.get("species")) or not (f.get("kg") is float or f.get("kg") is int) or not is_finite(float(f.kg)) or float(f.kg)<=0 or float(f.kg)>10000):status="Invalid fish response";return
 for key in ["garden_all","garden_month"]:
  if not parsed.get(key,[]) is Array or parsed.get(key,[]).size()>12:status="Invalid garden response";return
  for row in parsed.get(key,[]):
   if not row is Dictionary or not preload("res://scripts/giant_garden.gd").record_valid(row,"all"):status="Invalid crop response";return
 snapshot=parsed;status="Connected community • weekly records reset Mondays (Edmonton time)";redraw()
func redraw()->void:
 if legacy.page=="community" and legacy.game.menu=="legacy":legacy.render()
func build(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd")
 gui.label(parent,"COMMUNITY RECORDS",22);gui.label(parent,status,15)
 var tabs=HFlowContainer.new();parent.add_child(tabs)
 for entry in [["Hero damage","heroes"],["Fishing records","fish"],["Realm records","realms"],["Between runs","between"],["Garden fair","garden"],["Life streaks","streak"],["Relic finds","relic"]]:
  var tab=gui.button(tabs,entry[0],func():category=entry[1];redraw());tab.toggle_mode=true;tab.set_pressed_no_signal(category==entry[1]);tab.custom_minimum_size.x=160
 var refresh=gui.button(tabs,"Refresh",func():read_delay=0;fetch());refresh.disabled=reading
 gui.label(parent,"Community play records • public game names for cloud accounts",14).tooltip_text="Combined portable-profile high-water records. Repeat uploads do not add totals again. Co-op clears count per profile. These are client-reported, not verified competition scores."
 if snapshot.is_empty():preload("res://scripts/garden_ui.gd").label(parent,"No community data loaded yet. An internet connection and the matching server update are needed.",19);return
 var clears_parent:Node=parent
 var times_parent:Node=parent
 if category=="realms":
  var columns=HBoxContainer.new();columns.name="RealmRecordsColumns";columns.add_theme_constant_override("separation",16);parent.add_child(columns)
  for n in 2:
   var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_stretch_ratio=1;columns.add_child(column)
   if n==0:clears_parent=column
   else:times_parent=column
 for entry in [["TOP 5 HEROES • CUMULATIVE DAMAGE","heroes"],["TOP 5 REALMS • RECORDED CLEARS","realms"]]:
  if category!=entry[1]:continue
  var card=UI.card(clears_parent,entry[0],"Across connected profiles, all time")
  if snapshot.get(entry[1],[]).is_empty():preload("res://scripts/garden_ui.gd").label(card,"No records submitted yet.")
  var n=0
  for row in snapshot.get(entry[1],[]):
   n+=1;var id=str(row.get("id",""));var data=legacy.game.characters.get(id,{}) if entry[1]=="heroes" else legacy.game.realms.get(id,{})
   if not (row.get("value") is float or row.get("value") is int) or not is_finite(float(row.value)):continue
   var line=HBoxContainer.new();card.add_child(line)
   if entry[1]=="heroes":
    var art=TextureRect.new();var sprite=str(data.get("sprite",id));art.texture=legacy.game.art.get(sprite+"_idle",legacy.game.art.get(sprite+"_0"));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(44,48);line.add_child(art)
   preload("res://scripts/garden_ui.gd").label(line,"%d. %s    %s" % [n,str(data.get("name",id)),String.num(float(row.value),0)],20)
 preload("res://scripts/named_records_ui.gd").build(times_parent if category=="realms" else parent,legacy,snapshot.get("named",{}),"times" if category=="realms" else category)
 if category in ["heroes","realms","times","streak","relic"]:return
 if category=="garden":garden_records(parent);return
 var fish_row=HFlowContainer.new();parent.add_child(fish_row)
 for entry in [["BIGGEST FISH • ALL TIME","fish_all"],["BIGGEST FISH • THIS WEEK","fish_week"],["RAREST FISH • ALL TIME","rarest_all"],["RAREST FISH • THIS WEEK","rarest_week"]]:
  if category!="fish":continue
  var card=UI.card(fish_row,entry[0],"");card.get_parent().custom_minimum_size.x=425;var f=snapshot.get(entry[1]);var named=snapshot.get("named",{}).get(entry[1])
  if named is Dictionary and (f==null or (rarer(named,f) if str(entry[1]).begins_with("rarest") else float(named.kg)>=float(f.kg))):f=named
  if f==null:preload("res://scripts/garden_ui.gd").label(card,"No fish record submitted yet.");continue
  var art=TextureRect.new();art.texture=FISH.texture(str(f.species));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(300,110);card.add_child(art)
  preload("res://scripts/garden_ui.gd").label(card,str(FISH.fish()[f.species].name)+" • %.2f kg" % float(f.kg),22)
  gui.label(card,str(f.get("username","Earlier anonymous record")),18)
 if category=="fish":species_records(parent)
 if category=="fish":gui.label(parent,"Rarest: species rarity first, then its base catalogue catch weight. Fish weight breaks ties within a species. Weekly records reset Monday.",15)
 if category!="between":return
 var expeditions=UI.card(parent,"THE BETWEEN • SINGLE-RUN SHARD RECORDS","Successful extractions only • raw carried shards, before trial bonus")
 for route in ["solo","coop"]:
  var value=0
  for row in snapshot.get("between",[]):
   if row.get("id")==route:value=int(row.get("value",0))
  preload("res://scripts/garden_ui.gd").label(expeditions,("Solo" if route=="solo" else "Co-op")+" • "+(str(value)+" Waylight Shards" if value>0 else "No successful extraction recorded yet"),20)
func species_records(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd")
 var card=UI.card(parent,"SPECIES TROPHY HOLDERS • ALL TIME","Heaviest trophy of each species • discovered through connected cloud catches. Equal weights keep a stable holder.")
 var rows=snapshot.get("named",{}).get("species_trophies",[])
 if rows.is_empty():gui.label(card,"No species trophies recorded yet. Catch a trophy while using a cloud profile to reveal one.",17)
 for f in rows:
  if not f is Dictionary or not FISH.fish().has(str(f.get("species",""))) or not FISH.is_trophy(f):continue
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);card.add_child(row)
  var art=TextureRect.new();art.texture=FISH.texture(str(f.species));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(90,50);row.add_child(art)
  var name=gui.label(row,str(FISH.fish()[f.species].name),18);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  gui.label(row,"★ %.2f kg   •   %s" % [float(f.kg),str(f.get("username",""))],18)
func garden_records(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd");var id=legacy.gardening.fair.crop();var spec=legacy.gardening.crops()[id]
 gui.label(parent,"GIANT GROWERS FAIR • "+str(spec.name),22);gui.label(parent,"Monthly records follow the planting month; seven real days of growth. Cloud account usernames appear on new records; weights are client-reported.",15)
 var row=HFlowContainer.new();parent.add_child(row)
 for entry in [["THIS MONTH","garden_month"],["ALL-TIME BEST","garden_all"]]:
  var card=UI.card(row,entry[0],str(spec.name));card.get_parent().custom_minimum_size.x=425;gui.icon(card,id,3,Vector2(220,140));var kg=0.0;var grower=""
  for r in snapshot.get(entry[1],[]):
   if r.get("crop")==id:kg=maxf(kg,float(r.get("kg",0)))
  for r in snapshot.get("named",{}).get("garden",[]):
   if r.get("crop")==id and r.get("scope")==("all" if entry[1]=="garden_all" else snapshot.get("month","")) and float(r.kg)>=kg:grower=str(r.username);kg=float(r.kg)
  gui.label(card,"%.3f kg" % kg if kg>0 else "No harvest submitted yet",22)
  if not grower.is_empty():gui.label(card,grower,18)
 var archive=UI.card(parent,"YEAR-ROUND ALL-TIME RECORDS","")
 for r in snapshot.get("garden_all",[]):
  if not legacy.gardening.crops().has(r.get("crop")):continue
  var name=""
  for nr in snapshot.get("named",{}).get("garden",[]):
   if nr.crop==r.crop and nr.scope=="all" and float(nr.kg)>=float(r.kg):name=" • "+str(nr.username)
  gui.label(archive,str(legacy.gardening.crops()[r.crop].name)+" • %.3f kg" % float(r.kg)+name,17)
static func blocked(point:Vector2)->bool:return WALL.grow(3).has_point(point)
static func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>=75:return false
 g.hint="E • Community records"
 if Input.is_action_just_pressed("interact"):g.legacy.community.open()
 return true
static func draw_on(g:Node2D,camera:Vector2)->void:
 var c=Vector2(1035,560)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(200).has_point(c):return
 g.draw_rect(Rect2(c+Vector2(-68,1),Vector2(136,12)),Color("#74776a"))
 for side in [-1,1]:
  g.draw_rect(Rect2(c+Vector2(side*58-5,-128),Vector2(10,140)),Color("#755b40"));g.draw_line(c+Vector2(side*58-2,2),c+Vector2(side*58-2,-125),Color("#b29a70"),2)
 g.draw_rect(Rect2(c-Vector2(63,131),Vector2(126,114)),Color("#70553c"))
 for n in 7:
  var y=-126+n*15;g.draw_rect(Rect2(c+Vector2(-59,y),Vector2(118,13)),Color("#a08559") if n%2 else Color("#93774f"));g.draw_line(c+Vector2(-53,y+6),c+Vector2(49,y+7),Color("#776044"),1)
 for n in 3:
  var at=c+Vector2(-49+n*34,-110+(n%2)*6);g.draw_rect(Rect2(at,Vector2(28,65)),Color("#d9cba4"));g.draw_circle(at+Vector2(14,4),2,Color("#647e77"))
  for j in 4:g.draw_line(at+Vector2(5,23+j*7),at+Vector2(23-j%2*5,23+j*7),Color("#9e9476"),1)
 g.draw_colored_polygon(PackedVector2Array([c+Vector2(-77,-130),c+Vector2(0,-157),c+Vector2(77,-130)]),Color("#65766b"));g.draw_line(c+Vector2(-76,-130),c+Vector2(0,-158),Color("#b3b49a"),3)
 g.draw_rect(Rect2(c+Vector2(-76,-17),Vector2(152,23)),Color("#67533b"));g.draw_string(g.font,c+Vector2(-70,-1),"COMMUNITY RECORDS",HORIZONTAL_ALIGNMENT_CENTER,140,11,Color("#ede0b6"))
