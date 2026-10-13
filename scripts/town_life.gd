extends RefCounted
const WELL=Vector2(1120,730)
var clock:float=0
var toss:float=0
var cooldown:float=0
var rng=RandomNumberGenerator.new()
var residents:Array[Dictionary]=[
	{"kind":"ram","colour":"#61966d","route":[Vector2(560,710),Vector2(600,780),Vector2(560,840)],"task":"water"},
	{"kind":"ram","colour":"#b88259","route":[Vector2(1020,650),Vector2(1060,570),Vector2(1225,710)],"task":"seed"},
	{"kind":"human","colour":"#738db7","route":[Vector2(1330,750),Vector2(1420,800),Vector2(1350,865)],"task":"sweep"},
	{"kind":"human","colour":"#b583a3","route":[Vector2(690,880),Vector2(740,940),Vector2(820,920)],"task":"deliver"},
	{"kind":"rabbit","colour":"#c5ad76","route":[Vector2(1370,890),Vector2(1320,900),Vector2(1310,940)],"task":"seed"}
]
func _init()->void:rng.randomize()
func step(delta:float)->void:
	clock+=delta
	toss=maxf(0,toss-delta)
	cooldown=maxf(0,cooldown-delta)
func resident_state(index:int)->Dictionary:
	var npc:Dictionary=residents[index]
	var route:Array=npc.route
	var phase:float=fposmod(clock+index*3.7,24)
	var segment:int=int(phase/8)
	var local:float=fposmod(phase,8)
	var start:Vector2=route[segment]
	var finish:Vector2=route[(segment+1)%3]
	return {"pos":start.lerp(finish,minf(local/5,1)),"working":local>=5,"kind":npc.kind,"colour":npc.colour,"task":npc.task}

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
	var visible:=Rect2(camera,c.get_viewport_rect().size).grow(100)
	# Small working patches beside residents' routes.
	for garden in [Vector2(560,840),Vector2(1225,710),Vector2(1310,940)]:
		if not visible.has_point(garden):continue
		var g:Vector2=garden-camera
		c.draw_rect(Rect2(g+Vector2(12,2),Vector2(42,20)),Color("#65503e"))
		for n in 4:
			c.draw_line(g+Vector2(18+n*9,16),g+Vector2(18+n*9,4),Color("#719f68"),3)
			c.draw_circle(g+Vector2(18+n*9,4),3,Color("#e2bd82"))
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
	for index in residents.size():
		var state:Dictionary=resident_state(index)
		if not visible.has_point(state.pos):continue
		var point:Vector2=state.pos-camera
		var working:bool=state.working
		var bob:float=0 if working else sin(clock*9+index)*1.5
		c.draw_circle(point+Vector2(0,3),12,Color(0,0,0,.18))
		point.y+=bob
		var coat:Color=Color(state.colour)
		c.draw_rect(Rect2(point+Vector2(-10,-23),Vector2(20,23)),Color("#34414a"))
		c.draw_rect(Rect2(point+Vector2(-9,-22),Vector2(18,20)),coat)
		c.draw_rect(Rect2(point+Vector2(-9,-8),Vector2(18,3)),Color("#c2b092"))
		for arm in [-1,1]:
			var swing:float=0 if working else sin(clock*9+index)*2*arm
			c.draw_rect(Rect2(point+Vector2(arm*11-2,-20+swing),Vector2(4,10)),coat)
			c.draw_rect(Rect2(point+Vector2(arm*11-2,-10+swing),Vector2(4,3)),Color("#dfc5a6"))
		c.draw_rect(Rect2(point+Vector2(-8,-2),Vector2(6,6)),Color("#343d45"))
		c.draw_rect(Rect2(point+Vector2(2,-2),Vector2(6,6)),Color("#343d45"))
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
		if working:
			var hand:Vector2=point+Vector2(14,-17+sin(clock*4)*3)
			c.draw_line(point+Vector2(8,-20),hand,skin,4)
			match str(state.task):
				"water":
					c.draw_rect(Rect2(hand,Vector2(9,7)),Color("#739dad"))
					for drop in 3:c.draw_circle(hand+Vector2(12+drop*4,9+fposmod(clock*18+drop*3,10)),1.5,Color("#a7dce6"))
				"seed":
					for seed in 3:c.draw_circle(hand+Vector2(6+seed*5,8+fposmod(clock*12+seed*4,14)),1.5,Color("#e1c084"))
				"sweep":
					c.draw_line(hand,hand+Vector2(8,22),Color("#ba9262"),2)
					c.draw_rect(Rect2(hand+Vector2(2,20),Vector2(15,5)),Color("#d1bd82"))
				"deliver":c.draw_rect(Rect2(hand+Vector2(-3,-1),Vector2(12,10)),Color("#c29567"))

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
		var p:Vector2=resident_state(n).pos
		if c.position_in_world.distance_to(p)<distance and not recognition(c,n).is_empty():best=n;distance=c.position_in_world.distance_to(p)
	if best<0:return
	var message:String=recognition(c,best);var p:Vector2=resident_state(best).pos-camera+Vector2(0,-79)
	var width:float=minf(430,font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+28)
	p.x=clampf(p.x,width*.5+12,c.VIEW.x-width*.5-12);p.y=maxf(170,p.y)
	c.draw_style_box(bubble_style(),Rect2(p-Vector2(width*.5,24),Vector2(width,36)))
	c.draw_string(font,p+Vector2(-width*.5+14,0),message,HORIZONTAL_ALIGNMENT_LEFT,width-28,15,Color("#e7e3c9"))
func bubble_style()->StyleBoxFlat:
	var skin:=StyleBoxFlat.new();skin.bg_color=Color("#223c3a");skin.border_color=Color("#a4b7a1");skin.set_border_width_all(1);skin.set_corner_radius_all(8);return skin
