extends Node
## Data-driven expedition; host owns progress, enemy encounters and interaction.
var remote_golem_warnings:Array=[]
var highlands=preload("res://scripts/quest_highlands.gd").new()
var adventure:Node
var active:=false
var data:Dictionary={}
var states:Dictionary={}
var props:Array=[]
var buckets:Dictionary={}
var grid:AStarGrid2D
var clock:=0.0
var initialized:=false
var spawned:Dictionary={}
var debounce:Dictionary={}
var notice:=""
var notice_time:=0.0
var journal:=false
var journal_scroll:=0
var nav_cache:Dictionary={}
const CAVES=[Rect2(200,7400,3000,1800),Rect2(5300,7500,1700,1400),Rect2(7800,7500,1500,1400),Rect2(6600,9100,1600,1300),Rect2(8100,9500,1200,950),Rect2(6800,8050,1200,260),Rect2(6550,8700,260,650),Rect2(7550,8800,260,650),Rect2(7800,9700,500,260)]
const ROADS=[Vector2(1400,1800),Vector2(3400,1750),Vector2(4650,3650),Vector2(4900,3700),Vector2(5700,3700),Vector2(7800,4900),Vector2(7800,1900),Vector2(6800,1900),Vector2(6000,1250),Vector2(5700,900),Vector2(4900,900),Vector2(1400,1800)]
const NPC_TEXTURES={"quest_edda":preload("res://assets/quest_edda.png"),"quest_orrin":preload("res://assets/quest_orrin.png"),"quest_sable":preload("res://assets/quest_sable.png")}
var npc_art:Dictionary={}
var cottages:Array[Texture2D]=[preload("res://assets/quest_cottage0.png"),preload("res://assets/quest_cottage1.png"),preload("res://assets/quest_cottage2.png")]
var heal_tick:=0.0
var cave_texture:Texture2D=preload("res://assets/moonburrow_cave.png")
func v(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func save_path()->String:return "user://fx_quests_"+str(data.get("id","wayfarer"))+("_party" if adventure.arcade else "_solo")+".json"
func setup(id:String)->void:
 active=false;remote_golem_warnings.clear();states.clear();props.clear();buckets.clear();spawned.clear();debounce.clear();nav_cache.clear();grid=null;initialized=false;clock=0;notice_time=0;journal=false
 var region:Dictionary=adventure.game.regions.get(id,{}) if adventure.arcade else adventure.game.region
 var path:=str(region.get("quest_campaign",""))
 if path.is_empty():return
 data=JSON.parse_string(FileAccess.get_file_as_string(path));active=true
 npc_art.clear()
 for npc in data.get("npcs",[]):
  var sprite_path:="res://assets/"+str(npc.get("sprite","quest_edda"))+".png"
  npc_art[str(npc.id)]=load(sprite_path) if ResourceLoader.exists(sprite_path) else NPC_TEXTURES.quest_edda
 if adventure.authoritative():
  var stored:Variant=preload("res://scripts/profile_store.gd").read(save_path())
  if stored is Dictionary and int(stored.get("version",0))==int(data.get("version",1)):states=stored.get("states",{})
 for quest in data.get("quests",[]):
  var key:=str(quest.id)
  if not states.has(key):states[key]={"accepted":false,"stage":0,"done":false,"targets":[]}
  states[key].stage=clampi(int(states[key].get("stage",0)),0,quest.stages.size()-1)
  if bool(states[key].get("done",false)) and adventure.game.get("legacy")!=null:adventure.game.legacy.quest_done(key)
 var random:=RandomNumberGenerator.new();random.seed=42042
 var protected:Array=[v(data.spawn),Vector2(1800,2400)]
 for fishing_spot in preload("res://scripts/fishing_catalog.gd").spots("wayfarer"):protected.append(v(fishing_spot.bank))
 for npc in data.npcs:protected.append(v(npc.pos))
 for route in data.routes:protected.append(v(route.pos));protected.append(v(route.end));protected.append(v(route.end)+Vector2(0,100))
 for quest in data.quests:
  for stage in quest.stages:
   for target in stage.get("targets",[]):protected.append(v(target.pos))
   for foe in stage.get("encounters",[]):protected.append(v(foe.pos))
 for n in 500:
  var point:=Vector2(random.randf_range(160,9700),random.randf_range(180,6250))
  if not terrain(point) or point.distance_to(Vector2(1500,1900))<900 or point.distance_to(Vector2(4650,3650))<550:continue
  var blocked:=false
  for marker in protected:
   if point.distance_to(marker)<150:blocked=true;break
  for k in ROADS.size()-1:
   if Geometry2D.get_closest_point_to_segment(point,ROADS[k],ROADS[k+1]).distance_to(point)<170:blocked=true;break
  if blocked:continue
  var prop:Dictionary={"pos":point,"radius":40.0 if n%4 else 24.0,"kind":"tree" if n%4 else "stone"}
  props.append(prop)
  for x in range(floori((point.x-65)/128),floori((point.x+65)/128)+1):
   for y in range(floori((point.y-65)/128),floori((point.y+65)/128)+1):
    var key:=Vector2i(x,y)
    if not buckets.has(key):buckets[key]=[]
    buckets[key].append(prop)
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,320,220);grid.cell_size=Vector2(50,50);grid.offset=Vector2(25,25);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 for x in 320:
  for y in 220:grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*50+25,y*50+25)))
func terrain(point:Vector2)->bool:
 if point.x>=9900:return highlands.terrain(point)
 if point.y<6500:
  if point.x<60 or point.x>9900 or point.y<60:return false
  if point.x>5100 and point.x<5500:
   for y in [900,3700,5700]:
    if absf(point.y-y)<135:return true
   return false
  return true
 for room in CAVES:
  if room.grow(-22).has_point(point):return true
 return false
func can_stand(point:Vector2)->bool:
 if not terrain(point):return false
 for center in [Vector2(1450,1200),Vector2(1900,1790),Vector2(1000,2070),Vector2(4650,3420)]:
  if Rect2(center+Vector2(-115,-75),Vector2(230,145)).has_point(point):return false
 for prop in buckets.get(Vector2i(floori(point.x/128),floori(point.y/128)),[]):
  if point.distance_to(prop.pos)<float(prop.radius)+18:return false
 return true
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 target=adventure.combat.fern.redirect(enemy,target)
 var origin:Vector2=enemy.pos
 if absf(origin.y-target.y)>3000:return Vector2.ZERO
 if adventure.combat.path_clear(origin,target):
  return adventure.combat.ranged_direction(enemy,target) if ranged else (target-origin).normalized()
 var key:=int(enemy.uid);var cached:Dictionary=nav_cache.get(key,{})
 if clock>float(cached.get("until",0)):
  var a:=Vector2i(floori(origin.x/50),floori(origin.y/50));var b:=Vector2i(floori(target.x/50),floori(target.y/50))
  var path:=PackedVector2Array()
  if grid.is_in_boundsv(a) and grid.is_in_boundsv(b) and not grid.is_point_solid(a) and not grid.is_point_solid(b):path=grid.get_point_path(a,b)
  cached={"until":clock+.4,"path":path};nav_cache[key]=cached
 var path:PackedVector2Array=cached.get("path",PackedVector2Array())
 for point in path:
  if origin.distance_to(point)>40:return (point-origin).normalized()
 return Vector2.ZERO
func save()->void:
 if not active or not adventure.authoritative() or preload("res://scripts/profile_store.gd").progression_blocked():return
 preload("res://scripts/profile_store.gd").write(save_path(),{"version":data.get("version",1),"states":states})
func stage_of(quest:Dictionary)->Dictionary:return quest.stages[int(states[str(quest.id)].stage)]
func unlocked(quest:Dictionary)->bool:
 for key in quest.get("requires",[]):
  if not bool(states.get(str(key),{}).get("done",false)):return false
 return true
func say(text:String)->void:notice=text;notice_time=9
func encounter(quest:Dictionary)->void:
 var state:Dictionary=states[str(quest.id)];var token:=str(quest.id)+":"+str(state.stage)
 if spawned.has(token):return
 spawned[token]=true
 var definitions:Dictionary=adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
 for entry in stage_of(quest).get("encounters",[]):
  adventure.spawn(str(entry.type),v(entry.pos),float(entry.get("hp",definitions.get(str(entry.type),{}).get("health",90))),false)
  var foe:Dictionary=adventure.foes()[-1];foe["quest_group"]=token
func advance(quest:Dictionary)->void:
 var state:Dictionary=states[str(quest.id)];state.stage=mini(int(state.stage)+1,quest.stages.size()-1);state.targets=[]
 encounter(quest);save();say(str(quest.title)+": "+str(stage_of(quest).text))
func reward(quest:Dictionary)->void:
 var state:Dictionary=states[str(quest.id)]
 if bool(state.done):return
 state.done=true
 if adventure.game.get("legacy")!=null:adventure.game.legacy.quest_done(str(quest.id))
 if adventure.arcade:
  for id in adventure.points():
   adventure.game.gold[id]=int(adventure.game.gold.get(id,0))+int(quest.get("reward_gold",24))
   adventure.game.levels[id]=maxi(int(adventure.game.levels.get(id,1)),mini(10,6+completed_count()))
 else:
  adventure.game.gold+=int(quest.get("reward_gold",24));adventure.game.bounty_earned+=int(quest.get("reward_gold",24))
  adventure.game.level=maxi(adventure.game.level,mini(10,6+completed_count()));adventure.game.highest_level=maxi(adventure.game.highest_level,adventure.game.level)
  adventure.game.experience=maxi(adventure.game.experience,(adventure.game.level-1)*40)
 say(str(quest.title)+" complete! +"+str(quest.get("reward_gold",24))+" CC. "+("All quests finished. Return to the village waystone." if completed_count()==data.quests.size() else "New hero abilities unlocked. Speak to the villagers."));save()
func completed_count()->int:
 var count:=0
 for state in states.values():
  if bool(state.get("done",false)):count+=1
 return count
func step(delta:float)->void:
 if not active:return
 clock+=delta;step_golems(delta);notice_time=maxf(0,notice_time-delta);heal_tick-=delta
 if heal_tick<=0:
  heal_tick=1
  for id in adventure.points():
   var point:Vector2=adventure.points()[id]
   if not adventure.alive(str(id)) or point.distance_to(Vector2(1700,2250))>90:continue
   var safe:=true
   for foe in adventure.foes():
    if (foe.pos as Vector2).distance_to(point)<450:safe=false;break
   if not safe:continue
   if adventure.arcade:adventure.game.health[id]=mini(adventure.game._max_hp(str(id)),int(adventure.game.health[id])+4)
   else:adventure.game.health=minf(adventure.game.max_health(),adventure.game.health+4)
 if not initialized:
  initialized=true
  if adventure.arcade:
   for id in adventure.points():adventure.game.levels[id]=maxi(mini(10,3+completed_count()*2),int(adventure.game.levels.get(id,1)))
  else:adventure.game.level=maxi(mini(10,3+completed_count()*2),adventure.game.level);adventure.game.highest_level=adventure.game.level;adventure.game.experience=maxi(adventure.game.experience,(adventure.game.level-1)*40)
  for quest in data.quests:
   if bool(states[str(quest.id)].accepted) and not bool(states[str(quest.id)].done):encounter(quest)
  for n in 20:
   var point:=Vector2(2900+n%5*1400,2700+n/5*680)
   if can_stand(point):adventure.spawn("briar_bandit" if n%3 else "glowcap_slinger",point,90,false)
  say("WAYFARER WILDS • Speak to Edda, Orrin and Sable in Willowrest. Q / Journal shows your quests.")
 for quest in data.quests:
  var state:Dictionary=states[str(quest.id)]
  if not bool(state.accepted) or bool(state.done):continue
  var stage:Dictionary=stage_of(quest)
  if str(stage.type)=="clear":
   var remaining:=0;var token:=str(quest.id)+":"+str(state.stage)
   for foe in adventure.foes():
    if str(foe.get("quest_group",""))==token:remaining+=1
   if spawned.has(token) and remaining==0:advance(quest)
func routes()->Array:
 var result:Array=[]
 for route in data.get("routes",[]):
  result.append({"name":route.name,"pos":v(route.pos),"end":v(route.end)+Vector2(0,100)})
  result.append({"name":"Return to Wayfarer Wilds","pos":v(route.end),"end":v(route.pos)+Vector2(0,100)})
 return result
func interact(id:String)->bool:
 if not adventure.alive(id) or clock<float(debounce.get(id,0)):return false
 var point:Vector2=adventure.points().get(id,Vector2.ZERO)
 debounce[id]=clock+.4
 if point.distance_to(v(data.spawn))<100:
  save()
  if adventure.arcade:adventure.game.end_match("Wayfarer expedition • "+str(completed_count())+"/"+str(data.quests.size())+" quests complete. Host progress saved.")
  elif completed_count()==data.quests.size():adventure.game.finish_run(true)
  else:adventure.game.menu="";adventure.game.enter_region("town")
  return true
 for route in routes():
  if point.distance_to(route.pos)<115:adventure.teleport(id,route.end);debounce[id]=clock+1;return true
 for npc in data.npcs:
  if point.distance_to(v(npc.pos))>115:continue
  var choices:Array=[]
  for quest in data.quests:
   if str(quest.npc)==str(npc.id) and not bool(states[str(quest.id)].done):choices.append(quest)
  if choices.is_empty():say(str(npc.name)+": Thank you. You changed this place.");return true
  for accepted in [true,false]:
   for quest in choices:
    var state:Dictionary=states[str(quest.id)]
    if bool(state.accepted)!=accepted or not unlocked(quest):continue
    if not bool(state.accepted):state.accepted=true;encounter(quest);save();say(str(npc.name)+": "+str(quest.offer));return true
    if str(stage_of(quest).type)=="report":reward(quest)
    else:say(str(quest.title)+": "+str(stage_of(quest).text))
    return true
  say(str(npc.name)+": Finish the quests marked as prerequisites in your journal first.");return true
 for quest in data.quests:
  var state:Dictionary=states[str(quest.id)]
  if not bool(state.accepted) or bool(state.done):continue
  var stage:Dictionary=stage_of(quest)
  if str(stage.type) not in ["collect","switches","visit"]:continue
  for target in stage.get("targets",[]):
   if point.distance_to(v(target.pos))>105 or state.targets.has(str(target.id)):continue
   var guarded:=false
   for foe in adventure.foes():
    if (foe.pos as Vector2).distance_to(v(target.pos))<200:guarded=true;break
   if guarded:say("Clear nearby enemies before interacting with "+str(target.name)+".");return true
   state.targets.append(str(target.id));save();say(str(target.name)+" recovered • "+str(state.targets.size())+"/"+str(stage.targets.size()))
   if state.targets.size()==stage.targets.size():advance(quest)
   return true
 return false
func snapshot()->Dictionary:return {"golem_warnings":golem_warnings(),"states":states,"notice":notice,"notice_time":notice_time,"clock":clock}
func receive(packet:Dictionary)->void:
 remote_golem_warnings=packet.get("golem_warnings",[]);states=packet.get("states",states);notice=str(packet.get("notice",""));notice_time=float(packet.get("notice_time",0));clock=float(packet.get("clock",clock))
 if adventure.game.get("legacy")!=null:
  for id in states:
   if bool(states[id].get("done",false)):adventure.game.legacy.quest_done(str(id))
func texture(canvas:Node2D,name:String,point:Vector2,size:Vector2)->void:
 var art:Dictionary=adventure.game.art
 if art.has(name):canvas.draw_texture_rect(art[name],Rect2(point-size*.5,size),false)
func label(canvas:Node2D,point:Vector2,text:String,color:=Color("#e8dfbb"),size:=18)->void:canvas.draw_string(ThemeDB.fallback_font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func house(canvas:Node2D,point:Vector2,roof:Color)->void:
 var index:=0 if roof.b>roof.r else 1 if roof.r>roof.g else 2
 canvas.draw_texture_rect(cottages[index],Rect2(point-Vector2(128,155),Vector2(256,240)),false)
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 var bounds:=Rect2(camera-Vector2(200,200),adventure.game.VIEW+Vector2(400,400))
 if camera.y<6500:
  canvas.draw_rect(Rect2(Vector2(5100,0)-camera,Vector2(400,6500)),Color("#376a78"))
  for y in [900,3700,5700]:
   canvas.draw_rect(Rect2(Vector2(5070,y-145)-camera,Vector2(460,290)),Color("#a08b60"))
   for k in 9:canvas.draw_line(Vector2(5080+k*54,y-145)-camera,Vector2(5080+k*54,y+145)-camera,Color("#675d4c"),3)
  for x in range(floori(camera.x/64),ceili((camera.x+adventure.game.VIEW.x)/64)+1):
   for y in range(floori(camera.y/64),ceili((camera.y+adventure.game.VIEW.y)/64)+1):
    var point:=Vector2(x*64+32,y*64+32);var road:=point.distance_to(Vector2(1500,1900))<430
    for n in ROADS.size()-1:
     if Geometry2D.get_closest_point_to_segment(point,ROADS[n],ROADS[n+1]).distance_to(point)<65:road=true;break
    if road and terrain(point):texture(canvas,"path",point-camera,Vector2(64,64))
 else:
  canvas.draw_rect(Rect2(Vector2.ZERO,adventure.game.VIEW),Color("#182c30"))
  for x in range(floori(camera.x/64),ceili((camera.x+adventure.game.VIEW.x)/64)+1):
   for y in range(floori(camera.y/64),ceili((camera.y+adventure.game.VIEW.y)/64)+1):
    var point:=Vector2(x*64+32,y*64+32)
    if not terrain(point):continue
    var top:=point-Vector2(32,32)-camera
    canvas.draw_texture_rect(cave_texture,Rect2(top,Vector2(64,64)),false)
    for side in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
     if not terrain(point+side*64):canvas.draw_line(top+Vector2(32,32)+side*32-side.orthogonal()*32,top+Vector2(32,32)+side*32+side.orthogonal()*32,Color("#67907d"),6)
 highlands.draw_on(canvas,camera,clock,bool(states.get("skyworks",{}).get("done",false)))
 for prop in props:
  if not bounds.has_point(prop.pos):continue
  texture(canvas,"tree" if str(prop.kind)=="tree" else "oath_stone",prop.pos-camera-Vector2(0,40),Vector2(110,145) if str(prop.kind)=="tree" else Vector2(68,70))
 for entry in [{"pos":Vector2(1450,1200),"name":"LANTERNWRIGHT","roof":Color("#577781")},{"pos":Vector2(1900,1790),"name":"WILLOWREST","roof":Color("#7f6249")},{"pos":Vector2(1000,2070),"name":"PATHFINDER LODGE","roof":Color("#567654")},{"pos":Vector2(4650,3420),"name":"MOSSWHEEL MILL","roof":Color("#687884")}]:
  if bounds.has_point(entry.pos):house(canvas,entry.pos-camera,entry.roof);label(canvas,entry.pos-camera+Vector2(-100,95),entry.name)
 if bounds.has_point(Vector2(4600,3650)):
  var wheel:=Vector2(4600,3560)-camera;canvas.draw_circle(wheel,64,Color("#725e42"));canvas.draw_arc(wheel,61,0,TAU,32,Color("#d3b982"),6)
  for n in 8:
   var angle:float=TAU*n/8+(clock*.4 if int(states.get("mill",{}).get("stage",0))>0 else 0);canvas.draw_line(wheel,wheel+Vector2.from_angle(angle)*60,Color("#bd9b69"),5)
 for entry in [{"pos":Vector2(3400,1750),"label":"ABANDONED CAMP"},{"pos":Vector2(6000,1250),"label":"FALLEN WAYSHRINE"},{"pos":Vector2(2600,8300),"label":"GLOWROOT GROTTO"},{"pos":Vector2(8550,10000),"label":"THE HEART CHAMBER"}]:
  if bounds.has_point(entry.pos):
   for n in 6:texture(canvas,"oath_stone",entry.pos+Vector2.from_angle(n*TAU/6)*130-camera,Vector2(55,60))
   label(canvas,entry.pos-camera+Vector2(-110,-165),entry.label,Color("#acd4ba"))
 # Farm plots, lantern-lined roads, river reeds and ruin masonry add authored landmarks.
 for row in 4:
  for col in 8:
   var crop:=Vector2(2100+col*38,2150+row*38)-camera
   if bounds.has_point(crop+camera):canvas.draw_rect(Rect2(crop,Vector2(26,26)),Color("#615d40"));canvas.draw_line(crop+Vector2(6,22),crop+Vector2(13,4),Color("#b4bc70"),3)
 for n in 28:
  var point:Vector2=ROADS[n%(ROADS.size()-1)].lerp(ROADS[n%(ROADS.size()-1)+1],.25+floorf(n/12.0)*.2)+Vector2(0,-70)
  if bounds.has_point(point):
   var pole:Vector2=point-camera;canvas.draw_line(pole,pole-Vector2(0,42),Color("#5e6550"),4);canvas.draw_rect(Rect2(pole-Vector2(7,44),Vector2(14,16)),Color("#eadc97"));canvas.draw_circle(pole-Vector2(0,35),16,Color(1,.85,.4,.08))
 for n in 40:
  var point:=Vector2(5060 if n%2 else 5540,120+n*155)
  if bounds.has_point(point) and absf(point.y-900)>180 and absf(point.y-3700)>180 and absf(point.y-5700)>180:texture(canvas,"marsh_reeds",point-camera,Vector2(75,60))
 for n in 12:
  var point:=Vector2(700+n%4*340,7650+n/4*480)
  if bounds.has_point(point):canvas.draw_circle(point-camera,18,Color(.4,.8,.7,.1));canvas.draw_arc(point-camera,10,PI,TAU,16,Color("#8bd7b7"),5)
 for center in [Vector2(6500,7800),Vector2(8500,8100),Vector2(7400,9500),Vector2(8550,10000)]:
  if bounds.has_point(center):
   canvas.draw_arc(center-camera,160,0,TAU,48,Color("#617b6b"),8)
   for n in 8:
    var point:Vector2=center+Vector2.from_angle(TAU*n/8)*180;canvas.draw_line(point-camera,point-camera-Vector2(0,32),Color("#6c8974"),7)
 var trail_end:Vector2=v(data.spawn)-camera
 var trail_start:Vector2=v(data.spawn)+Vector2(-350,-160)-camera
 canvas.draw_line(trail_start,trail_end,Color("#88785a"),90)
 canvas.draw_line(trail_start,trail_end,Color("#b4a076"),68)
 for n in 4:
  var post:Vector2=trail_start.lerp(trail_end,n/4.0)+Vector2(0,-56)
  canvas.draw_line(post,post-Vector2(0,28),Color("#735c43"),5)
 label(canvas,trail_end+Vector2(-110,-65),"CROSSROADS TOWN ←",Color("#f4d9a1"),18)
 var spring:=Vector2(1700,2250)-camera
 if bounds.has_point(spring+camera):
  canvas.draw_circle(spring,48,Color("#65776b"));canvas.draw_circle(spring,38,Color("#699f9e"));canvas.draw_arc(spring,26,clock,clock+TAU*.8,32,Color("#b3e5d9"),3);label(canvas,spring+Vector2(-75,70),"RESTING SPRING",Color("#bde0c9"),15)
 for npc in data.npcs:
  var point:=v(npc.pos)-camera
  if bounds.has_point(v(npc.pos)):
   canvas.draw_texture_rect(npc_art.get(str(npc.id),NPC_TEXTURES.quest_edda),Rect2(point-Vector2(24,62),Vector2(48,72)),false);label(canvas,point+Vector2(-95,35),str(npc.name),Color("#f1ddb0"),16)
   var mark:="+"
   for quest in data.quests:
    if str(quest.npc)!=str(npc.id) or bool(states[str(quest.id)].done):continue
    if not unlocked(quest):mark="-"
    elif bool(states[str(quest.id)].accepted):mark="?" if str(stage_of(quest).type)=="report" else "..."
    else:mark="!"
    break
   label(canvas,point+Vector2(-6,-80),mark,Color("#ffe392"),26)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 for warning in golem_warnings():
  var point:Vector2=v(warning.pos)-camera
  preload("res://scripts/combat_cues.gd").danger(canvas,point,145,float(warning.time),1.0,Color("#c3edf0"))
 var id:=str(adventure.game.my_id) if adventure.arcade else "solo"
 var origin:Vector2=adventure.points().get(id,Vector2.ZERO)
 var hint:=""
 for route in routes():
  var point:Vector2=route.pos-camera
  if not Rect2(Vector2(-150,-150),adventure.game.VIEW+Vector2(300,300)).has_point(point):continue
  canvas.draw_circle(point,65,Color("#233d35"));canvas.draw_arc(point,65,PI,TAU,24,Color("#71977d"),12,true)
  canvas.draw_rect(Rect2(point+Vector2(-43,0),Vector2(86,24)),Color("#998563"));label(canvas,point+Vector2(-110,70),str(route.name))
  if origin.distance_to(route.pos)<115:hint="E / Interact: "+str(route.name)
 for quest in data.quests:
  var state:Dictionary=states.get(str(quest.id),{})
  if not bool(state.get("accepted",false)) or bool(state.get("done",false)):continue
  for target in stage_of(quest).get("targets",[]):
   if state.get("targets",[]).has(str(target.id)):continue
   var point:=v(target.pos)-camera
   if not Rect2(Vector2(-150,-150),adventure.game.VIEW+Vector2(300,300)).has_point(point):continue
   canvas.draw_circle(point,26,Color(.7,.95,.65,.15));canvas.draw_arc(point,26,clock,clock+TAU*.8,24,Color("#c6f5a4"),3,true)
   canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-20),point+Vector2(9,0),point+Vector2(0,18),point+Vector2(-9,0)]),Color("#e4e7a6"));label(canvas,point+Vector2(-70,48),str(target.name),Color("#dfedbb"),16)
   if origin.distance_to(v(target.pos))<105:hint="E / Interact: "+str(target.name)
 for npc in data.npcs:
  if origin.distance_to(v(npc.pos))<115:hint="E / Interact: Talk to "+str(npc.name)
 var stone:=v(data.spawn)-camera;canvas.draw_rect(Rect2(stone-Vector2(16,30),Vector2(32,55)),Color("#91bcb1"));label(canvas,stone+Vector2(-100,50),"WAYSTONE • RETURN TO TOWN",Color("#c5e2d0"),15)
 if origin.distance_to(v(data.spawn))<100:hint="E / Interact: Return to town • quest progress saved"
 if not hint.is_empty():
  if not adventure.arcade:adventure.game.hint=hint
  label(canvas,Vector2(320,adventure.game.VIEW.y-105),hint,Color("#e2f2c8"),18)
func wrapped(canvas:Node2D,text:String,pos:Vector2,width:float,size:=17)->float:
 var line:="";var y:=pos.y;var font:=ThemeDB.fallback_font
 for word in text.split(" "):
  if font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not line.is_empty():label(canvas,Vector2(pos.x,y),line,Color("#e9eddc"),size);y+=23;line=""
  line+=word+" "
 label(canvas,Vector2(pos.x,y),line,Color("#e9eddc"),size);return y+24
func journal_key(code:int)->bool:
 if not active:return false
 if code==KEY_Q:journal=not journal;return true
 if not journal:return false
 if code in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:journal=false;return true
 if code in [KEY_UP,KEY_DOWN]:journal_scroll=clampi(journal_scroll+(-1 if code==KEY_UP else 1),0,maxi(0,data.quests.size()-3));return true
 return false
func target_for(quest:Dictionary)->Vector2:
 var state:Dictionary=states[str(quest.id)];var stage:Dictionary=stage_of(quest)
 for target in stage.get("targets",[]):
  if not state.targets.has(str(target.id)):return v(target.pos)
 if str(stage.type)=="clear":
  var token:=str(quest.id)+":"+str(state.stage)
  for foe in adventure.foes():
   if str(foe.get("quest_group",""))==token:return foe.pos
 for npc in data.npcs:
  if str(npc.id)==str(quest.npc):return v(npc.pos)
 return v(data.spawn)
func draw_hud(canvas:Node2D)->void:
 if not active:return
 var view:Vector2=adventure.game.VIEW;var id:=str(adventure.game.my_id) if adventure.arcade else "solo";var origin:Vector2=adventure.points().get(id,Vector2.ZERO)
 var map:=Rect2(Vector2(view.x-245,185),Vector2(220,130));canvas.draw_rect(map,Color(.05,.12,.13,.9));canvas.draw_rect(map,Color("#b0c4a0"),false,2)
 var underground:=origin.y>6500;var offset:=Vector2(0,7300) if underground else Vector2.ZERO;var span:=Vector2(10000 if underground else 16000,3500 if underground else 6500)
 for npc in data.npcs:
  if not underground:canvas.draw_circle(map.position+(v(npc.pos)-offset)/span*map.size,4,Color("#f5dd97"))
 if underground:
  for room in CAVES:canvas.draw_rect(Rect2(map.position+(room.position-offset)/span*map.size,room.size/span*map.size),Color(.25,.4,.35,.45))
 else:
  canvas.draw_rect(Rect2(map.position+Vector2(5100,0)/span*map.size,Vector2(400,6500)/span*map.size),Color("#416f7c"))
  for floor in highlands.MOUNTAIN+highlands.SKYWORKS:canvas.draw_rect(Rect2(map.position+floor.position/span*map.size,floor.size/span*map.size),Color("#729b99"))
  for n in ROADS.size()-1:canvas.draw_line(map.position+ROADS[n]/span*map.size,map.position+ROADS[n+1]/span*map.size,Color("#9d9771"),1)
 for route in routes():
  if (route.pos.y>6500)==underground:canvas.draw_circle(map.position+(route.pos-offset)/span*map.size,4,Color("#a3bff0"))
 for quest in data.quests:
  if not bool(states[str(quest.id)].accepted) or bool(states[str(quest.id)].done):continue
  for target in stage_of(quest).get("targets",[]):
   if states[str(quest.id)].targets.has(str(target.id)):continue
   var point:=v(target.pos)
   if (point.y>6500)==underground:canvas.draw_circle(map.position+(point-offset)/span*map.size,3,Color("#96e991"))
 for player in adventure.points():
  var point:Vector2=adventure.points()[player]
  if (point.y>6500)==underground:canvas.draw_circle(map.position+(point-offset)/span*map.size,4,Color("#e7fff1"))
 label(canvas,map.position+Vector2(8,-8),"WARRENS" if underground else "WAYFARER WILDS",Color("#d2e2c6"),15)
 var y:=190.0
 if journal:
  canvas.draw_rect(Rect2(Vector2(300,175),Vector2(600,350)),Color(.06,.13,.14,.96));label(canvas,Vector2(320,205),"QUEST JOURNAL • Q / Journal to close",Color("#f1dca6"),22);y=240
 var shown:Array=data.quests.slice(journal_scroll,journal_scroll+3) if journal else data.quests
 for quest in shown:
  var state:Dictionary=states.get(str(quest.id),{})
  var text:=str(quest.title)+": "+("Complete" if bool(state.get("done",false)) else "Speak to its villager" if not bool(state.get("accepted",false)) else str(stage_of(quest).text))
  if not unlocked(quest):text=str(quest.title)+": Requires "+", ".join(quest.get("requires",[]))
  if journal:y=wrapped(canvas,text,Vector2(320,y),550,19)+15
  elif bool(state.get("accepted",false)) and not bool(state.get("done",false)):
   canvas.draw_rect(Rect2(Vector2(24,175),Vector2(590,88)),Color(.04,.12,.12,.85));wrapped(canvas,text,Vector2(38,202),550,17)
   var target:=target_for(quest)
   if (target.y>6500)!=(origin.y>6500):
    var best:=INF;var destination:=target
    for route in routes():
     if (route.pos.y>6500)!=(origin.y>6500):continue
     var cost:float=origin.distance_to(route.pos)+destination.distance_to(route.end)
     if cost<best:best=cost;target=route.pos
   var arrow:=Vector2(590,235);canvas.draw_line(arrow,arrow+(target-origin).normalized()*19,Color("#e8d994"),4,true);label(canvas,Vector2(38,250),"Q / Journal • "+str(completed_count())+"/"+str(data.quests.size())+" quests finished",Color("#d6dfc9"),15);break
 if journal:label(canvas,Vector2(320,500),"Up / Down: scroll quests • Close / Q: return",Color("#b4d0bf"),16)
 if notice_time>0 and not journal:
  canvas.draw_rect(Rect2(Vector2(300,275),Vector2(600,115)),Color(.04,.12,.12,.92));wrapped(canvas,notice,Vector2(316,302),566,17)


func step_golems(delta:float)->void:
 if not adventure.authoritative():return
 for foe in adventure.foes():
  if str(foe.get("type",""))!="summit_golem":continue
  if adventure.combat.stunned(adventure.combat.npc_key(foe)):continue
  foe["ice_cooldown"]=maxf(0,float(foe.get("ice_cooldown",2))-delta)
  if float(foe.get("ice_windup",0))>0:
   foe.ice_windup=maxf(0,float(foe.ice_windup)-delta)
   if float(foe.ice_windup)<=0:
    var center:Vector2=v(foe.ice_center)
    for id in adventure.combat.v59.target_points():
     if adventure.alive(str(id)) and center.distance_to(adventure.combat.v59.target_position(str(id)))<=145 and adventure.combat.path_clear(center,adventure.combat.v59.target_position(str(id))):
      if adventure.arcade:adventure.game._hurt(str(id),26,"enemy","",preload("res://scripts/defeat_credit.gd").resolve(adventure.game,adventure.combat.npc_key(foe),"Ice slam"))
      else:adventure.hit_player(str(id),26,"",preload("res://scripts/defeat_credit.gd").resolve(adventure.game,adventure.combat.npc_key(foe),"Ice slam"))
      adventure.combat.apply_status(adventure.combat.player_key(str(id)),"slow",2,"enemy",.6)
    adventure.combat.visuals.append({"pos":foe.ice_center,"radius":145,"time":.5,"color":"#c2e9f2"})
   continue
  if float(foe.ice_cooldown)>0:continue
  for id in adventure.combat.v59.target_points():
   if adventure.alive(str(id)) and (foe.pos as Vector2).distance_to(adventure.combat.v59.target_position(str(id)))<240:
    foe.ice_windup=.9;foe.ice_center=[foe.pos.x,foe.pos.y];foe.ice_cooldown=5
    break


func golem_warnings()->Array:
 if not adventure.authoritative():return remote_golem_warnings
 var result:Array=[]
 for foe in adventure.foes():
  if str(foe.get("type",""))=="summit_golem" and float(foe.get("ice_windup",0))>0:
   result.append({"pos":foe.ice_center,"time":foe.ice_windup})
 return result
