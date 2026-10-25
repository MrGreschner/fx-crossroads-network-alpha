extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const FISH=preload("res://scripts/fishing_catalog.gd")
const ENTRY=Vector2(1035,600)
const WALL=Rect2(957,403,156,192)
# Aggregate realm popularity is a top-ten list too; named speed boards are separate.
const SUMMARY_LIMITS={"heroes":10,"realms":10,"between":5}
var legacy:Node
var sync_request:HTTPRequest
var read_request:HTTPRequest
var snapshot:Dictionary={}
var rendered_signature=""
var view_body:Node
var navigation_status:Label
var refresh_button:Button
var body_status:Label
var content_updates=0
var category="heroes"
var status="Connect to see community records"
var delay:float=8
var read_delay:float=0
var busy=false
var reading=false
var endpoint=""
var sync_status=""
var claims:Array=[]
var sent_claims:Array=[]
var sent_extractions:Array=[]
var refresh_after_sync=false
var pending_sync=false
var manual_cooldown=0.0
var last_identity=""
var last_mode=""
var generation=0
var reading_generation=0
var synced_identity=""
var board_refresh=0.0
var stale=false
var last_refresh=""
func compatible(data:Dictionary)->bool:
 var limits=data.get("limits",{});var named=data.get("named",{})
 return int(data.get("record_policy",0))>=3 and named is Dictionary and named.get("damage_week") is Array and limits is Dictionary and int(limits.get("heroes",0))>=10 and int(limits.get("damage",0))>=10 and int(limits.get("fish",0))>=10 and int(limits.get("descent",0))>=10 and data.get("fish_boards") is Dictionary
func board_notice()->String:
 if not snapshot.is_empty() and not compatible(snapshot):return "SERVER UPDATE REQUIRED • Render is still sending older record lists. Deploy the matching server ZIP; your saved records are safe."
 if stale:return "RECORDS UNAVAILABLE • Retrying automatically." if snapshot.is_empty() else "RECORDS UNAVAILABLE • Showing the last loaded records. Retrying automatically."
 if reading:return "Refreshing community records…"
 return "Updated "+last_refresh+" • refreshes every 30 seconds" if not last_refresh.is_empty() else status
func setup(owner:Node)->void:
 legacy=owner;state();endpoint=preload("res://scripts/brand.gd").insights_http().trim_suffix("/")
 sync_request=HTTPRequest.new();sync_request.timeout=8;sync_request.body_size_limit=16384;legacy.add_child(sync_request);sync_request.request_completed.connect(synced)
 read_request=HTTPRequest.new();read_request.timeout=8;read_request.body_size_limit=524288;legacy.add_child(read_request);read_request.request_completed.connect(received)
func state()->Dictionary:
 if not legacy.data.has("community_records"):legacy.data.community_records={"version":1,"solo":0,"coop":0}
 return legacy.data.community_records
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()>5 or v.get("version")!=1:return false
 if v.has("extractions") and not preload("res://scripts/extraction_ledger.gd").valid(v.extractions):return false
 for key in ["solo","coop"]:
  if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or float(v[key])<0 or float(v[key])>1000000 or float(v[key])!=floor(float(v[key])):return false
 if v.has("rare_week"):
  var r=v.rare_week
  if not r is Dictionary or not r.get("week") is String or r.week.length()!=10 or not FISH.fish().has(r.get("species")) or not (r.get("kg") is int or r.get("kg") is float) or not is_finite(float(r.kg)) or float(r.kg)<=0 or float(r.kg)>float(FISH.fish()[r.species].max_kg)*4+.01:return false
 return true
func allowed()->bool:return not bool(legacy.data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").progression_blocked() and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func record_between(amount:int,route:String,run_id:String="")->void:
 if not allowed() or route not in ["solo","coop"]:return
 if not run_id.is_empty():preload("res://scripts/extraction_ledger.gd").record(legacy,amount,route,run_id)
 var previous=int(state()[route]);var best=clampi(amount,0,1000000)
 if best>previous or best==previous and best>0:
  preload("res://scripts/named_records.gd").remember_hero(legacy,"between","all",route,best,best>previous)
 state()[route]=maxi(previous,best);delay=1
static func rarer(a:Dictionary,b:Dictionary)->bool:
 if a.is_empty() or not FISH.fish().has(a.get("species")):return false
 if b.is_empty() or not FISH.fish().has(b.get("species")):return true
 var grades=["Common","Uncommon","Rare","Very rare","Legendary","Mystical","Fabled"];var fa=FISH.fish()[a.species];var fb=FISH.fish()[b.species];var ga=grades.find(fa.rarity);var gb=grades.find(fb.rarity)
 if ga!=gb:return ga>gb
 if float(fa.chance)!=float(fb.chance):return float(fa.chance)<float(fb.chance)
 if a.species!=b.species:return str(a.species)<str(b.species)
 return float(a.kg)>float(b.kg)
func note_fish(catch:Dictionary)->void:
 if not allowed():return
 claims.append({"kind":"fish","species":catch.species,"kg":catch.kg})
 if claims.size()>12:claims.pop_front()
 var week=legacy.cosmetics.rankings.week();var r:Dictionary=state().get("rare_week",{})
 if r.get("week","")!=week or rarer(catch,r):state().rare_week={"week":week,"species":catch.species,"kg":catch.kg}
 delay=minf(delay,2)
func payload()->Dictionary:
 var scores=legacy.cosmetics.rankings.scores();var hero_damage={};var realm_clears={};var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 for id in legacy.data.heroes:
  if preload("res://scripts/record_eligibility.gd").hero_allowed(legacy.game,str(id)):hero_damage[id]=minf(1e12,float(legacy.data.heroes[id].get("damage",0)))
 for id in legacy.data.realm_counts:
  if id in manifest.regions:realm_clears[id]=mini(1000000,int(legacy.data.realm_counts[id]))
 var best={"species":"","kg":0.0};var rare={};var trophies=[]
 for id in legacy.fishing_records.state().journal:
  var weight=float(legacy.fishing_records.state().journal[id].get("kg",0))
  var entry={"species":id,"kg":weight}
  if FISH.is_trophy(entry):trophies.append(entry)
  if weight>0 and rarer(entry,rare):rare=entry
  if weight>float(best.kg):best={"species":id,"kg":weight}
 return {"extractions":preload("res://scripts/extraction_ledger.gd").batch(legacy),"catch_records":legacy.fishing_records.record_payload(),"record_policy":3,"unofficial":false,"claims":claims.slice(-12),"trophies":trophies,"named":preload("res://scripts/named_records.gd").payload(legacy),"rarest_all":rare,"rarest_week":state().get("rare_week",{}) if state().get("rare_week",{}).get("week","")==scores.week else {},"garden_records":legacy.gardening.fair.payload(),"version":1,"profile":scores.profile,"hero_damage":hero_damage,"realm_clears":realm_clears,"fish_all":best,"week":scores.week,"fish_week":{"species":scores.fish_species,"kg":scores.fish},"between":{"solo":int(state().solo),"coop":int(state().coop)}}
func cloud_identity()->String:
 var account=legacy.get_node("/root/FXAccount")
 return str(account.user.get("id","")) if account.loaded and not account.conflict else ""
func request_sync(refresh_board=false)->void:
 if not allowed() or endpoint.is_empty():
  sync_status="Record uploads are paused in preview / developer mode."
  if refresh_board:read_delay=0;fetch()
  return
 refresh_after_sync=refresh_after_sync or refresh_board
 if busy:pending_sync=true;return
 var account=legacy.get_node("/root/FXAccount")
 sent_claims=claims.duplicate(true);sent_extractions=preload("res://scripts/extraction_ledger.gd").batch(legacy).duplicate(true)
 synced_identity=cloud_identity();busy=true;pending_sync=false;delay=120+randf()*15
 sync_status="Syncing your records"+(" as "+str(account.user.username) if not synced_identity.is_empty() else " anonymously")+"…"
 var error=sync_request.request(endpoint+"/community/sync",account.record_headers(),HTTPClient.METHOD_POST,JSON.stringify(payload()))
 if error!=OK:
  busy=false;delay=30;sync_status="Could not upload records. Your saved progress is safe."
  if refresh_after_sync:refresh_after_sync=false;read_delay=0;fetch()
 redraw()
func resync()->void:
 if manual_cooldown>0:return
 manual_cooldown=5;request_sync(true)
func step(delta:float)->void:
 manual_cooldown=maxf(0,manual_cooldown-delta);read_delay=maxf(0,read_delay-delta);board_refresh=maxf(0,board_refresh-delta)
 if legacy.page=="community" and legacy.game.menu=="legacy" and board_refresh<=0 and not reading and not busy:fetch()
 if not allowed() or endpoint.is_empty():return
 var identity=cloud_identity();var mode=str(legacy.game.mode)
 if identity!=last_identity:
  last_identity=identity
  if not identity.is_empty():delay=0
 if mode!=last_mode:
  last_mode=mode
  if mode=="town":delay=minf(delay,2)
 if identity.is_empty() and not legacy.get_tree().root.get_node("FXActivity").enabled:return
 delay-=delta
 if delay<=0 and not busy:request_sync(legacy.page=="community")
func synced(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 busy=false
 var success=result==HTTPRequest.RESULT_SUCCESS and code==200
 if not success:
  delay=45;sync_status="Records upload failed (%d). Your saved progress is safe; retry Resync." % code
 else:
  for claim in sent_claims:claims.erase(claim)
  var response=JSON.parse_string(body.get_string_from_utf8())
  if response is Dictionary:
   preload("res://scripts/extraction_ledger.gd").acknowledge(legacy,response.get("extraction_receipts",[]),sent_extractions)
   for text in response.get("records_broken",[]):
    if text is String and text.length()<200:preload("res://scripts/record_toast.gd").show(legacy.game,text)
  generation+=1;read_delay=0
  sync_status="Records synced"+(" to your cloud username." if not synced_identity.is_empty() else " anonymously. Load a cloud profile to show your username.")
 if pending_sync:
  pending_sync=false;request_sync(refresh_after_sync);return
 if refresh_after_sync or legacy.page=="community":
  refresh_after_sync=false;read_delay=0;fetch()
 redraw()
func open()->void:
 legacy.open_page("community");read_delay=0;fetch();resync()
func fetch()->void:
 if reading or endpoint.is_empty() or read_delay>0:return
 status="Loading community records…";reading_generation=generation;board_refresh=30
 reading=read_request.request(endpoint+"/community/records?refresh="+str(Time.get_ticks_msec()))==OK;read_delay=5
 if not reading:stale=true;board_refresh=15;status="Community records unavailable • retrying automatically"
 redraw()
func reject_response(message:String)->void:
 stale=true;board_refresh=15;status=message;redraw()
func received(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 reading=false
 if reading_generation!=generation:
  read_delay=0;fetch();return
 var parser=JSON.new();var parsed:Variant=parser.data if parser.parse(body.get_string_from_utf8())==OK else null
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or not parsed is Dictionary or parsed.get("version")!=1:
  stale=true;board_refresh=15;status="Community records unavailable • retrying automatically; saved records are safe";redraw();return
 if not parsed.get("named",{}) is Dictionary:reject_response("Invalid named records response");return
 for key in SUMMARY_LIMITS:
  if not parsed.get(key) is Array:reject_response("Invalid community %s list • expected a record list" % key);return
  if parsed[key].size()>int(SUMMARY_LIMITS[key]):reject_response("Invalid community %s list • received %d entries, maximum %d; keeping the last loaded records" % [key,parsed[key].size(),int(SUMMARY_LIMITS[key])]);return
 for key in ["fish_all","fish_week","rarest_all","rarest_week"]:
  var f=parsed.get(key)
  if f!=null and (not f is Dictionary or not FISH.fish().has(f.get("species")) or not (f.get("kg") is float or f.get("kg") is int) or not is_finite(float(f.kg)) or float(f.kg)<=0 or float(f.kg)>10000):reject_response("Invalid fish response • keeping the last loaded records");return
 if parsed.has("fish_boards") and not valid_fish_boards(parsed.fish_boards):reject_response("Invalid fish rankings • keeping the last loaded records");return
 for key in ["garden_all","garden_month"]:
  if not parsed.get(key,[]) is Array or parsed.get(key,[]).size()>12:reject_response("Invalid garden response • keeping the last loaded records");return
  for row in parsed.get(key,[]):
   if not row is Dictionary or not preload("res://scripts/giant_garden.gd").record_valid(row,"all"):reject_response("Invalid crop response • keeping the last loaded records");return
 snapshot=parsed;stale=false;last_refresh=Time.get_time_string_from_system();status="Connected community • weekly records reset Mondays" if compatible(parsed) else "Older server connected • server update required";redraw()
func view_signature()->String:
 # Network status changes never replace the records currently being read.
 var records=snapshot.duplicate();records.erase("updated_at")
 return category+":"+JSON.stringify(JSON.parse_string(JSON.stringify(records)))
func update_chrome()->void:
 if is_instance_valid(navigation_status):
  navigation_status.text=board_notice()
  navigation_status.modulate=Color("#f0ca87") if stale or not snapshot.is_empty() and not compatible(snapshot) else Color("#b7d4d7")
 if is_instance_valid(refresh_button):
  refresh_button.text="Syncing…" if busy or reading else "Resync records"
  refresh_button.disabled=reading or busy
 if is_instance_valid(body_status):body_status.text=status+(" • "+sync_status if not sync_status.is_empty() else "")
 for tab in legacy.community_navigation.find_children("RecordsTab_*","Button",true,false):
  var selected=tab.name=="RecordsTab_"+category;tab.set_pressed_no_signal(selected)
  var skin=UI.box("#32636c" if selected else "#102b34","#f1cd82" if selected else "#416b74",5,7)
  tab.add_theme_stylebox_override("normal",skin);tab.add_theme_stylebox_override("pressed",skin)
func redraw()->void:
 if legacy.page!="community" or legacy.game.menu!="legacy":return
 if not is_instance_valid(view_body) or view_body!=legacy.body:
  legacy.render();return
 if rendered_signature!=view_signature():
  var position=legacy.profile_scroll.scroll_vertical
  # Construct replacement rows off-tree, then exchange them within one frame.
  # The panel, pinned tabs, focus and ScrollContainer all retain their identity.
  var replacement=VBoxContainer.new();build(replacement)
  for child in legacy.body.get_children():legacy.body.remove_child(child);child.queue_free()
  for child in replacement.get_children():replacement.remove_child(child);legacy.body.add_child(child)
  replacement.free();view_body=legacy.body;content_updates+=1
  legacy.profile_scroll.scroll_vertical=position
  legacy.profile_scroll.set_deferred("scroll_vertical",position)
 update_chrome()
func choose_category(value:String)->void:
 category=value;redraw();legacy.profile_scroll.set_deferred("scroll_vertical",0)
func build_navigation(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd")
 var panel=PanelContainer.new();panel.name="RecordsNavigation";panel.add_theme_stylebox_override("panel",UI.box("#173f49","#75afb1",8,10));parent.add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",7);panel.add_child(col)
 var heading=HBoxContainer.new();col.add_child(heading)
 var title=gui.label(heading,"COMMUNITY RECORDS  /  CHOOSE A BOARD",17);title.add_theme_color_override("font_color",Color("#f2d494"))
 var refresh=gui.button(heading,"Syncing…" if busy or reading else "Resync records",resync);refresh_button=refresh;refresh.name="ResyncRecords";refresh.custom_minimum_size=Vector2(155,34);refresh.size_flags_horizontal=Control.SIZE_SHRINK_END;refresh.disabled=reading or busy
 refresh.tooltip_text="Upload the active profile, then refresh the community boards."
 var notice=gui.label(col,board_notice(),14);navigation_status=notice;notice.custom_minimum_size.y=36;notice.max_lines_visible=2;notice.name="RecordsSyncStatus";notice.modulate=Color("#f0ca87") if not snapshot.is_empty() and not compatible(snapshot) or stale else Color("#b7d4d7")
 var tabs=HFlowContainer.new();tabs.name="RecordsCategoryTabs";tabs.add_theme_constant_override("h_separation",6);tabs.add_theme_constant_override("v_separation",5);col.add_child(tabs)
 for entry in [["Hero damage","heroes"],["Fishing records","fish"],["Realm records","realms"],["Between runs","between"],["Ram’s Descent","descent"],["Garden fair","garden"],["Life streaks","streak"],["Relic finds","relic"]]:
  var tab=gui.button(tabs,entry[0],choose_category.bind(str(entry[1])));tab.name="RecordsTab_"+str(entry[1]);tab.toggle_mode=true;tab.set_pressed_no_signal(category==entry[1]);tab.custom_minimum_size=Vector2(126,36);tab.add_theme_font_size_override("font_size",15)
  var skin=UI.box("#32636c" if category==entry[1] else "#102b34","#f1cd82" if category==entry[1] else "#416b74",5,7)
  tab.add_theme_stylebox_override("normal",skin);tab.add_theme_stylebox_override("pressed",skin)
func build(parent:Node)->void:
 view_body=parent;rendered_signature=view_signature()
 var gui=preload("res://scripts/garden_ui.gd")
 body_status=gui.label(parent,status+(" • "+sync_status if not sync_status.is_empty() else ""),14);body_status.custom_minimum_size.y=36;body_status.max_lines_visible=2
 gui.label(parent,"Community play records • public game names for cloud accounts",14).tooltip_text="Best results use high-water values. Cumulative extractions count each successful run once per account. Co-op hauls count for each participating account. These are client-reported, not verified competition scores."
 if snapshot.is_empty():preload("res://scripts/garden_ui.gd").label(parent,"No community data loaded yet. An internet connection and the matching server update are needed.",19);return
 var clears_parent:Node=parent
 var times_parent:Node=parent
 if category=="realms":
  var columns=HBoxContainer.new();columns.name="RealmRecordsColumns";columns.add_theme_constant_override("separation",16);parent.add_child(columns)
  for n in 2:
   var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.size_flags_stretch_ratio=1;columns.add_child(column)
   if n==0:clears_parent=column
   else:times_parent=column
 for entry in [["TOP 10 HEROES • TOTAL DAMAGE","heroes"],["TOP 10 REALMS • RECORDED CLEARS","realms"]]:
  if category!=entry[1]:continue
  var card=UI.card(clears_parent,entry[0],"Ranked by total damage across connected profiles • all time" if entry[1]=="heroes" else "Recorded clears across connected profiles • all time")
  if snapshot.get(entry[1],[]).is_empty():preload("res://scripts/garden_ui.gd").label(card,"No records submitted yet.")
  if entry[1]=="heroes":
   preload("res://scripts/records_hall_ui.gd").hero_leaders(card,legacy,snapshot.get("heroes",[]));continue
  var n=0
  for row in snapshot.get(entry[1],[]):
   n+=1;var id=str(row.get("id",""));var data=legacy.game.characters.get(id,{}) if entry[1]=="heroes" else legacy.game.realms.get(id,{})
   if not (row.get("value") is float or row.get("value") is int) or not is_finite(float(row.value)):continue
   var line=HBoxContainer.new();card.add_child(line)
   if entry[1]=="heroes":
    var art=TextureRect.new();var sprite=str(data.get("sprite",id));art.texture=legacy.game.art.get(sprite+"_idle",legacy.game.art.get(sprite+"_0"));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(44,48);line.add_child(art)
   preload("res://scripts/garden_ui.gd").label(line,"%d. %s    %s" % [n,str(data.get("name",id)),String.num(float(row.value),0)],20)
 preload("res://scripts/named_records_ui.gd").build(times_parent if category=="realms" else parent,legacy,snapshot.get("named",{}),"times" if category=="realms" else category)
 if category in ["heroes","realms","times","streak","relic","descent"]:return
 if category=="garden":garden_records(parent);return
 if category=="fish":fish_leaderboards(parent)
 if category=="fish":species_records(parent)
 if category=="fish":gui.label(parent,"Rarest: species rarity first, then its base catalogue catch weight. Fish weight breaks ties within a species. Weekly records reset Monday.",15)
 if category!="between":return
 var expeditions=UI.card(parent,"THE BETWEEN • TOP 10 EXTRACTORS","Cumulative raw shards from successful solo and co-op returns • tracked from v202 • excludes bonuses and failed escapes")
 var named=snapshot.get("named",{})
 if not named.has("between_extractors"):
  gui.label(expeditions,"Deploy the matching server update to load cumulative extractions.",16);return
 var rows=named.get("between_extractors",[]);var cols=preload("res://scripts/records_hall_ui.gd").columns(expeditions)
 for i in 10:
  if i<rows.size():
   var row=rows[i]
   gui.label(cols[i/5],"%d. %s • %s shards" % [i+1,str(row.username),String.num(float(row.value),0)],18)
   gui.label(cols[i/5],"%d successful returns • Solo %s / Co-op %s" % [int(row.get("runs",0)),String.num(float(row.get("solo",0)),0),String.num(float(row.get("coop",0)),0)],14)
  else:gui.label(cols[i/5],str(i+1)+". No successful returns yet",16)

static func preferred_fish(anonymous:Variant,named:Variant,rarest:bool)->Variant:
 if not named is Dictionary:return anonymous
 if anonymous==null:return named
 if rarest:
  return named if rarer(named,anonymous) or (str(named.species)==str(anonymous.species) and float(named.kg)>=float(anonymous.kg)) else anonymous
 return named if float(named.kg)>=float(anonymous.kg) else anonymous
func fish_size(parent:Node,record:Dictionary)->void:
 var gui=preload("res://scripts/garden_ui.gd");var spec=FISH.fish()[record.species]
 var rarity=gui.label(parent,str(spec.rarity)+(" • TROPHY SIZE" if FISH.is_trophy(record) else " • "+size_word(record)),18)
 rarity.modulate=preload("res://scripts/fish_weight_gauge.gd").rarity_color(str(spec.rarity))
 var gauge=preload("res://scripts/fish_weight_gauge.gd").new();gauge.species=str(record.species);gauge.kg=float(record.kg);parent.add_child(gauge)
static func size_word(record:Dictionary)->String:
 var ratio=float(record.kg)/maxf(.001,FISH.mean_kg(str(record.species)))
 return "Small size" if ratio<.75 else "Typical size" if ratio<1.25 else "Large size"
func species_records(parent:Node)->void:
 var gui=preload("res://scripts/garden_ui.gd")
 var card=UI.card(parent,"SPECIES TROPHY HOLDERS • ALL TIME","Heaviest trophy of each species • your saved journal’s trophy catches sync when you load a cloud profile or press Resync.")
 var rows=snapshot.get("named",{}).get("species_trophies",[])
 if rows.is_empty():gui.label(card,"No species trophies recorded yet. Load your cloud profile and press Resync to submit saved trophy catches. Ordinary catches do not qualify.",17)
 for f in rows:
  if not f is Dictionary or not FISH.fish().has(str(f.get("species",""))) or not FISH.is_trophy(f):continue
  trophy_row(card,f)
func trophy_row(parent:Node,f:Dictionary)->PanelContainer:
 var spec:Dictionary=FISH.fish()[f.species]
 var frame=PanelContainer.new();frame.name="TrophyRow";frame.add_theme_stylebox_override("panel",UI.box("#153440",preload("res://scripts/fish_weight_gauge.gd").rarity_color(str(spec.rarity)).to_html(),8,8));parent.add_child(frame)
 var row=HFlowContainer.new();row.add_theme_constant_override("h_separation",12);row.add_theme_constant_override("v_separation",4);frame.add_child(row)
 var art=TextureRect.new();art.texture=FISH.texture(str(f.species));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(112,72);row.add_child(art)
 var details=VBoxContainer.new();details.custom_minimum_size.x=210;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
 var gui=preload("res://scripts/fish_collection_ui.gd")
 gui.text(details,str(spec.name)+" • %.2f kg" % float(f.kg),17)
 gui.text(details,str(f.get("username","Earlier anonymous record")),15)
 gui.text(details,str(spec.rarity)+" • TROPHY SIZE",13,preload("res://scripts/fish_weight_gauge.gd").rarity_color(str(spec.rarity)))
 var gauge=preload("res://scripts/fish_weight_gauge.gd").new();gauge.compact=true;gauge.species=str(f.species);gauge.kg=float(f.kg);row.add_child(gauge)
 return frame

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

const FISH_BOARD_KEYS=["fish_all","fish_week","rarest_all","rarest_week"]
static func valid_fish_boards(boards:Variant)->bool:
 if not boards is Dictionary:return false
 for key in FISH_BOARD_KEYS:
  if not boards.get(key) is Array or boards[key].size()>10:return false
  for row in boards[key]:
   if not row is Dictionary or not FISH.fish().has(row.get("species")) or not (row.get("kg") is float or row.get("kg") is int):return false
   if not is_finite(float(row.kg)) or float(row.kg)<=0 or float(row.kg)>minf(10000,float(FISH.fish()[row.species].max_kg)*4+.01):return false
   if row.has("username") and (not row.username is String or row.username.length()>96):return false
 return true
func fish_leaders(key:String)->Array:
 if snapshot.get("fish_boards") is Dictionary and snapshot.fish_boards.get(key) is Array:return snapshot.fish_boards[key].slice(0,10)
 var best=preferred_fish(snapshot.get(key),snapshot.get("named",{}).get(key),key.begins_with("rarest"))
 return [best] if best is Dictionary and FISH.fish().has(best.get("species")) else []
func fish_leaderboards(parent:Node)->void:
 var flow=HFlowContainer.new();flow.name="FishLeaderboards";flow.add_theme_constant_override("h_separation",12);flow.add_theme_constant_override("v_separation",12);parent.add_child(flow)
 for entry in [["LARGEST FISH • THIS WEEK","fish_week"],["LARGEST FISH • ALL TIME","fish_all"],["RAREST FISH • THIS WEEK","rarest_week"],["RAREST FISH • ALL TIME","rarest_all"]]:
  var card=UI.card(flow,entry[0],"Top 10 individual catches • players can hold multiple places");card.name="FishBoard_"+str(entry[1]);card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.get_parent().custom_minimum_size.x=clampf(legacy.game.get_viewport_rect().size.x-96,300,400)
  var leaders:Array=fish_leaders(str(entry[1]))
  if leaders.is_empty():preload("res://scripts/garden_ui.gd").label(card,"No catches recorded for this period yet.",16)
  for i in leaders.size():fish_leader_row(card,leaders[i],i+1)
func fish_leader_row(parent:Node,record:Dictionary,rank:int)->Control:
 var spec:Dictionary=FISH.fish()[record.species]
 var frame=PanelContainer.new();frame.name="FishLeader_"+str(rank);frame.add_theme_stylebox_override("panel",UI.box("#153440","#688e91" if rank==1 else "#284e59",6,7));parent.add_child(frame)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);frame.add_child(row)
 var number=Label.new();number.text=str(rank);number.custom_minimum_size.x=20;number.add_theme_font_size_override("font_size",22);number.modulate=Color("#efcd83" if rank==1 else "#bed7df");row.add_child(number)
 var art=TextureRect.new();art.texture=FISH.texture(str(record.species));art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(64,54);row.add_child(art)
 var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.custom_minimum_size.x=150;details.add_theme_constant_override("separation",2);row.add_child(details)
 var gui=preload("res://scripts/garden_ui.gd")
 gui.label(details,str(record.get("username","Earlier anonymous catch")),17)
 var weight=gui.label(details,"%s • %.2f kg • %s" % [str(spec.name),float(record.kg),str(spec.rarity)],15);weight.modulate=preload("res://scripts/fish_weight_gauge.gd").rarity_color(str(spec.rarity))
 return frame
