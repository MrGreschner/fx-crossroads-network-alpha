extends Node
## Voyage cargo is deliberately separate from awarded catches until a safe landing.
const C=preload("res://scripts/fishing_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
const PIER=Vector2(1860,2300)
const HOME=Vector2(1100,5650)
const WORLD=Vector2(9000,6800)
const OCEAN_WORLD=Vector2(28000,20000)
const CURRENT_BANDS=[3400.0,6100.0,8400.0,11500.0,15800.0,20500.0,24200.0]
var night_seed=0
var island_found_night=-1
var cached_night=-999999
var cached_night_center=Vector2.ZERO
var cached_rock_key=""
var cached_rocks:Array=[]
const PRICE=1200
const LIMIT=20
var game:Node
var active=false
var route="lake"
var boat=HOME
var velocity=Vector2.ZERO
var facing=-PI/2
var hull=100.0
var anchored=false
var ashore=false
var elapsed=0.0
var start_hour=12.0
var impact=0.0
var weather_timer=0.0
var cargo:Array=[]
var release_log:Array=[]
var hud_view=preload("res://scripts/voyage_hud.gd").new()
var xp_quote_key=""
var xp_quote=0
var cages:Array=[]
var repairs:Array=[]
var seen:Array=[]
var rng=RandomNumberGenerator.new()
var hud:CanvasLayer
var strip:HBoxContainer
var status:Label
var anchor_button:Button
var dock_button:Button
var overlay:CanvasLayer
var panel:PanelContainer
var chart=false
var last_checkpoint=0.0
var last_night=false
var darkness_image:Image
var darkness_texture:ImageTexture
var darkness_key=""
var darkness_builds=0
var is_banking=false
var surf=preload("res://scripts/voyage_waves.gd").new()
var debris=preload("res://scripts/voyage_debris.gd").new()
const ISLES=preload("res://scripts/voyage_islands.gd")
func setup(g:Node)->void:
 game=g;rng.randomize();hud=CanvasLayer.new();hud.layer=57;add_child(hud)
 hud_view.build(self)
 hud.hide()
func records():return game.legacy.fishing_records
func context()->Dictionary:
 var ctx=preload("res://scripts/town_weather.gd").context(game.town_life.calendar.now)
 ctx.weather=game.town_life.calendar.weather()
 ctx.region="night_crater" if route=="coast" and ashore else "voyage_"+route
 ctx.hour=game.town_life.calendar.hour
 return ctx
func night()->bool:
 var hour=float(context().hour);return hour>=20 or hour<6
func world_size()->Vector2:return OCEAN_WORLD if route=="coast" else WORLD
func night_number()->int:return int(game.town_life.calendar.day_number)-(1 if float(context().hour)<20 else 0)
static func night_site(number:int)->Vector2:
 var random=RandomNumberGenerator.new();random.seed=number*7919+37
 # Full deep-water search area, not a repeating circuit of six known sites.
 return Vector2(random.randf_range(11000,26400),random.randf_range(1400,18600))
func night_center()->Vector2:
 var number=night_number()
 if number==cached_night:return cached_night_center
 cached_night=number;cached_night_center=night_site(number)
 return cached_night_center
func safe_water_near(center:Vector2)->Vector2:
 for i in 16:
  var candidate=(center+Vector2.from_angle(i*TAU/16)*900).clamp(Vector2(100,100),world_size()-Vector2(100,100))
  var clear=true
  for rock in rocks():
   if candidate.distance_to(rock.p)<float(rock.r)+60:clear=false
  for isle in islands():
   if ISLES.distance_to_shore(isle,candidate)<60:clear=false
  if clear:return candidate
 return (center+Vector2(0,1100)).clamp(Vector2(100,100),world_size()-Vector2(100,100))
func current_at(point:Vector2)->Vector2:
 var flow=Vector2(sin(point.y/850+elapsed*.05),cos(point.x/1100-elapsed*.04))*(55 if route=="coast" else 38)
 if route=="coast":
  for band in CURRENT_BANDS:
   var strength=maxf(0,1-absf(point.x-band)/650.0)
   flow+=Vector2(sin(point.y/680+band*.001)*70,(-150 if int(band) in [6100,11500,20500] else 150))*strength
  var eddy=point-Vector2(10600,3400)
  if eddy.length()<1250 and eddy.length()>20:flow+=eddy.normalized().orthogonal()*90*(1-eddy.length()/1250)
 if str(context().weather)=="Storm":flow*=1.5
 return flow.limit_length(260)
func islands()->Array:
 if route=="lake":return [{"p":Vector2(2650,4350),"r":470.0,"name":"Birch Landing"},{"p":Vector2(5100,3050),"r":580.0,"name":"Oldwater Isle"},{"p":Vector2(2800,1500),"r":430.0,"name":"Reedwatch Island"}]
 var result:Array=[{"p":Vector2(2300,4400),"r":330.0,"name":"Shore Refuge"},{"p":Vector2(5450,4300),"r":340.0,"name":"Kelp Rest"}]
 if night():result.append({"p":night_center(),"r":610.0,"name":"Night Island"})
 return result
func rocks()->Array:
 var key=route+":"+str(night_number())+":"+str(night())
 if cached_rock_key==key:return cached_rocks
 var result:Array=[]
 for i in (312 if route=="coast" else 48):
  var p=Vector2(1650+fposmod(i*977,world_size().x-2400),650+fposmod(i*1327,world_size().y-1500))
  var near_island=false
  for isle in islands():
   if p.distance_to(isle.p)<float(isle.r)+140:near_island=true
  if not near_island and p.distance_to(HOME)>650:result.append({"p":p,"r":34.0+(i%4)*13})
 cached_rock_key=key;cached_rocks=result
 return result
func land_at(p:Vector2)->bool:
 if not active:return true
 for isle in islands():
  if ISLES.contains(isle,p,28):
   if route=="coast" and str(isle.name)=="Night Island" and p.distance_to(night_center())<210:return false
   return true
 return false
func nearby_island()->Dictionary:
 for isle in islands():
  if ISLES.distance_to_shore(isle,boat)<145:return isle
 return {}
func habitat()->String:
 if route=="lake":return "voyage_lake_"+("reeds" if boat.x<3300 else "islands" if boat.y>2700 else "deep")
 return "voyage_coast_"+("channel" if boat.x>6500 or boat.y<1900 else "kelp" if boat.x>4100 and boat.y>3000 else "reef" if boat.y<3800 else "shoals")
func fishing_spot()->Dictionary:
 if not active:return {}
 var id=habitat();var bank=game.position_in_world;var water=boat+Vector2.from_angle(facing)*100
 if ashore:
  if route!="coast" or not night() or bank.distance_to(night_center()+Vector2(-240,-20))>140:return {}
  id="voyage_night_crater";water=night_center()+Vector2(-120,-20)
 elif not anchored:return {}
 var spot:Dictionary=C.pools()[id].duplicate(true);spot.id=id;spot.region="night_crater" if id=="voyage_night_crater" else spot.region;spot.bank=[bank.x,bank.y];spot.water=[water.x,water.y]
 return spot
func pier_interact()->bool:
 if game.position_in_world.distance_to(PIER)>150 and not preload("res://scripts/town_marina.gd").on_deck(game.position_in_world):return false
 game.hint="E • Ripple & Reel marina • Lake & coastal voyages"
 if Input.is_action_just_pressed("interact"):open_menu("pier")
 return true
func purchase()->void:
 if game.mode!="town" or records().state().get("deep_sea_rod",false):return
 if not game.legacy.glimmers.debit(PRICE):game.message="You need 1,200 Glimmers for the permanent Deep Sea Rod.";game.message_time=5;return
 records().state().deep_sea_rod=true;records().save();game.message="Deep Sea Rod owned • Coastal voyages unlocked."
 if is_instance_valid(overlay):open_menu("pier")
func checkpoint()->void:
 # A live voyage is session-only. Only a transaction already at safe harbour is persisted.
 last_checkpoint=elapsed
func camp_state()->Dictionary:
 var result:Dictionary={}
 for i in game.region.get("enemies",[]).size():result[str(i)]=0.0
 for entry in game.enemies:result[str(entry.uid)]=maxf(0,float(entry.hp))
 return result
func launch(destination:String,resume:bool=false)->void:
 if active:return
 if destination=="coast" and not records().state().get("deep_sea_rod",false):return
 var previous:Dictionary=records().state().get("voyage",{}).duplicate(true)
 if resume and not valid_state(previous):return
 if not resume and bool(previous.get("banking",false)):return
 if resume and (not bool(previous.get("banking",false)) or Vector2(previous.get("boat",[0,0])[0],previous.get("boat",[0,0])[1]).distance_to(HOME)>260):
  game.message="Ended voyages cannot be resumed. Sail home before leaving to keep the rewards.";game.message_time=6;return
 if not resume and not previous.is_empty():records().state().erase("voyage");records().save()
 close_menu();night_seed=int(game.town_life.calendar.day_number);island_found_night=-1;route=destination;boat=HOME;hull=100;elapsed=0;velocity=Vector2.ZERO;anchored=false;ashore=false;cargo=[];release_log=[];xp_quote_key="";cages=[];seen=[];repairs=[];start_hour=float(preload("res://scripts/fishing_ecology.gd").context(game).hour)
 if resume:
  if not valid_state(previous):return
  night_seed=int(previous.get("night_seed",night_seed));island_found_night=int(previous.get("island_found_night",-1))
  route=str(previous.route);boat=Vector2(previous.boat[0],previous.boat[1]);hull=float(previous.hull);elapsed=float(previous.elapsed);start_hour=float(previous.start_hour);cargo=previous.cargo.duplicate(true);release_log=previous.get("release_log",[]).duplicate(true)
  for item in cargo.duplicate():
   if not item.keep:release_log.append(item);cargo.erase(item)
  cages=previous.cages.duplicate(true);seen=previous.seen.duplicate();repairs=previous.repairs.duplicate()
 game.start_run(false,"voyage_"+route)
 if game.region_id!="voyage_"+route:return
 active=true;surf.reset();debris.reset();last_night=night();game.level=6;game.position_in_world=boat;game.update_camera();game.enemies=game.enemies.filter(func(e):return land_at(e.pos))
 if resume:
  game.health=minf(game.max_health(),maxf(1,float(previous.get("hero_hp",game.health))))
  var camp_hp:Dictionary=previous.get("camp_hp",{})
  for entry in game.enemies:
   if camp_hp.has(str(entry.uid)):entry.hp=minf(entry.max_hp,float(camp_hp[str(entry.uid)]))
  game.enemies=game.enemies.filter(func(e):return e.hp>0)
 game.message="Boat voyage • Anchor to fish, explore islands, and bring your catches home alive.";game.message_time=7
 last_night=night()
 checkpoint()
 if resume and bool(previous.get("banking",false)):bank()
func suspend()->void:
 # Compatibility for old callers: leaving ends the attempt, never suspends it.
 if active:fail("Voyage ended")
func capacity()->int:return records().progress.voyage_capacity()
func manifest_state(banking:bool)->Dictionary:
 return {"version":1,"night_seed":night_seed,"island_found_night":island_found_night,"route":route,"boat":[boat.x,boat.y],"hull":hull,"elapsed":elapsed,"start_hour":start_hour,"cargo":cargo.duplicate(true),"release_log":release_log.duplicate(true),"cages":cages.duplicate(true),"seen":seen.duplicate(),"repairs":repairs.duplicate(),"banking":banking,"hero_hp":game.health,"camp_hp":camp_state()}
func pending_xp()->int:
 var p=records().progress;var state=records().state();var key=str(cargo.size())+":"+str(release_log.size())+":"+str(state.xp)+":"+str(state.talents.hash())+":"+str(state.journal.hash())
 if key==xp_quote_key:return xp_quote
 xp_quote_key=key;xp_quote=0;var journal:Dictionary=state.journal.duplicate(true)
 for item in cargo+release_log:
  var c:Dictionary=item.catch
  if c.id in state.recent:continue
  var first=not journal.has(c.species);var better=first or float(c.kg)>float(journal.get(c.species,{}).get("kg",0))
  xp_quote+=p.quote_xp(c,first,better,bool(item.keep));journal[c.species]={"kg":maxf(float(c.kg),float(journal.get(c.species,{}).get("kg",0)))}
 return mini(xp_quote,1000000000-int(state.xp))
func stow(catch:Dictionary,keep:bool)->bool:
 if not active or not preload("res://scripts/fishing_records.gd").valid_catch(catch):return false
 if keep and cargo.size()>=capacity() or not keep and release_log.size()>=1000:return false
 if str(C.pools()[catch.pool].region)!="voyage_"+route:return false
 for item in cargo+release_log:
  if item.catch.id==catch.id:return false
 if catch.id in records().state().recent:return false
 var item={"catch":catch.duplicate(true),"keep":keep}
 if keep:cargo.append(item)
 else:release_log.append(item)
 xp_quote_key="";checkpoint();return true
func release_cargo(id:String)->bool:
 if release_log.size()>=1000:return false
 for n in cargo.size():
  if str(cargo[n].catch.id)!=id:continue
  var item:Dictionary=cargo.pop_at(n);item.keep=false;release_log.append(item);xp_quote_key="";checkpoint();return true
 return false

func toggle_anchor()->void:
 if ashore:return
 if game.fishing.busy():game.fishing.cancel("Cast cancelled before moving the boat.")
 anchored=not anchored;velocity=Vector2.ZERO
func interact()->void:
 if not active:return
 if game.fishing.busy():return
 if not ashore and boat.distance_to(HOME)<260:
  anchored=true;open_menu("landing");return
 if ashore:
  if game.position_in_world.distance_to(boat)>230:game.message="Return to your boat's lantern to board.";game.message_time=4;return
  ashore=false;game.position_in_world=boat;anchored=true;checkpoint();return
 var isle=nearby_island()
 if isle.is_empty():game.message="Approach a sandy island landing, or the harbour to return.";game.message_time=4;return
 var dir=(boat-isle.p).normalized();var target:Vector2=isle.p+dir*(ISLES.radius(isle,dir.angle())-70)
 if not land_at(target):return
 ashore=true;anchored=true;game.position_in_world=target;game.update_camera();game.message="Island landing • your normal hero attacks work here. Return to the lantern to board.";game.message_time=6
func cage_action()->void:
 if not active or ashore or not anchored:return
 if not records().progress.method_unlocked("pot"):return
 for i in range(cages.size()-1,-1,-1):
  var cage:Dictionary=cages[i];var pos=Vector2(cage.pos[0],cage.pos[1])
  if boat.distance_to(pos)<150 and elapsed>=float(cage.ready):
   var specimens:Array=cage.fish
   if cargo.size()+specimens.size()>capacity():game.fishing.status="Make cargo room before recovering this cage.";return
   cages.remove_at(i)
   for catch in specimens:cargo.append({"catch":catch,"keep":true})
   checkpoint();game.fishing.status="Cage recovered • %d catches aboard, unbanked." % specimens.size();return
 if records().progress.bait()=="basic":game.fishing.status="A voyage cage needs consumable fish bait. Choose worms, dough or specialist fish bait.";return
 if cages.size()>=3:game.fishing.status="Three cages already deployed. Recover them at their chart markers.";return
 var pool=habitat();var specimens:Array=[];var progress=records().progress
 for i in progress.basket_capacity():
  var catch=C.roll(pool,rng,context(),"pot",progress.bait(),progress.level(),progress.trophy_bonus(),progress.rarity_bonus("pot"))
  if not catch.is_empty():specimens.append(catch)
 if specimens.is_empty():game.fishing.status="No cage catches feed here in these conditions. Try another habitat.";return
 progress.spend_bait(rng,"pot")
 cages.append({"pos":[boat.x,boat.y],"pool":pool,"ready":elapsed+120.0*progress.basket_minutes()/20.0,"fish":specimens})
 checkpoint();game.fishing.status="Cage lowered • fills in two active voyage minutes. Marker added to chart. Recover before returning."
func fail(reason:String)->void:
 if not active:return
 var lost=cargo.size()+release_log.size();cargo.clear();release_log.clear();cages.clear();records().state().erase("voyage");records().save();active=false;hud.hide();game.fishing.cancel("");close_menu();game.enter_region("town");game.health=float(game.characters.get(game.selected_character,{}).get("max_health",120));game.position_in_world=PIER-Vector2(80,0);game.update_camera();game.message=reason+" • %d unbanked catches lost. Your existing collection is safe." % lost;game.message_time=9
func abandon(after:Callable=Callable())->void:
 var dialog=ConfirmationDialog.new();dialog.title="Abandon this voyage?";dialog.dialog_text="All unbanked catches and deployed voyage cages will be lost. Your existing collection stays safe.";game.add_child(dialog)
 dialog.confirmed.connect(func():
  game.session_menu.resume()
  if active:fail("Voyage abandoned")
  else:records().state().erase("voyage");records().save();open_menu("pier")
  if after.is_valid():after.call()
  dialog.queue_free())
 dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(480,180))
func harbour_access()->bool:
 return active and not ashore and hull>0 and game.health>0 and game.mode=="run" and game.region_id=="voyage_"+route and boat.distance_to(HOME)<=260
func sell_stored(id:String)->bool:
 if not harbour_access() or not records().stored(id):return false
 var catch=records().specimen(id)
 if catch.is_empty():return false
 var wallet=game.legacy.glimmers;var price=wallet.fish_price(catch)
 if price<=0 or not wallet.credit(price):return false
 records().release(id)
 return true
func stored_action(id:String,sell:bool)->void:
 if not harbour_access() or not records().stored(id):return
 var catch=records().specimen(id)
 if catch.is_empty():return
 var dialog=ConfirmationDialog.new();dialog.title=("Sell stored fish?" if sell else "Release stored fish?")
 dialog.dialog_text=str(C.fish()[catch.species].name)+" • %.2f kg" % float(catch.kg)+(" • %d Glimmers" % game.legacy.glimmers.fish_price(catch) if sell else "")+"\nRemoves this older stored catch and any tank/favourite placement. Your current voyage cargo is untouched. Journal and records remain."
 overlay.add_child(dialog)
 dialog.confirmed.connect(func():
  if harbour_access() and records().stored(id):
   if sell:
    game.fishing.status="Stored fish sold." if sell_stored(id) else "Could not sell this fish. No catch removed."
   else:records().release(id);game.fishing.status="Older stored fish released."
  dialog.queue_free();open_menu("storage"))
 dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(520,220))
func bank()->void:
 if not harbour_access():return
 var keep_count=0
 for item in cargo:
  if item.keep and item.catch.id not in records().state().recent:keep_count+=1
 if keep_count>0 and records().storage_count()+keep_count>records().storage_capacity():game.fishing.status="Not enough storage room. Use Manage stored fish to sell older catches, move them to your bag or upgrade storage. Your voyage catch is safe while this session remains open.";open_menu("landing");return
 is_banking=true
 # Pop first, then complete() saves both reward and remaining queue together.
 var s=records().state();s.voyage=manifest_state(true);records().save()
 var total=0
 while not cargo.is_empty() or not release_log.is_empty():
  var item:Dictionary=cargo.pop_front() if not cargo.is_empty() else release_log.pop_front();s.voyage.cargo=cargo;s.voyage.release_log=release_log
  if item.catch.id in s.recent:continue
  if not records().complete(item.catch,bool(item.keep),true):
   
   if item.keep:cargo.push_front(item)
   else:release_log.push_front(item)
   s.voyage.cargo=cargo;s.voyage.release_log=release_log;records().save();is_banking=false;game.fishing.status="Landing paused. No catches were discarded. Resume landing from the manifest.";return
  total+=1
  var activity=game.get_tree().root.get_node_or_null("FXActivity")
  if activity!=null:activity.event(game,"fish_catch","completed",0,{"species_id":str(item.catch.species),"fish_level":records().progress.level(),"fish_weight":float(item.catch.kg),"fish_xp_gain":records().progress.last_xp,"fish_trophy":1 if C.is_trophy(item.catch) else 0,"fish_kept":1 if item.keep else 0})
 s.erase("voyage");records().save();is_banking=false;active=false;cages.clear();hud.hide();close_menu();game.enter_region("town");game.health=float(game.characters.get(game.selected_character,{}).get("max_health",120));game.position_in_world=PIER-Vector2(80,0);game.update_camera();game.message="SAFE RETURN • %d catches recorded • fishing XP, discoveries and community records updated." % total;game.message_time=8
func obstruction(from:Vector2,to:Vector2)->String:
 # Sweep the boat path so a strong wave cannot skip a narrow obstacle.
 for rock in rocks():
  if Geometry2D.get_closest_point_to_segment(rock.p,from,to).distance_to(rock.p)<float(rock.r)+25:return "rock"
 var samples=maxi(1,ceili(from.distance_to(to)/16))
 for n in range(samples+1):
  var point=from.lerp(to,float(n)/samples)
  if point.x<520:return "shore"
  for isle in islands():
   if ISLES.distance_to_shore(isle,point)<40:return "shore"
 return debris.hit(from,to)
func strike(kind:String)->void:
 if impact>0:return
 hull-=8 if kind=="drifting debris" else 12;impact=1.2
 game.message="Hull struck "+kind+"! Steer clear of hazards; waves can push you into them.";game.message_time=4
func step(delta:float)->bool:
 hud.visible=active and game.menu.is_empty() and game.session_menu.page.is_empty() and game.presentation.page.is_empty()
 if not active:return false
 if not game.menu.is_empty() or not game.session_menu.page.is_empty() or not game.presentation.page.is_empty():return not ashore
 if not ashore:
  game.VIEW=game.get_viewport_rect().size;game.visual_clock+=delta;game.run_time+=delta;game.message_time=maxf(0,game.message_time-delta);game.hint="Anchor to fish • E near islands to land • bring catches home alive"
 elapsed+=minf(delta,.1);impact=maxf(0,impact-delta);surf.step(self,minf(delta,.1));debris.step(self,minf(delta,.1))
 var now_night=night()
 if last_night and not now_night and route=="coast" and boat.distance_to(night_center())<1000:
  ashore=false;boat=safe_water_near(night_center());game.position_in_world=boat;game.fishing.cancel("Dawn • Night Island slips beneath the mist. You are back aboard.")
 last_night=now_night
 if Input.is_action_just_pressed("interact"):interact()
 
 if ashore:
  game.hint="Island expedition • E near the boat to board"
  if game.health<=0:fail("You fell on the island");return true
 else:
  var move:Vector2=game.mobile.movement if game.mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
  if not anchored:
   var current=current_at(boat)
   velocity=velocity.lerp(move*280+current+surf.force_at(boat),1-exp(-delta*3))
   var next=(boat+velocity*minf(delta,.05)).clamp(Vector2(100,100),world_size()-Vector2(100,100))
   var hit=obstruction(boat,next)
   if not hit.is_empty():strike(hit);velocity=-velocity*.4
   else:boat=next
   if move.length()>.1:facing=lerp_angle(facing,velocity.angle(),minf(1,delta*6))
  else:
   velocity=surf.force_at(boat)*.18
   var drift=(boat+velocity*minf(delta,.05)).clamp(Vector2(100,100),world_size()-Vector2(100,100))
   var hit=obstruction(boat,drift)
   if hit.is_empty():boat=drift
   else:strike(hit)
  game.position_in_world=boat;game.update_camera()
  if str(context().weather)=="Storm":
   weather_timer+=delta
   if weather_timer>=8:weather_timer=0;hull-=1
  if hull<=0:fail("Your boat was wrecked");return true
  var id=habitat()
  if id not in seen:seen.append(id)
  if route=="coast" and night() and boat.distance_to(night_center())<1050:island_found_night=night_number()
 if elapsed-last_checkpoint>=8:checkpoint()
 hud_view.refresh(self)
 game.queue_redraw();return not ashore
func combat(delta:float)->void:
 if game.stun_time<=0 and not game.fishing.busy():
  if game.adventure.combat.v90.primary_pressed("solo",game.mobile.attacking if game.mobile.enabled else Input.is_action_pressed("primary")):game.fire("primary")
  if Input.is_action_pressed("secondary"):game.fire("secondary")
  if Input.is_action_just_pressed("special"):game.pulse()
 var epoch=game.combat_epoch
 game.update_bullets(delta)
 if not active or not game.combat_frame_active(epoch):return
 game.update_allies(delta);game.update_enemies(delta)
 if not active or not game.combat_frame_active(epoch):return
 game.update_enemy_shots(delta)
func repair()->void:
 var isle=nearby_island()
 if isle.is_empty() or not ashore or str(isle.name) in repairs:return
 for enemy in game.enemies:
  if enemy.hp>0 and enemy.pos.distance_to(isle.p)<float(isle.r)+100:game.fishing.status="Clear this island's enemies before repairing.";return
 hull=minf(100,hull+35);repairs.append(str(isle.name));checkpoint();open_menu("voyage")
func _input(event:InputEvent)->void:
 if is_instance_valid(overlay) and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  close_menu();get_viewport().set_input_as_handled()
func close_menu()->void:
 if is_instance_valid(overlay):overlay.queue_free()
 overlay=null;chart=false
 if game.menu=="voyage":game.menu=""
func open_menu(kind:String)->void:
 if kind=="storage" and not harbour_access():return
 close_menu();game.fishing.cancel("");game.menu="voyage";game.mobile.reset_controls()
 overlay=CanvasLayer.new();overlay.layer=95;add_child(overlay)
 var shade=ColorRect.new();shade.color=Color(.015,.035,.06,.96);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);overlay.add_child(panel)
 var scroll=ScrollContainer.new();panel.add_child(scroll);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",12);scroll.add_child(col)
 var f=game.fishing
 var row=HBoxContainer.new();col.add_child(row);f.label(row,"RIPPLE & REEL • "+("MARINA" if kind=="pier" else "SAFE HARBOUR STORAGE" if kind=="storage" else "SAFE HARBOUR" if kind=="landing" else "EXPEDITION CHART & CARGO"),22);f.button(row,"Close",close_menu)
 if kind=="storage":
  preload("res://scripts/voyage_storage.gd").build(self,col)
 elif kind=="pier":
  f.button(col,"Sell landed fish • Ripple & Reel",func():close_menu();game.fishing.open_sales())
  f.label(col,"Take the helm. Move with WASD / arrows or the touch stick. Drop anchor to fish. E or Land boards islands and returns at the harbour. Bring every voyage catch home alive before it earns XP or records. A voyage is one committed attempt. Sail back alive to bank rewards. Quitting, leaving or being KO’d ends it and loses every unbanked reward.",17)
  var saved:Dictionary=records().state().get("voyage",{})
  if not saved.is_empty() and bool(saved.get("banking",false)):
   f.label(col,"A safe landing has an unfinished reward transaction. Finish it before starting another voyage.",16)
   f.button(col,"Finish safe landing",func():launch(str(saved.route),true))
  else:
   if not saved.is_empty():records().state().erase("voyage");records().save();f.label(col,"The previous unfinished voyage ended. Unbanked rewards were not kept.",15)
   f.label(col,"Cargo %d • Ripple & Reel storage space %d. Sell kept fish before departing if your storage is full." % [capacity(),maxi(0,records().storage_capacity()-records().storage_count())],15)
   var lake=UI.card(col,"UPSTREAM • OLDWATER LAKE","Open from the start • lake fish, creatures and island landings. Return alive with every catch you want to keep.");f.button(lake,"Launch lake voyage",func():launch("lake"))
   var coast=UI.card(col,"DOWNSTREAM • COASTAL WATERS","Deep Sea Rod required • saltwater habitats, currents, surf and an island found only at night.")
   if records().state().get("deep_sea_rod",false):f.button(coast,"Launch coastal voyage",func():launch("coast"))
   else:f.button(coast,"Buy Deep Sea Rod • 1,200 Glimmers",purchase)
  f.label(col,"Lake, ocean and town share the same real 24-hour Edmonton clock and weather, throughout every voyage. Nights are almost black beyond your boat lantern; it stays aboard when you land. Medium and large ocean swells push the boat, with stronger surf near shore. Steer sideways across a crest; anchoring reduces the push. The ocean is four times its former area. Drifting logs, broken spars and floating cargo can damage the hull; the largest waves push much farther, even against an anchor. Night Island moves to an unpredictable deep-water location each night and is not charted until found. The harbour is sheltered. Storms strengthen currents and slowly damage the hull. Anchoring steadies casts, but storms still matter. Island camps contain repair timber after enemies are cleared. Cages take two active voyage minutes, hold five fish before perks, and must be recovered before returning.",16)
 else:
  f.label(col,"Released at sea: %d • Safe-return XP pool: +%d" % [release_log.size(),pending_xp()],16)
  f.label(col,"Unbanked cargo • %d/%d • Ripple & Reel storage space %d • %s" % [cargo.size(),capacity(),maxi(0,records().storage_capacity()-records().storage_count()),game.fishing.status],17)
  var map=Control.new();map.custom_minimum_size=Vector2(700,300);col.add_child(map);map.draw.connect(func():draw_chart(map))
  f.label(col,"Chart: gold = harbour • cream = island • cyan = fishing habitat • orange = cage • arrows = currents. Night Island is charted only after you find it that night. Drifting debris is not marked: watch the water ahead.",15)
  if kind=="landing":
   f.label(col,"Manage older stored fish or upgrade storage here before unloading. You do not need to release your new catches. Kept catches and released catches earn XP only on safe landing. Unrecovered cages are left behind.",17)
   f.button(col,"Manage stored fish • sell / move / upgrade",func():open_menu("storage"))
   f.button(col,"Land safely • record catches & earn XP",bank)
  else:
   if ashore:f.button(col,"Use island repair timber • +35 hull, once per island",repair)
   if anchored and not ashore:f.button(col,"Deploy / recover nearby voyage cage",func():cage_action();open_menu("voyage"))
   f.button(col,"Abandon voyage & cargo…",abandon)
  for i in cargo.size():
   var item:Dictionary=cargo[i];var r=HBoxContainer.new();col.add_child(r);f.picture(r,str(item.catch.species),Vector2(76,48),item.catch);f.label(r,str(C.fish()[item.catch.species].name)+" • %.2f kg • " % float(item.catch.kg)+str(C.fish()[item.catch.species].rarity),16)
   var id=str(item.catch.id);f.button(r,"Release • free cargo slot",func():release_cargo(id);open_menu(kind))
 game.fishing.fit_panel(panel,Vector2(900,640))
 preload("res://scripts/touch_list_scroll.gd").attach(scroll)
func draw_chart(c:Control)->void:
 var size=Vector2(minf(800,c.size.x),300);c.draw_rect(Rect2(Vector2.ZERO,size),Color('#13384d'));var scale_xy=size/world_size()
 if route=="coast":
  for band in CURRENT_BANDS:c.draw_rect(Rect2(Vector2(band-500,0)*scale_xy,Vector2(1000,world_size().y)*scale_xy),Color('#64b4bd',.13))
 var chart_step=2000 if route=="coast" else 1000
 for x in range(0,int(world_size().x),chart_step):
  for y in range(0,int(world_size().y),chart_step):
   var world_point=Vector2(x+500,y+500);var p=world_point*scale_xy;var direction=current_at(world_point).normalized()*11
   c.draw_line(p,p+direction,Color('#547e8f'),1);c.draw_line(p+direction,p+direction*.6+direction.orthogonal()*.3,Color('#547e8f'),1)
 for isle in islands():
  if str(isle.name)=="Night Island" and island_found_night!=night_number():continue
  if night():c.draw_circle(isle.p*scale_xy,3,Color('#b5b894'))
  else:
   var outline=PackedVector2Array()
   for point in ISLES.polygon(isle):outline.append(point*scale_xy)
   c.draw_colored_polygon(outline,Color('#b5b894'))
  c.draw_string(ThemeDB.fallback_font,isle.p*scale_xy+Vector2(8,-9),isle.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#f5e5c4'))
 for rock in rocks():c.draw_circle(rock.p*scale_xy,2,Color('#8b9f9b'))
 for cage in cages:
  var p=Vector2(cage.pos[0],cage.pos[1])*scale_xy;c.draw_circle(p,5,Color('#edb378'))
 c.draw_circle(HOME*scale_xy,6,Color('#f4ce76'));c.draw_circle(boat*scale_xy,5,Color('#ffffff'))
 for id in seen:
  var names={"voyage_lake_reeds":[Vector2(1500,4000),"Reedbanks"],"voyage_lake_islands":[Vector2(6000,4900),"Island narrows"],"voyage_lake_deep":[Vector2(5400,1300),"Deep basin"],"voyage_coast_shoals":[Vector2(2200,5700),"Shoals"],"voyage_coast_kelp":[Vector2(5800,5400),"Kelp"],"voyage_coast_reef":[Vector2(3200,2500),"Reef"],"voyage_coast_channel":[Vector2(7700,3700),"Deep channel"]}
  if names.has(id):c.draw_string(ThemeDB.fallback_font,names[id][0]*scale_xy,names[id][1],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#84d5d2'))
func draw_ground(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.get_viewport_rect().size/game.media.factor()).grow(150)
 c.draw_rect(Rect2(-cam,world_size()),Color('#235065') if route=="lake" else Color('#183b53'))
 # Submerged sandbars and darker channels show depth without revealing every species.
 if route=="coast":
  c.draw_rect(Rect2(Vector2(6500,0)-cam,Vector2(world_size().x-6500,world_size().y)),Color('#102e47'))
  c.draw_rect(Rect2(Vector2(0,0)-cam,Vector2(world_size().x,1700)),Color('#122f48'))
 for x in range(int(view.position.x/120)*120,int(view.end.x),120):
  for y in range(int(view.position.y/120)*120,int(view.end.y),120):
   var seed_value=absi(int(x/120)*73856093 ^ int(y/120)*19349663)
   var p=Vector2(x+posmod(seed_value,71)-35,y+posmod(seed_value/3,77)-38)
   var phase=sin(elapsed*1.2+x*.01+y*.008)*8
   if seed_value%5!=0:c.draw_arc(p-cam+Vector2(phase,0),17+seed_value%23,.12,PI*.7,10,Color('#58828e',.45),1.3)
   if (x/120+y/120)%7==0:
    var flow=current_at(p);var direction=flow.normalized()*(18+flow.length()*.13)
    c.draw_line(p-cam,p+direction-cam,Color('#77a0ac',.3),2);c.draw_line(p+direction-cam,p+direction*.65+direction.orthogonal()*.25-cam,Color('#77a0ac',.3),2)
   if route=="coast" and p.x>4100 and p.x<6500 and p.y>3000 and seed_value%4==0:
    for frond in 3:
     var points=PackedVector2Array()
     for k in 8:points.append(p+Vector2(frond*12+sin(k*.8+elapsed*.4+frond)*9,-k*9)-cam)
     c.draw_polyline(points,Color('#578b75',.5),3)
   elif route=="coast" and p.y>1900 and p.y<3800 and p.x<6500 and seed_value%4==0:
    c.draw_circle(p-cam,28+seed_value%17,Color('#768b80',.28))
    c.draw_arc(p-cam,22,PI,TAU,12,Color('#9c9c81',.3),4)
   elif (route=="lake" and p.x<3300 or route=="coast" and p.y>3800 and p.x<4100) and seed_value%4==0:c.draw_circle(p-cam,45+seed_value%35,Color('#a2ab80',.1))
   if (x/120*7+y/120*3)%19==0:
    for i in 4:c.draw_line(p+Vector2(i*13,i%2*9)-cam,p+Vector2(i*13+10,i%2*9+3)-cam,Color('#9bbcae',.28),4)
   if route=="lake" and seed_value%6==0:
    if p.x<3300:
     for stalk in 5:
      var at=p+Vector2(stalk*9,stalk%2*7)-cam
      c.draw_line(at,at+Vector2(sin(elapsed*.5+stalk)*5,-42-stalk%3*7),Color('#779b6f',.6),2)
      c.draw_line(at+Vector2(1,-30),at+Vector2(1,-44),Color('#b7a979',.7),4)
    else:
     c.draw_circle(p-cam,14,Color('#78a18c',.3));c.draw_arc(p-cam,10,.3,5.8,12,Color('#a2bb98',.4),2)
 # A visible mainland shore keeps the destination recognisably coastal.
 var shore=PackedVector2Array([Vector2(-cam.x,-cam.y),Vector2(460-cam.x,-cam.y)])
 for y in range(0,int(world_size().y)+201,160):shore.append(Vector2(430+sin(y*.003)*75,y)-cam)
 shore.append(Vector2(0,world_size().y)-cam);c.draw_colored_polygon(shore,Color('#b8b185'));c.draw_polyline(shore,Color('#6f9a98'),14)
 var inland=PackedVector2Array([Vector2(-cam.x,-cam.y),Vector2(280-cam.x,-cam.y)])
 for y in range(0,int(world_size().y)+201,220):inland.append(Vector2(250+sin(y*.003)*65,y)-cam)
 inland.append(Vector2(0,world_size().y)-cam);c.draw_colored_polygon(inland,Color('#4b705b'))
 surf.draw_on(c,cam)
 debris.draw_on(c,cam)
 for rock in rocks():
  if not view.has_point(rock.p):continue
  c.draw_circle(rock.p-cam,float(rock.r)+12,Color('#50747c'));c.draw_circle(rock.p-cam,float(rock.r),Color('#69797c'));c.draw_arc(rock.p-cam,float(rock.r)+20,0,TAU,22,Color('#b3c6c3'),3)
 for isle in islands():
  if not view.intersects(Rect2(isle.p-Vector2.ONE*(float(isle.r)+40),Vector2.ONE*float(isle.r)*2+Vector2(80,80))):continue
  var p:Vector2=isle.p-cam
  for layer in [{"inset":-18.0,"color":"#63918e"},{"inset":0.0,"color":"#c8bc8b"},{"inset":52.0,"color":"#5c7862"}]:
   var outline=PackedVector2Array()
   for point in ISLES.polygon(isle,float(layer.inset)):outline.append(point-cam)
   c.draw_colored_polygon(outline,Color(layer.color))
  for j in 9:
   var q=p+Vector2.from_angle(j*2.4)*(ISLES.radius(isle,j*2.4)*.64);c.draw_circle(q,40,Color('#3c5d51'));c.draw_circle(q-Vector2(0,14),32,Color('#6b8767'))
  c.draw_string(ThemeDB.fallback_font,p-Vector2(95,float(isle.r)+35),str(isle.name),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color('#f3e5bf'))
  for j in 22:
   var angle=j*2.399;var at=p+Vector2.from_angle(angle)*(ISLES.radius(isle,angle)-29-j%3*13)
   c.draw_circle(at,4+j%4*2,Color('#a19f84'))
   if j%4==0:c.draw_arc(at,11,.2,PI,8,Color('#ede0af'),2)
  for j in 6:
   var at=p+Vector2.from_angle(j*2.1+1)*ISLES.radius(isle,j*2.1+1)*.52
   c.draw_line(at+Vector2(0,13),at-Vector2(0,35),Color('#766a4e'),7)
   for crown in 4:c.draw_circle(at+Vector2.from_angle(crown*1.8)*24-Vector2(0,33),19,Color('#719062') if j%2 else Color('#597b5d'))
  var trail=PackedVector2Array()
  for j in 30:
   var a=.3+j/29.0*1.9;trail.append(p+Vector2.from_angle(a)*(ISLES.radius(isle,a)-105))
  c.draw_polyline(trail,Color('#b7b080',.6),14)
  ISLES.draw_details(c,isle,cam)
  if str(isle.name)=="Night Island":c.draw_circle(p,210,Color('#305a70'));c.draw_arc(p,216,0,TAU,70,Color('#a0bac1'),8)
 var hp=HOME-cam
 c.draw_rect(Rect2(hp-Vector2(230,95),Vector2(150,190)),Color('#9d8059'))
 for j in 13:c.draw_line(hp+Vector2(-230+j*12,-95),hp+Vector2(-230+j*12,95),Color('#5b5043'),2)
 c.draw_string(ThemeDB.fallback_font,hp-Vector2(270,120),'HOME HARBOUR • RETURN HERE',HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color('#f2d296'))
 for cage in cages:
  var p=Vector2(cage.pos[0],cage.pos[1])-cam
  if not view.has_point(p+cam):continue
  c.draw_circle(p,12,Color('#edb378'));c.draw_line(p,p-Vector2(0,25),Color('#c9d5c5'),2);c.draw_string(ThemeDB.fallback_font,p+Vector2(16,0),'READY' if elapsed>=float(cage.ready) else '%ds' % ceili(float(cage.ready)-elapsed),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color('#f7d4a2'))
 draw_landmarks(c,cam,view)
 draw_boat(c,cam)
func draw_landmarks(c:Node2D,cam:Vector2,view:Rect2)->void:
 var sites=[Vector2(1750,3200),Vector2(3850,2100),Vector2(6500,4400),Vector2(5700,1900)] if route=="lake" else [Vector2(3900,5200),Vector2(6000,2100),Vector2(8650,6100),Vector2(11300,5500),Vector2(12600,8500),Vector2(14500,2800),Vector2(17200,6900),Vector2(20400,12300),Vector2(24100,4500),Vector2(25300,16000),Vector2(13400,14700),Vector2(18200,17400)]
 for i in sites.size():
  var world:Vector2=sites[i]
  if not view.grow(260).has_point(world):continue
  var q=world-cam
  c.draw_circle(q,170,Color('#b0ba89',.10))
  if i%3==0:
   # A submerged ferry/wreck: ribs, broken mast and deck planking.
   var hull_points=PackedVector2Array([q+Vector2(-130,-35),q+Vector2(90,-45),q+Vector2(147,4),q+Vector2(95,40),q+Vector2(-130,32)])
   c.draw_colored_polygon(hull_points,Color('#6f7770',.55))
   for j in 9:c.draw_line(q+Vector2(-110+j*27,-36),q+Vector2(-110+j*27,32),Color('#b1a583',.55),4)
   c.draw_line(q+Vector2(-25,10),q+Vector2(35,-110),Color('#b6ad8b',.6),7)
   c.draw_line(q+Vector2(35,-110),q+Vector2(94,-58),Color('#b6ad8b',.4),3)
   c.draw_polyline(PackedVector2Array([q+Vector2(-132,-35),q+Vector2(90,-45),q+Vector2(147,4),q+Vector2(95,40),q+Vector2(-132,32)]),Color('#a4a88c',.7),5)
   for plank in 7:
    var at=q+Vector2(-104+plank*30,60+plank%3*17)
    c.draw_line(at,at+Vector2(25,-8),Color('#a0a58a',.45),5)
   c.draw_circle(q+Vector2(48,3),13,Color('#273e4b',.55))
   var anchor=q+Vector2(-178,44)
   c.draw_line(anchor,anchor+Vector2(10,-45),Color('#96aaa2',.7),4)
   c.draw_arc(anchor,22,0,PI,12,Color('#96aaa2',.7),4)
  elif i%3==1:
   # Coral/reed beds with layered branching silhouettes and stone shelves.
   for j in 12:
    var at=q+Vector2.from_angle(j*2.4)*float(40+j*9)
    c.draw_circle(at,19+j%4*7,Color('#829784',.4))
    c.draw_line(at,at+Vector2(0,-44-j%3*14),Color('#90b19a',.7),4)
    c.draw_line(at+Vector2(0,-25),at+Vector2(-19,-39),Color('#90b19a',.7),3)
    c.draw_line(at+Vector2(0,-34),at+Vector2(20,-52),Color('#90b19a',.7),3)
  else:
   for j in 7:
    var at=q+Vector2((j-3)*43,sin(j)*35)
    c.draw_circle(at,24,Color('#536b73',.7));c.draw_arc(at,24,PI,TAU,12,Color('#b5b89c',.5),3)
   c.draw_arc(q-Vector2(0,15),122,PI,TAU,28,Color('#8a9d94',.55),13)
func draw_boat(c:Node2D,cam:Vector2)->void:
 var p=boat-cam;var dir=Vector2.from_angle(facing);var side=dir.orthogonal()
 preload("res://scripts/marina_art250.gd").boat(c,"skiff_amber",p+dir*5.5,Vector2(58,113),facing+PI*.5,Color.WHITE if impact<=0 else Color("#efb49b"))
 if not anchored:
  c.draw_line(p-dir*30+side*32,p-dir*65+side*49,Color('#b2aa89'),4);c.draw_line(p-dir*30-side*32,p-dir*65-side*49,Color('#b2aa89'),4)
  c.draw_arc(p-dir*61,28,facing+1.9,facing+4.4,12,Color('#a8c6cb',.4),2)
 var lantern=p+dir*30;c.draw_circle(lantern,7,Color('#ffe2a0'));c.draw_line(lantern,lantern-Vector2(0,20),Color('#433f38'),3)
 if not ashore:
  var sprite=str(game.hero.get("sprite",game.selected_character));var tex=game.art.get(sprite+"_idle",game.art.get(sprite+"_0"))
  if tex!=null:c.draw_texture_rect(tex,preload("res://scripts/hero_visual_scale.gd").apply(sprite,Rect2(p-dir*8-Vector2(14,27),Vector2(28,33))),false)
  else:c.draw_circle(p-dir*7,11,Color('#584c62'));c.draw_circle(p-dir*7-Vector2(0,8),7,Color('#e5c29a'))
 if anchored:c.draw_string(ThemeDB.fallback_font,p+Vector2(-30,65),'ANCHORED',HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color('#e4dfc7'))
func lighting_state()->Dictionary:
 var hour=float(context().hour);var dark=hour>=20 or hour<6
 # Dawn fades gradually after 06:00; dusk gathers before 20:00. Anchor state is irrelevant.
 var dusk=clampf((hour-19)/1.0,0,1) if hour>=12 else clampf((7-hour)/1.0,0,1)
 var weather=str(context().weather);var alpha=maxf(.998 if dark else .998*dusk,.32 if weather=="Storm" else .18 if weather=="Mist" else 0)
 return {"night":dark,"alpha":alpha,"radius":165.0 if dark or dusk>0 else 420.0}
func draw_lighting(c:Node2D,cam:Vector2)->void:
 var state=lighting_state();var dark=bool(state.night);var weather=str(context().weather);var alpha=float(state.alpha)
 if alpha>0:
  var center=boat-cam;var radius=float(state.radius)
  # One complete screen texture avoids holes between radial polygons at camera/zoom changes.
  var key=str(c.VIEW)+str(Vector2(roundf(center.x/4)*4,roundf(center.y/4)*4))+str(snappedf(alpha,.02))+str(radius)
  if darkness_image==null:darkness_image=Image.create(64,36,false,Image.FORMAT_RGBA8)
  if key!=darkness_key:
   darkness_key=key;darkness_builds+=1
   for y in 36:
    for x in 64:
     var point=Vector2((x+.5)/64*c.VIEW.x,(y+.5)/36*c.VIEW.y)
     var shade=alpha*smoothstep(radius*.5,radius*1.05,point.distance_to(center))
     darkness_image.set_pixel(x,y,Color(0,0,.002,shade))
   var softened=darkness_image.duplicate();softened.resize(512,288,Image.INTERPOLATE_BILINEAR)
   if darkness_texture==null:darkness_texture=ImageTexture.create_from_image(softened)
   else:darkness_texture.update(softened)
  c.draw_texture_rect(darkness_texture,Rect2(Vector2.ZERO,c.VIEW),false)
  if dark:c.draw_circle(center,68,Color(1,.78,.32,.035))
 if weather in ["Rain","Storm"]:
  for i in 45:
   var p=Vector2(fposmod(i*173+elapsed*180,game.VIEW.x),fposmod(i*241+elapsed*440,game.VIEW.y));c.draw_line(p,p+Vector2(-8,23),Color('#b5d8e0',.35),1.5)
func draw_pier(c:Node2D,cam:Vector2)->void:
 preload("res://scripts/town_marina.gd").draw(c,cam)
static func valid_state(v:Variant)->bool:return preload("res://scripts/fishing_records.gd").valid_voyage(v)
