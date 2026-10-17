extends RefCounted
var game:Node
var active:=false
var wave:=0
var started=false
var moved=false
var attacked=false
var attack_ready=false
var initial_position=Vector2.ZERO
const BEACON=Vector2(470,600)
var timer:=0.0
var defeated:=0
var used:Dictionary={}
var saved_pack:Array=[]
var saved_food:=""
var unlock_queue:Array[String]=[]
func start(id:String)->void:
 if id not in game.manifest.characters.slice(0,9):return
 saved_pack=game.loadout.duplicate();saved_food=game.provisions.packed
 game.selected_character=id;game.save_profile();active=true;wave=0;timer=1;defeated=0;used.clear();unlock_queue.clear();started=false;moved=false;attacked=false;attack_ready=false
 game.start_run(false,"first_steps");game.level=1;game.highest_level=1;game.inventory.clear();game.provisions.packed="";game.enemies.clear();game.boss_spawned=true;game.health=game.max_health();game.menu="";game.message="";game.message_time=0;initial_position=game.position_in_world
func spawn_wave()->void:
 wave+=1
 var count:int=3 if wave==1 else 4 if wave<4 else 1
 for n in count:
  var kind:String="bramble" if wave==1 or n%3!=2 else "archer"
  var point:=Vector2(650+n*110,380 if wave%2 else 780)
  game.enemies.append({"uid":900000+wave*10+n,"pos":point,"hp":190.0 if wave==4 else 30.0+wave*6,"max_hp":190.0 if wave==4 else 30.0+wave*6,"attack_timer":1.5,"secondary_timer":3.0,"windup":0.0,"boss":wave==4,"type":"boss" if wave==4 else kind,"tutorial":true})
 game.health=minf(game.max_health(),game.health+20)
 game.message="";game.message_time=0
func step(delta:float)->void:
 if not active or not game.menu.is_empty():return
 if game.position_in_world.distance_to(initial_position)>5:moved=true
 var held=game.mobile.attacking if game.mobile.enabled else Input.is_action_pressed("primary")
 if not held:attack_ready=true
 if attack_ready and held:attacked=true
 if not started:return
 if not unlock_queue.is_empty():game.presentation.skill_unlock(unlock_queue.pop_front());return
 if game.enemies.is_empty():
  if wave>=4:finish(true);return
  timer-=delta
  if timer<=0:timer=1.6;spawn_wave()
func damage(index:int,amount:float)->void:
 if index<0 or index>=game.enemies.size():return
 var foe:Dictionary=game.enemies[index];var actual:=minf(maxf(0,amount),float(foe.hp))
 game.adventure.combat.feedback.hit(foe.pos,actual)
 game.dealt_damage+=actual;foe.hp=float(foe.hp)-amount;game.enemy_flashes[int(foe.uid)]=.16
 game.add_float_text(foe.pos-Vector2(18,42),"−"+str(int(actual)),Color("#ffe3ae"));game.journey.cue("hit")
 if float(foe.hp)>0:return
 game.enemies.remove_at(index);defeated+=1;game.kills+=1
 var next:int=mini(6,1+int(defeated*.75));var old:int=game.level
 game.level=next;game.highest_level=next;game.experience=defeated*10
 if old<3 and next>=3:unlock_queue.append("secondary")
 if old<5 and next>=5:unlock_queue.append("passive")
 if old<6 and next>=6:unlock_queue.append("special")
 if not unlock_queue.is_empty() and game.menu.is_empty():game.presentation.skill_unlock(unlock_queue.pop_front())

func finish(won:bool,skipped:bool=false)->void:
 if not active:return
 unlock_queue.clear();active=false;game.provisions.packed=saved_food;game.loadout.assign(saved_pack);game.profile["tutorial_seen"]=true;game.save_profile();game.menu="";game.gold=100;game.enter_region("town");game.health=game.max_health()
 game.journey.data.skipped=true;game.journey.save()
 game.message="Welcome to Crossroads! Choose your next adventure from the Adventure board." if won or skipped else "Nice first attempt! You can retry First Steps from the Adventure board."
 game.message_time=8;game.presentation.tutorial_end(won,skipped)
func interact()->bool:
 if started:return false
 game.hint=""
 if game.position_in_world.distance_to(BEACON)<100 and Input.is_action_just_pressed("interact"):
  started=true;timer=.8;game.hint="";game.journey.cue("level")
 # Keep attacks and ordinary exit handling active after the interaction.
 return false
func update_melee(foe:Dictionary,delta:float)->bool:
 if not bool(foe.get("tutorial",false)) or str(foe.type)=="archer":return false
 var reach=110.0 if foe.boss else 63.0
 var duration=1.05 if foe.boss else .72
 var diff:Vector2=game.position_in_world-foe.pos
 foe.attack_timer=maxf(0,float(foe.attack_timer)-delta)
 if game.adventure.combat.stunned(game.adventure.combat.npc_key(foe)):return true
 if float(foe.get("windup",0))>0:
  foe.windup=maxf(0,float(foe.windup)-delta)
  if foe.windup==0:
   foe.strike_flash=.45;foe.strike_direction=foe.get("warning_direction",Vector2.DOWN);foe.attack_timer=2.0 if foe.boss else 1.45
   var relative:Vector2=game.position_in_world-foe.pos
   var aimed=foe.boss or relative.length()<1 or relative.normalized().dot(foe.strike_direction)>.35
   if relative.length()<reach and aimed and game.stealth_time<=0:
    game.take_player_damage(16.0 if foe.boss else 8.0,game.adventure.combat.npc_key(foe),preload("res://scripts/defeat_credit.gd").resolve(game,game.adventure.combat.npc_key(foe),"Telegraphed stomp" if foe.boss else "Telegraphed melee"))
  return true
 if game.stealth_time>0:return true
 if diff.length()<reach*.86 and foe.attack_timer<=0:
  foe.windup=duration;foe.warning_direction=diff.normalized() if diff.length()>0 else Vector2.DOWN
 elif diff.length()>reach*.65:
  game.move_enemy_around_obstacles(foe,diff.normalized()*(82.0 if foe.boss else 68.0)*delta,false)
 return true
func draw_world(c:Node2D,camera:Vector2)->void:
 if not active:return
 if not started:
  var p=BEACON-camera;var pulse=sin(game.visual_clock*3)*.5+.5
  c.draw_circle(p,26,Color(.4,.8,.8,.09));c.draw_arc(p,27,0,TAU,24,Color("#7ccfc6"),2,true)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-18,4),p+Vector2(-12,-19),p+Vector2(12,-19),p+Vector2(18,4)]),Color("#788679"))
  c.draw_line(p-Vector2(0,18),p-Vector2(0,54),Color("#d4bf89"),5)
  c.draw_circle(p-Vector2(0,55),8+pulse*2,Color("#9de9d4"))
  c.draw_string(game.font,p+Vector2(-62,43),"Interact" if game.mobile.enabled else "E • Begin waves",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f2dfa6"))
 for foe in game.enemies:
  if not foe.get("tutorial",false) or float(foe.get("windup",0))<=0:continue
  var point:Vector2=foe.pos-camera;var reach=110.0 if foe.boss else 63.0;var duration=1.05 if foe.boss else .72
  preload("res://scripts/combat_cues.gd").danger(c,point,reach,float(foe.windup),duration)
  if not foe.boss:
   var angle:float=foe.get("warning_direction",Vector2.DOWN).angle()
   c.draw_arc(point,reach,angle-1.15,angle+1.15,20,Color("#ffbc84"),4,true)
func key(c:Node2D,at:Vector2,value:String)->void:
 var box=Rect2(at,Vector2(31,29));c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#183640","#b4d7cb",5,3),box)
 c.draw_string(game.font,at+Vector2(8,21),value,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f2e6c1"))
func draw_on(c:Node2D)->void:
 if not active:return
 var center=game.VIEW.x*.5
 var heading="Light the beacon • E" if not started and not game.mobile.enabled else "Light the beacon • Interact" if not started else "Mini-boss" if wave==4 else "Wave %d / 3" % maxi(1,wave)
 var width=game.font.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
 c.draw_rect(Rect2(center-width*.5-12,107,width+24,31),Color(.025,.08,.12,.88))
 c.draw_string(game.font,Vector2(center-width*.5,129),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ecd397"))
 var origin=Vector2(38,163)
 if not moved:
  if game.mobile.enabled:
   var p=Vector2(100,game.VIEW.y-245);c.draw_arc(p,30,0,TAU,24,Color("#c3e8d9"),2,true);c.draw_circle(p+Vector2(8,-8),12,Color("#85bfae"));c.draw_string(game.font,p+Vector2(-46,-40),"Move stick",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e6eddb"))
  else:
   key(c,origin+Vector2(34,0),"W");key(c,origin+Vector2(0,33),"A");key(c,origin+Vector2(34,33),"S");key(c,origin+Vector2(68,33),"D")
   c.draw_string(game.font,origin+Vector2(19,88),"Move",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e6eddb"))
 if not attacked:
  var p=Vector2(game.VIEW.x-90,190)
  if game.mobile.enabled:
   c.draw_arc(p,27,0,TAU,24,Color("#c3e8d9"),2,true);c.draw_line(p-Vector2(12,0),p+Vector2(12,0),Color("#c3e8d9"),2,true)
  else:
   c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#183640","#b4d7cb",15,3),Rect2(p-Vector2(22,30),Vector2(44,64)))
   c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#d9b774","#fff0bf",5,2),Rect2(p+Vector2(-17,-25),Vector2(15,24)))
   c.draw_line(p-Vector2(0,28),p-Vector2(0,0),Color("#b4d7cb"),1.5,true)
  c.draw_string(game.font,p+Vector2(-48,58),"Aim / attack" if game.mobile.enabled else "Click to attack",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e6eddb"))
 var danger=false
 for foe in game.enemies:
  if float(foe.get("windup",0))>0 and game.position_in_world.distance_to(foe.pos)<(150 if foe.boss else 105):danger=true;break
 if danger:
  var cue="DODGE • button" if game.mobile.enabled else "DODGE • SHIFT"
  var point=game.position_in_world-game.camera+Vector2(0,-85)
  point.x=clampf(point.x,100,game.VIEW.x-110);point.y=maxf(170,point.y)
  c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#4d3431","#ffd396",7,5),Rect2(point-Vector2(87,24),Vector2(174,33)))
  c.draw_string(game.font,point-Vector2(73,1),cue,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffe8b1"))
