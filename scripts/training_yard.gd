extends RefCounted
const ALLY=Vector2(650,620)
var ally_health:float=50
var full_time:float=0
var runner_phase:float=0
var clock:float=0
var next_shots:Array[float]=[1.0,2.1]
const HERO_BOOK=Vector2(660,400)
var outpost:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/training_outpost.svg")
var book:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/training_hero_book.svg")
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
const LAUNCHERS=[Vector2(1460,410),Vector2(1460,790)]
func reset()->void:ally_health=50;full_time=0;clock=0;runner_phase=0;next_shots=[1.0,2.1]
func heal(game:Node,amount:float)->void:
 var gained:float=minf(maxf(0,amount),200-ally_health)
 ally_health+=gained
 if gained>0:game.adventure.combat.feedback.hit(ALLY,gained,"training_ally",true);game.add_float_text(ALLY-Vector2(18,68),"+"+str(int(gained)),Color("#8bedad"))
func step(game:Node,delta:float)->void:
 clock+=delta
 if ally_health>=200:full_time+=delta
 else:full_time=0
 if full_time>=3:ally_health=50;full_time=0
 if game.position_in_world.distance_to(ALLY)<85:
  game.hint="E • Reset allied healing / buff target"
  if Input.is_action_just_pressed("interact"):
   ally_health=50;full_time=0;game.adventure.combat.statuses.erase("p:training_ally")
 for foe in game.enemies:
  if str(foe.get("type",""))=="training_runner":
   if game.adventure.combat.stunned(game.adventure.combat.npc_key(foe)):continue
   runner_phase+=delta*.7*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(foe))
   foe.pos=Vector2(1560,600+sin(runner_phase)*210)
 for n in LAUNCHERS.size():
  if clock<next_shots[n]:continue
  next_shots[n]=clock+2.6
  if game.position_in_world.distance_to(LAUNCHERS[n])>620 or game.enemy_shots.size()>16:continue
  var aim:Vector2=(game.position_in_world-LAUNCHERS[n]).normalized()
  game.enemy_shots.append({"pos":LAUNCHERS[n],"direction":aim,"speed":245.0,"damage":3.0,"distance":0.0,"practice_shot":true})
 game.health=minf(game.max_health(),game.health+delta*4)
func draw_on(game:Node,camera:Vector2)->void:
 var a:Vector2=ALLY-camera
 game.draw_circle(a+Vector2(0,8),29,Color(.25,.8,.4,.13))
 game.draw_line(a+Vector2(0,4),a+Vector2(0,-35),Color("#7a694b"),9,true)
 game.draw_line(a+Vector2(-26,-24),a+Vector2(26,-24),Color("#5ba96a"),12,true)
 game.draw_circle(a+Vector2(0,-48),15,Color("#8bcd82"))
 game.draw_line(a+Vector2(-7,-48),a+Vector2(7,-48),Color("#e3ffe3"),3,true)
 game.draw_line(a+Vector2(0,-55),a+Vector2(0,-41),Color("#e3ffe3"),3,true)
 game.draw_rect(Rect2(a+Vector2(-42,-80),Vector2(84,6)),Color("#244236"))
 game.draw_rect(Rect2(a+Vector2(-42,-80),Vector2(84*ally_health/200,6)),Color("#78d28a"))
 game.draw_string(font,a+Vector2(-70,33),"ALLY • HEAL / BUFF",HORIZONTAL_ALIGNMENT_CENTER,140,12,Color("#b8f0bc"))
 game.draw_string(font,a+Vector2(-55,49),str(int(ally_health))+" / 200 HP",HORIZONTAL_ALIGNMENT_CENTER,110,12,Color("#e5edc6"))
 var buffs:Array=game.adventure.combat.statuses.get("p:training_ally",{}).keys()
 if not buffs.is_empty():game.draw_string(font,a+Vector2(-80,65),", ".join(buffs),HORIZONTAL_ALIGNMENT_CENTER,160,11,Color("#f3d895"))
 for n in LAUNCHERS.size():
  var point:Vector2=LAUNCHERS[n]-camera
  var warning:float=clampf(1-(next_shots[n]-clock)/.6,0,1)
  game.draw_rect(Rect2(point+Vector2(-20,-15),Vector2(40,35)),Color("#747f79"))
  game.draw_circle(point+Vector2(0,-20),17,Color("#9fae9f"))
  game.draw_line(point+Vector2(0,-20),point+Vector2(-24,-20),Color("#626e6c"),10,true)
  game.draw_circle(point+Vector2(-25,-20),5,Color("#edb574") if warning>.1 else Color("#405557"))
  game.draw_string(font,point+Vector2(-55,48),"SHOT PRACTICE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e1d3a8"))
 for foe in game.enemies:
  if str(foe.get("type",""))=="training_runner":
   var point:Vector2=foe.pos-camera
   for side in [-1,1]:game.draw_circle(point+Vector2(side*18,28),6,Color("#6c6855"))
   game.draw_string(font,point+Vector2(-50,53),"MOVING TARGET",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e1d3a8"))

func draw_outpost(game:Node2D,camera:Vector2)->void:
 var base:=Vector2(160,215)-camera
 game.draw_texture_rect(outpost,Rect2(base,Vector2(420,230)),false)
 game.draw_string(font,base+Vector2(43,98),"CROSSROADS TRAINING",HORIZONTAL_ALIGNMENT_CENTER,193,13,Color("#f5ddb0"))
 var b:Vector2=HERO_BOOK-camera
 game.draw_circle(b,48,Color(.3,.65,.83,.09))
 game.draw_texture_rect(book,Rect2(b-Vector2(36,84),Vector2(72,100)),false)
 var nearby:bool=game.position_in_world.distance_to(HERO_BOOK)<85
 game.draw_arc(b,45,0,TAU,24,Color("#f2d394") if nearby else Color(.4,.76,.9,.45),2)
 game.draw_string(font,b+Vector2(-80,42),"HERO BOOK",HORIZONTAL_ALIGNMENT_CENTER,160,14,Color("#f5ddb0"))
 # A tiny ember bucket and frost staff: bounded decoration only, never combat.
 var fire:=Vector2(420,407)-camera
 for n in 5:
  var h:=12+sin(clock*5+n*1.7)*4;var x:=float(n-2)*3
  game.draw_colored_polygon(PackedVector2Array([fire+Vector2(x-5,-11),fire+Vector2(x+sin(clock*3+n)*3,-11-h),fire+Vector2(x+5,-11)]),Color("#e99245"))
 game.draw_rect(Rect2(fire+Vector2(-11,-11),Vector2(22,17)),Color("#626e70"));game.draw_line(fire+Vector2(-13,-11),fire+Vector2(13,-11),Color("#a6b0a8"),3)
 var frost:=Vector2(520,335)-camera
 game.draw_circle(frost,15+sin(clock*2)*2,Color(.35,.76,1,.13))
 game.draw_circle(frost,5,Color("#91e4f1"))
 for n in 7:
  var point:=frost+Vector2(sin(n*2.4)*21,fmod(clock*12+n*11,65)-12)
  game.draw_circle(point,1.5,Color(.75,.9,1,.65))
