extends RefCounted
const POND=Vector2(200,365)
const POND_RADII=Vector2(200,112)
const POND_BENCH=Vector2(345,565)
const CAMP=Vector2(2890,1450)
const TOWER=Vector2(1720,420)
var trees:Array[Vector2]=[]
var tree_cells:Dictionary={}
var clock:float=0
var guard_texture:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/guard_melee.svg")
var routes:Array=[
	[Vector2(800,295),Vector2(800,550),Vector2(790,585),Vector2(420,585),Vector2(300,550),Vector2(160,500)],
	[Vector2(1000,295),Vector2(1200,330),Vector2(1500,310),Vector2(1620,500),Vector2(1810,500),Vector2(1810,750),Vector2(1900,900)],
	[Vector2(820,320),Vector2(820,560),Vector2(780,580),Vector2(420,580),Vector2(180,550)]
]
var patrols:Array=[]
var patrol_times:Array=[]
var patrol_cycles:Array=[]
func _init()->void:
	routes.append([Vector2(-1210,1240),Vector2(-1210,1280),Vector2(-1160,1280),Vector2(-1160,1240)])
	routes.append([Vector2(-940,1220),Vector2(-940,1280),Vector2(-1000,1280),Vector2(-1000,1220)])
	for x in range(70,3100,125):trees.append(Vector2(x,-510))
	for y in [-350,-180,-20]:
		trees.append(Vector2(65,y));trees.append(Vector2(3040,y))
	routes.append([Vector2(1850,1000),Vector2(1850,1210),Vector2(2280,1210),Vector2(2280,1150),Vector2(2510,1150),Vector2(2890,1150)])
	routes.append([Vector2(750,1700),Vector2(1330,1710),Vector2(1440,1910)])
	for x in range(70,3100,125):
		if abs(x-900)>130:trees.append(Vector2(x,100))
		trees.append(Vector2(x,2190))
	for y in range(280,2190,125):
		trees.append(Vector2(65,y))
		trees.append(Vector2(3040,y))
	for point in [Vector2(160,240),Vector2(250,170),Vector2(1640,160),Vector2(1820,180),Vector2(1930,400),Vector2(2190,380),Vector2(2210,630),Vector2(2140,860),Vector2(1860,1310)]:
		trees.append(point)
	# River silhouettes and both east-bank walking corridors remain clear.
	trees=trees.filter(func(p:Vector2):return not (p.x>2200 and p.x<2520) and not Rect2(2490,940,650,780).has_point(p) and not Rect2(2525,690,125,450).has_point(p))
	# Keep the clinic entrance and its connected street free of trunks.
	trees=trees.filter(func(point:Vector2):return not Rect2(1800,680,760,170).has_point(point) and not (point.x<270 and point.y>290 and point.y<1420))
	# Trees belong on the foothill apron, with gaps for both cave approaches.
	for point in [Vector2(360,595),Vector2(295,1000),Vector2(275,1060),Vector2(165,1445)]:trees.append(point)
	trees=trees.filter(func(point:Vector2):return not Rect2(point-Vector2(55,115),Vector2(110,145)).intersects(Rect2(POND-Vector2(230,142),Vector2(460,284))))
	trees=trees.filter(func(p:Vector2):return not (p.x<320 and p.y>500))
	for y in range(250,2250,190):trees.append(Vector2(-1360,y))
	trees=trees.filter(func(p:Vector2):return not Rect2(300,520,130,125).has_point(p))
	trees=trees.filter(func(p:Vector2):return not preload("res://scripts/town_plan.gd").reserved(p))
	for tree in trees:
		var cell:=Vector2i(floori(tree.x/128),floori(tree.y/128))
		if not tree_cells.has(cell):tree_cells[cell]=[]
		tree_cells[cell].append(tree)
	for outward in routes:
		var route:Array=outward.duplicate()
		for n in range(outward.size()-2,0,-1):route.append(outward[n])
		var durations:Array=[];var cycle:float=0
		for n in route.size():
			var duration:float=route[n].distance_to(route[(n+1)%route.size()])/55.0
			durations.append(duration);cycle+=duration+1.2
		patrols.append(route);patrol_times.append(durations);patrol_cycles.append(cycle)
func step(delta:float)->void:clock+=delta
func blocked(point:Vector2)->bool:
	var offset:Vector2=(point-POND)/POND_RADII
	if offset.length()<1:return true
	if point.distance_to(TOWER)<40:return true
	if point.distance_to(CAMP)<28:return true
	var cell:=Vector2i(floori(point.x/128),floori(point.y/128))
	for x in range(cell.x-1,cell.x+2):
		for y in range(cell.y-1,cell.y+2):
			for tree in tree_cells.get(Vector2i(x,y),[]):
				if point.distance_squared_to(tree)<625:return true
	return false
func guard_position(index:int)->Vector2:
	var route:Array=patrols[index]
	var cycle:float=patrol_cycles[index]
	var elapsed:float=fposmod(clock+index*14.0,cycle)
	for n in route.size():
		var start:Vector2=route[n]
		var finish:Vector2=route[(n+1)%route.size()]
		var duration:float=patrol_times[index][n]
		if elapsed<duration:return start.lerp(finish,elapsed/duration)
		elapsed-=duration
		if elapsed<1.2:return finish
		elapsed-=1.2
	return route[0]
func guard(c:CanvasItem,point:Vector2,moving:bool)->void:
	c.draw_circle(point+Vector2(0,4),13,Color(0,0,0,.2))
	var bob:float=sin(clock*8)*1.2 if moving else 0
	c.draw_texture_rect(guard_texture,Rect2(point+Vector2(-20,-42+bob),Vector2(40,48)),false)
func draw_on(c:CanvasItem,camera:Vector2,font:Font)->void:
	var visible:Rect2=Rect2(camera,c.get_viewport_rect().size).grow(210)
	for tree in trees:
		if visible.has_point(tree):c.draw_sprite("tree",tree-Vector2(55,115),Vector2(110,145))
	# A planned pond garden sits north of the cliff, with a separate waterside walk.
	if visible.has_point(POND):
		var walk:=PackedVector2Array([Vector2(420,510)-camera,Vector2(330,525)-camera,Vector2(220,530)-camera,Vector2(180,550)-camera,Vector2(290,550)-camera])
		c.draw_polyline(walk,Color("#8e9871"),44,true);c.draw_polyline(walk,Color("#c2b28a"),30,true)
		for point in [Vector2(105,440),Vector2(188,456),Vector2(413,375)]:
			var q:Vector2=point-camera; c.draw_circle(q,5,Color("#d4c495"));c.draw_circle(q+Vector2(12,6),3,Color("#dcb7c9"))
		# Pond, lily pads and visible swimming fish.
		var pond:Vector2=POND-camera
		var rim:PackedVector2Array=PackedVector2Array()
		var water:PackedVector2Array=PackedVector2Array()
		for n in 48:
			var angle:float=n*TAU/48
			rim.append(pond+Vector2(cos(angle)*(220+sin(angle*3)*9),sin(angle)*(132+cos(angle*5)*7)))
			water.append(pond+Vector2(cos(angle)*(202+sin(angle*3)*7),sin(angle)*(114+cos(angle*5)*5)))
		c.draw_colored_polygon(rim,Color("#899e7c"))
		c.draw_colored_polygon(water,Color("#3e8592"))
		for n in 12:
			var a:float=n*TAU/12;var shore:Vector2=pond+Vector2(cos(a)*214,sin(a)*124)
			c.draw_circle(shore,5+n%3,Color("#b4b295"))
			if n%3==0:
				for k in 3:c.draw_line(shore+Vector2(k*4,0),shore+Vector2(k*4-3,-18-k*4),Color("#789569"),2,true)
		c.draw_circle(pond+Vector2(18,-3),44,Color(.15,.39,.47,.15))
		c.draw_polyline(water,Color(.65,.86,.83,.3),2,true)
		for n in 4:
			var angle:float=clock*(.28+n*.04)+n*1.7
			var fish:Vector2=pond+Vector2(cos(angle)*(55+n*12),sin(angle)*(24+n*5))
			var direction:Vector2=Vector2(-sin(angle)*2,cos(angle)).normalized()
			var side:Vector2=direction.orthogonal()
			c.draw_line(fish-direction*5,fish+direction*5,Color("#e8ba7a"),4,true)
			c.draw_colored_polygon(PackedVector2Array([fish-direction*4,fish-direction*10+side*4,fish-direction*10-side*4]),Color("#c99566"))
			c.draw_circle(fish+direction*4,1,Color("#293f4b"))
		var night:float=c.town_life.calendar.night_amount()
		var phase:float=fposmod(c.town_life.calendar.now,90.0)
		if night>.1 and phase<34:
			var angle:float=clock*.21+1.1;var fish:Vector2=pond+Vector2(cos(angle)*120,sin(angle)*69)
			var direction=Vector2(-sin(angle)*120,cos(angle)*69).normalized();var side=direction.orthogonal();var alpha=night*smoothstep(0,4,phase)*(1-smoothstep(28,34,phase))
			for radius in [19,11]:c.draw_circle(fish,radius,Color(.25,.95,.9,alpha*.09))
			c.draw_line(fish-direction*6,fish+direction*7,Color(.5,1,.91,alpha*.9),4,true)
			c.draw_colored_polygon(PackedVector2Array([fish-direction*5,fish-direction*13+side*5,fish-direction*13-side*5]),Color(.38,.78,1,alpha*.9))
		for n in 3:
			c.draw_arc(pond+Vector2(-60+n*50,20+n*7),16+sin(clock*2+n)*3,.15,2.5,16,Color(.7,.91,.94,.38),1,true)
			var lily:Vector2=pond+Vector2(-75+n*65,-30+n*8)
			c.draw_circle(lily,10,Color("#6ca778"))
			c.draw_circle(lily+Vector2(2,-3),3,Color("#edc6d5"))
	# Wooden lookout with ladder, parapet and a watch light.
	if visible.has_point(TOWER):
		var tower:Vector2=TOWER-camera
		c.draw_circle(tower+Vector2(0,10),48,Color(0,0,0,.2))
		for side in [-1,1]:c.draw_line(tower+Vector2(side*30,-85),tower+Vector2(side*40,18),Color("#81624d"),8)
		c.draw_line(tower+Vector2(-30,-70),tower+Vector2(34,12),Color("#b49366"),5)
		c.draw_line(tower+Vector2(30,-70),tower+Vector2(-34,12),Color("#b49366"),5)
		c.draw_rect(Rect2(tower+Vector2(-44,-107),Vector2(88,32)),Color("#a68b64"))
		for n in 6:c.draw_rect(Rect2(tower+Vector2(-42+n*15,-113),Vector2(9,13)),Color("#c3ab7e"))
		for side in [-1,1]:c.draw_line(tower+Vector2(side*10,-74),tower+Vector2(side*10,18),Color("#d1b884"),3)
		for n in 8:c.draw_line(tower+Vector2(-10,-68+n*11),tower+Vector2(10,-68+n*11),Color("#d1b884"),3)
		c.draw_rect(Rect2(tower+Vector2(-7,-140),Vector2(14,20)),Color("#ead49b"))
		c.draw_circle(tower+Vector2(0,-132),16,Color(1,.8,.3,.1+.03*sin(clock*3)))
		c.draw_string(font,tower+Vector2(-48,44),"LOOKOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e9d9b3"))
	# Two small guard stations at the arena entrance.
	for station in [Vector2(-70,1335),Vector2(330,1335)]:
		if not visible.has_point(station):continue
		var post:Vector2=station-camera
		c.draw_rect(Rect2(post+Vector2(-21,-17),Vector2(42,23)),Color("#75634f"))
		c.draw_rect(Rect2(post+Vector2(-23,-62),Vector2(5,58)),Color("#917352"))
		c.draw_rect(Rect2(post+Vector2(18,-62),Vector2(5,58)),Color("#917352"))
		c.draw_colored_polygon(PackedVector2Array([post+Vector2(-32,-61),post+Vector2(0,-81),post+Vector2(32,-61)]),Color("#587992"))
		guard(c,post,false)
	# Flower beds, benches and glowing mushrooms near the forest.
	for bed in [Vector2(330,620),Vector2(1470,600),Vector2(1900,975),Vector2(840,1250),Vector2(1900,1055)]:
		if not visible.has_point(bed):continue
		var b:Vector2=bed-camera
		var half:float=30 if bed.x==1900 else 36
		c.draw_rect(Rect2(b+Vector2(-half,-8),Vector2(half*2,23)),Color("#705a44"))
		for n in (6 if bed.x==1900 else 7):
			var flower:Vector2=b+Vector2(-half+7+n*9,sin(n*2)*5)
			c.draw_line(flower+Vector2(0,11),flower,Color("#739666"),2)
			c.draw_circle(flower,4,Color("#dcb3c9") if n%2==0 else Color("#ead29a"))
	for bench in [POND_BENCH,Vector2(1650,1120)]:
		if not visible.has_point(bench):continue
		var b:Vector2=bench-camera
		c.draw_rect(Rect2(b+Vector2(-25,-14),Vector2(50,9)),Color("#b08b61"))
		c.draw_rect(Rect2(b+Vector2(-25,-1),Vector2(50,7)),Color("#967351"))
		for side in [-1,1]:c.draw_line(b+Vector2(side*19,3),b+Vector2(side*19,13),Color("#4d514d"),4)
	if visible.has_point(CAMP):
		var fire:Vector2=CAMP-camera
		var strength:float=c.town_life.calendar.fire_strength()
		c.draw_circle(fire,65,Color(1,.54,.18,(.06+.02*sin(clock*5))*strength))
		for n in 9:
			var stone:Vector2=fire+Vector2(cos(n*TAU/9)*27,sin(n*TAU/9)*15)
			c.draw_circle(stone,6,Color("#92958a"))
		c.draw_line(fire+Vector2(-21,5),fire+Vector2(17,-3),Color("#79523e"),7)
		c.draw_line(fire+Vector2(21,5),fire+Vector2(-17,-3),Color("#79523e"),7)
		if strength>0 and strength<.25:c.draw_circle(fire,9,Color(1,.37,.12,strength*2))
		for n in (5 if strength>.08 else 0):
			var base:Vector2=fire+Vector2(-16+n*8,0)
			var tip:Vector2=base+Vector2(sin(clock*7+n)*5,(-20-12*sin(clock*5+n))*strength)
			c.draw_colored_polygon(PackedVector2Array([base+Vector2(-6,4),tip,base+Vector2(7,4)]),Color("#ed833b"))
			c.draw_colored_polygon(PackedVector2Array([base+Vector2(-3,2),base.lerp(tip,.6),base+Vector2(4,2)]),Color("#f7d27a"))
		for n in (4 if strength>.25 else 0):
			var age:float=fposmod(clock*.6+n*.25,1)
			c.draw_circle(fire+Vector2(sin(clock*2+n)*12,-10-age*55),1.7,Color(1,.73,.3,1-age))
		# Ash uses the log at dusk; his daily route is drawn by town_life.
		var seat:Vector2=fire+Vector2(-83,27)
		c.draw_line(seat+Vector2(-29,6),seat+Vector2(29,6),Color("#76533c"),18)
		c.draw_circle(seat+Vector2(29,6),9,Color("#bb956b"))
		c.draw_arc(seat+Vector2(29,6),5,0,TAU,12,Color("#846044"),1)
		c.draw_line(seat+Vector2(-20,3),seat+Vector2(18,3),Color("#ad8256"),2)

	for n in 4:
		var m:Vector2=Vector2(1970+n*35,1240)-camera
		c.draw_circle(m+Vector2(0,-7),5,Color("#a8cdaf"))
		c.draw_line(m+Vector2(0,-4),m+Vector2(0,3),Color("#d8d6ac"),2)
	for group in 2:
		var phase:float=fposmod(clock+group*21,48)
		if phase>=32:continue
		var points:Array=[Vector2(120,290),Vector2(125,650),Vector2(270,1240)] if group==0 else [Vector2(2030,940),Vector2(2190,940),Vector2(2270,1240)]
		var progress:float=phase/8
		var start:Vector2=points[int(progress)%3]
		var finish:Vector2=points[(int(progress)+1)%3]
		var fairy:Vector2=start.lerp(finish,smoothstep(0,1,fposmod(progress,1)))-camera+Vector2(sin(clock*3)*9,-60+cos(clock*4)*7)
		for glow in [18,10,4]:c.draw_circle(fairy,glow,Color(.8,1,.69,.08 if glow>4 else .9))
		c.draw_circle(fairy+Vector2(sin(clock*5)*13,8),1.5,Color(.9,1,.7,.5))
func _guard_at_time(index:int,time:float)->Vector2:
	var saved:float=clock
	clock=time
	var result:Vector2=guard_position(index)
	clock=saved
	return result

func draw_patrols(c:Node2D,camera:Vector2)->void:
	var visible=Rect2(camera,c.VIEW).grow(80)
	for index in routes.size():
		var point:Vector2=guard_position(index)
		if visible.has_point(point):guard(c,point-camera,point.distance_to(_guard_at_time(index,clock-.05))>0.1)
		if index>=3:
			var partner:Vector2=_guard_at_time(index,clock-.85)+Vector2(0,18)
			if visible.has_point(partner):guard(c,partner-camera,true)
