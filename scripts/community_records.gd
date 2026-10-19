extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const FISH=preload("res://scripts/fishing_catalog.gd")
const ENTRY=Vector2(1035,600)
const WALL=Rect2(973,430,124,134)
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
 read_request=HTTPRequest.new();read_request.timeout=8;read_request.body_size_limit=32768;legacy.add_child(read_request);read_request.request_completed.connect(received)
func state()->Dictionary:
 if not legacy.data.has("community_records"):legacy.data.community_records={"version":1,"solo":0,"coop":0}
 return legacy.data.community_records
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()!=3 or v.get("version")!=1:return false
 for key in ["solo","coop"]:
  if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or float(v[key])<0 or float(v[key])>1000000 or float(v[key])!=floor(float(v[key])):return false
 return true
func allowed()->bool:return not bool(legacy.data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").progression_blocked() and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func record_between(amount:int,route:String)->void:
 if not allowed() or route not in ["solo","coop"]:return
 state()[route]=maxi(int(state()[route]),clampi(amount,0,1000000));delay=1
func payload()->Dictionary:
 var scores=legacy.cosmetics.rankings.scores();var hero_damage={};var realm_clears={}
 for id in legacy.data.heroes:
  if id in legacy.game.manifest.characters:hero_damage[id]=minf(1e12,float(legacy.data.heroes[id].get("damage",0)))
 for id in legacy.data.realm_counts:
  if id in legacy.game.manifest.regions:realm_clears[id]=mini(1000000,int(legacy.data.realm_counts[id]))
 var best={"species":"","kg":0.0}
 for id in legacy.fishing_records.state().journal:
  var weight=float(legacy.fishing_records.state().journal[id].get("kg",0))
  if weight>float(best.kg):best={"species":id,"kg":weight}
 return {"version":1,"profile":scores.profile,"hero_damage":hero_damage,"realm_clears":realm_clears,"fish_all":best,"week":scores.week,"fish_week":{"species":scores.fish_species,"kg":scores.fish},"between":{"solo":int(state().solo),"coop":int(state().coop)}}
func step(delta:float)->void:
 if not allowed() or endpoint.is_empty() or not legacy.get_tree().root.get_node("FXActivity").enabled:return
 delay-=delta;read_delay=maxf(0,read_delay-delta)
 if delay<=0 and not busy:
  delay=120+randf()*15;busy=sync_request.request(endpoint+"/community/sync",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(payload()))==OK
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
  status="Community records unavailable • deploy the v184 server, then try again";redraw();return
 for key in ["heroes","realms","between"]:
  if not parsed.get(key) is Array or parsed[key].size()>5:status="Invalid community response";return
 for key in ["fish_all","fish_week"]:
  var f=parsed.get(key)
  if f!=null and (not f is Dictionary or not FISH.fish().has(f.get("species")) or not (f.get("kg") is float or f.get("kg") is int) or not is_finite(float(f.kg)) or float(f.kg)<=0 or float(f.kg)>10000):status="Invalid fish response";return
 snapshot=parsed;status="Connected community • weekly records reset Mondays (Edmonton time)";redraw()
func redraw()->void:
 if legacy.page=="community" and legacy.game.menu=="legacy":legacy.render()
func build(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd")
 gui.label(parent,"COMMUNITY RECORDS",22);gui.label(parent,status,15)
 var tabs=HFlowContainer.new();parent.add_child(tabs)
 for entry in [["Hero damage","heroes"],["Biggest fish","fish"],["Realm clears","realms"],["Between runs","between"]]:
  var tab=gui.button(tabs,entry[0],func():category=entry[1];redraw());tab.toggle_mode=true;tab.set_pressed_no_signal(category==entry[1]);tab.custom_minimum_size.x=190
 var refresh=gui.button(tabs,"Refresh",func():read_delay=0;fetch());refresh.disabled=reading
 gui.label(parent,"All connected players • anonymous community play records",14).tooltip_text="Combined portable-profile high-water records. Repeat uploads do not add totals again. Co-op clears count per profile. These are client-reported, not verified competition scores."
 if snapshot.is_empty():preload("res://scripts/garden_ui.gd").label(parent,"No community data loaded yet. An internet connection and the v184 server update are needed.",19);return
 for entry in [["TOP 5 HEROES • CUMULATIVE DAMAGE","heroes"],["TOP 5 REALMS • RECORDED CLEARS","realms"]]:
  if category!=entry[1]:continue
  var card=UI.card(parent,entry[0],"Across connected profiles, all time")
  if snapshot.get(entry[1],[]).is_empty():preload("res://scripts/garden_ui.gd").label(card,"No records submitted yet.")
  var n=0
  for row in snapshot.get(entry[1],[]):
   n+=1;var id=str(row.get("id",""));var data=legacy.game.characters.get(id,{}) if entry[1]=="heroes" else legacy.game.realms.get(id,{})
   if not (row.get("value") is float or row.get("value") is int) or not is_finite(float(row.value)):continue
   var line=HBoxContainer.new();card.add_child(line)
   if entry[1]=="heroes":
    var art=TextureRect.new();var sprite=str(data.get("sprite",id));art.texture=legacy.game.art.get(sprite+"_idle",legacy.game.art.get(sprite+"_0"));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(44,48);line.add_child(art)
   preload("res://scripts/garden_ui.gd").label(line,"%d. %s    %s" % [n,str(data.get("name",id)),String.num(float(row.value),0)],20)
 if category in ["heroes","realms"]:return
 var fish_row=HFlowContainer.new();parent.add_child(fish_row)
 for entry in [["BIGGEST FISH • ALL TIME","fish_all"],["BIGGEST FISH • THIS WEEK","fish_week"]]:
  if category!="fish":continue
  var card=UI.card(fish_row,entry[0],"");card.get_parent().custom_minimum_size.x=425;var f=snapshot.get(entry[1])
  if f==null:preload("res://scripts/garden_ui.gd").label(card,"No fish record submitted yet.");continue
  var art=TextureRect.new();art.texture=FISH.texture(str(f.species));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(300,110);card.add_child(art)
  preload("res://scripts/garden_ui.gd").label(card,str(FISH.fish()[f.species].name)+" • %.2f kg" % float(f.kg),22)
 if category!="between":return
 var expeditions=UI.card(parent,"THE BETWEEN • SINGLE-RUN SHARD RECORDS","Successful extractions only • raw carried shards, before trial bonus")
 for route in ["solo","coop"]:
  var value=0
  for row in snapshot.get("between",[]):
   if row.get("id")==route:value=int(row.get("value",0))
  preload("res://scripts/garden_ui.gd").label(expeditions,("Solo" if route=="solo" else "Co-op")+" • "+(str(value)+" Waylight Shards" if value>0 else "No successful extraction recorded yet"),20)
static func blocked(point:Vector2)->bool:return WALL.grow(3).has_point(point)
static func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>=75:return false
 g.hint="E • Community records"
 if Input.is_action_just_pressed("interact"):g.legacy.community.open()
 return true
static func draw_on(g:Node2D,camera:Vector2)->void:
 var center=Vector2(1035,560)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(200).has_point(center):return
 g.draw_rect(Rect2(center+Vector2(-67,3),Vector2(134,14)),Color("#69746c"))
 for side in [-1,1]:g.draw_rect(Rect2(center+Vector2(side*58-4,-126),Vector2(8,142)),Color("#8f7851"))
 g.draw_style_box(UI.box("#223f48","#d6bd80",7,3),Rect2(center-Vector2(61,132),Vector2(122,129)))
 g.draw_colored_polygon(PackedVector2Array([center+Vector2(-76,-132),center+Vector2(0,-163),center+Vector2(76,-132)]),Color("#436779"));g.draw_line(center+Vector2(-76,-132),center+Vector2(0,-163),Color("#b7c9b4"),3)
 g.draw_string(g.font,center+Vector2(-55,-109),"COMMUNITY",HORIZONTAL_ALIGNMENT_CENTER,110,13,Color("#f2d799"));g.draw_string(g.font,center+Vector2(-52,-92),"RECORDS",HORIZONTAL_ALIGNMENT_CENTER,104,13,Color("#f2d799"))
 for n in 3:
  var at=center+Vector2(-39+n*38,-52);g.draw_rect(Rect2(at+Vector2(-8,-n*7),Vector2(16,23+n*7)),Color("#81b7b1") if n!=1 else Color("#d9b773"))
 g.draw_string(g.font,center+Vector2(-51,-9),"HEROES • FISH",HORIZONTAL_ALIGNMENT_CENTER,102,10,Color("#c4d7cf"))
