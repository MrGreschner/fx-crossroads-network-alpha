extends RefCounted
const WELL=Vector2(1120,730)
var clock:float=0
var toss:float=0
var cooldown:float=0
var rng=RandomNumberGenerator.new()
var neighborhood=preload("res://scripts/town_neighborhood.gd").new()
var routines=preload("res://scripts/town_resident_routes.gd").new()
var resident_cache:Array=[]
var cached_clock=-1.0
var events=preload("res://scripts/town_events.gd").new()
var calendar=preload("res://scripts/town_calendar.gd").new()
var residents:Array[Dictionary]=[
 {"name":"Briar","kind":"ram","colour":"#61966d"},
 {"name":"Mira","kind":"human","colour":"#b88259"},
 {"name":"Alden","kind":"rabbit","colour":"#738db7"},
 {"name":"Pip","kind":"ram","colour":"#b583a3"},
 {"name":"Clover","kind":"human","colour":"#c5ad76"},
 {"name":"Flint","kind":"rabbit","colour":"#718eaa"},
 {"name":"Hazel","kind":"ram","colour":"#90a86f"},
 {"name":"Theo","kind":"human","colour":"#b98870"},
 {"name":"Nell","kind":"rabbit","colour":"#61966d"},
 {"name":"Rowe","kind":"ram","colour":"#b88259"},
 {"name":"Fern","kind":"human","colour":"#738db7"},
 {"name":"Kit","kind":"rabbit","colour":"#b583a3"},
 {"name":"Wren","kind":"ram","colour":"#c5ad76"},
 {"name":"Bram","kind":"human","colour":"#718eaa"},
 {"name":"Lark","kind":"rabbit","colour":"#90a86f"},
 {"name":"Juniper","kind":"ram","colour":"#b98870"},
 {"name":"Tess","kind":"human","colour":"#61966d"},
 {"name":"Oak","kind":"rabbit","colour":"#b88259"},
 {"name":"Ada","kind":"ram","colour":"#738db7"},
 {"name":"Finch","kind":"human","colour":"#b583a3"},
 {"name":"Ash","kind":"ram","colour":"#8c789c"},
]
func _init()->void:rng.randomize()
func setup(g:Node)->void:
 if calendar.game==null:calendar.setup(g)
 routines.setup(g,residents)
func blocked(p:Vector2)->bool:return neighborhood.blocked(p)
func step(delta:float)->void:
 clock+=delta;toss=maxf(0,toss-delta);cooldown=maxf(0,cooldown-delta)
func resident_state(index:int)->Dictionary:
 if cached_clock!=clock:
  resident_cache.clear();resident_cache.resize(residents.size());cached_clock=clock
 if resident_cache[index]==null:resident_cache[index]=routines.state(index,calendar.hour,residents[index],calendar.weekday)
 return resident_cache[index]

func interact(g:Node)->bool:
 if events.interact(g):return true
 if calendar.interact(g):return true
 for n in residents.size():
  var state=resident_state(n)
  if not state.visible or g.position_in_world.distance_to(state.pos)>48:continue
  g.hint="E • Say hello to "+str(state.name)
  if Input.is_action_just_pressed("interact"):
   var sayings={"harbour_trade":"Fresh supplies for the marina! We meet the river traders here on Tuesday and Thursday mornings.","picnic":"We bring lunch here on Tuesdays and Thursdays. The river sounds different every day.","market":"Fresh fruit, handmade wares and fish bait for a good day by the water.","lanterns":"Walk with us. The little lanterns make the whole street feel warmer.","stars":"That constellation looks like a leaping fish, if you tilt your head.","shop":"A full shopping basket is my kind of treasure.","read":"One more page, then I really will head home.","guard":"Keeping the roads safe. My boots deserve a medal.","water":"A little water, a little patience. No shouting at seedlings.","deliver":"Special delivery! Mostly herbs. Probably no beetles.","repair":"Measure twice, hammer once. Usually.","fish":"Bramble says the big one is still out there.","rest":"Best seat in town. Listen to that fountain.","chat":"Just catching up with the neighbours.","lunch":"Moss makes a good lunch. Then it is back to work!","music":"Wednesday evenings belong to music. Come listen with us!","explore":"The forest is different every time I walk it.","camp":"A warm fire after a long walk. I fish at dawn, before the town wakes.","sleep":"Time for a good night’s sleep.","home":"Heading home. Even adventurers need a cosy doorstep."}
   g.message=str(state.name)+": "+str(sayings.get(state.task,"Lovely day in Crossroads!"))
   if not state.working:g.message+=" Next stop: "+str(state.destination)+"."
   g.message_time=5
  return true
 for home in neighborhood.HOMES:
  if g.position_in_world.distance_to(home.door)>65:continue
  g.hint="E • "+str(home.name)
  if Input.is_action_just_pressed("interact"):g.message=str(home.name)+" • A private home. Residents sleep here at night and follow their own weekly routines.";g.message_time=4
  return true
 return false

func offer(game:Node)->bool:
 if cooldown>0:return false
 if game.gold<1:
  game.message="The well needs 1 CC coin.";game.message_time=3;return false
 if game.loadout.size()>=3:
  game.message="Your pack is full. Make room before wishing (no CC spent).";game.message_time=4;return false
 game.gold-=1
 toss=0.7
 cooldown=0.8
 if rng.randi_range(1,100)==1:
  var prizes:Array=["last_stand","aegis","heart_locket"]
  var id:String=prizes[rng.randi_range(0,prizes.size()-1)]
  game.loadout.append(id)
  game.message="A golden light rises! "+str(game.items[id].name)+" added to your pack."
 else:
  game.message="Plink! Your coin sinks into the well. No treasure this time."
 game.message_time=4
 return true

func draw_world(c:CanvasItem,camera:Vector2,font:Font)->void:
 events.draw_on(c,camera)
 var visible:=Rect2(camera,c.get_viewport_rect().size).grow(100)
 if visible.has_point(WELL):
  var w:Vector2=WELL-camera
  c.draw_circle(w+Vector2(0,10),35,Color(0,0,0,.22))
  c.draw_rect(Rect2(w+Vector2(-30,-6),Vector2(60,26)),Color("#8e8e8a"))
  for n in 4:c.draw_rect(Rect2(w+Vector2(-28+n*14,0),Vector2(12,10)),Color("#c7c5b0"))
  c.draw_circle(w,29,Color("#dad3b8"))
  c.draw_circle(w,21,Color("#283f4c"))
  c.draw_arc(w,14,0,TAU,24,Color("#75a4af"),2,true)
  for side in [-1,1]:c.draw_rect(Rect2(w+Vector2(side*28-3,-61),Vector2(6,62)),Color("#775b42"))
  c.draw_line(w+Vector2(-29,-50),w+Vector2(29,-50),Color("#b78c59"),5)
  c.draw_line(w+Vector2(0,-50),w+Vector2(0,-8),Color("#d9c9a2"),2)
  c.draw_colored_polygon(PackedVector2Array([w+Vector2(-42,-62),w+Vector2(0,-85),w+Vector2(42,-62)]),Color("#647f90"))
  c.draw_string(font,w+Vector2(-55,47),"WISHING WELL",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f4dfac"))
  if toss>0:
   var t:float=1-toss/.7
   c.draw_circle(w+Vector2(-32*(1-t),-14-42*sin(PI*t)),4*(1-t*.65),Color("#f3d267"))

func draw_residents(c:CanvasItem,camera:Vector2)->void:
 var visible:=Rect2(camera,c.get_viewport_rect().size).grow(100)
 for index in residents.size():
  var state:Dictionary=resident_state(index)
  if not bool(state.visible) or not visible.has_point(state.pos):continue
  var point:Vector2=state.pos-camera
  var working:bool=state.working
  var bob:float=0 if working else sin(clock*9+index)*1.5
  if working and state.task in ["rest","camp"]:bob=5
  if working and state.task=="music":bob=sin(clock*6+index)*2.5
  c.draw_circle(point+Vector2(0,3),12,Color(0,0,0,.18))
  point.y+=bob
  var phase=0 if working else 1+posmod(int(floorf((clock*9+index)/TAU*16)),16)
  var atlas=preload("res://scripts/town_sprite_cache.gd").texture("residents")
  c.draw_texture_rect_region(atlas,Rect2(point-Vector2(24,56),Vector2(48,72)),Rect2(phase*48,index*72,48,72))
  var skin:Color=Color("#e7dac4") if state.kind!="human" else Color("#c99970")
  if state.task in ["deliver","harbour_trade","shop","read","guard","repair"] or working:
   var hand:Vector2=point+Vector2(14,-17+sin(clock*4)*3)
   c.draw_line(point+Vector2(8,-20),hand,skin,4)
   match str(state.task):
    "fish":
     if str(state.get("destination",""))=="Marina fishing afternoon":
      c.draw_line(hand,hand+Vector2(12,-18),Color("#c8ae7c"),2);c.draw_line(hand+Vector2(12,-18),point+Vector2(28,42),Color(.8,.87,.83,.7),1);c.draw_circle(point+Vector2(28,42),2,Color("#e2bb79"));continue
     var facing=-1 if index==20 else 1
     c.draw_line(hand,hand+Vector2(facing*20,-30),Color("#c8ae7c"),2)
     c.draw_line(hand+Vector2(facing*20,-30),hand+Vector2(facing*42,14),Color(.8,.87,.83,.7),1)
    "lunch":
     c.draw_rect(Rect2(hand+Vector2(-7,3),Vector2(22,3)),Color("#d5cfad"))
     c.draw_circle(hand+Vector2(4,0),5,Color("#d8a568"))
    "music":
     c.draw_circle(hand+Vector2(0,2),7,Color("#d5a565"));c.draw_line(hand,hand-Vector2(2,18),Color("#d5a565"),3)
    "water":
     c.draw_rect(Rect2(hand,Vector2(9,7)),Color("#739dad"))
     for drop in 3:c.draw_circle(hand+Vector2(12+drop*4,9+fposmod(clock*18+drop*3,10)),1.5,Color("#a7dce6"))
    "read":
     c.draw_rect(Rect2(hand-Vector2(5,2),Vector2(14,12)),Color("#78a7ad"));c.draw_line(hand+Vector2(2,0),hand+Vector2(2,8),Color("#e8d7ad"),2)
    "guard":
     c.draw_line(hand-Vector2(0,20),hand+Vector2(0,15),Color("#8e7959"),3);c.draw_colored_polygon(PackedVector2Array([hand-Vector2(5,20),hand-Vector2(0,29),hand+Vector2(5,-20)]),Color("#c3d2cf"))
    "repair":
     c.draw_line(hand,hand-Vector2(0,16),Color("#9d7956"),3);c.draw_rect(Rect2(hand-Vector2(7,21),Vector2(15,7)),Color("#9aafb2"))
    "sweep":
     c.draw_line(hand,hand+Vector2(8,22),Color("#ba9262"),2)
     c.draw_rect(Rect2(hand+Vector2(2,20),Vector2(15,5)),Color("#d1bd82"))
    "deliver","harbour_trade","shop":c.draw_rect(Rect2(hand+Vector2(-3,-1),Vector2(12,10)),Color("#c29567"))

func recognition(c:Node,index:int)->String:
 if c.get("legacy")==null or bool(c.legacy.data.get("teacher",false)):return ""
 var tasks:Dictionary=c.legacy.data.tasks
 var id:String=str(c.selected_character)
 if index==0 and c.legacy.final_eligible(id):return str(c.characters[id].name)+" — a true master!"
 if index==0 and c.legacy.eligible(id,true):return "You have earned your champion title!"
 if index==0 and c.legacy.eligible(id):return "That new technique really suits you."
 if index==1 and int(tasks.get("defense30",0))>0:return "You faced the Tollbreaker. Our gate stands!"
 if index==2 and int(tasks.get("coop_clears",0))>0:return "I hear your party brought everyone home."
 if index==3 and int(tasks.get("quests",0))>0:return "The Wayfarer villagers speak well of you."
 if index==4 and int(tasks.get("clears",0))>0:return "Welcome back, adventurer!"
 return ""

func draw_recognition(c:Node2D,camera:Vector2,font:Font)->void:
 # Only one short greeting at a time; a quiet interval between greetings.
 if fposmod(clock,18)>6:return
 var best:=-1;var distance:=180.0
 for n in residents.size():
  var state:Dictionary=resident_state(n)
  if not state.visible:continue
  var p:Vector2=state.pos
  if c.position_in_world.distance_to(p)<distance and not recognition(c,n).is_empty():best=n;distance=c.position_in_world.distance_to(p)
 if best<0:return
 var message:String=recognition(c,best);var p:Vector2=resident_state(best).pos-camera+Vector2(0,-79)
 var width:float=minf(430,font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+28)
 p.x=clampf(p.x,width*.5+12,c.VIEW.x-width*.5-12);p.y=maxf(170,p.y)
 c.draw_style_box(bubble_style(),Rect2(p-Vector2(width*.5,24),Vector2(width,36)))
 c.draw_string(font,p+Vector2(-width*.5+14,0),message,HORIZONTAL_ALIGNMENT_LEFT,width-28,15,Color("#e7e3c9"))
func bubble_style()->StyleBoxFlat:
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#223c3a");skin.border_color=Color("#a4b7a1");skin.set_border_width_all(1);skin.set_corner_radius_all(8);return skin

func draw_resident_body(c:CanvasItem,point:Vector2,state:Dictionary,index:int,phase:float,working:bool)->void:
 var coat:Color=Color(state.colour)
 c.draw_rect(Rect2(point+Vector2(-10,-23),Vector2(20,23)),Color("#34414a"))
 c.draw_rect(Rect2(point+Vector2(-9,-22),Vector2(18,20)),coat)
 c.draw_rect(Rect2(point+Vector2(-9,-8),Vector2(18,3)),Color("#c2b092"))
 for arm in [-1,1]:
  var swing:float=0 if working else sin(phase)*2*arm
  c.draw_rect(Rect2(point+Vector2(arm*11-2,-20+swing),Vector2(4,10)),coat)
  c.draw_rect(Rect2(point+Vector2(arm*11-2,-10+swing),Vector2(4,3)),Color("#dfc5a6"))
 for side in [-1,1]:
  var foot=0.0 if working else sin(phase+side*PI*.5)*2
  c.draw_rect(Rect2(point+Vector2(side*5-3,-2+foot),Vector2(6,6)),Color("#343d45"))
 var skin:Color=Color("#e7dac4") if state.kind!="human" else Color("#c99970")
 c.draw_rect(Rect2(point+Vector2(-10,-41),Vector2(20,20)),Color("#4f4a46"))
 c.draw_rect(Rect2(point+Vector2(-9,-40),Vector2(18,18)),skin)
 c.draw_rect(Rect2(point+Vector2(-2,-28),Vector2(4,2)),Color("#b18275"))
 if state.kind=="ram":
  for side in [-1,1]:
   c.draw_circle(point+Vector2(side*11,-32),6,Color("#806147"))
   c.draw_circle(point+Vector2(side*11,-32),3,Color("#c7a47c"))
 elif state.kind=="rabbit":
  for side in [-1,1]:
   c.draw_rect(Rect2(point+Vector2(side*5-2,-53),Vector2(5,15)),skin)
   c.draw_rect(Rect2(point+Vector2(side*5-1,-50),Vector2(2,8)),Color("#dca2a4"))
 else:
  c.draw_rect(Rect2(point+Vector2(-10,-43),Vector2(20,7)),Color("#655045") if index==2 else Color("#b7a26a"))
 for side in [-1,1]:c.draw_rect(Rect2(point+Vector2(side*4-1,-34),Vector2(2,3)),Color("#31333e"))
