extends Node
## Shared solo/co-op four-realm adventure; authority stays with the multiplayer host.
var polish:Node
var newcomers:Node
var additions:Node
var game: Node
var arcade := false
var active := false
var marsh := false
var river := false
var clockwork := false
var astral := false
var waves: Array = []
var vault: Node
var combat: Node
var city: Node
var hollow:Node
var quests:Node
var expansion:Node
var immersive:Node
var tech:Node
var foundry:Node
var school:Node
var lob_shots: Array = []
var lob_blasts: Array = []
var lob_snapshot_msec := 0
var healing_zones: Array = []
var discs: Array = []
var trials: Array = []
var visited: Array = []
var cleared: Array = []
var final_started := false
var complete := false
var stolen: Dictionary = {}
var traps: Array = []
var warnings: Array = []
var clock := 0.0
var last_trap_hit: Dictionary = {}
const HUB := Vector2(11130,2730)
const FINAL_SPAWN := Vector2(10010,6160)
const OATH_EXIT := FINAL_SPAWN+Vector2(140,0)
var hub_populated:=false

func _ready() -> void:
	game = get_parent()
	polish=preload("res://scripts/realm_polish.gd").new();add_child(polish);polish.adventure=self
	newcomers=preload("res://scripts/realm_v143.gd").new();add_child(newcomers);newcomers.adventure=self
	additions=preload("res://scripts/realm_v103.gd").new();add_child(additions);additions.adventure=self
	vault = preload("res://scripts/chimevault.gd").new();add_child(vault)
	vault.adventure=self
	combat=preload("res://scripts/object_combat.gd").new();add_child(combat);combat.adventure=self
	arcade = game.has_method("_attack_request")
	city=preload("res://scripts/lantern_city.gd").new();add_child(city);city.adventure=self
	hollow=preload("res://scripts/moonburrow.gd").new();add_child(hollow);hollow.adventure=self

	quests=preload("res://scripts/quest_world.gd").new();add_child(quests);quests.adventure=self

	expansion=preload("res://scripts/v43_expansion.gd").new();add_child(expansion);expansion.adventure=self

	immersive=preload("res://scripts/immersive_worlds.gd").new();add_child(immersive);immersive.adventure=self
	tech=preload("res://scripts/neon_crucible.gd").new();add_child(tech);tech.adventure=self
	foundry=preload("res://scripts/confluence_world.gd").new();add_child(foundry);foundry.adventure=self
	school=preload("res://scripts/school_world.gd").new();add_child(school);school.adventure=self

func setup(id: String) -> void:
	newcomers.setup()
	additions.setup()
	immersive.setup(id)
	tech.setup(id)
	foundry.setup(id)
	school.setup(id)
	expansion.setup(id)
	quests.setup(id)
	hollow.setup(id)
	city.setup(id)
	vault.setup(id)
	combat.setup(id)
	polish.setup(id)
	waves.clear()
	active = id == "shattered_oath"
	marsh = id == "lantern_marsh" and not immersive.active
	river = id == "silverfall" and not immersive.active
	clockwork = id == "clockwork_orchard"
	astral = id == "astral_rift"
	lob_shots.clear();lob_blasts.clear()
	healing_zones.clear()
	discs.clear()
	trials.clear()
	visited.clear();cleared.clear();warnings.clear();traps.clear();stolen.clear()
	hub_populated=false;final_started = false;complete = false;clock = 0.0;last_trap_hit.clear()
	if astral:
		for n in 3: traps.append({"rect":[2500+n*1400,1100,95,1400],"period":5.5,"on":1.5,"phase":n*1.2,"trial":3})
	if not active: return
	var data: Dictionary = game.regions.get(id,{}) if arcade else game.region
	trials = data.get("trials",[])
	for n in trials.size():
		var origin := vec(trials[n]["origin"])
		for k in 4:
			traps.append({"rect":[origin.x+910+k*280,origin.y+1190,154,420],"period":[3.8,4.6,3.2,2.6][n],"on":[1.5,2.7,1.35,1.0][n],"phase":k*[.9,1.3,1.6,.7][n],"trial":n})

func vec(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))
func foes() -> Array:
	return game.opponents if arcade else game.enemies
func points() -> Dictionary:
	if not arcade and game.practice:return {"solo":game.position_in_world,"training_ally":game.training_yard.ALLY}
	return game.positions if arcade else {"solo":game.position_in_world}
func alive(id: String) -> bool:
	if id=="training_ally":return not arcade and game.practice and game.training_yard.ally_health>0
	if combat!=null and id.begins_with("summon:"):return float(combat.summon_body(id).get("hp",0))>0
	if combat!=null and combat.morrow!=null and id.begins_with("risen:"):return bool(combat.morrow.actor(id).get("alive",false))
	if combat!=null and combat.pact!=null and id.begins_with("bond:"):return bool(combat.pact.ally_actor(id).get("alive",false))
	if combat!=null and combat.v59!=null and combat.v59.is_mirror(id):return bool(combat.v59.mirror_actor(id).get("alive",false))
	return int(game.health.get(id,0)) > 0 if arcade else game.health > 0
func authoritative() -> bool:
	return not arcade or game.role == "host"
func can_stand(point: Vector2) -> bool:
	if arcade and game.get("expedition")!=null and game.expedition.between():return game.expedition.expedition.open(point)
	if not arcade and game.get("waylight")!=null and game.waylight.between() and game.mode=="run":return game.waylight.expedition.open(point)
	if immersive.active:return immersive.can_stand(point)
	if foundry.active:return foundry.can_stand(point)
	if tech.active:return tech.can_stand(point)
	if school.active:return school.can_stand(point)
	if expansion.active:return expansion.can_stand(point)
	if quests.active:return quests.can_stand(point)
	if hollow.active:return hollow.can_stand(point)
	if city.active: return city.can_stand(point)
	if combat != null and combat.coast.active: return combat.coast.can_stand(point)
	if vault != null and vault.active: return vault.can_stand(point)
	if astral:
		for floor in [Rect2(180,1100,7640,1400),Rect2(600,500,1100,500),Rect2(3400,500,1200,500),Rect2(6500,500,1200,500),Rect2(1050,900,200,500),Rect2(3900,900,200,500),Rect2(7000,900,200,500)]:
			if floor.has_point(point): return true
		return false
	if river:
		for n in 3:
			var x := 1600.0+n*1800
			var y: float = [1100.0,2600.0,1400.0][n]
			if point.x > x and point.x < x+380 and absf(point.y-y)>180: return false
		return point.y > 460
	if not active: return true
	for trial in trials:
		var origin := vec(trial["origin"])
		var relative := point-origin
		if Rect2(42,42,2716,2716).has_point(relative):
			# Two walls funnel the crossing through the three timed trap gates.
			return not (relative.x > 826 and relative.x < 1778 and (relative.y < 1218 or relative.y > 1582))
	return Rect2(9562,1582,3276,2436).has_point(point) or Rect2(9562,4802,3276,2716).has_point(point)

func teleport(id: String, point: Vector2) -> void:
	if arcade and game.has_method("network_relocate"):
		game.network_relocate(id,point);return
	if arcade:
		game.positions[id] = point
		game.charges.erase(id)
		if id == game.my_id: game.local_pos = point;game.dodge_time=0
		else: game._send_channel(id,{"type":"teleport","point":[point.x,point.y]})
	else:
		game.charge_time=0;game.dodge_time=0;game.flame_bursts.clear()
		game.position_in_world = point
		game.update_camera()

func portals() -> Array:
	var result: Array = []
	for n in trials.size():
		var origin := vec(trials[n]["origin"])
		result.append({"pos":HUB+Vector2(-770+(n%2)*1540,-560+(n/2)*1050),"trial":n,"destination":origin+Vector2(280,1400),"label":str(trials[n]["name"])+( " • CLEARED" if cleared.has(n) else "")})
		result.append({"pos":origin+Vector2(210,1092),"trial":-1,"destination":HUB,"label":"Return to the Nexus"})
		if cleared.has(n): result.append({"pos":origin+Vector2(2380,1400),"trial":-1,"destination":HUB,"label":"Seal claimed • return"})
	result.append({"pos":HUB+Vector2(0,728),"trial":4,"destination":FINAL_SPAWN,"label":"The Gilded Usurper" if cleared.size()==4 else "Final rift • needs four seals"})
	return result

func interact(id: String) -> bool:
	if immersive.active:return immersive.interact(id)
	if foundry.active:return foundry.interact(id)
	if tech.active:return tech.interact(id)
	if school.active:return school.interact(id)
	if quests.active:return quests.interact(id)
	if hollow.active:return hollow.interact(id)
	if city.active: return city.interact(id)
	if combat != null and combat.coast.active: return combat.coast.interact(id)
	if vault != null and vault.active: return vault.interact(id)
	if not active or not alive(id): return false
	var point: Vector2 = points().get(id,Vector2.ZERO)
	if complete and point.distance_to(OATH_EXIT)<150:
		if arcade: game.end_match("The Shattered Oath restored!")
		else: game.finish_run(true)
		return true
	for portal in portals():
		if point.distance_to(portal["pos"]) > 115: continue
		var trial := int(portal["trial"])
		if trial == 4 and cleared.size()<4: return true
		if trial in range(4) and not visited.has(trial):
			visited.append(trial)
			spawn_trial(trial)
		if trial == 4 and not final_started:
			final_started = true
			spawn("gilded_usurper",Vector2(11480,6160),1300,true,4,0)
		teleport(id,portal["destination"])
		return true
	return false

func spawn(kind: String, point: Vector2, hp: float, boss: bool, trial: int=-1, generation: int=0) -> void:
	var scale := 1.0+.55*maxi(0,points().size()-1)
	var foe := {"pos":point,"hp":hp*scale,"max_hp":hp*scale,"type":kind,"boss":boss,"uid":randi(),"lane":0,"attack_timer":0.0,"secondary_timer":3.0,"windup":0.0,"expansion_boss":boss,"trial_index":trial,"generation":generation,"skill_timer":2.0,"skill_step":0}
	foes().append(foe)

func spawn_trial(n: int) -> void:
	var trial: Dictionary = trials[n]
	var origin := vec(trial["origin"])
	for k in 18:
		spawn(str(trial["enemy"]),origin+Vector2(1940+(k%4)*180,500+(k/4)*400),95,false,n)
	spawn(str(trial["boss"]),origin+Vector2(2324,1400),850+n*130,true,n)

func on_defeat(enemy: Dictionary) -> bool:
	if arcade and game.get("expedition")!=null and game.expedition.special():game.expedition.defeated(enemy)
	if newcomers.on_defeat(enemy):return true
	if immersive.active and immersive.on_defeat(enemy):return true
	if foundry.active and foundry.on_defeat(enemy):return true
	if tech.active and tech.on_defeat(enemy):return true
	if school.active and school.on_defeat(enemy):return true
	if vault != null and vault.active: return vault.on_defeat(enemy)
	if not active or not bool(enemy.get("expansion_boss",false)): return false
	var n := int(enemy.get("trial_index",-1))
	if n == 4 and int(enemy.get("generation",0))<2:
		var generation := int(enemy.get("generation",0))+1
		for child in 3:
			spawn("gilded_usurper",enemy["pos"]+Vector2.from_angle(TAU*child/3.0)*95,380 if generation==1 else 150,true,4,generation)
		announce("The Usurper fractures into three!")
	elif n in range(4):
		# A seal requires the guardian AND every original enemy in its trial.
		enemy["guardian_dead"] = true
		for foe in foes():
			if int(foe.get("trial_index",-1))==n: return true
		clear_trial(n)
	else:
		var bosses := false
		for foe in foes():
			if bool(foe.get("expansion_boss",false)) and int(foe.get("trial_index",-1))==4: bosses=true
		if not bosses:
			complete = true
			restore_xp()
			announce("The Usurper is gone. Stolen XP restored! Use the glowing exit seal near the arena entrance.")
	return true

func clear_trial(n: int) -> void:
	if cleared.has(n): return
	cleared.append(n)
	for id in points():
		if arcade:
			if alive(str(id)): game.health[id] = mini(game._max_hp(str(id)),int(game.health[id])+30)
		else: game.health = minf(game.max_health(),game.health+30)
	announce(str(trials[n]["name"])+" seal claimed! "+str(cleared.size())+"/4")

func check_trial_clear(enemy: Dictionary) -> void:
	if not active: return
	var n := int(enemy.get("trial_index",-1))
	if n not in range(4) or cleared.has(n): return
	for foe in foes():
		if int(foe.get("trial_index",-1))==n: return
	clear_trial(n)

func announce(message: String) -> void:
	if arcade: game.status_label.text = message
	else: game.message=message;game.message_time=7.0

func drain(id: String) -> void:
	var entry: Dictionary = stolen.get(id,{"xp":0,"gold":0})
	if arcade:
		# Multiplayer XP is stored as progress into the next level.
		var level := int(game.levels.get(id,1));var progress := int(game.xp.get(id,0))
		var total := progress
		for prior in range(1,level): total += 5+prior*3
		var loss := mini(24,total)
		entry["xp"] = int(entry["xp"])+loss
		total -= loss
		level=1
		while total >= 5+level*3 and level < 10: total-=5+level*3;level+=1
		game.levels[id]=level;game.xp[id]=total
		var coins := mini(5,int(game.gold.get(id,0)));game.gold[id]=int(game.gold.get(id,0))-coins;entry["gold"]+=coins
	else:
		var loss := mini(36,game.experience)
		entry["xp"] = int(entry["xp"])+loss
		game.experience -= loss
		game.level = clampi(1+int(game.experience/(int(game.region.get("xp_per_level",4))*10)),1,10)
		var coins := mini(5,game.gold);game.gold-=coins;entry["gold"]+=coins
		game.add_float_text(game.position_in_world-Vector2(50,70),"XP STOLEN • LEVEL "+str(game.level),Color("#c9a4ee"))
	stolen[id] = entry
	announce("Soul Tax hit! XP stolen; abilities follow your current level.")

func restore_xp() -> void:
	for id in stolen:
		var entry: Dictionary = stolen[id]
		if arcade:
			var total := int(game.xp.get(id,0))+int(entry["xp"])
			var level := int(game.levels.get(id,1))
			for prior in range(1,level): total+=5+prior*3
			level=1
			while total >= 5+level*3 and level<10:total-=5+level*3;level+=1
			game.levels[id]=level;game.xp[id]=total;game.gold[id]=int(game.gold.get(id,0))+int(entry["gold"])
		else:
			game.experience+=int(entry["xp"]);game.gold+=int(entry["gold"])
			game.level=clampi(1+int(game.experience/(int(game.region.get("xp_per_level",4))*10)),1,10)
	stolen.clear()

var warning_credit:Dictionary={}
func warn(point: Vector2, radius: float, damage: float, delay: float=.9, end: Vector2=Vector2.ZERO, steal: bool=false) -> void:
	warnings.append({"credit":warning_credit.duplicate(true),"pos":[point.x,point.y],"end":[end.x,end.y],"radius":radius,"damage":damage,"time":delay,"duration":delay,"steal":steal})

func hit_player(id: String, amount: float, source:String="",cause:Dictionary={}) -> void:
	if id.begins_with("risen:"):combat.morrow.hurt(id,amount,"enemy");return
	if id.begins_with("bond:"):combat.pact.hurt_ally(id.trim_prefix("bond:"),amount,"enemy");return
	if combat.v59.is_mirror(id):combat.v59.hurt_copy(id.trim_prefix("mirror:"),amount,"enemy");return
	if arcade: game._hurt(id,amount,"enemy",source,cause)
	else: game.take_player_damage(amount,source,cause)

func step(delta: float) -> void:
	warning_credit.clear()
	if not authoritative(): return
	# Rift echoes use a bounded independent AI; keep hero combat effects, not realm scripts.
	if not arcade and game.mistglass_rift!=null and game.mistglass_rift.active:
		combat.step(delta);step_lobs(delta);step_healing_zones(delta);step_discs(delta);return
	if active and not hub_populated:
		hub_populated=true
		for n in 16:
			var point:=HUB+Vector2.from_angle(TAU*n/16)*Vector2(1050,950)
			spawn("oath_shade" if n%3 else "storm_rook",point,80,false,-2)
	newcomers.step(delta)
	additions.step(delta)
	immersive.step(delta)
	tech.step(delta)
	foundry.step(delta)
	school.step(delta)
	expansion.step(delta)
	quests.step(delta)
	combat.step(delta)
	city.step(delta)
	hollow.step(delta)
	step_waves(delta)
	if vault != null and vault.active: vault.step(delta)
	step_lobs(delta)
	step_healing_zones(delta)
	step_discs(delta)
	polish.bosses(delta)
	if not active and not marsh and not river and not clockwork and not astral and not vault.active and not city.active and not hollow.active and not quests.active and not expansion.active and not school.active and not tech.active and not (game.realm_id=="moonveil" if arcade else game.region_id=="moonveil"): return
	clock+=delta
	for n in range(warnings.size()-1,-1,-1):
		var warning: Dictionary = warnings[n]
		warning["time"]-=delta
		if float(warning["time"])>0: continue
		var center := vec(warning["pos"]);var end := vec(warning["end"])
		for id in ([] if warning.has("wave") else points().keys()):
			if not alive(str(id)):continue
			var point: Vector2 = points()[id]
			var impact := point.distance_to(center)<float(warning["radius"])
			if end!=Vector2.ZERO: impact=Geometry2D.get_closest_point_to_segment(point,center,end).distance_to(point)<float(warning["radius"])
			if impact:
				var protected: bool = Time.get_ticks_msec()<int(game.invincible_until.get(id,0)) if arcade else game.invulnerable_time>0
				hit_player(str(id),float(warning["damage"]),"",warning.get("credit",{}))
				if bool(warning["steal"]) and not protected and alive(str(id)):drain(str(id))
		if warning.has("wave"):
			launch_wave(center,vec(warning["wave"]),float(warning["radius"]),float(warning["damage"]),float(warning.get("distance",600)),str(warning.get("colour","#94dcff")))
			warnings.remove_at(n)
			continue
		if warning.has("charge_uid"):
			for foe in foes():
				if int(foe.get("uid",0))==int(warning["charge_uid"]):foe["pos"]=end
		warnings.remove_at(n)
	for trap in traps:
		if fmod(clock+float(trap["phase"]),float(trap["period"]))>=float(trap["on"]):continue
		var bounds := Rect2(float(trap["rect"][0]),float(trap["rect"][1]),float(trap["rect"][2]),float(trap["rect"][3]))
		for id in points():
			if alive(str(id)) and bounds.has_point(points()[id]) and clock-float(last_trap_hit.get(id,-2.0))>.8:
				hit_player(str(id),18 if active else 12,"",preload("res://scripts/defeat_credit.gd").hazard("Realm trap"));last_trap_hit[id]=clock
	for enemy in foes().duplicate():
		if bool(enemy.get("immersive",false)) or str(enemy.get("type","")) in newcomers.TYPES:continue
		if str(enemy.get("type","")) in foundry.TYPES or str(enemy.get("type","")) in tech.TYPES or str(enemy.get("type","")) in school.TYPES or str(enemy.get("type","")) in expansion.TYPES or str(enemy.get("type","")) in hollow.TYPES or str(enemy.get("type","")) in city.TYPES or bool(enemy.get("vault_actor",false)) or combat.stunned(combat.npc_key(enemy)):continue
		var definitions: Dictionary = game.enemy_defs if arcade else game.enemy_types
		var custom := str(definitions.get(str(enemy["type"]),{}).get("custom_attack",""))
		if not bool(enemy.get("expansion_boss",false)) and custom.is_empty():continue
		warning_credit=preload("res://scripts/defeat_credit.gd").resolve(game,combat.npc_key(enemy),"Area attack")
		var target := Vector2.ZERO;var nearest:=INF
		for id in points():
			if alive(str(id)) and enemy["pos"].distance_to(points()[id])<nearest:target=points()[id];nearest=enemy["pos"].distance_to(target)
		target=combat.fern.redirect(enemy,target)
		if bool(enemy.get("expansion_boss",false)) and str(enemy.type) not in ["hourglass_hart","mirror_marquis","gilded_usurper"] and nearest<1200:
			var heading:Vector2=(target-(enemy.pos as Vector2)).normalized()
			if nearest<240:heading=heading.orthogonal()*(-1 if int(enemy.uid)%2 else 1)
			var movement:Vector2=heading*100*combat.speed_factor(combat.npc_key(enemy))*delta
			if can_stand(enemy.pos+movement) and combat.path_clear(enemy.pos,enemy.pos+movement):enemy.pos+=movement
		if str(enemy["type"])=="hourglass_hart" and nearest<1400:
			move_clockwork_hart(enemy,target,delta)
		if str(enemy["type"])=="mirror_marquis" and nearest<1000:
			var orbit:=target+Vector2.from_angle(clock*1.6)*300
			var movement:Vector2=(orbit-(enemy["pos"] as Vector2)).normalized()*145*combat.speed_factor(combat.npc_key(enemy))*delta
			if combat.path_clear(enemy["pos"],enemy["pos"]+movement):enemy["pos"]+=movement
		if str(enemy["type"])=="gilded_usurper" and nearest<1600:
			var orbit:=Vector2.from_angle(clock*1.4+int(enemy.get("uid",0))%10)*330
			var destination:=target+orbit
			var move:Vector2=(destination-(enemy["pos"] as Vector2)).normalized()*(135+int(enemy.get("generation",0))*15)*combat.speed_factor(combat.npc_key(enemy))*delta
			var end:Vector2=(enemy["pos"] as Vector2)+move
			if combat.path_clear(enemy["pos"],end):enemy["pos"]=end
			elif combat.path_clear(enemy["pos"],enemy["pos"]+Vector2(-move.y,move.x)):enemy["pos"]+=Vector2(-move.y,move.x)
		if active and bool(enemy.get("expansion_boss",false)) and nearest<1500:
			enemy["ranged_timer"]=float(enemy.get("ranged_timer",1.6))-delta
			if float(enemy["ranged_timer"])<=0:
				enemy["ranged_timer"]=2.6 if str(enemy["type"])!="gilded_usurper" else 3.2
				var aim:Vector2=(target-(enemy["pos"] as Vector2)).normalized()
				for k in 3:combat.launch_projectile("enemy",enemy["pos"],aim.rotated((k-1)*.22),{"credit":warning_credit.duplicate(true),"range":1050,"speed":330,"color":"#e9b08e"},18 if str(enemy["type"])!="gilded_usurper" else 16)
		if nearest>(1500 if active else 800):continue
		enemy["skill_timer"] = float(enemy.get("skill_timer",2.0))-delta
		if float(enemy["skill_timer"])>0:continue
		enemy["skill_timer"]=(1.8 if int(enemy.get("generation",0))==0 else 2.5) if str(enemy["type"])=="gilded_usurper" else 2.8 if active else 3.4 if int(enemy.get("generation",0))==0 else 4.6
		var point: Vector2 = enemy["pos"]
		if custom in ["tide_cross","bell_echo","rootbound"]:
			if not combat.path_clear(point,target):continue
			var aim:Vector2=(target-point).normalized()
			if custom=="tide_cross":
				for angle in [-.28,.28]:combat.launch_projectile("enemy",point,aim.rotated(angle),{"credit":warning_credit.duplicate(true),"range":650,"speed":235,"slow_duration":2,"slow_factor":.65,"color":"#8fe4e1"},13,"weaving")
				warn_wave(point,aim*220,42,16,550,.85,"#8ad6db")
			elif custom=="bell_echo":
				for n in 5:combat.launch_projectile("enemy",point,aim.rotated((n-2)*.28),{"credit":warning_credit.duplicate(true),"range":700,"speed":210,"return_distance":260,"color":"#ead692"},12,"echo_bolt")
			else:
				var turn:=int(enemy.get("skill_step",0));enemy["skill_step"]=turn+1
				if turn%3==0:
					var endpoint:=point+aim*minf(280,point.distance_to(target)+40)
					if not combat.path_clear(point,endpoint):endpoint=point
					warn(point,46 if endpoint!=point else 90,23,.9,endpoint if endpoint!=point else Vector2.ZERO)
					if endpoint!=point:warnings[-1]["charge_uid"]=int(enemy.uid)
				elif turn%3==1:
					for n in 3:launch_lob("enemy",point,target+Vector2.from_angle(TAU*n/3)*90,{"travel_speed":300,"blast_radius":70,"color":"#afd99a"},17)
				else:
					for n in 5:combat.launch_projectile("enemy",point,aim.rotated((n-2)*.23),{"credit":warning_credit.duplicate(true),"range":650,"speed":240,"color":"#e7d28e"},14,"weaving")
			continue
		if custom=="prism_fan":
			var aim:Vector2=(target-point).normalized()
			for angle in [-.18,.18]:combat.launch_projectile("enemy",point,aim.rotated(angle),{"credit":warning_credit.duplicate(true),"range":600,"speed":250,"split_distance":180,"color":"#c7b3f0"},11,"split_lance")
			continue
		if custom == "lob":
			var definition: Dictionary = definitions.get(str(enemy["type"]),{})
			enemy["skill_timer"] = float(definition.get("skill_cooldown",3.8))
			launch_lob("enemy",point,target,{"travel_speed":float(definition.get("lob_speed",300)),"blast_radius":float(definition.get("blast_radius",85)),"color":str(definition.get("attack_color","#ffba75"))},float(definition.get("damage",12)))
			continue
		var kind := str(enemy["type"])
		var turn := int(enemy.get("skill_step",0));enemy["skill_step"]=turn+1
		var warning_start := warnings.size()
		match kind:
			"mirror_marquis":
				var aim:Vector2=(target-point).normalized()
				if turn%3==0:
					var endpoint:=point+aim*400
					if combat.path_clear(point,endpoint):
						warn(point,38,20,.85,endpoint);warnings[-1]["charge_uid"]=int(enemy["uid"])
				elif turn%3==1:
					for angle in [-.4,0,.4]:combat.launch_projectile("enemy",point,aim.rotated(angle),{"credit":warning_credit.duplicate(true),"range":700,"speed":300,"split_distance":180,"color":"#d0bbf0"},16,"split_lance")
				else:launch_lob("enemy",point,target,{"travel_speed":300,"blast_radius":100,"color":"#c4dcef"},22)
			"briar_matron":
				for k in 3: warn(target+Vector2((k-1)*130,0),72,15,1.05)
			"kiln_knight":
				var n:=int(enemy.get("trial_index",1));var origin:=vec(trials[n]["origin"])
				var end := (point+(target-point).normalized()*600).clamp(origin+Vector2(1848,140),origin+Vector2(2660,2660))
				warn(point,48,22,.95,end)
				warnings[-1]["charge_uid"]=int(enemy["uid"])
			"mirror_oracle":
				for k in 6:warn(point+Vector2.from_angle(TAU*k/6.0+clock)*230,70,13,1.1)
			"storm_archon":
				var ray := Vector2.from_angle(clock*.7)*650
				warn(point-ray,38,18,1.0,point+ray)
				warn(point-Vector2(-ray.y,ray.x),38,18,1.0,point+Vector2(-ray.y,ray.x))
			"rift_weaver":
				warn(target+Vector2(-85,0),60,12,1.0)
				warn(target+Vector2(85,0),60,12,1.0)
			"prism_kite":
				var ray := Vector2.from_angle(clock*.5)*280
				warn(point-ray,22,13,1.15,point+ray)
			"comet_urchin":
				var end := point+(target-point).normalized()*minf(300,nearest)
				warn(point,30,15,1.0,end)
				warnings[-1]["charge_uid"]=int(enemy["uid"])
			"eclipse_engine":
				match turn%3:
					0:
						for k in 6:warn_wave(point,Vector2.from_angle(TAU*k/6.0+clock*.1)*250,28,29,650,1.1,"#d9a9fa")
					1:
						for k in 3:
							warn_wave(point+Vector2((k-1)*90,0),(target-point).normalized()*310,30,32,850,1.0+k*.3,"#f0b6f5")
					2:
						warn(target,120,35,1.2)
						var count := 0
						for foe in foes():
							if str(foe["type"])=="prism_kite":count+=1
						if count<3:spawn("prism_kite",point+Vector2(-130,100),50,false)
			"hourglass_hart":
				match turn%3:
					0:
						for k in 5: warn(point+Vector2.from_angle(TAU*k/5.0+clock*.15)*230,65,17,1.25)
					1:
						var ray := (target-point).normalized()*450
						warn(point-ray,35,20,1.1,point+ray)
					2:
						warn(target,100,21,1.4)
			"crowned_torrent":
				match turn%3:
					0:
						for k in 3: warn(point+Vector2(-450,(k-1)*170),32,18,1.15,point+Vector2(450,(k-1)*170))
					1:
						for k in 3: warn(target+Vector2.from_angle(TAU*k/3.0)*110,65,16,1.2)
					2:
						warn(point,175,22,1.35)
						var eels := 0
						for foe in foes():
							if str(foe["type"]) == "ripple_eel": eels += 1
						if eels < 3: spawn("ripple_eel",point+Vector2(-130,100),45,false)
			"bellroot":
				for k in 8:warn(point+Vector2.from_angle(TAU*k/8.0+clock*.2)*210,60,14,1.1)
				if turn%2==0:
					var reeds:=0
					for foe in foes():
						if str(foe["type"])=="reed_stalker":reeds+=1
					if reeds<4:spawn("reed_stalker",point+Vector2(-140,80),45,false,-1)

			"gilded_usurper":
				match turn%3:
					0:
						var shades:=0
						for foe in foes():
							if str(foe["type"])=="oath_shade":shades+=1
						if shades<10:
							for k in 2:spawn("oath_shade",point+Vector2(k*100-50,90),70,false,4)
						warn(point,100,10,.9)
					1: warn(target,145,26,.65,Vector2.ZERO,true)
					2:
						var direction := (target-point).normalized()
						for k in 3:warn(point,38,24,.7,point+direction.rotated((k-1)*.35)*750)
		if kind in ["rift_weaver","prism_kite","comet_urchin","eclipse_engine"]:
			for index in range(warning_start,warnings.size()):
				warnings[index]["colour"] = "#b28feb" if kind == "rift_weaver" else "#91e2ef" if kind == "prism_kite" else "#edbc83" if kind == "comet_urchin" else "#e9b8fa"
				warnings[index]["visual"] = kind
	# Don't let incidental mobs follow a player across rifts.
	for foe in foes():
		if bool(foe.get("expansion_boss",false)):continue
		var n:=int(foe.get("trial_index",-1))
		if n in range(4):
			var origin:=vec(trials[n]["origin"])
			foe["pos"]=(foe["pos"] as Vector2).clamp(origin+Vector2(1820,140),origin+Vector2(2660,2660))

	warning_credit.clear()

func snapshot() -> Dictionary:
	return {"newcomers":newcomers.snapshot(),"additions":additions.snapshot(),"foundry":foundry.snapshot(),"immersive":immersive.snapshot(),"tech":tech.snapshot(),"school":school.snapshot(),"expansion":expansion.snapshot(),"quests":quests.snapshot(),"hollow":hollow.snapshot(),"city":city.snapshot(),"combat":combat.snapshot() if combat != null else {},"waves":waves,"vault":vault.snapshot() if vault != null else {},"lob_shots":lob_shots,"lob_blasts":lob_blasts,"healing_zones":healing_zones,"discs":discs,"active":active,"visited":visited,"cleared":cleared,"final":final_started,"complete":complete,"clock":clock,"warnings":warnings,"stolen":stolen}
func receive(data: Dictionary) -> void:
	newcomers.receive(data.get("newcomers",{}))
	additions.receive(data.get("additions",{}))
	immersive.receive(data.get("immersive",{}))
	tech.receive(data.get("tech",{}))
	foundry.receive(data.get("foundry",{}))
	school.receive(data.get("school",{}))
	expansion.receive(data.get("expansion",{}))
	quests.receive(data.get("quests",{}))
	hollow.receive(data.get("hollow",{}))
	city.receive(data.get("city",{}))
	if combat != null: combat.receive(data.get("combat",{}))
	visited.clear();cleared.clear()
	for value in data.get("visited",[]):visited.append(int(value))
	for value in data.get("cleared",[]):cleared.append(int(value))
	waves=data.get("waves",[])
	if vault != null: vault.receive(data.get("vault",{}))
	lob_shots=data.get("lob_shots",[]);lob_blasts=data.get("lob_blasts",[])
	lob_snapshot_msec=Time.get_ticks_msec()
	healing_zones=data.get("healing_zones",[])
	discs=data.get("discs",[])
	final_started=bool(data.get("final",false));complete=bool(data.get("complete",false));clock=float(data.get("clock",0));warnings=data.get("warnings",[]);stolen=data.get("stolen",{})


func draw_on(canvas: Node2D, camera: Vector2) -> void:
	newcomers.draw_on(canvas,camera)
	additions.draw_on(canvas,camera)
	immersive.draw_on(canvas,camera)
	tech.draw_on(canvas,camera)
	foundry.draw_on(canvas,camera)
	school.draw_on(canvas,camera)
	expansion.draw_on(canvas,camera)
	quests.draw_on(canvas,camera)
	hollow.draw_on(canvas,camera)
	city.draw_on(canvas,camera)
	if combat != null: combat.draw_on(canvas,camera)
	if vault != null and vault.active: vault.draw_on(canvas,camera)
	for wave in waves:
		var extra := minf(.25,(Time.get_ticks_msec()-lob_snapshot_msec)/1000.0) if arcade and not authoritative() else 0.0
		var point := vec(wave["pos"])+vec(wave["velocity"])*extra-camera
		var radius := float(wave["radius"])
		var tint := Color(str(wave["colour"]))
		canvas.draw_circle(point,radius,Color(tint,.14))
		canvas.draw_arc(point,radius,0,TAU,32,Color(tint,.65),3,true)
		canvas.draw_arc(point,radius*.6,0,TAU,24,Color(tint,.3),2,true)
	draw_lob_aim(canvas,camera)
	for shot in lob_shots:
		var extra := minf(.25,(Time.get_ticks_msec()-lob_snapshot_msec)/1000.0) if arcade and not authoritative() else 0.0
		var progress := clampf((float(shot["elapsed"])+extra)/float(shot["flight"]),0,1)
		var landing := vec(shot["end"])-camera
		var point := vec(shot["start"]).lerp(vec(shot["end"]),progress)-camera
		var tint := Color(str(shot["color"]))
		var enemy := str(shot["owner"]) == "enemy"
		if enemy:preload("res://scripts/combat_cues.gd").danger(canvas,landing,float(shot["radius"]),1-progress,1)
		else:
			canvas.draw_circle(landing,float(shot["radius"]),Color(tint,.08));canvas.draw_arc(landing,float(shot["radius"]),0,TAU,40,Color(tint,.6),2,true)
			canvas.draw_arc(landing,float(shot["radius"])*.85,-PI*.5,-PI*.5+TAU*progress,32,Color(tint,.9),3,true)
		canvas.draw_circle(point,6,Color(0,0,0,.3))
		point.y -= sin(progress*PI)*70
		if str(shot.get("cast_visual",""))=="fragment":
			canvas.draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),Color("#bfd49b"))
			canvas.draw_line(point+Vector2(0,-5),point+Vector2(4,-10),Color("#f3dfa0"),2,true)
		if str(shot.get("cast_visual",""))=="storm":
			canvas.draw_arc(point,17,progress*TAU,progress*TAU+PI*1.7,18,Color(tint,.8),3,true)
			preload("res://scripts/lightning.gd").draw_on(canvas,point-Vector2(12,18),point+Vector2(12,12),tint)
		if str(shot.get("cast_visual",""))=="meteor":
			canvas.draw_line(point,point+Vector2(-18,-55),Color(tint,.35),14,true)
			canvas.draw_line(point,point+Vector2(-14,-42),Color(tint,.8),5,true)
			canvas.draw_circle(point,13*float(shot.get("comet_size",1)),Color(tint,.25))
		canvas.draw_circle(point,(9 if bool(shot["ice"]) else 6)*float(shot.get("comet_size",1)),tint)
		canvas.draw_circle(point,3,Color.WHITE)
		canvas.draw_line(point,point-Vector2(0,18),Color(tint,.5),3)
	for blast in lob_blasts:
		var progress := 1-float(blast["time"])/.45
		var point := vec(blast["pos"])-camera
		var tint := Color(str(blast["color"]))
		if str(blast.get("cast_visual",""))=="storm":
			for n in 6:
				var end:=point+Vector2.from_angle(TAU*n/6)*float(blast["radius"])*maxf(.2,progress)
				preload("res://scripts/lightning.gd").draw_on(canvas,point,end,Color(tint,1-progress))
		canvas.draw_circle(point,float(blast["radius"]),Color(tint,.18*(1-progress)))
		canvas.draw_arc(point,maxf(4,float(blast["radius"])*progress),0,TAU,48,Color(tint,1-progress),6,true)
	for zone in healing_zones:
		var point := vec(zone["pos"])-camera
		var radius := float(zone["radius"])
		canvas.draw_circle(point,radius,Color(.2,.8,.5,.18))
		canvas.draw_arc(point,radius,0,TAU,48,Color(.55,1,.7,.8),3,true)
		preload("res://scripts/combat_cues.gd").healing(canvas,point,radius)
	for disc in discs:
		var point := vec(disc["pos"])-camera
		canvas.draw_arc(point,17,float(disc["life"])*8,float(disc["life"])*8+TAU*.85,16,Color("#94eafa"),5,true)
		canvas.draw_circle(point,7,Color("#e8f7ee"))
	if not active and not marsh and not river and not clockwork and not astral:return
	var font:=ThemeDB.fallback_font
	if astral:
		for n in 22:
			var point := Vector2(300+n*347,300+sin(n*1.7)*200)-camera
			canvas.draw_circle(point,3+sin(clock*2+n),Color(.55,.7,1,.8))
			if n%3!=0:canvas.draw_line(point,Vector2(300+(n-1)*347,300+sin((n-1)*1.7)*200)-camera,Color(.3,.5,.8,.3),1)
	for trial in trials:
		var origin:=vec(trial["origin"])
		for rect in [Rect2(origin+Vector2(826,0),Vector2(952,1218)),Rect2(origin+Vector2(826,1582),Vector2(952,1218))]:
			canvas.draw_rect(Rect2(rect.position-camera,rect.size),Color("#171c2c"))
			canvas.draw_rect(Rect2(rect.position-camera,rect.size),Color("#727394"),false,4)
	for trap in traps:
		var bounds:=Rect2(float(trap["rect"][0]),float(trap["rect"][1]),float(trap["rect"][2]),float(trap["rect"][3]))
		var phase:=fmod(clock+float(trap["phase"]),float(trap["period"]))
		var hot:=phase<float(trap["on"])
		canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color(0.95,.38,.20,.28) if hot else Color(.25,.85,.62,.12))
		canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#f4bc70") if hot else Color("#6dcba8"),false,3)
		if hot:
			var center := bounds.get_center()-camera
			match int(trap["trial"]):
				0:
					for k in 4:
						var tip:=center+Vector2(-40+k*25,-20)
						canvas.draw_colored_polygon(PackedVector2Array([tip+Vector2(-9,25),tip+Vector2(0,-15),tip+Vector2(9,25)]),Color("#b0bd73"))
				1:
					for k in 4:canvas.draw_line(center+Vector2(-35+k*22,25),center+Vector2(-30+k*22,-40),Color("#ffdf82"),7,true)
				2:
					canvas.draw_line(center+Vector2(-45,-40),center+Vector2(45,40),Color("#d5ecff"),7,true)
				3:
					canvas.draw_polyline(PackedVector2Array([center+Vector2(5,-45),center+Vector2(-15,-4),center+Vector2(15,-10),center+Vector2(-5,45)]),Color("#eae9ad"),6,true)
		canvas.draw_string(font,bounds.position-camera+Vector2(-25,-12),"WAIT" if hot else "CROSS",HORIZONTAL_ALIGNMENT_LEFT,-1,17)
	for warning in warnings:
		var point:=vec(warning["pos"])-camera;var end:=vec(warning["end"])
		var colour:=Color(.80,.45,1,.75) if bool(warning["steal"]) else Color(str(warning.get("colour","#ff994dbf")))
		if end==Vector2.ZERO:
			preload("res://scripts/combat_cues.gd").danger(canvas,point,float(warning["radius"]),float(warning.time),float(warning.get("duration",1)),colour)
			if str(warning.get("visual","")) == "rift_weaver": canvas.draw_arc(point,float(warning["radius"])*.6,clock*2,clock*2+TAU*.8,32,colour,3,true)
			if bool(warning["steal"]):canvas.draw_string(font,point+Vector2(-45,-15),"SOUL TAX",HORIZONTAL_ALIGNMENT_LEFT,-1,17,colour)
		else:
			preload("res://scripts/combat_cues.gd").corridor(canvas,point,end-camera,float(warning["radius"]))
	for portal in (portals() if active else []):
		var point:Vector2=portal["pos"]-camera
		canvas.draw_arc(point,44,0,TAU,40,Color("#b5c5ff"),5,true)
		canvas.draw_string(font,point+Vector2(-95,-58),str(portal["label"]),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#e9dca9"))
		var player:Vector2=game.local_pos if arcade else game.position_in_world
		if player.distance_to(portal["pos"])<115:canvas.draw_string(font,Vector2(400,550),"Interact to enter • four seals "+str(cleared.size())+"/4",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#e9dca9"))
	if active:canvas.draw_string(font,Vector2(35,175 if not arcade else 108),"OATH SEALS "+str(cleared.size())+"/4 • traps cycle: red wait / green cross",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ddd6ee"))
	if complete:
		var exit_point:=OATH_EXIT-camera
		canvas.draw_circle(exit_point,65,Color(.35,.9,.65,.2));canvas.draw_arc(exit_point,55,clock,clock+TAU*.9,40,Color("#9bf0bc"),6,true)
		canvas.draw_string(font,exit_point+Vector2(-110,-75),"EXIT SEAL • E / Interact",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#b2e6bb"))
		canvas.draw_string(font,Vector2(350,200),"Restored! Use the green exit seal near the arena entrance.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#b2e6bb"))

func launch_disc(id: String, aim: Vector2, stats: Dictionary, damage: float) -> void:
	var owner_discs := 0
	for disc in discs:
		if str(disc["owner"])==id: owner_discs+=1
	if owner_discs>=4:return
	var origin: Vector2 = points().get(id,Vector2.ZERO)
	discs.append({"owner":id,"pos":[origin.x,origin.y],"aim":[aim.x,aim.y],"damage":damage,"range":float(stats.get("range",220)),"speed":float(stats.get("speed",380)),"distance":0.0,"life":0.0,"leg":0,"hit":[]})

func step_discs(delta: float) -> void:
	for n in range(discs.size()-1,-1,-1):
		var disc: Dictionary = discs[n]
		var id := str(disc["owner"])
		var disc_delta:float=combat.clock_delta(id,delta)
		disc["life"]+=disc_delta
		if not alive(id) or float(disc["life"])>3.0:discs.remove_at(n);continue
		var point := vec(disc["pos"])
		var owner: Vector2 = points().get(id,point)
		var returning := int(disc["leg"])==1
		var direction := (owner-point).normalized() if returning else vec(disc["aim"])
		var next := point+direction*float(disc["speed"])*disc_delta
		if returning and point.distance_to(owner)<float(disc["speed"])*disc_delta+20:discs.remove_at(n);continue
		var path_clear: bool = game._clear_path(point,next) if arcade else game.shot_path_clear(point,next)
		if not path_clear:
			if returning:discs.remove_at(n);continue
			disc["leg"]=1;continue
		disc["distance"]+=float(disc["speed"])*disc_delta
		for k in range(foes().size()-1,-1,-1):
			var foe: Dictionary = foes()[k]
			var key := str(foe.get("uid",k))+":"+str(disc["leg"])
			if (disc["hit"] as Array).has(key):continue
			if Geometry2D.get_closest_point_to_segment(foe["pos"],point,next).distance_to(foe["pos"])<35:
				(disc["hit"] as Array).append(key)
				if arcade:game._hit_enemy(k,float(disc["damage"]),id)
				else:game.damage_enemy(k,float(disc["damage"]))
		if arcade and game.mode in ["arena","battlegrounds"]:
			for other in game.positions:
				var key := "player:"+str(other)+":"+str(disc["leg"])
				if not game._rival(id,str(other)) or (disc["hit"] as Array).has(key):continue
				if Geometry2D.get_closest_point_to_segment(game.positions[other],point,next).distance_to(game.positions[other])<32:
					(disc["hit"] as Array).append(key);game._hurt(str(other),float(disc["damage"]),id)
		if arcade and game.mode=="battlegrounds":
			for target_key in game.battlegrounds.hostile(id):
				var a:Dictionary=game.battlegrounds.actor(target_key);var key:String=target_key+":"+str(disc.leg)
				if not disc.hit.has(key) and Geometry2D.get_closest_point_to_segment(a.pos,point,next).distance_to(a.pos)<32:disc.hit.append(key);game.battlegrounds.damage(target_key,float(disc.damage),id)
		disc["pos"]=[next.x,next.y]
		if not returning and float(disc["distance"])>=float(disc["range"]):disc["leg"]=1

func create_healing_zone(owner: String, stats: Dictionary) -> void:
	if not authoritative() or not points().has(owner): return
	var point: Vector2 = points()[owner]
	healing_zones.append({"owner":owner,"pos":[point.x,point.y],"radius":float(stats.get("radius",125)),"time":float(stats.get("duration",5)),"tick":0.0,"heal":int(stats.get("heal_per_tick",6))})

func step_healing_zones(delta: float) -> void:
	for i in range(healing_zones.size()-1,-1,-1):
		var zone: Dictionary = healing_zones[i]
		var owner := str(zone["owner"])
		if not points().has(owner):
			healing_zones.remove_at(i)
			continue
		zone["tick"] = float(zone["tick"])+minf(delta,float(zone["time"]))
		zone["time"] = maxf(0,float(zone["time"])-delta)
		while float(zone["tick"]) >= .99999:
			zone["tick"] = maxf(0,float(zone["tick"])-1.0)
			for target in points():
				if not alive(str(target)) or vec(zone["pos"]).distance_to(points()[target]) > float(zone["radius"]): continue
				if arcade:
					if game.mode in ["arena","battlegrounds"] and target != owner and (game.pvp_rule != "teams" or int(game.teams.get(target,-1)) != int(game.teams.get(owner,-2))): continue
					game._heal(owner,str(target),int(zone["heal"]))
				else: combat.release_heroes.heal(owner,str(target),int(zone["heal"]))
		if float(zone["time"]) <= .00001: healing_zones.remove_at(i)

func launch_lob(owner: String, origin: Vector2, target: Vector2, stats: Dictionary, damage: float) -> void:
	if not authoritative() or lob_shots.size() >= 64: return
	var speed := maxf(100,float(stats.get("travel_speed",400)))
	lob_shots.append({"stun":clampf(float(stats.get("stun_duration",0)),0,2),"owner":owner,"start":[origin.x,origin.y],"end":[target.x,target.y],"elapsed":0.0,"flight":clampf(origin.distance_to(target)/speed,.45,2.5),"radius":float(stats.get("blast_radius",110)),"damage":damage,"color":str(stats.get("color","#d6efff")),"ice":str(stats.get("style",""))=="ice_wall","slow":float(stats.get("slow_duration",0)),"cast_visual":str(stats.get("cast_visual","")),"fragments":clampi(int(stats.get("fragment_count",0)),0,8),"fragment_damage":float(stats.get("fragment_damage",4)),"fragment_radius":float(stats.get("fragment_radius",32)),"fragment_distance":float(stats.get("fragment_distance",95)),"wall_time":float(stats.get("duration",4)),"comet_size":lerpf(1,1.8,float(stats.get("charge_power",0))) if bool(stats.get("sky_comet",false)) else 1.0})

func step_lobs(delta: float) -> void:
	for i in range(lob_blasts.size()-1,-1,-1):
		lob_blasts[i]["time"] = float(lob_blasts[i]["time"])-delta
		if float(lob_blasts[i]["time"]) <= 0: lob_blasts.remove_at(i)
	for i in range(lob_shots.size()-1,-1,-1):
		var shot: Dictionary = lob_shots[i]
		var flight_delta:float=combat.clock_delta(str(shot.owner),delta)
		var prior:Vector2=combat.vec(shot.start).lerp(combat.vec(shot.end),clampf(float(shot.elapsed)/float(shot.flight),0,1))
		var next:Vector2=combat.vec(shot.start).lerp(combat.vec(shot.end),clampf((float(shot.elapsed)+flight_delta)/float(shot.flight),0,1))
		if combat.v56.catch_shot(prior,next,str(shot.owner),float(shot.damage),str(shot.color),false):lob_shots.remove_at(i);continue
		shot["elapsed"] = float(shot["elapsed"])+flight_delta
		if float(shot["elapsed"]) < float(shot["flight"]): continue
		var center := vec(shot["end"])
		var radius := float(shot["radius"])
		var owner := str(shot["owner"])
		lob_shots.remove_at(i)
		lob_blasts.append({"pos":shot["end"],"radius":radius,"time":.45,"color":shot["color"],"cast_visual":shot.get("cast_visual","")})
		if owner == "enemy":
			for target in combat.v59.target_points():
				if alive(str(target)) and center.distance_to(combat.v59.target_position(str(target))) <= radius: hit_player(str(target),float(shot["damage"]),"",preload("res://scripts/defeat_credit.gd").resolve(game,str(shot.get("owner","enemy")),str(shot.get("stats",{}).get("name","Lobbed attack"))))
			continue
		if not points().has(owner): continue
		for n in int(shot.get("fragments",0)):
			var direction:=Vector2.from_angle(TAU*n/int(shot.fragments))
			var landing:Vector2=combat.chain.clip(center,direction,float(shot.get("fragment_distance",95)))
			launch_lob(owner,center,landing,{"travel_speed":180,"blast_radius":shot.fragment_radius,"color":"#e6f3b3","cast_visual":"fragment"},float(shot.fragment_damage))
		if float(shot.get("stun",0))>0:
			for key in combat.hostile(owner):
				var victim=combat.actor(str(key))
				if not victim.is_empty() and center.distance_to(victim.pos)<=radius and combat.path_clear(center,victim.pos):combat.apply_status(str(key),"stun",float(shot.stun),owner)
		for index in range(foes().size()-1,-1,-1):
			if center.distance_to(foes()[index]["pos"]) > radius: continue
			if float(shot.get("slow",0)) > 0 and combat.path_clear(center,foes()[index]["pos"]): combat.apply_status(combat.npc_key(foes()[index]),"slow",float(shot["slow"]),owner,.6)
			if arcade:
				if game._clear_path(center,foes()[index]["pos"]): game._hit_enemy(index,float(shot["damage"]),owner)
			else: game.damage_enemy(index,float(shot["damage"]))
		if arcade and game.mode=="battlegrounds":
			for key in game.battlegrounds.hostile(owner):
				var a:Dictionary=game.battlegrounds.actor(key)
				if center.distance_to(a.pos)<=radius and game._clear_path(center,a.pos):game.battlegrounds.damage(key,float(shot.damage),owner);combat.apply_status(key,"slow",float(shot.get("slow",0)),owner,.6)
		if arcade and game.mode in ["arena","battlegrounds"]:
			combat.v59.clone_blast(center,radius,owner,float(shot["damage"]))
			for target in points():
				if game._rival(owner,str(target)) and center.distance_to(points()[target]) <= radius and game._clear_path(center,points()[target]): game._hurt(str(target),float(shot["damage"]),owner);combat.apply_status(combat.player_key(str(target)),"slow",float(shot.get("slow",0)),owner,.6)
		if bool(shot["ice"]):
			if arcade: game.ice_walls.append({"pos":center,"time":float(shot["wall_time"])})
			else: game.ice_walls.append({"pos":center,"time":float(shot["wall_time"]),"radius":38.0})

func draw_lob_aim(canvas: Node2D, camera: Vector2) -> void:
	var hero: Dictionary
	var origin: Vector2
	var level: int
	if arcade:
		if not game.started or not points().has(game.my_id) or not alive(game.my_id) or game.shop_open != "": return
		hero = game.characters.get(str(game.hero_ids.get(game.my_id,"ram")),{})
		origin = game.local_pos
		level = int(game.levels.get(game.my_id,1))
	else:
		if game.mode != "run" or game.menu != "": return
		hero = game.hero;origin=game.position_in_world;level=game.level
	for kind in ["secondary","special"]:
		if level < (3 if kind == "secondary" else 6): continue
		var stats: Dictionary = hero.get(kind,{})
		if float(stats.get("travel_speed",0)) <= 0 or not Input.is_action_pressed(kind): continue
		var owner:String=str(game.my_id) if arcade else "solo"
		if combat.held_cast.supports(owner,kind):continue
		var reach := float(stats.get("range",330))
		var target: Vector2
		if arcade:
			var offset: Vector2 = game.mobile.aim*reach if game.mobile.enabled else game.media_mouse_world()-origin
			target = origin+offset.limit_length(reach)
		else: target=game.aimed_point(reach)
		canvas.draw_arc(target-camera,float(stats.get("blast_radius",110)),0,TAU,40,Color(str(stats.get("color","#d6efff")),.4),2,true)
		canvas.draw_circle(target-camera,3,Color(str(stats.get("color","#d6efff")),.7))

func warn_wave(point: Vector2, velocity: Vector2, radius: float, damage: float, distance: float, delay: float, colour: String) -> void:
	warn(point,radius,damage,delay)
	warnings[-1]["wave"]=[velocity.x,velocity.y];warnings[-1]["distance"]=distance;warnings[-1]["colour"]=colour
func launch_wave(point: Vector2, velocity: Vector2, radius: float, damage: float, distance: float, colour: String) -> void:
	if not authoritative() or waves.size()>=60:return
	waves.append({"credit":warning_credit.duplicate(true),"pos":[point.x,point.y],"velocity":[velocity.x,velocity.y],"radius":radius,"damage":damage,"remaining":distance,"hits":[],"colour":colour})
func step_waves(delta: float) -> void:
	for n in range(waves.size()-1,-1,-1):
		var wave:Dictionary=waves[n]
		var start:=vec(wave["pos"]);var velocity:=vec(wave["velocity"])
		var end:=start+velocity*delta
		if (school.active or hollow.active or quests.active or expansion.active or river or marsh) and not combat.path_clear(start,end) or vault.active and not vault.clear_path(start,end):
			waves.remove_at(n);continue
		wave["pos"]=[end.x,end.y];wave["remaining"]=float(wave["remaining"])-velocity.length()*delta
		for id in combat.v59.target_points():
			if not alive(str(id)) or wave["hits"].has(id):continue
			if Geometry2D.get_closest_point_to_segment(combat.v59.target_position(str(id)),start,end).distance_to(combat.v59.target_position(str(id)))<=float(wave["radius"])+18:
				wave["hits"].append(id);hit_player(str(id),float(wave["damage"]),"",wave.get("credit",{}))
		if float(wave["remaining"])<=0:waves.remove_at(n)

func move_clockwork_hart(enemy:Dictionary,target:Vector2,delta:float)->void:
	# A circling mechanical stag, with obstacle-aware sidesteps and clockwork dashes.
	var p:Vector2=enemy.pos
	var phase:=clock*.8+int(enemy.get("uid",0))%7
	var destination:=target+Vector2.from_angle(phase)*190
	var speed:float=115.0*(1.7 if fmod(clock,5.0)<.7 else 1.0)*combat.speed_factor(combat.npc_key(enemy))
	var offset:Vector2=(destination-p).normalized()*speed*delta
	for angle in [0.0,.65,-.65,1.3,-1.3]:
		var end:=p+offset.rotated(angle)
		if combat.path_clear(p,end):enemy.pos=end;return
