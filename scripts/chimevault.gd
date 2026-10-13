extends Node
## Three deterministic maze floors, shared by solo and the multiplayer host.
var adventure: Node
var active := false
var stage := 0
var started := false
var complete := false
var gates: Array[Vector2] = []
var grids: Array[AStarGrid2D] = []
var cells: Array = []
const TILE := 160.0
const NAMES := ["Echo Vestibule","Bell Foundry","Silent Crown"]
func setup(id: String) -> void:
	active=id=="chimevault";stage=0;started=false;complete=false
	if not active:return
	build_mazes()
func origin(n: int) -> Vector2: return Vector2(n*3000+100,100)
func cell_point(cell: Vector2i,n: int) -> Vector2: return origin(n)+(Vector2(cell)+Vector2(.5,.5))*TILE
func build_mazes() -> void:
	cells.clear();grids.clear();gates.clear()
	for n in 3:
		var rng:=RandomNumberGenerator.new();rng.seed=92063+n*721
		var opened:Dictionary={Vector2i(1,1):true};var stack:Array[Vector2i]=[Vector2i(1,1)]
		while not stack.is_empty():
			var current:=stack[-1];var choices:Array[Vector2i]=[]
			for direction in [Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2),Vector2i(0,-2)]:
				var next:Vector2i=current+direction
				if next.x>0 and next.y>0 and next.x<16 and next.y<12 and not opened.has(next):choices.append(next)
			if choices.is_empty():stack.pop_back();continue
			var next:=choices[rng.randi_range(0,choices.size()-1)]
			opened[(current+next)/2]=true;opened[next]=true;stack.append(next)
		# A few loops provide alternate routes around enemies without removing the maze.
		for k in 10:
			var cell:=Vector2i(rng.randi_range(2,14),rng.randi_range(2,10))
			if opened.has(cell+Vector2i(1,0)) and opened.has(cell-Vector2i(1,0)):opened[cell]=true
		var grid:=AStarGrid2D.new();grid.region=Rect2i(0,0,17,13);grid.cell_size=Vector2(TILE,TILE);grid.offset=origin(n)+Vector2(TILE*.5,TILE*.5);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
		for x in 17:
			for y in 13:grid.set_point_solid(Vector2i(x,y),not opened.has(Vector2i(x,y)))
		var far:=Vector2i(1,1);var longest:=0
		for cell in opened:
			var length:=grid.get_id_path(Vector2i(1,1),cell).size()
			if length>longest:longest=length;far=cell
		# Give the guardian enough room to swing its bell.
		for x in range(maxi(1,far.x-1),mini(16,far.x+2)):
			for y in range(maxi(1,far.y-1),mini(12,far.y+2)):
				opened[Vector2i(x,y)]=true;grid.set_point_solid(Vector2i(x,y),false)
		cells.append(opened);grids.append(grid);gates.append(cell_point(far,n))
func can_stand(point: Vector2) -> bool:
	var n:=int(point.x/3000)
	if n<0 or n>=cells.size():return false
	for corner in [Vector2(-22,-22),Vector2(22,-22),Vector2(-22,22),Vector2(22,22)]:
		var cell:=Vector2i(((point+corner-origin(n))/TILE).floor())
		if not cells[n].has(cell):return false
	return true
func clear_path(start: Vector2,end: Vector2) -> bool:
	var count:=maxi(1,int(ceil(start.distance_to(end)/12)))
	for k in range(count+1):
		if not can_stand(start.lerp(end,float(k)/count)):return false
	return true
func spawn_stage() -> void:
	started=true
	if adventure.arcade:adventure.game.wave=stage+1
	var grid:=grids[stage];var end:=Vector2i(((gates[stage]-origin(stage))/TILE).floor())
	var route:=grid.get_id_path(Vector2i(1,1),end)
	for k in 10:
		var index:=clampi(4+int(float(k)/10*maxi(1,route.size()-8)),1,route.size()-2)
		spawn_actor("tuning_wraith" if k%2==0 else "resonance_beetle",cell_point(route[index],stage),95+stage*25,false)
	spawn_actor("gongbreaker",gates[stage],1100+stage*300,true)
	if stage==2:
		spawn_actor("silence_regent",cell_point(route[maxi(2,route.size()/2)],stage),2400,true)
	adventure.announce("Chimevault • "+NAMES[stage]+" • defeat the guardian and find the lift")
func spawn_actor(kind: String,point: Vector2,hp: float,boss: bool) -> void:
	adventure.spawn(kind,point,hp,boss)
	var foe:Dictionary=adventure.foes()[-1];foe["vault_actor"]=true;foe["vault_stage"]=stage;foe["vault_timer"]=2.0;foe["nav_timer"]=0.0
func step(delta: float) -> void:
	if not started:spawn_stage()
	if complete:return
	for foe in adventure.foes():
		if not bool(foe.get("vault_actor",false)) or adventure.combat.stunned(adventure.combat.npc_key(foe)):continue
		var target:=Vector2.ZERO;var distance:=INF
		for id in adventure.points():
			if adventure.arcade:
				if Time.get_ticks_msec()<int(adventure.game.stealth_until.get(id,0)):continue
			elif adventure.game.stealth_time>0:continue
			if adventure.alive(str(id)) and int((adventure.points()[id] as Vector2).x/3000)==stage and (foe["pos"] as Vector2).distance_to(adventure.points()[id])<distance:
				target=adventure.points()[id];distance=(foe["pos"] as Vector2).distance_to(target)
		if distance==INF:continue
		var kind:=str(foe["type"])
		var speed:=35.0 if kind=="gongbreaker" else 48.0 if kind=="silence_regent" else 92.0
		speed*=adventure.combat.speed_factor(adventure.combat.npc_key(foe))
		foe["nav_timer"]=float(foe.get("nav_timer",0))-delta
		if float(foe["nav_timer"])<=0:
			foe["nav_timer"]=.5
			var first:=Vector2i(((foe["pos"]-origin(stage))/TILE).floor());var last:=Vector2i(((target-origin(stage))/TILE).floor())
			var path:=grids[stage].get_point_path(first,last,true)
			foe["nav_goal"]=(path[1] if clear_path(foe["pos"],path[1]) else path[0]) if path.size()>1 else target
		var destination:Vector2=target if clear_path(foe["pos"],target) else foe.get("nav_goal",target)
		var direction:Vector2=adventure.combat.ranged_direction(foe,target) if kind=="tuning_wraith" and clear_path(foe["pos"],target) else (destination-(foe["pos"] as Vector2)).normalized()
		var next:Vector2=foe["pos"]+direction*minf(speed*delta,(destination-(foe["pos"] as Vector2)).length())
		if can_stand(next):foe["pos"]=next
		foe["vault_timer"]=float(foe["vault_timer"])-delta
		if float(foe["vault_timer"])>0 or distance>650:continue
		foe["vault_timer"]=4.5 if kind in ["gongbreaker","silence_regent"] else 3.5
		var point:Vector2=foe["pos"];var aim:Vector2=(target-point).normalized()
		match kind:
			"tuning_wraith":
				for k in 3:adventure.warn_wave(point,aim.rotated((k-1)*.3)*260,22,19+stage*3,650,.85,"#7ae5e7")
			"resonance_beetle":
				adventure.launch_lob("enemy",point,target,{"travel_speed":230,"blast_radius":90,"color":"#f0bd69"},22+stage*3)
			"gongbreaker":
				if distance<260:adventure.warn(target,115,45+stage*5,1.35)
				else:
					for k in 3:adventure.warn_wave(point,aim*210,36,38+stage*3,650,1.1+k*.25,"#f2bd71")
			"silence_regent":
				var turn:=int(foe.get("vault_turn",0));foe["vault_turn"]=turn+1
				if turn%2==0:
					for k in 8:adventure.warn_wave(point,Vector2.from_angle(TAU*k/8)*260,30,36,750,1.1,"#dfadf2")
				else:
					for k in 3:adventure.warn(target+Vector2((k-1)*100,0),80,42,1.1+k*.25)
func on_defeat(foe: Dictionary) -> bool:
	return bool(foe.get("vault_actor",false)) and bool(foe.get("boss",false))
func interact(id: String) -> bool:
	if not adventure.alive(id):return false
	if (adventure.points()[id] as Vector2).distance_to(gates[stage])>120:return false
	if not adventure.foes().is_empty():
		adventure.announce("The lift stays sealed while enemies remain on this floor.");return true
	if stage==2:
		complete=true
		if adventure.arcade:adventure.game.end_match("The Chimevault silenced • three maze floors cleared!")
		else:adventure.game.finish_run(true)
		return true
	stage+=1;started=false
	if adventure.arcade: adventure.game.wave=stage+1
	adventure.warnings.clear();adventure.waves.clear();adventure.lob_shots.clear();adventure.lob_blasts.clear()
	for who in adventure.points():
		adventure.teleport(str(who),cell_point(Vector2i(1,1),stage)+Vector2(20*(stage%2),0))
	spawn_stage()
	return true
func snapshot() -> Dictionary: return {"active":active,"stage":stage,"started":started,"complete":complete}
func receive(data: Dictionary) -> void:
	active=bool(data.get("active",false));stage=int(data.get("stage",0));started=bool(data.get("started",false));complete=bool(data.get("complete",false))
	if active and grids.is_empty():build_mazes()
func draw_world(canvas: Node2D,camera: Vector2) -> void:
	var visible:=Rect2(camera-Vector2(180,180),canvas.get_viewport_rect().size+Vector2(360,360))
	for n in 3:
		for x in 17:
			for y in 13:
				var at:=origin(n)+Vector2(x,y)*TILE
				if not visible.intersects(Rect2(at,Vector2(TILE,TILE))):continue
				var point:=at-camera
				if cells[n].has(Vector2i(x,y)):
					canvas.draw_rect(Rect2(point,Vector2(TILE,TILE)),Color(["#243337","#3c2d29","#302d42"][n]))
					canvas.draw_rect(Rect2(point+Vector2(4,4),Vector2(TILE-8,TILE-8)),Color(["#304447","#625041","#56506e"][n]),false,2)
					if (x+y)%3==0:canvas.draw_arc(point+Vector2(80,80),18,0,TAU,20,Color(.3,.7,.7,.22),2)
				else:
					canvas.draw_rect(Rect2(point,Vector2(TILE,TILE)),Color("#101921"))
					canvas.draw_rect(Rect2(point+Vector2(6,6),Vector2(TILE-12,TILE-12)),Color(["#49605a","#887354","#786983"][n]),false,5)
					canvas.draw_line(point+Vector2(8,8),point+Vector2(TILE-8,8),Color("#b09962"),3)

func draw_on(canvas: Node2D,camera: Vector2) -> void:
	for n in 3:
		var point:=gates[n]-camera
		canvas.draw_arc(point,45,0,TAU,40,Color("#83e2dd"),5,true)
		canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-100,-65),"E • Lift" if n<2 else "E • Seal the Chimevault",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#d9d4a9"))
	canvas.draw_string(ThemeDB.fallback_font,Vector2(28,145),"CHIMEVAULT • "+NAMES[stage]+" • Floor "+str(stage+1)+" / 3 • "+str(adventure.foes().size())+" enemies remain",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#98e0d9"))

	if adventure.foes().is_empty():
		var player:Vector2=adventure.game.local_pos if adventure.arcade else adventure.game.position_in_world
		var direction:Vector2=(gates[stage]-player).normalized()
		var center:=Vector2(canvas.get_viewport_rect().size.x-90,150)
		canvas.draw_arc(center,24,0,TAU,32,Color("#83e2dd"),2,true)
		canvas.draw_line(center,center+direction*20,Color("#83e2dd"),4,true)
		canvas.draw_string(ThemeDB.fallback_font,center+Vector2(-35,42),"Find lift",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#d9d4a9"))
