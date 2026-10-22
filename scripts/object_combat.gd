extends Node
## Shared effects and object hero mechanics. Only the host applies damage.
var golf:Node
var starfield:Node
var feedback:Node
var v112:Node
var v110:Node
var halloween:Node
var held_cast:Node
var twister:Node
var v98:Node
var v90:Node
var dot_damage:=false
var encounter_book=preload("res://scripts/encounter_book.gd").new()
var stance_heroes:Node
var party_heroes:Node
var release_heroes:Node
var morrow:Node
var mantis:Node
var confluence:Node
var v79:Node
var v78:Node
var v75:Node
var chronicle:Node
var mastery_combat:Node
var pact:Node
var tempo_serial:=0
var tempo_hits:Dictionary={}
var agent:Node
var ninja:Node
var v59:Node
var v58:Node
var v56:Node
var adventure:Node
var variants:Node
var courier:Node
var chain:Node
var classics:Node
var fern:Node
var robot:Node
var v48:Node
var runebearer:Node
var statuses:Dictionary={}
var projectiles:Array=[]
var rings:Array=[]
var casts:Array=[]
var auras:Array=[]
var actor_index:Dictionary={}
var actor_frame:=-1
var anchors:Array=[]
var wires:Array=[]
var pools:Array=[]
var visuals:Array=[]
var remote_indicators:Array=[]
var orbits:Array=[]
var vortices:Array=[]
var shot_turn:Dictionary={}
var mines:Array=[]
var received_at:=0
var coast:Node
const STYLES=["golf_drive","navigator_bolt","meteor_shower","split_lance","manual_mines","ground_sequence","cross_shot","charged_beam","chill_aura","rolling_snow","pulse_wave","pulse_burst","magnet_pin","magnet_pull","magnet_wire","waterfall_wave","ricochet_projectile","burst_projectile","spiral_shot","orbit_shards","vortex_field"]
func _ready()->void:
	golf=preload("res://scripts/golf_chain.gd").new();add_child(golf);golf.combat=self
	starfield=preload("res://scripts/starfield.gd").new();add_child(starfield);starfield.combat=self
	feedback=preload("res://scripts/combat_feedback.gd").new();add_child(feedback);feedback.combat=self
	v112=preload("res://scripts/v112_combat.gd").new();add_child(v112);v112.combat=self
	v110=preload("res://scripts/v110_combat.gd").new();add_child(v110);v110.combat=self
	halloween=preload("res://scripts/halloween_combat.gd").new();add_child(halloween);halloween.combat=self
	held_cast=preload("res://scripts/held_cast.gd").new();add_child(held_cast);held_cast.combat=self
	twister=preload("res://scripts/twister_combat.gd").new();add_child(twister);twister.combat=self
	v98=preload("res://scripts/v98_heroes.gd").new();add_child(v98);v98.combat=self
	v90=preload("res://scripts/v90_heroes.gd").new();add_child(v90);v90.combat=self
	stance_heroes=preload("res://scripts/stance_heroes.gd").new();add_child(stance_heroes);stance_heroes.combat=self
	party_heroes=preload("res://scripts/party_heroes.gd").new();add_child(party_heroes);party_heroes.combat=self
	release_heroes=preload("res://scripts/release_heroes.gd").new();add_child(release_heroes);release_heroes.combat=self
	morrow=preload("res://scripts/morrow_combat.gd").new();add_child(morrow);morrow.combat=self
	mantis=preload("res://scripts/mantis_combat.gd").new();add_child(mantis);mantis.combat=self
	confluence=preload("res://scripts/confluence_heroes.gd").new();add_child(confluence);confluence.combat=self
	v79=preload("res://scripts/v79_heroes.gd").new();add_child(v79);v79.combat=self
	v78=preload("res://scripts/v78_heroes.gd").new();add_child(v78);v78.combat=self
	v75=preload("res://scripts/v75_heroes.gd").new();add_child(v75);v75.combat=self
	chronicle=preload("res://scripts/chronicle_combat.gd").new();add_child(chronicle);chronicle.combat=self
	mastery_combat=preload("res://scripts/mastery_combat.gd").new();add_child(mastery_combat);mastery_combat.combat=self
	pact=preload("res://scripts/pact_combat.gd").new();add_child(pact);pact.combat=self
	agent=preload("res://scripts/agent_combat.gd").new();add_child(agent);agent.combat=self
	ninja=preload("res://scripts/ninja_combat.gd").new();add_child(ninja);ninja.combat=self
	v59=preload("res://scripts/v59_combat.gd").new();add_child(v59);v59.combat=self
	v58=preload("res://scripts/v58_combat.gd").new();add_child(v58);v58.combat=self
	v56=preload("res://scripts/v56_combat.gd").new();add_child(v56);v56.combat=self
	fern=preload("res://scripts/fern_combat.gd").new();add_child(fern);fern.combat=self
	robot=preload("res://scripts/robot_combat.gd").new();add_child(robot);robot.combat=self
	v48=preload("res://scripts/v48_combat.gd").new();add_child(v48);v48.combat=self
	runebearer=preload("res://scripts/runebearer_combat.gd").new();add_child(runebearer);runebearer.combat=self
	classics=preload("res://scripts/v46_heroes.gd").new();add_child(classics);classics.combat=self
	chain=preload("res://scripts/chain_combat.gd").new();add_child(chain);chain.combat=self
	courier=preload("res://scripts/courier_combat.gd").new();add_child(courier);courier.combat=self
	variants=preload("res://scripts/hero_variants.gd").new();add_child(variants);variants.combat=self
	coast=preload("res://scripts/folded_coast.gd").new();add_child(coast);coast.combat=self
func setup(id:String)->void:
	golf.balls.clear()
	starfield.reset()
	feedback.contacts.clear()
	actor_index.clear();actor_frame=-1
	v112.reset()
	v110.reset()
	halloween.reset()
	held_cast.reset()
	twister.reset()
	v98.reset()
	v90.reset()
	stance_heroes.reset()
	party_heroes.reset()
	release_heroes.reset()
	morrow.reset()
	mantis.reset()
	confluence.reset()
	v79.reset()
	v78.reset()
	v75.reset()
	chronicle.reset()
	mastery_combat.reset()
	pact.reset();tempo_hits.clear();tempo_serial=0
	agent.reset()
	ninja.reset()
	v59.reset()
	v58.reset()
	v56.reset()
	fern.reset()
	robot.reset()
	v48.reset()
	runebearer.reset()
	classics.reset()
	chain.reset()
	courier.reset()
	variants.reset()
	mines.clear();orbits.clear();vortices.clear();shot_turn.clear();statuses.clear();projectiles.clear();rings.clear();casts.clear();auras.clear();anchors.clear();wires.clear();pools.clear();visuals.clear();remote_indicators.clear()
	coast.setup(id)
func vec(value:Array)->Vector2:return Vector2(float(value[0]),float(value[1]))
func point_array(point:Vector2)->Array:return [point.x,point.y]
func npc_key(foe:Dictionary)->String:return "e:"+str(foe.get("uid",0))
func player_key(id:String)->String:return "p:"+id
# Older hero summons live in arcade.guards; use stable IDs instead of array indices.
func summon_points()->Dictionary:
	var result:Dictionary={}
	if not adventure.arcade:return result
	for body in adventure.game.guards:
		if str(body.get("type",""))!="summoned" or float(body.get("hp",0))<=0:continue
		if not body.has("net_uid"):
			if not adventure.authoritative():continue
			body.net_uid=adventure.game.transport.next()
		result["summon:"+str(body.net_uid)]=body.pos
	return result
func summon_body(id:String)->Dictionary:
	if not adventure.arcade:return {}
	for body in adventure.game.guards:
		if str(body.get("type",""))=="summoned" and str(body.get("net_uid",-1))==id.trim_prefix("summon:"):return body
	return {}
func summon_enemy_to(id:String,source:String)->bool:
	var body:=summon_body(id)
	if body.is_empty() or float(body.get("hp",0))<=0:return false
	return source=="enemy" or adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(source,str(body.get("owner","")))
func summon_hurt(id:String,amount:float,source:String)->void:
	if not adventure.authoritative() or not summon_enemy_to(id,source):return
	var body:=summon_body(id)
	amount=adventure.game.legacy.critical(source,amount,body.pos)
	var taken:=minf(float(body.hp),maxf(0,amount))
	if taken<=0:return
	body.hp=float(body.hp)-taken
	adventure.game._stat(source,"damage",taken);adventure.game._damage_feedback(body.pos,taken)
	if float(body.hp)<=0:
		adventure.game.guards.erase(body);statuses.erase(player_key(id))
func catch_summon(start:Vector2,end:Vector2,source:String,amount:float)->bool:
	if not adventure.authoritative():return false
	for id in summon_points():
		if summon_enemy_to(str(id),source) and Geometry2D.get_closest_point_to_segment(summon_body(str(id)).pos,start,end).distance_to(summon_body(str(id)).pos)<25 and path_clear(start,summon_body(str(id)).pos):
			summon_hurt(str(id),amount,source);return true
	return false
func visible_owner(id:String)->bool:
	if not adventure.arcade:return true
	var g:Node=adventure.game
	if g.mode not in ["arena","battlegrounds"] or g.spectating() or id==str(g.my_id):return true
	return not (g._rival(str(g.my_id),id) and Time.get_ticks_msec()<int(g.stealth_until.get(id,0)))
func actor(key:String)->Dictionary:
	if (key.begins_with("c|") or key.begins_with("p:c|")) and adventure.arcade:return adventure.game.custom_party.minion_actor(key.trim_prefix("p:"))
	if actor_frame!=Engine.get_process_frames():
		actor_frame=Engine.get_process_frames();actor_index.clear()
		for foe in adventure.foes():actor_index[npc_key(foe)]=foe
	if key.begins_with("bg") and adventure.arcade and adventure.game.mode=="battlegrounds":return adventure.game.battlegrounds.actor(key)
	if key.begins_with("p:summon:"):
		var body:=summon_body(key.substr(2))
		if not body.is_empty():return {"pos":body.pos,"alive":float(body.get("hp",0))>0,"player":key.substr(2)}
		return {}
	if key.begins_with("p:risen:"):return morrow.actor(key.substr(2))
	if key.begins_with("p:bond:"):return pact.ally_actor(key.substr(2))
	if key.begins_with("p:mirror:"):return v59.mirror_actor(key.substr(2))
	if key.begins_with("e:"):
		var foe:Dictionary=actor_index.get(key,{})
		if foe.is_empty():
			for candidate in adventure.foes():
				if npc_key(candidate)==key:foe=candidate;actor_index[key]=foe;break
		if not foe.is_empty() and float(foe.hp)>0 and not bool(foe.get("buried",false)):return {"pos":foe.pos,"alive":true,"npc":foe}
	elif adventure.points().has(key.substr(2)):
		var id:=key.substr(2)
		return {"pos":adventure.points()[id],"alive":adventure.alive(id),"player":id}
	return {}
func hostile(owner:String,near:Vector2=Vector2.ZERO,radius:float=-1)->Array[String]:
	var result:Array[String]=[]
	if adventure.arcade and adventure.game.mode=="battlegrounds":result.append_array(adventure.game.battlegrounds.hostile_near(owner,near,radius) if radius>=0 else adventure.game.battlegrounds.hostile(owner))
	if owner!="enemy":
		for foe in adventure.foes():result.append(npc_key(foe))
	for id in adventure.points():
		if owner=="enemy" or (adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(owner,str(id))):result.append(player_key(str(id)))
	for mirror_owner in v59.copies:
		if owner=="enemy" or adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(owner,str(mirror_owner)):result.append(player_key(v59.mirror_id(str(mirror_owner))))
	for bond_owner in pact.allies:
		if pact.enemy_to_ally(str(bond_owner),owner):result.append(player_key("bond:"+str(bond_owner)))
	for id in morrow.units:
		if morrow.enemy_to(str(id),owner):result.append(player_key(str(id)))
	for id in summon_points():
		if summon_enemy_to(str(id),owner):result.append(player_key(str(id)))
	if adventure.arcade:result.append_array(adventure.game.custom_party.minion_keys(owner))
	return result
func path_clear(start:Vector2,end:Vector2)->bool:
	return adventure.game._clear_path(start,end) if adventure.arcade else adventure.game.shot_path_clear(start,end)
func damage(key:String,amount:float,owner:String,attack:String="Ability hit",cause:Dictionary={})->void:
	if (key.begins_with("c|") or key.begins_with("p:c|")) and adventure.arcade and adventure.authoritative():
		var target=adventure.game.custom_party.minion_actor(key.trim_prefix("p:"))
		if not target.is_empty():target.minion.hp-=maxf(0,amount)
		return
	if key=="p:training_ally":
		if not adventure.arcade and adventure.game.practice:adventure.game.training_yard.ally_health=maxf(1,adventure.game.training_yard.ally_health-amount)
		return
	if key.begins_with("bg") and adventure.arcade and adventure.game.mode=="battlegrounds":adventure.game.battlegrounds.damage(key,amount,owner);return
	if not adventure.authoritative():return
	if key.begins_with("p:summon:"):summon_hurt(key.substr(2),amount,owner);return
	if key.begins_with("p:risen:"):morrow.hurt(key.substr(2),amount,owner);return
	if key.begins_with("p:bond:"):pact.hurt_ally(key.substr(7),amount,owner);return
	if key.begins_with("p:mirror:"):v59.hurt_copy(key.substr(9),amount,owner);return
	if key.begins_with("e:"):
		for i in range(adventure.foes().size()-1,-1,-1):
			if npc_key(adventure.foes()[i])==key:
				if adventure.arcade:adventure.game._hit_enemy(i,amount,owner)
				else:adventure.game.damage_enemy(i,amount)
				return
	elif adventure.alive(key.substr(2)):
		var credit:Dictionary=cause if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(adventure.game,owner,attack)
		if adventure.arcade:adventure.game._hurt(key.substr(2),amount,owner,"",credit)
		else:adventure.game.take_player_damage(amount,"",credit)
func apply_status(key:String,kind:String,duration:float,owner:String,value:float=0,cause:Dictionary={})->void:
	if not adventure.arcade and key=="p:solo" and adventure.game.hero.has("studio_project") and adventure.game.hero.get("studio_project",{}).get("hero",{}).get("passive","")=="resilience":duration*=.75
	if key.begins_with("bgbase:") or key.begins_with("bgheart:"):return
	if key.begins_with("p:mirror:") and bool(v59.copies.get(key.substr(9),{}).get("transferred",false)):key=player_key(key.substr(9))
	if not adventure.authoritative() or actor(key).is_empty() or not bool(actor(key).get("alive",false)):return
	var effects:Dictionary=statuses.get(key,{})
	var old:Dictionary=effects.get(kind,{})
	var status_credit:Dictionary=cause.duplicate(true) if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(adventure.game,owner,kind.capitalize())
	status_credit["attack"]=kind.capitalize() if str(status_credit.get("attack",""))==kind.capitalize() else kind.capitalize()+" • "+str(status_credit.get("attack","Effect"))
	effects[kind]={"time":maxf(duration,float(old.get("time",0))),"tick":float(old.get("tick",0)),"value":maxf(value,float(old.get("value",0))),"owner":owner,"credit":status_credit}
	statuses[key]=effects
	if key!="p:training_ally" and key.begins_with("p:") and not key.begins_with("p:mirror:") and not key.begins_with("p:bond:") and not key.begins_with("p:risen:") and not key.begins_with("p:summon:"):
		adventure.game.provisions.check_auto(key.substr(2),true)
func effect_time(key:String,kind:String)->float:
	var remaining:=float(statuses.get(key,{}).get(kind,{}).get("time",0))
	if not adventure.authoritative():remaining-=(Time.get_ticks_msec()-received_at)/1000.0
	return maxf(0,remaining)
func stunned(key:String)->bool:return effect_time(key,"stun")>0
func speed_factor(key:String)->float:
	if key.begins_with("p:") and halloween.moving(key.substr(2)):return 0
	if key.begins_with("p:") and twister.chanting(key.substr(2)):return 0
	if key.begins_with("p:") and (stance_heroes.moving(key.substr(2)) or v90.moving(key.substr(2)) or v98.moving(key.substr(2))):return 0
	if key.begins_with("p:") and release_heroes.locked(key.substr(2)):return 0
	if key.begins_with("p:") and v79.moving(key.substr(2)):return 0
	if key.begins_with("p:") and v78.locked(key.substr(2)):return 0
	if key.begins_with("p:") and adventure.immersive.aboard(key.substr(2)):return 0
	if key.begins_with("p:") and (classics.locked(key.substr(2)) or v48.moving(key.substr(2))):return 0
	if key.begins_with("p:") and chain.moving(key.substr(2)):return 0
	if stunned(key):return 0
	var factor:=float(statuses.get(key,{}).get("slow",{}).get("value",.55)) if effect_time(key,"slow")>0 else 1.0
	if key.begins_with("p:") and busy(key.substr(2)) and not classics.channeling(key.substr(2)) and not v110.charging(key.substr(2)):factor*=.45
	if effect_time(key,"scout_stride")>0:factor*=float(statuses[key].scout_stride.value)
	if effect_time(key,"rune_stride")>0:factor*=1.3
	if key.begins_with("p:") and robot.transformed(key.substr(2)):factor*=.42
	if effect_time(key,"fern_stride")>0:factor*=1.2
	if effect_time(key,"tailwind")>0:factor*=1.2
	var target:Dictionary=actor(key)
	if not target.is_empty():
		factor*=adventure.immersive.terrain_speed(target.pos)
		if key.begins_with("p:") and adventure.school.active:factor*=adventure.school.terrain_speed(target.pos)
	if key.begins_with("p:"):factor*=twister.speed(key.substr(2))*halloween.speed(key.substr(2))*v110.speed(key.substr(2))
	if key.begins_with("p:") and support_aura(key.substr(2),"storm_aura"):factor*=1.15
	return factor
func reduction(id:String)->float:
	if adventure.arcade and adventure.game.custom_party.runtimes.has(id):return adventure.game.custom_party.runtimes[id].reduction()
	var base:=maxf(float(statuses.get(player_key(id),{}).get("guard",{}).get("value",0)) if effect_time(player_key(id),"guard")>0 else 0, .35 if effect_time(player_key(id),"rune_ward")>0 else 0)
	if effect_time(player_key(id),"silk_guard")>0:base=maxf(base,.15)
	base=base+(1-base)*v112.defence(id)
	base=base+(1-base)*v98.defence(id)
	base=base+(1-base)*v48.defence(id)
	base=base+(1-base)*v90.defence(id)
	return base+(1-base)*robot.reduction(id)
func display_reduction(id:String)->float:
	var g:Node=adventure.game;var remain:=1.0-reduction(id)
	if g.get("legacy")!=null:remain*=g.legacy.hurt_factor(id)
	var gear:Array=[];var passive_name:="";var lv:=1
	if adventure.arcade:
		gear=g.inventory.get(id,[]);lv=int(g.levels.get(id,1));passive_name=str(g.characters.get(str(g.hero_ids.get(id,"ram")),{}).get("passive_effect",""))
		if Time.get_ticks_msec()<int(g.shield_until.get(id,0)):remain*=1-float(g.shield_reduction.get(id,.75))
		if Time.get_ticks_msec()<int(g.invincible_until.get(id,0)):return 1
	else:
		gear=g.inventory;lv=g.level;passive_name=str(g.hero.get("passive_effect",""))
		if g.block_time>0:remain*=1-g.block_reduction
		if g.invulnerable_time>0:return 1
	if v78.immune(id) or stance_heroes.immune(id):return 1
	for item in gear:
		var data:Dictionary=g.items.get(str(item),{})
		if str(data.get("effect",""))=="armor":remain*=maxf(.3 if not adventure.arcade else 0,1-float(data.get("amount",0))/100)
	if lv>=5 and passive_name=="guard":remain*=.8 if adventure.arcade and str(g.mastery_choice.get(id,""))=="passive" else .9
	remain=v79.erode(player_key(id),1,remain)
	return clampf(1-remain,0,1)
func busy(id:String)->bool:
	if v110.charging(id):return true
	if halloween.moving(id):return true
	if twister.locked(id):return true
	if stance_heroes.moving(id) or v90.moving(id) or v98.moving(id):return true
	if release_heroes.locked(id) or release_heroes.teaching(id):return true
	if v79.moving(id):return true
	if v78.locked(id):return true
	if adventure.immersive.aboard(id):return true
	if classics.channeling(id) or classics.moving(id) or v48.moving(id):return true
	for cast in casts:
		if str(cast["owner"])==id and str(cast["style"])=="charged_beam":return true
	return false
func owner_pos(owner:String)->Vector2:
	if adventure.game.get_meta("fx_drawing_world",false) and adventure.game.has_method("melee_visual_position"):
		return adventure.game.melee_visual_position(owner,adventure.points().get(owner,Vector2.ZERO))
	if owner.begins_with("bgunit:") and adventure.arcade and adventure.game.mode=="battlegrounds":return adventure.game.battlegrounds.actor(owner).get("pos",Vector2.ZERO)
	return adventure.points().get(owner,Vector2.ZERO)
func passive(owner:String,effect:String)->bool:
	if owner=="training_ally" or not playing():return false
	if adventure.arcade:return int(adventure.game.levels.get(owner,1))>=5 and str(adventure.game.characters.get(str(adventure.game.hero_ids.get(owner,"ram")),{}).get("passive_effect",""))==effect
	return adventure.game.level>=5 and str(adventure.game.hero.get("passive_effect",""))==effect
func support_aura(owner:String,effect:String)->bool:
	for source in adventure.points():
		if adventure.alive(str(source)) and passive(str(source),effect) and (str(source)==owner or v75.friendly(str(source),owner) and owner_pos(str(source)).distance_to(owner_pos(owner))<=160 and path_clear(owner_pos(str(source)),owner_pos(owner))):return true
	return false
func effective_stats(owner:String,kind:String,stats:Dictionary)->Dictionary:
	var result:Dictionary=robot.effective(owner,kind,stats).duplicate(true)
	if adventure.game.get("legacy")!=null:result=adventure.game.legacy.stats(owner,kind,result)
	result=stance_heroes.effective(owner,kind,result)
	if kind=="primary" and passive(owner,"primary_bleed"):result["bleed_duration"]=4;result["bleed_damage"]=2
	if support_aura(owner,"telescope_aura") and float(result.get("range",0))>0:result["range"]=float(result.range)*1.15
	return held_cast.effective(owner,kind,result)
func melee_received(id:String,attacker:String)->void:
	if effect_time(player_key(id),"silk_guard")>0:
		apply_status(attacker,"poison",3,id,2)
		if statuses.has(attacker) and statuses[attacker].has("poison"):statuses[attacker].poison["interval"]=.5
	if passive(id,"slow_thorns"):apply_status(attacker,"slow",3,id,.55)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
	if passive(owner,"needle_frost"):
		stats=stats.duplicate(true);stats["slow_duration"]=1.0;stats["slow"]=.8
	var style:=str(stats.get("style",""))
	if float(stats.get("self_speed_seconds",0))>0 and adventure.authoritative() and adventure.alive(owner):apply_status(player_key(owner),"scout_stride",float(stats.self_speed_seconds),owner,float(stats.get("self_speed_factor",1.25)))
	if held_cast.cast(owner,stats,aim,amount):return true
	if v112.cast(owner,stats,aim,amount):return true
	if v110.cast(owner,stats,aim,amount):return true
	if halloween.cast(owner,stats,aim,amount):return true
	if twister.cast(owner,stats,aim,amount):return true
	if v98.cast(owner,stats,aim,amount):return true
	if v90.cast(owner,stats,aim,amount):return true
	if stance_heroes.cast(owner,stats,aim,amount):return true
	if party_heroes.cast(owner,stats,aim,amount):return true
	if release_heroes.cast(owner,stats,aim,amount):return true
	if morrow.cast(owner,stats,aim,amount):return true
	if mantis.cast(owner,stats,aim,amount):return true
	if confluence.cast(owner,stats,aim,amount):return true
	if v79.cast(owner,stats,aim,amount):return true
	if v78.cast(owner,stats,aim,amount):return true
	if v75.cast(owner,stats,aim,amount):return true
	if chronicle.cast(owner,stats,aim,amount):return true
	if mastery_combat.cast(owner,stats,aim,amount):return true
	if adventure.expansion.cast(owner,stats,aim,amount):return true
	if pact.cast(owner,stats,aim,amount):return true
	if agent.cast(owner,stats,aim,amount):return true
	if ninja.cast(owner,stats,aim,amount):return true
	if v59.cast(owner,stats,aim,amount):return true
	if v58.cast(owner,stats,aim,amount):return true
	if style=="projectile" and float(stats.get("stun_duration",0))>0:
		if adventure.authoritative() and adventure.alive(owner):
			for n in int(stats.get("count",1)):
				var direction:Vector2=aim.rotated((n-(int(stats.get("count",1))-1)*.5)*float(stats.get("spread",0)))
				launch_projectile(owner,owner_pos(owner)+direction*26,direction,stats,amount)
		return true
	if v56.cast(owner,stats,aim,amount):return true
	if fern.cast(owner,stats,aim,amount):return true
	if robot.cast(owner,stats,aim,amount):return true
	if v48.cast(owner,stats,aim,amount):return true
	if runebearer.cast(owner,stats,aim,amount):return true
	if classics.cast(owner,stats,aim,amount):return true
	if chain.cast(owner,stats,aim,amount):return true
	if courier.cast(owner,stats,aim,amount):return true
	if variants.cast(owner,stats,aim,amount):return true
	if style not in STYLES and not (style=="homing" and float(stats.get("splash_radius",0))>0):return false
	if not adventure.authoritative() or not adventure.alive(owner):return true
	var origin:=owner_pos(owner);aim=aim.normalized()
	match style:
		"meteor_shower":
			var center:=origin+aim*float(stats.get("range",230))
			if not path_clear(origin,center):center=origin
			var bounds:Rect2=adventure.game.FIELD if adventure.arcade else Rect2(Vector2.ZERO,adventure.game.region_size())
			var constellation:Array=[]
			var count:=clampi(int(stats.get("count",7)),1,9)
			for n in count:
				var location:=center if n==0 else center+Vector2.from_angle(TAU*(n-1)/maxi(1,count-1))*float(stats.get("radius",125))
				if not bounds.grow(-30).has_point(location) or not path_clear(center,location):continue
				var meteor:Dictionary=stats.duplicate();meteor["blast_radius"]=float(stats.get("blast_radius",65))+(12 if passive(owner,"wide_meteors") else 0);meteor["travel_speed"]=650;meteor["cast_visual"]="meteor"
				casts.append({"owner":owner,"style":style,"pos":point_array(location),"time":.4+n*float(stats.get("interval",.16)),"stats":meteor,"damage":amount})
				constellation.append(point_array(location))
			visuals.append({"pos":point_array(center),"style":"constellation","points":constellation,"time":2.7,"radius":float(stats.get("radius",125)),"color":"#efd5a4"})
		"manual_mines":
			var owned:Array=[]
			for mine in mines:
				if str(mine["owner"])==owner:owned.append(mine)
			if bool(stats.get("timed_mines",false)):
				if owned.size()<3:
					var location:Vector2=origin+aim*float(stats.get("range",190))
					if not path_clear(origin,location):location=origin
					mines.append({"owner":owner,"pos":point_array(location),"time":float(stats.get("duration",1.4)),"stats":stats,"damage":amount})
			elif owned.size()>=2:
				for mine in owned:
					var blast:Dictionary=mine["stats"].duplicate();blast["radius"]=float(blast.get("radius",95))+(20 if passive(owner,"wide_mines") else 0)
					add_ring(owner,vec(mine["pos"]),blast,float(mine["damage"]));mines.erase(mine)
			else:
				var location:=origin+aim*float(stats.get("range",100))
				if not path_clear(origin,location):location=origin
				mines.append({"owner":owner,"pos":point_array(location),"time":float(stats.get("duration",12)),"stats":stats,"damage":amount})
		"ground_sequence":
			for n in clampi(int(stats.get("count",3)),1,8):
				var location:=origin+aim*(n+1)*float(stats.get("spacing",85))
				if not path_clear(origin,location):break
				casts.append({"owner":owner,"style":style,"pos":point_array(location),"time":.25+n*float(stats.get("interval",.24)),"stats":stats,"damage":amount})
		"cross_shot":
			for n in 4:
				var direction:=aim.rotated(n*PI*.5)
				launch_projectile(owner,origin+direction*26,direction,stats,amount)
		"waterfall_wave":add_ring(owner,origin,stats,amount)
		"golf_drive","navigator_bolt","ricochet_projectile","homing","spiral_shot","split_lance":
			var count:=2 if style=="homing" and passive(owner,"twin_orbs") else int(stats.get("count",1))
			for n in count:
				var direction:=aim.rotated((n-(count-1)*.5)*float(stats.get("spread",0)))
				launch_projectile(owner,origin+direction*26,direction,stats,amount,style)
		"burst_projectile":
			stats=stats.duplicate(true);stats["_net_action_seq"]=int(adventure.game.get_meta("fx_action_seq",-1))
			var count:=clampi(int(stats.get("count",4)),1,5)
			var seed_damage:=float(stats.get("damage",5))+(amount-float(stats.get("damage",5)))/count if bool(stats.get("bonus_split",false)) else amount
			for n in count:casts.append({"owner":owner,"style":"seed_burst","time":n*float(stats.get("burst_interval",.1)),"shot_index":n,"stats":stats,"aim":point_array(aim),"damage":seed_damage})
		"orbit_shards":orbits.append({"owner":owner,"time":float(stats.get("duration",2.4))+(1 if passive(owner,"long_orbit") else 0),"angle":0.0,"radius":float(stats.get("radius",95)),"damage":amount,"hits":[[],[],[]]})
		"vortex_field":
			var center:=origin+aim*130
			if not path_clear(origin,center):center=origin
			vortices.append({"owner":owner,"pos":point_array(center),"time":3.0,"tick":0.0,"radius":float(stats.get("radius",200)),"damage":amount})
		"charged_beam":
			casts.append({"owner":owner,"style":style,"aim":point_array(aim),"time":float(stats.get("charge",2.5)),"total":float(stats.get("charge",2.5)),"damage":amount,"range":float(stats.get("range",620)),"width":float(stats.get("width",140))})
		"chill_aura":auras.append({"owner":owner,"time":float(stats.get("duration",4)),"radius":float(stats.get("radius",145)),"reduction":float(stats.get("reduction",.3)),"slow":float(stats.get("slow",.55))})
		"rolling_snow","magnet_pin":launch_projectile(owner,origin+aim*26,aim,stats,amount,style)
		"pulse_wave":add_ring(owner,origin,stats,amount)
		"pulse_burst":
			var burst_stats:Dictionary=stats.duplicate(true)
			if bool(stats.get("tempo_burn",false)):
				tempo_serial+=1;burst_stats["tempo_id"]=str(tempo_serial);tempo_hits[str(tempo_serial)]={"time":2.0,"hits":{}}
			for n in 3:casts.append({"owner":owner,"style":style,"time":n*.22,"stats":burst_stats,"damage":amount})
		"magnet_pull":
			var pins:=owner_anchors(owner)
			if pins.is_empty():pins.append({"pos":point_array(origin)})
			for key in hostile(owner):
				var target:=actor(key)
				if target.is_empty():continue
				var focus:=origin;var distance:=INF
				for pin in pins:
					if vec(pin["pos"]).distance_to(target["pos"])<distance:focus=vec(pin["pos"]);distance=focus.distance_to(target["pos"])
				if distance>float(stats.get("radius",170)) or not path_clear(focus,target["pos"]):continue
				visuals.append({"style":"magnet_tether","start":point_array(target["pos"]),"end":point_array(focus),"time":.55,"color":"#d693ef"})
				knock(key,(focus-(target["pos"] as Vector2)).normalized(),minf(75,distance*.55));damage(key,amount,owner);apply_status(key,"slow",1.0,owner,.6)
			for pin in pins:
				visuals.append({"style":"magnet_surge","pos":pin["pos"],"radius":float(stats.get("radius",170)),"time":.55,"color":"#d693ef"})
		"magnet_wire":
			var pins:=owner_anchors(owner)
			var wanted:=3 if passive(owner,"third_anchor") else 2
			while pins.size()<wanted:
				add_anchor(owner,origin+aim.rotated(-.5+pins.size()*.5)*160);pins=owner_anchors(owner)
			var links:Array=[]
			for n in pins.size()-1:links.append([pins[n]["pos"],pins[n+1]["pos"]])
			if pins.size()==3:links.append([pins[2]["pos"],pins[0]["pos"]])
			wires.append({"owner":owner,"start":pins[0]["pos"],"end":pins[1]["pos"],"links":links,"time":3.0,"tick":0.0,"damage":amount})
	return true
func launch_projectile(owner:String,origin:Vector2,aim:Vector2,stats:Dictionary,amount:float,style:String="pellet")->void:
	if projectiles.size()>=96:return
	projectiles.append({"credit":stats.get("credit",preload("res://scripts/defeat_credit.gd").resolve(adventure.game,owner,str(stats.get("name","Projectile")))),"owner":owner,"pos":point_array(origin),"aim":point_array(aim.normalized()),"distance":0.0,"range":float(stats.get("range",480)),"speed":float(stats.get("speed",260)),"style":style,"damage":amount,"radius":float(stats.get("projectile_radius",12.0)),"color":str(stats.get("color","#edf7ff")),"stats":stats,"bounces":int(stats.get("bounces",0))+(1 if passive(owner,"stone_bounce") else 0) if style=="ricochet_projectile" else 0,"wall_bounces":int(stats.get("wall_bounces",0)),"origin":point_array(origin),"base_aim":point_array(aim.normalized()),"hits":[],"curve":float(stats.get("curve",1.1))*(-1 if int(shot_turn.get(owner,0))%2 else 1)})
	if adventure.game.get("dedicated")==true:
		adventure.game.projectile_serial+=1
		projectiles[-1].net_id=adventure.game.projectile_serial
		projectiles[-1].born_tick=adventure.game.authority_tick-1
		projectiles[-1].action_seq=int(stats.get("_net_action_seq",adventure.game.get_meta("fx_action_seq",-1)))
		projectiles[-1].shot_index=int(stats.get("_net_shot_index",adventure.game.get_meta("fx_shot_index",0)))
		adventure.game.set_meta("fx_shot_index",int(adventure.game.get_meta("fx_shot_index",0))+1)
	shot_turn[owner]=int(shot_turn.get(owner,0))+1
func add_ring(owner:String,origin:Vector2,stats:Dictionary,amount:float)->void:
	if rings.size()>=32:return
	rings.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,owner,str(stats.get("name","Sound wave"))),"kind":"attached_ring" if bool(stats.get("follow_owner",false)) else "world_ring","follow_owner":bool(stats.get("follow_owner",false)),"tempo_id":str(stats.get("tempo_id","")),"style":str(stats.get("style","pulse_wave")),"prism_bloom":bool(stats.get("prism_bloom",false)),"owner":owner,"pos":point_array(origin),"radius":0.0,"max_radius":float(stats.get("radius",105)),"speed":float(stats.get("wave_speed",260)),"damage":amount,"slow":float(stats.get("slow_duration",0)),"slow_factor":float(stats.get("slow",.55)),"knockback":float(stats.get("knockback",0)),"stun":float(stats.get("stun",0)),"clear":bool(stats.get("clear_projectiles",false)),"hits":[],"color":str(stats.get("color","#eed395"))})
func owner_anchors(owner:String)->Array:
	var result:Array=[]
	for pin in anchors:
		if str(pin["owner"])==owner:result.append(pin)
	return result
func add_anchor(owner:String,point:Vector2)->void:
	var owned:=owner_anchors(owner)
	if owned.size()>=(3 if passive(owner,"third_anchor") else 2):anchors.erase(owned[0])
	anchors.append({"owner":owner,"pos":point_array(point),"time":8.0})
func knock(key:String,direction:Vector2,distance:float)->void:
	if key.begins_with("bg") and adventure.arcade and adventure.game.mode=="battlegrounds":adventure.game.battlegrounds.knock(key,direction,distance);return
	var target:=actor(key)
	if target.is_empty():return
	var point:Vector2=target["pos"]
	for n in int(ceil(distance/8.0)):
		var next:=point+direction*minf(8,distance-n*8)
		if not path_clear(point,next):break
		point=next
	if target.has("npc"):target["npc"]["pos"]=point
	elif str(target.get("player","")).begins_with("summon:"):
		var body:=summon_body(str(target.player))
		if not body.is_empty():body.pos=point
	elif str(target.get("player","")).begins_with("risen:"):
		morrow.units[str(target.player)].pos=point_array(point)
	elif str(target.get("player","")).begins_with("bond:"):
		var owner:String=str(target.player).trim_prefix("bond:")
		if pact.allies.has(owner):pact.allies[owner].pos=point_array(point)
	elif v59.is_mirror(str(target.get("player",""))):
		var owner:String=str(target.player).trim_prefix("mirror:")
		if v59.copies.has(owner):v59.copies[owner].pos=point_array(point)
	else:adventure.teleport(str(target["player"]),point)
func apply_hit_status(key:String,stats:Dictionary,owner:String,cause:Dictionary={})->void:
	if bool(stats.get("rewind_mark",false)):chronicle.mark(key,owner)
	if float(stats.get("stun_duration",0))>0:apply_status(key,"stun",float(stats.stun_duration),owner)
	if float(stats.get("burn_duration",0))>0:apply_status(key,"burn",float(stats.burn_duration),owner,float(stats.get("burn_damage",2)),cause)
	if float(stats.get("bleed_duration",0))>0:apply_status(key,"bleed",float(stats["bleed_duration"]),owner,float(stats.get("bleed_damage",2)),cause)
	if float(stats.get("poison_duration",0))>0:apply_status(key,"poison",float(stats["poison_duration"]),owner,float(stats.get("poison_damage",1)),cause)
func burn_foe(foe:Dictionary,owner:String)->void:apply_status(npc_key(foe),"burn",10,owner,2)
func tick_statuses(delta:float)->void:
	for key in statuses.keys():
		var target:=actor(key)
		if target.is_empty() or not bool(target.get("alive",false)):statuses.erase(key);continue
		var effects:Dictionary=statuses[key]
		for kind in effects.keys():
			var effect:Dictionary=effects[kind];var elapsed:=minf(delta,float(effect["time"]))
			effect["time"]=maxf(0,float(effect["time"])-delta)
			if kind in ["burn","poison","bleed"]:
				effect["tick"]=float(effect["tick"])+elapsed
				var interval:float=clampf(float(effect.get("interval",1)),.5,1)
				while float(effect["tick"])>=interval-.00001:
					effect["tick"]=maxf(0,float(effect["tick"])-interval);dot_damage=true;damage(str(key),float(effect["value"]),str(effect["owner"]),str(kind).capitalize(),effect.get("credit",{}));dot_damage=false
			if float(effect["time"])<=.00001:effects.erase(kind)
		if effects.is_empty():statuses.erase(key)
func step_summoners(delta:float)->void:
	var definitions:Dictionary=adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
	for enemy in adventure.foes().duplicate():
		var definition:Dictionary=definitions.get(str(enemy.get("type","")),{})
		if str(definition.get("behaviour",""))!="summoner" or stunned(npc_key(enemy)):continue
		var target:=Vector2.ZERO;var nearest:=INF
		for id in adventure.points():
			if not adventure.alive(str(id)):continue
			var hidden:bool=Time.get_ticks_msec()<int(adventure.game.stealth_until.get(id,0)) if adventure.arcade else adventure.game.stealth_time>0
			if hidden:continue
			var candidate:Vector2=adventure.points()[id]
			if candidate.distance_to(enemy["pos"])<nearest:nearest=candidate.distance_to(enemy["pos"]);target=candidate
		enemy["ranged_cast_timer"]=maxf(0,float(enemy.get("ranged_cast_timer",1.8))-delta)
		if nearest<float(definition.get("aggro_range",460)) and path_clear(enemy["pos"],target) and float(enemy["ranged_cast_timer"])<=0:
			launch_projectile("enemy",enemy["pos"],(target-(enemy["pos"] as Vector2)).normalized(),{"speed":float(definition.get("shot_speed",230)),"range":600,"split_distance":float(definition.get("split_distance",200)),"color":str(definition.get("attack_color","#efa375")),"flame_orb":true},float(definition.get("shot_damage",8)),str(definition.get("shot_style","split_lance")))
			enemy["ranged_cast_timer"]=float(definition.get("shot_cooldown",3.6))
		# Solo keeps its existing minion spawning; this supplies the equivalent host behaviour.
		if not adventure.arcade:continue
		enemy["summon_timer"]=maxf(0,float(enemy.get("summon_timer",1.5))-delta)
		if nearest>=float(definition.get("aggro_range",460)) or float(enemy["summon_timer"])>0:continue
		var count:=0
		for other in adventure.foes():
			if int(other.get("summoned_by",-1))==int(enemy.get("uid",0)):count+=1
		if count>=int(definition.get("max_summons",2)):continue
		var kind:=str(definition.get("summon_type","imp"));var stats:Dictionary=definitions.get(kind,{})
		if stats.is_empty():continue
		for n in 8:
			var point:Vector2=enemy["pos"]+Vector2.from_angle(TAU*n/8)*70
			if not path_clear(enemy["pos"],point):continue
			adventure.spawn(kind,point,float(stats.get("health",25)),false)
			var minion:Dictionary=adventure.foes()[-1];minion["summoned_by"]=int(enemy.get("uid",0));minion["summoned"]=true;minion["lane"]=int(enemy.get("lane",0))
			enemy["summon_timer"]=float(definition.get("summon_cooldown",5));break

func step(delta:float)->void:
	encounter_book.step(self,delta)
	if not adventure.authoritative():
		halloween.client_step(delta);return
	starfield.step(delta)
	golf.step(delta)
	v112.step(delta)
	v110.step(delta)
	halloween.step(delta)
	held_cast.step(delta)
	twister.step(delta)
	v98.step(delta)
	v90.step(delta)
	stance_heroes.step(delta)
	party_heroes.step(delta)
	release_heroes.step(delta)
	morrow.step(delta)
	mantis.step(delta)
	confluence.step(delta)
	v79.step(delta)
	v78.step(delta)
	v75.step(delta)
	chronicle.step(delta)
	mastery_combat.step(delta)
	step_summoners(delta)
	pact.step(delta)
	for token in tempo_hits.keys():
		tempo_hits[token].time=float(tempo_hits[token].time)-delta
		if float(tempo_hits[token].time)<=0:tempo_hits.erase(token)
	agent.step(delta)
	ninja.step(delta)
	v59.step(delta)
	v58.step(delta)
	v56.step(delta)
	fern.step(delta)
	robot.step(delta)
	v48.step(delta)
	runebearer.step(delta)
	classics.step(delta)
	chain.step(delta)
	courier.step(delta)
	variants.step(delta)
	tick_statuses(delta)
	for i in range(mines.size()-1,-1,-1):
		mines[i]["time"]=float(mines[i]["time"])-delta
		if float(mines[i]["time"])<=0 or not adventure.alive(str(mines[i]["owner"])):
			if bool(mines[i].stats.get("timed_mines",false)) and adventure.alive(str(mines[i].owner)):add_ring(str(mines[i].owner),vec(mines[i].pos),mines[i].stats,float(mines[i].damage))
			mines.remove_at(i)
	for i in range(visuals.size()-1,-1,-1):
		visuals[i]["time"]=float(visuals[i]["time"])-delta
		if float(visuals[i]["time"])<=0:visuals.remove_at(i)
	for i in range(auras.size()-1,-1,-1):
		var aura:Dictionary=auras[i];var owner:=str(aura["owner"])
		if not adventure.alive(owner):auras.remove_at(i);continue
		aura["time"]=float(aura["time"])-delta
		if float(aura["time"])<=0:auras.remove_at(i);continue
		apply_status(player_key(owner),"guard",.15,owner,float(aura["reduction"]))
		for key in hostile(owner):
			var target:=actor(key)
			if not target.is_empty() and owner_pos(owner).distance_to(target["pos"])<=float(aura["radius"]) and path_clear(owner_pos(owner),target["pos"]):apply_status(key,"slow",.15,owner,float(aura["slow"]))
	for i in range(casts.size()-1,-1,-1):
		var entry:Dictionary=casts[i];var owner:=str(entry["owner"])
		if not adventure.alive(owner) or stunned(player_key(owner)):casts.remove_at(i);continue
		entry["time"]=float(entry["time"])-delta
		if float(entry["time"])>.00001:continue
		casts.remove_at(i)
		if str(entry["style"])=="seed_burst":
			var seed_stats:Dictionary=entry["stats"].duplicate();seed_stats["_net_shot_index"]=int(entry.get("shot_index",0))
			launch_projectile(owner,owner_pos(owner)+vec(entry["aim"])*26,vec(entry["aim"]),seed_stats,float(entry["damage"]))
		elif str(entry["style"])=="meteor_shower":adventure.launch_lob(owner,vec(entry["pos"])+Vector2(-60,-420),vec(entry["pos"]),entry["stats"],float(entry["damage"]))
		elif str(entry["style"])=="ground_sequence":add_ring(owner,vec(entry["pos"]),entry["stats"],float(entry["damage"]))
		elif str(entry["style"])=="pulse_burst":add_ring(owner,owner_pos(owner),entry["stats"],float(entry["damage"]))
		else:
			var start:=owner_pos(owner);var end:=start+vec(entry["aim"])*float(entry["range"])
			visuals.append({"start":point_array(start),"end":point_array(end),"width":entry["width"],"time":.5,"color":"#fff49a"})
			for key in hostile(owner):
				var target:=actor(key)
				if not target.is_empty() and Geometry2D.get_closest_point_to_segment(target["pos"],start,end).distance_to(target["pos"])<=float(entry["width"])*.5 and path_clear(start,target["pos"]):damage(key,float(entry["damage"]),owner)
	step_rings(delta);step_projectiles(delta);step_orbits(delta);step_vortices(delta)
	for i in range(anchors.size()-1,-1,-1):
		anchors[i]["time"]=float(anchors[i]["time"])-delta
		if float(anchors[i]["time"])<=0:anchors.remove_at(i)
	for i in range(wires.size()-1,-1,-1):
		var wire:Dictionary=wires[i];wire["time"]=float(wire["time"])-delta;wire["tick"]=float(wire["tick"])+minf(delta,maxf(0,float(wire["time"])+delta))
		while float(wire["tick"])>=.5:
			wire["tick"]=float(wire["tick"])-.5
			for key in hostile(str(wire["owner"])):
				var target:=actor(key)
				if target.is_empty():continue
				for link in wire.get("links",[[wire["start"],wire["end"]]]):
					if Geometry2D.get_closest_point_to_segment(target["pos"],vec(link[0]),vec(link[1])).distance_to(target["pos"])<28 and path_clear(vec(link[0]),target["pos"]):damage(key,float(wire["damage"]),str(wire["owner"]));break
		if float(wire["time"])<=0:wires.remove_at(i)
	for i in range(pools.size()-1,-1,-1):
		var pool:Dictionary=pools[i];pool["time"]=float(pool["time"])-delta
		if float(pool["time"])<=0:pools.remove_at(i);continue
		for key in hostile("enemy"):
			var target:=actor(key)
			if not target.is_empty() and vec(pool["pos"]).distance_to(target["pos"])<=float(pool["radius"]):apply_status(key,"poison",3,"enemy",2)
	coast.step(delta)
func step_rings(delta:float)->void:
	for i in range(rings.size()-1,-1,-1):
		var ring:Dictionary=rings[i];var previous:=float(ring["radius"]);ring["radius"]=minf(float(ring["max_radius"]),previous+float(ring["speed"])*delta)
		var before:=vec(ring["pos"]);var owner:=str(ring["owner"])
		if bool(ring.get("follow_owner",false)):
			if not adventure.alive(owner):rings.remove_at(i);continue
			ring.pos=point_array(owner_pos(owner))
		var center:=vec(ring["pos"])
		# Teleports relocate the wave; they cannot sweep damage across the map.
		if before.distance_to(center)>128:before=center
		for key in hostile(owner):
			if ring["hits"].has(key):continue
			var target:=actor(key)
			if target.is_empty():continue
			if ring_contact(target["pos"],before,center,previous,float(ring["radius"])) and path_clear(center,target["pos"]):
				ring["hits"].append(key);damage(key,float(ring["damage"]),owner,"Sound wave",ring.get("credit",{}))
				var token:String=str(ring.get("tempo_id",""))
				if tempo_hits.has(token):
					var tally:Dictionary=tempo_hits[token].hits;tally[key]=int(tally.get(key,0))+1
					if int(tally[key])==3:apply_status(key,"burn",3,owner,3)
				if float(ring.get("slow",0))>0:apply_status(key,"slow",float(ring["slow"]),owner,float(ring["slow_factor"]))
				if float(ring.get("knockback",0))>0:knock(key,((target["pos"] as Vector2)-center).normalized(),float(ring["knockback"]))
				if float(ring["stun"])>0:apply_status(key,"stun",float(ring["stun"]),owner)
		if bool(ring["clear"]):clear_projectiles(owner,center,float(ring["radius"])+16)
		if float(ring["radius"])>=float(ring["max_radius"]):rings.remove_at(i)
func ring_contact(target:Vector2,start:Vector2,finish:Vector2,inner:float,outer:float)->bool:
	# Sample the moving expanding shell so ordinary movement cannot skip a target.
	var count:=clampi(int(ceil((start.distance_to(finish)+outer-inner)/8.0)),1,64)
	for n in range(count+1):
		var t:=float(n)/count
		var gap:=start.lerp(finish,t).distance_to(target)-lerpf(inner,outer,t)
		if gap>=-20 and gap<=18:return true
	return false
func clear_projectiles(owner:String,center:Vector2,radius:float)->void:
	var shots:Array=adventure.game.missiles if adventure.arcade else adventure.game.enemy_shots
	for i in range(shots.size()-1,-1,-1):
		var other:=str(shots[i].get("owner","enemy"))
		if other!=owner and (other=="enemy" or (adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(owner,other))) and center.distance_to(shots[i]["pos"])<=radius:shots.remove_at(i)
	for list in [projectiles,adventure.lob_shots,adventure.waves]:
		for i in range(list.size()-1,-1,-1):
			var other:=str(list[i].get("owner","enemy"))
			var point:Vector2=vec(list[i].get("pos",list[i].get("start",[0,0])))
			if list[i].has("flight"):point=vec(list[i]["start"]).lerp(vec(list[i]["end"]),clampf(float(list[i]["elapsed"])/float(list[i]["flight"]),0,1))
			if other!=owner and (other=="enemy" or (adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(owner,other))) and center.distance_to(point)<=radius:list.remove_at(i)
func step_projectiles(delta:float)->void:
	for i in range(projectiles.size()-1,-1,-1):
		var shot:Dictionary=projectiles[i];var start:=vec(shot["pos"]);var direction:=vec(shot["aim"])
		if str(shot["style"])=="echo_bolt" and float(shot["distance"])>=float(shot["stats"].get("return_at",240)) and not bool(shot.get("returned",false)):
			direction=-direction;shot["returned"]=true
		if str(shot["style"])=="spiral_shot":direction=direction.rotated(float(shot["curve"])*delta)
		if str(shot["style"])=="homing":
			var nearest:=INF;var focus:=Vector2.ZERO
			var chosen:String=str(shot["stats"].get("homing_target",""))
			var intended:Dictionary=actor(chosen) if not chosen.is_empty() else {}
			if not intended.is_empty() and bool(intended.get("alive",false)) and hostile(str(shot["owner"])).has(chosen) and path_clear(start,intended.pos):focus=intended.pos;nearest=start.distance_to(focus)
			else:
				var seek_radius=maxf(80,float(shot["range"])-float(shot["distance"])+80) if str(shot["owner"]).begins_with("bgarmy:") else -1.0
				for key in hostile(str(shot["owner"]),start,seek_radius):
					var candidate:=actor(key)
					if not candidate.is_empty() and bool(candidate.get("alive",false)) and start.distance_to(candidate["pos"])<nearest and path_clear(start,candidate.pos):focus=candidate["pos"];nearest=start.distance_to(focus)
			if nearest<INF:direction=direction.lerp((focus-start).normalized(),minf(1,delta*5)).normalized()
		shot["aim"]=point_array(direction)
		var travel:=minf(float(shot["speed"])*clock_delta(str(shot["owner"]),delta),float(shot["range"])-float(shot["distance"]))
		var end:=start+direction*travel;shot["distance"]=float(shot["distance"])+travel
		if str(shot["style"]) in ["weaving","corkscrew_key"]:
			var base:=vec(shot["base_aim"]);var side:=Vector2(-base.y,base.x)
			end=vec(shot["origin"])+base*float(shot["distance"])+side*sin(float(shot["distance"])*TAU/float(shot["stats"].get("wavelength",170)))*float(shot["stats"].get("amplitude",20))
		if v56.catch_shot(start,end,str(shot["owner"]),float(shot["damage"]),str(shot.get("color","#edb3a0")),true,shot):projectiles.remove_at(i);continue
		if bool(shot.get("stats",{}).get("ball_lightning",false)) and path_clear(start,end):
			shot["shock_tick"]=float(shot.get("shock_tick",0))+delta
			if float(shot.shock_tick)>=.25:
				shot.shock_tick=0.0
				var counts:Dictionary=shot.get("shock_counts",{})
				for key in hostile(str(shot.owner)):
					var f:Dictionary=actor(key)
					if not f.is_empty() and bool(f.alive) and end.distance_to(f.pos)<90 and path_clear(end,f.pos) and int(counts.get(key,0))<3:
						counts[key]=int(counts.get(key,0))+1;damage(key,4,str(shot.owner),"Ball Lightning")
						if visuals.size()<64:visuals.append({"pos":point_array(end),"start":point_array(end),"end":point_array(f.pos),"width":2,"style":"ball_shock","radius":0,"time":.15,"color":"#b0ceff"})
				shot["shock_counts"]=counts
		var ratio:=clampf(float(shot["distance"])/float(shot["range"]),0,1)
		if str(shot["style"])=="rolling_snow":shot["radius"]=12+ratio*34
		var impact:="";var blocked:=not path_clear(start,end)
		if blocked and str(shot["style"])=="bankshot" and int(shot.get("wall_bounces",0))>0:
			var reflected:=direction
			var x_clear:=path_clear(start,start+Vector2(direction.x*travel,0));var y_clear:=path_clear(start,start+Vector2(0,direction.y*travel))
			if not x_clear:reflected.x=-reflected.x
			if not y_clear:reflected.y=-reflected.y
			if x_clear and y_clear:reflected=-reflected
			shot["aim"]=point_array(reflected);shot["wall_bounces"]=int(shot["wall_bounces"])-1
			shot["pos"]=point_array(start);continue
		if str(shot["style"])=="rolling_snow":
			for offset in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
				if not path_clear(start+offset*float(shot["radius"]),end+offset*float(shot["radius"])):blocked=true
		for key in hostile(str(shot["owner"]),(start+end)*.5,start.distance_to(end)*.5+float(shot["radius"])+180):
			var target:=actor(key)
			if not target.is_empty() and not (shot.get("hits",[]) as Array).has(key) and projectile_near(start,end,key,target["pos"],float(shot["radius"])+v110.target_radius(key,float(target.get("npc",{}).get("hit_radius",18)))):impact=key;break
		shot["pos"]=point_array(start if blocked else end)
		if str(shot["style"])=="split_lance" and float(shot["distance"])>=float(shot["stats"].get("split_distance",150)) and impact.is_empty() and not blocked:
			projectiles.remove_at(i)
			for angle in [-.32,.32]:
				var branch:Dictionary=shot["stats"].duplicate();branch["range"]=maxf(60,float(shot["range"])-float(shot["distance"]))
				launch_projectile(str(shot["owner"]),end,direction.rotated(angle),branch,float(shot["damage"])*.65)
			continue
		if not impact.is_empty() and not blocked and str(shot["style"])=="corkscrew_key":
			damage(impact,float(shot["damage"]),str(shot["owner"]),"Projectile",shot.get("credit",{}));apply_hit_status(impact,shot["stats"],str(shot["owner"]),shot.get("credit",{}));shot["hits"].append(impact)
			if float(shot["stats"].get("slow_duration",0))>0:apply_status(impact,"slow",float(shot["stats"].slow_duration),str(shot["owner"]),float(shot["stats"].get("slow",.7)))
			if (shot["hits"] as Array).size()<int(shot["stats"].get("pierce",2)) and ratio<1:continue
			projectiles.remove_at(i);continue
		if not impact.is_empty() and not blocked and str(shot["style"])=="latchline":
			damage(impact,float(shot["damage"]),str(shot["owner"]),"Projectile",shot.get("credit",{}))
			var toward:Vector2=owner_pos(str(shot["owner"]))-actor(impact).get("pos",end)
			var boss:bool=bool(actor(impact).get("npc",{}).get("boss",false))
			knock(impact,toward.normalized(),maxf(0,minf(140,toward.length()-60))*(.25 if boss else 1.0));apply_status(impact,"stun",float(shot["stats"].get("stun_duration",1.5)),str(shot["owner"]))
			projectiles.remove_at(i);continue
		if not impact.is_empty() or blocked or ratio>=1:
			projectiles.remove_at(i)
			var center:=vec(shot["pos"]);var owner:=str(shot["owner"])
			match str(shot["style"]):
				"rolling_snow":
					var blast:=70+ratio*55;var amount:=float(shot["damage"])+ratio*36
					for key in hostile(owner):
						var target:=actor(key)
						if not target.is_empty() and center.distance_to(target["pos"])<=blast and path_clear(center,target["pos"]):damage(key,amount,owner,"Projectile explosion",shot.get("credit",{}))
					if not impact.is_empty():knock(impact,direction,65+ratio*35)
					for n in 6:launch_projectile(owner,center,Vector2.from_angle(TAU*n/6),{"range":210,"speed":340,"color":"#e5f7ff"},5)
					visuals.append({"pos":point_array(center),"radius":blast,"time":.4,"color":"#edfaff"})
				"magnet_pin":
					if not impact.is_empty() and not blocked:damage(impact,float(shot["damage"]),owner,"Projectile",shot.get("credit",{}))
					add_anchor(owner,center)
				_:
					if not impact.is_empty() and not blocked:
						if bool(shot.get("stats",{}).get("star_mark",false)):starfield.mark_area(owner,center,float(shot.get("stats",{}).get("splash_radius",75)))
						if bool(shot.get("stats",{}).get("pistol",false)):v90.pistol_hit(owner,impact)
						damage(impact,float(shot["damage"]),owner,"Projectile",shot.get("credit",{}));shot["hits"].append(impact)
						v59.impact(shot,center)
						var stats:Dictionary=shot.get("stats",{})
						if float(stats.get("echo_brand",0))>0:adventure.expansion.brand(owner,impact,float(stats.echo_brand))
						apply_hit_status(impact,stats,owner,shot.get("credit",{}))
						if float(stats.get("slow_duration",0))>0:apply_status(impact,"slow",float(stats["slow_duration"]),owner,float(stats.get("slow_factor",.75)))
						if float(stats.get("splash_radius",0))>0:
							for key in hostile(owner):
								var target:=actor(key)
								if key!=impact and not target.is_empty() and center.distance_to(target["pos"])<=float(stats["splash_radius"]) and path_clear(center,target["pos"]):damage(key,float(stats.get("splash_damage",8)),owner,"Projectile splash",shot.get("credit",{}))
							visuals.append({"pos":point_array(center),"radius":stats["splash_radius"],"time":.35,"color":"#b9a2ef"})
						if int(shot.get("bounces",0))>0:
							var next:="";var nearest:=float(stats.get("bounce_range",180))
							for key in hostile(owner):
								var target:=actor(key)
								if not target.is_empty() and not shot["hits"].has(key) and center.distance_to(target["pos"])<nearest and path_clear(center,target["pos"]):next=key;nearest=center.distance_to(target["pos"])
							if not next.is_empty():
								shot["aim"]=point_array(((actor(next)["pos"] as Vector2)-center).normalized());shot["distance"]=0.0;shot["range"]=nearest+45;shot["bounces"]=int(shot["bounces"])-1;shot["damage"]=float(shot["damage"])*float(stats.get("bounce_scale",.65));projectiles.append(shot)
func step_orbits(delta:float)->void:
	for i in range(orbits.size()-1,-1,-1):
		var orbit:Dictionary=orbits[i];var owner:=str(orbit["owner"])
		if not adventure.alive(owner):orbits.remove_at(i);continue
		var elapsed:=minf(delta,float(orbit["time"]));var old:=float(orbit["angle"]);orbit["angle"]=old+elapsed*5;orbit["time"]=float(orbit["time"])-delta
		for n in 3:
			for step in maxi(1,int(ceil(elapsed/.025))):
				var angle:=lerpf(old,float(orbit["angle"]),(step+1.0)/maxi(1,int(ceil(elapsed/.025))))+TAU*n/3
				var point:=owner_pos(owner)+Vector2.from_angle(angle)*float(orbit["radius"])
				for key in hostile(owner):
					var target:=actor(key)
					if not target.is_empty() and not orbit["hits"][n].has(key) and point.distance_to(target["pos"])<30 and path_clear(owner_pos(owner),target["pos"]):orbit["hits"][n].append(key);damage(key,float(orbit["damage"]),owner)
		if float(orbit["time"])<=0:orbits.remove_at(i)
func step_vortices(delta:float)->void:
	for i in range(vortices.size()-1,-1,-1):
		var vortex:Dictionary=vortices[i];var owner:=str(vortex["owner"]);var center:=vec(vortex["pos"])
		if not adventure.alive(owner):vortices.remove_at(i);continue
		var elapsed:=minf(delta,float(vortex["time"]));vortex["time"]=float(vortex["time"])-delta;vortex["tick"]=float(vortex["tick"])+elapsed
		for key in hostile(owner):
			var target:=actor(key)
			if not target.is_empty() and center.distance_to(target["pos"])<float(vortex["radius"]) and path_clear(center,target["pos"]):knock(key,(center-(target["pos"] as Vector2)).normalized(),minf(elapsed*65,center.distance_to(target["pos"])));apply_status(key,"slow",.15,owner,.6)
		while float(vortex["tick"])>=.49999:
			vortex["tick"]=maxf(0,float(vortex["tick"])-.5)
			for key in hostile(owner):
				var target:=actor(key)
				if not target.is_empty() and center.distance_to(target["pos"])<float(vortex["radius"]) and path_clear(center,target["pos"]):damage(key,float(vortex["damage"]),owner)
		if float(vortex["time"])<=.00001:vortices.remove_at(i)
func indicators()->Array:
	if not adventure.authoritative():return remote_indicators
	var result:Array=[]
	for key in statuses:
		var target:=actor(key)
		if target.is_empty():continue
		var flags:Array=[]
		for kind in ["burn","bleed","slow","stun","poison"]:
			if effect_time(key,kind)>0:flags.append(kind)
		if not flags.is_empty():result.append({"key":str(key),"pos":point_array(target["pos"]),"flags":flags})
	return result
func snapshot()->Dictionary:return {"golf":golf.balls,"starfield":starfield.marks,"held_cast":held_cast.snapshot(),"v112":v112.snapshot(),"v110":v110.snapshot(),"halloween":halloween.snapshot(),"twister":twister.snapshot(),"v98":v98.snapshot(),"v90":v90.snapshot(),"stance_heroes":stance_heroes.snapshot(),"party_heroes":party_heroes.snapshot(),"release_heroes":release_heroes.snapshot(),"mantis":mantis.snapshot(),"morrow":morrow.snapshot(),"confluence":confluence.snapshot(),"v79":v79.snapshot(),"v78":v78.snapshot(),"v75":v75.snapshot(),"chronicle":chronicle.snapshot(),"mastery_combat":mastery_combat.snapshot(),"pact":pact.snapshot(),"agent":agent.snapshot(),"ninja":ninja.snapshot(),"v59":v59.snapshot(),"v58":v58.snapshot(),"v56":v56.snapshot(),"fern":fern.snapshot(),"robot":robot.snapshot(),"v48":v48.snapshot(),"runebearer":runebearer.snapshot(),"classics":classics.snapshot(),"chain":chain.snapshot(),"courier":courier.snapshot(),"variants":variants.snapshot(),"mines":mines,"orbits":orbits,"vortices":vortices,"statuses":statuses,"projectiles":projectiles,"rings":rings,"casts":casts,"auras":auras,"anchors":anchors,"wires":wires,"pools":pools,"visuals":visuals,"indicators":indicators(),"coast":coast.snapshot()}
func receive(data:Dictionary)->void:
	golf.balls=data.get("golf",[]).duplicate(true)
	starfield.marks=data.get("starfield",{})
	v112.receive(data.get("v112",{}))
	v110.receive(data.get("v110",{}))
	halloween.receive(data.get("halloween",{}))
	held_cast.receive(data.get("held_cast",{}))
	twister.receive(data.get("twister",{}))
	v98.receive(data.get("v98",{}))
	v90.receive(data.get("v90",{}))
	stance_heroes.receive(data.get("stance_heroes",{}))
	party_heroes.receive(data.get("party_heroes",{}))
	release_heroes.receive(data.get("release_heroes",{}))
	morrow.receive(data.get("morrow",{}))
	mantis.receive(data.get("mantis",{}))
	confluence.receive(data.get("confluence",{}))
	v79.receive(data.get("v79",{}))
	v78.receive(data.get("v78",{}))
	v75.receive(data.get("v75",{}))
	chronicle.receive(data.get("chronicle",{}))
	mastery_combat.receive(data.get("mastery_combat",{}))
	pact.receive(data.get("pact",{}))
	agent.receive(data.get("agent",{}))
	ninja.receive(data.get("ninja",{}))
	v59.receive(data.get("v59",{}))
	v58.receive(data.get("v58",{}))
	v56.receive(data.get("v56",{}))
	fern.receive(data.get("fern",{}))
	robot.receive(data.get("robot",{}))
	v48.receive(data.get("v48",{}))
	runebearer.receive(data.get("runebearer",{}))
	classics.receive(data.get("classics",{}))
	chain.receive(data.get("chain",{}))
	courier.receive(data.get("courier",{}))
	variants.receive(data.get("variants",{}))
	mines=data.get("mines",[]);orbits=data.get("orbits",[]);vortices=data.get("vortices",[]);statuses=data.get("statuses",{});projectiles=data.get("projectiles",[]);rings=data.get("rings",[]);casts=data.get("casts",[]);auras=data.get("auras",[]);anchors=data.get("anchors",[]);wires=data.get("wires",[]);pools=data.get("pools",[]);visuals=data.get("visuals",[]);remote_indicators=data.get("indicators",[]);received_at=Time.get_ticks_msec();coast.receive(data.get("coast",{}))
func playing()->bool:
	return adventure.game.started if adventure.arcade else adventure.game.mode=="run"
func draw_on(canvas:Node2D,camera:Vector2)->void:
	var began=Time.get_ticks_usec()
	_draw_on_measured(canvas,camera)
	if adventure.game.has_method("profile_work"):adventure.game.profile_work("combat_draw",Time.get_ticks_usec()-began)
func _draw_on_measured(canvas:Node2D,camera:Vector2)->void:
	if not playing():return
	feedback.draw_on(canvas,camera)
	golf.draw_on(canvas,camera)
	v112.draw_on(canvas,camera)
	v110.draw_on(canvas,camera)
	halloween.draw_on(canvas,camera)
	held_cast.draw_on(canvas,camera)
	twister.draw_on(canvas,camera)
	v98.draw_on(canvas,camera)
	v90.draw_on(canvas,camera)
	stance_heroes.draw_on(canvas,camera)
	party_heroes.draw_on(canvas,camera)
	release_heroes.draw_on(canvas,camera)
	morrow.draw_on(canvas,camera)
	mantis.draw_on(canvas,camera)
	confluence.draw_on(canvas,camera)
	var ground_began=Time.get_ticks_usec()
	v79.draw_on(canvas,camera)
	if adventure.game.has_method("profile_work"):adventure.game.profile_work("ground_family_draw",Time.get_ticks_usec()-ground_began)
	v78.draw_on(canvas,camera)
	v75.draw_on(canvas,camera)
	chronicle.draw_on(canvas,camera)
	mastery_combat.draw_on(canvas,camera)
	pact.draw_on(canvas,camera)
	agent.draw_on(canvas,camera)
	ninja.draw_on(canvas,camera)
	v59.draw_on(canvas,camera)
	v58.draw_on(canvas,camera)
	v56.draw_on(canvas,camera)
	fern.draw_on(canvas,camera)
	robot.draw_on(canvas,camera)
	v48.draw_on(canvas,camera)
	runebearer.draw_on(canvas,camera)
	classics.draw_on(canvas,camera)
	chain.draw_on(canvas,camera)
	courier.draw_on(canvas,camera)
	variants.draw_on(canvas,camera)
	for id in adventure.points():
		if adventure.alive(str(id)) and passive(str(id),"war_drums"):
			var center:Vector2=adventure.points()[id]-camera
			canvas.draw_circle(center,200,Color(.95,.7,.3,.045));canvas.draw_arc(center,200,0,TAU,48,Color(.95,.7,.3,.3),2,true)
	for mine in mines:
		var point:=vec(mine["pos"])-camera
		if not preload("res://scripts/combat_cues.gd").visible(canvas,point,32):continue
		canvas.draw_circle(point,12,Color("#78617a"));canvas.draw_arc(point,14,0,TAU,16,Color("#e5bb78"),2,true)
		canvas.draw_circle(point+Vector2(0,-4),3,Color("#ffdd85"))
		canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-18,-22),"MINE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#edcf9f"))
	for entry in casts:
		if str(entry["style"]) in ["ground_sequence","meteor_shower"]:canvas.draw_arc(vec(entry["pos"])-camera,float(entry["stats"].get("blast_radius",65) if str(entry["style"])=="meteor_shower" else entry["stats"].get("radius",65)),0,TAU,24,Color(.9,.7,.5,.35),2,true)
	var clock:=Time.get_ticks_msec()/1000.0
	for indicator in indicators():
		if str(indicator.get("key","")).begins_with("p:") and not visible_owner(str(indicator.key).substr(2)):continue
		for n in indicator["flags"].size():
			var kind:=str(indicator["flags"][n])
			var point:=vec(indicator["pos"])-camera+Vector2(-12+n*16,-63)
			preload("res://scripts/combat_cues.gd").status(canvas,point,kind,clock)
	for ring in draw_effect_records("root","rings",rings):
		var fallback:Vector2=owner_pos(str(ring.owner)) if bool(ring.get("follow_owner",false)) else vec(ring.pos)
		var center:=draw_effect_position("root",ring,fallback)-camera;var radius:=maxf(1,float(ring["radius"]))
		if not preload("res://scripts/combat_cues.gd").visible(canvas,center,radius+32):continue
		canvas.draw_arc(center,radius,0,TAU,48,Color(str(ring["color"]),.6),4,true)
		if bool(ring.get("prism_bloom",false)):preload("res://scripts/hero_visuals1987.gd").bloom(canvas,center,radius,clock)
		if str(ring.get("style",""))=="waterfall_wave":
			canvas.draw_arc(center,maxf(1,radius-12),0,TAU,48,Color(.65,.95,1,.45),9,true)
			for n in 18:
				var angle:=TAU*n/18+clock*.4
				var point:=center+Vector2.from_angle(angle)*radius
				canvas.draw_arc(point,8,angle-PI*.7,angle+PI*.3,10,Color(.7,.95,1,.7),3,true)
				canvas.draw_circle(center+Vector2.from_angle(angle+.03)*(radius+11),2,Color(.85,1,1,.7))
	starfield.draw_on(canvas,camera)
	for shot in projectiles:draw_projectile(canvas,shot,camera)
	for aura in auras:
		if adventure.points().has(str(aura["owner"])):canvas.draw_circle(owner_pos(str(aura["owner"]))-camera,float(aura["radius"]),Color(.5,.8,1,.13));canvas.draw_arc(owner_pos(str(aura["owner"]))-camera,float(aura["radius"]),clock,clock+TAU*.9,48,Color(.6,.85,1,.6),3,true)
	for pin in anchors:
		var point:=vec(pin["pos"])-camera;canvas.draw_arc(point,12,PI*.2,PI*2.8,24,Color("#e995d6"),4,true);canvas.draw_circle(point,4,Color("#96d9ff"))
	for wire in wires:
		for link in wire.get("links",[[wire["start"],wire["end"]]]):preload("res://scripts/lightning.gd").draw_on(canvas,vec(link[0])-camera,vec(link[1])-camera,Color("#f0afe8"))
	for entry in casts:
		if str(entry["style"])!="charged_beam" or not adventure.points().has(str(entry["owner"])):continue
		var point:=owner_pos(str(entry["owner"]));var direction:=vec(entry["aim"]);var progress:=1-float(entry["time"])/float(entry["total"])
		canvas.draw_line(point-camera,point+direction*float(entry["range"])-camera,Color(1,.9,.3,.08),float(entry["width"]),true);canvas.draw_arc(point-camera,35,-PI*.5,-PI*.5+TAU*progress,40,Color("#ffe37a"),5,true)
	for pool in pools:
		var p:=vec(pool["pos"])-camera;var r:=float(pool["radius"])
		if canvas.has_method("draw_ground_patch") and canvas.draw_ground_patch(p,r,1,clock,"poison"):continue
		if canvas.has_method("draw_ground_patch") and not Rect2(Vector2.ZERO,canvas.VIEW).grow(r+32).has_point(p):continue
		canvas.draw_circle(p,r,Color(.55,.3,.7,.2));canvas.draw_arc(p,r,0,TAU,32,Color(.7,.5,.9,.55),2,true)
	for effect in visuals:
		if str(effect.get("style",""))=="ball_shock":
			var a:Vector2=vec(effect.start)-camera;var b:Vector2=vec(effect.end)-camera;var side:Vector2=(b-a).normalized().orthogonal()*5
			canvas.draw_polyline(PackedVector2Array([a,a.lerp(b,.3)+side,a.lerp(b,.5)-side,a.lerp(b,.7)+side,b]),Color("#c8e5ff"),2,true);continue
		if str(effect.get("style",""))=="brush_crush":
			var center:Vector2=vec(effect.pos)-camera
			var angle:float=vec(effect.aim).angle()
			var progress:float=clampf(1-float(effect.time)/.35,0,1)
			canvas.draw_arc(center,100,angle-.96,angle+.96,24,Color(.9,.78,.5,(1-progress)*.4),2,true)
			var sweep:float=angle-.96+progress*1.92
			canvas.draw_line(center+Vector2.from_angle(sweep)*35,center+Vector2.from_angle(sweep)*100,Color(1,.88,.57,1-progress),8,true)
			continue
		if str(effect.get("style",""))=="fern_bloom":
			var center:Vector2=vec(effect["pos"])-camera
			var progress:float=clampf(1-float(effect["time"])/.6,0,1)
			var radius:float=float(effect["radius"])
			canvas.draw_arc(center,maxf(1,radius*progress),0,TAU,48,Color(.72,.95,.7,1-progress),5,true)
			for leaf in 12:
				var heading:Vector2=Vector2.from_angle(leaf*TAU/12+progress*.5)
				var tip:Vector2=center+heading*radius*progress
				var side:Vector2=heading.orthogonal()*4
				canvas.draw_colored_polygon(PackedVector2Array([tip-heading*9,tip+side,tip+heading*7,tip-side]),Color(.83,.96,.64,1-progress))
			continue
		if str(effect.get("style",""))=="dawn_circle":
			var center:Vector2=vec(effect["pos"])-camera
			var radius:float=float(effect["radius"])
			var progress:float=clampf(1-float(effect["time"])/.85,0,1)
			var fade:float=1-progress
			canvas.draw_circle(center,radius,Color(1,.8,.35,fade*.16))
			canvas.draw_arc(center,radius,0,TAU,64,Color(1,.9,.6,fade*.9),3,true)
			for blade in 3:
				var angle:float=progress*TAU+blade*TAU/3
				canvas.draw_arc(center,radius*(.73+blade*.09),angle-1.0,angle,20,Color(1,.93,.7,fade),5,true)
				var tip:Vector2=center+Vector2.from_angle(angle)*radius*(.73+blade*.09)
				canvas.draw_line(tip-Vector2.from_angle(angle)*20,tip,Color(1,1,.86,fade),4,true)
			canvas.draw_circle(center,maxf(1,radius*progress),Color(1,.86,.5,fade*.12))
			continue
		if str(effect.get("style",""))=="magnet_surge":
			var center:=vec(effect["pos"])-camera;var progress:=clampf(1-float(effect["time"])/.55,0,1)
			var tint:=Color("#d693ef");tint.a=1-progress*.7
			canvas.draw_circle(center,10+sin(progress*PI)*8,Color(tint,.45))
			for n in 8:
				var direction:=Vector2.from_angle(TAU*n/8+progress*.25)
				var tip:=center+direction*lerpf(float(effect["radius"]),18,progress)
				canvas.draw_line(tip+direction*18,tip,tint,3,true)
				canvas.draw_line(tip,tip+direction.rotated(.6)*9,tint,2,true)
				canvas.draw_line(tip,tip+direction.rotated(-.6)*9,tint,2,true)
			continue
		if str(effect.get("style",""))=="magnet_tether":
			var start:=vec(effect["start"])-camera;var end:=vec(effect["end"])-camera
			var progress:=clampf(1-float(effect["time"])/.55,0,1)
			canvas.draw_line(start,end,Color(.83,.58,.94,(1-progress)*.65),2,true)
			for n in 3:canvas.draw_circle(start.lerp(end,fmod(progress*2+n/3.0,1)),3,Color("#f0c7ff"))
			continue
		if str(effect.get("style",""))=="constellation":
			var stars:Array=effect.get("points",[])
			for n in stars.size():
				var point:=vec(stars[n])-camera-Vector2(0,75)
				canvas.draw_circle(point,4,Color("#fff0ca"));canvas.draw_arc(point,9,0,TAU,12,Color(.95,.75,.4,.5),2,true)
				if n>0:canvas.draw_line(point,vec(stars[n-1])-camera-Vector2(0,75),Color(.9,.75,.55,.4),2,true)
			continue
		if effect.has("start"):canvas.draw_line(vec(effect["start"])-camera,vec(effect["end"])-camera,Color(str(effect["color"]),.3),float(effect["width"]),true);canvas.draw_line(vec(effect["start"])-camera,vec(effect["end"])-camera,Color(str(effect["color"]),.85),8,true)
		else:canvas.draw_arc(vec(effect["pos"])-camera,float(effect["radius"]),0,TAU,48,Color(str(effect["color"]),.6),5,true)
	for orbit in orbits:
		if not adventure.points().has(str(orbit["owner"])):continue
		var center:=owner_pos(str(orbit["owner"]))-camera
		canvas.draw_arc(center,float(orbit["radius"]),0,TAU,48,Color(.4,.9,.8,.2),2,true)
		for n in 3:
			var point:=center+Vector2.from_angle(float(orbit["angle"])+TAU*n/3)*float(orbit["radius"])
			canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-12),point+Vector2(8,0),point+Vector2(0,12),point+Vector2(-8,0)]),Color("#c4f2df"))
	for vortex in vortices:
		var center:=vec(vortex["pos"])-camera;var radius:=float(vortex["radius"])
		canvas.draw_circle(center,radius,Color(.3,.8,.75,.13))
		for n in 5:canvas.draw_arc(center,radius*(n+1)/5,clock*3+n,clock*3+n+PI,40,Color(.6,.95,.8,.6),3,true)
	coast.draw_on(canvas,camera)

func ranged_enemy(foe:Dictionary,definition:Dictionary)->bool:
	return not bool(foe.get("boss",false)) and (str(definition.get("behaviour","")) in ["ranged","burst_ranged","dual_ranged","homing","summoner"] or str(definition.get("custom_attack","")) in ["lob","beam","portals","bankshot_volley","grate_march","honey_halo","burrow_shards","echo_return","sap_heal","tide_cross","bell_echo"] or str(foe.get("type","")) in ["inkfin","foldwing","tuning_wraith"])
func ranged_direction(foe:Dictionary,target:Vector2)->Vector2:
	var origin:Vector2=foe["pos"];var offset:=target-origin;var distance:=offset.length();var uid:=int(foe.get("uid",0))
	var desired:=245.0+float(uid%3)*20
	var toward:=offset.normalized() if distance>1 else Vector2.from_angle(float(uid%628)/100)
	var wish:=Vector2.ZERO
	if distance<desired-35:wish=-toward
	elif distance>desired+30 or not path_clear(origin,target):wish=toward
	for other in adventure.foes():
		if int(other.get("uid",-1))==uid:continue
		var away:Vector2=origin-other["pos"];var gap:=away.length()
		if gap<110:wish+=away.normalized()*1.6*(1-gap/110.0)
	if wish.length()<.1:return Vector2.ZERO
	wish=(wish+Vector2(-toward.y,toward.x)*(.2 if uid%2 else -.2)).normalized()
	var best:=Vector2.ZERO;var score:=-INF
	var bounds:Rect2=adventure.game.FIELD if adventure.arcade else Rect2(Vector2.ZERO,adventure.game.region_size())
	for angle in [0.0,.5,-.5,1.0,-1.0,1.6,-1.6,PI]:
		var direction:=wish.rotated(angle);var endpoint:=origin+direction*65
		if not bounds.grow(-40).has_point(endpoint) or not path_clear(origin,endpoint):continue
		var value:=direction.dot(wish)*2-absf(endpoint.distance_to(target)-desired)/100
		for other in adventure.foes():
			if int(other.get("uid",-1))!=uid:value-=maxf(0,105-endpoint.distance_to(other["pos"]))/70
		if value>score:score=value;best=direction
	return best

func war_multiplier(owner:String)->float:
	var rune_bonus:=1.2 if effect_time(player_key(owner),"rune_might")>0 else 1.0
	if owner.is_empty() or owner=="enemy" or not adventure.alive(owner):return 1.0
	rune_bonus*=halloween.bonus(owner)*v112.bonus(owner)
	for id in adventure.points():
		if not adventure.alive(str(id)) or not passive(str(id),"war_drums"):continue
		if adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and adventure.game._rival(owner,str(id)):continue
		if owner_pos(owner).distance_to(owner_pos(str(id)))<=200:return 1.08*rune_bonus
	return rune_bonus

func clock_delta(owner:String,delta:float)->float:
	var magic:Node=adventure.game.get("dev_magic")
	return delta if magic==null else delta/maxf(.3,magic.world_scale())*magic.scale_for(owner)

func draw_projectile(canvas:Node2D,shot:Dictionary,camera:Vector2)->void:
	var began=Time.get_ticks_usec()
	_draw_projectile_measured(canvas,shot,camera)
	if adventure.game.has_method("profile_work"):adventure.game.profile_work("projectile_art",Time.get_ticks_usec()-began)
func _draw_projectile_measured(canvas:Node2D,shot:Dictionary,camera:Vector2)->void:
	var borrowed:Dictionary=shot.get("stats",{}).get("stolen_appearance",{})
	if not borrowed.is_empty():
		var replica:Dictionary=shot.duplicate();replica.stats=borrowed.get("stats",{});replica.style=str(borrowed.get("style","pellet"));replica.color=str(borrowed.get("color","#aeead9"));replica.radius=float(borrowed.get("radius",5))
		var custom:String=str(borrowed.get("custom",""));var p:Vector2=vec(shot.pos)-camera;var aim:Vector2=vec(shot.aim);var t:float=Time.get_ticks_msec()/1000.0
		if not custom.is_empty():
			if adventure.arcade and adventure.game.has_method("object_projectile_display"):p=adventure.game.object_projectile_display(shot,p+camera)-camera
			if not preload("res://scripts/combat_cues.gd").visible(canvas,p,maxf(float(replica.radius),48)):return
		if custom=="windwheel":preload("res://scripts/hero_visuals1987.gd").windwheel(canvas,p,t*20,false);return
		if custom=="rocket":
			var side:Vector2=aim.orthogonal();canvas.draw_colored_polygon(PackedVector2Array([p+aim*15,p-aim*10+side*6,p-aim*7,p-aim*10-side*6]),Color("#c8dcdb"));canvas.draw_line(p-aim*6,p+aim*6,Color("#526a72"),4,true);return
		if custom=="bubble":canvas.draw_circle(p,float(replica.radius),Color(Color(replica.color),.15));canvas.draw_arc(p,float(replica.radius),0,TAU,24,Color(replica.color),2,true);return
		if custom in ["ribbon","dart"]:
			canvas.draw_line(p-aim*22,p+aim*8,Color(replica.color),3,true)
			if custom=="ribbon":canvas.draw_arc(p,6,t*5,t*5+PI,12,Color(replica.color),2,true)
			return
		_draw_projectile_measured(canvas,replica,camera);return
	var clock:float=Time.get_ticks_msec()/1000.0
	var point:=vec(shot["pos"])-camera;var radius:=float(shot["radius"])
	if not bool(shot.get("net_rendered",false)) and not adventure.authoritative() and adventure.game.get("net_ready")==true:point+=vec(shot["aim"])*float(shot.get("speed",0))*clampf((Time.get_ticks_msec()-received_at)/1000.0,0,.12)
	if adventure.arcade and adventure.game.has_method("object_projectile_display"):point=adventure.game.object_projectile_display(shot,point+camera)-camera
	if not preload("res://scripts/combat_cues.gd").visible(canvas,point,maxf(radius,48)):return
	if shot["stats"].has("cinder_visual"):
		var aim=vec(shot.aim);var side=aim.orthogonal();var tail=point-aim*(21+sin(clock*15)*5)
		canvas.draw_colored_polygon(PackedVector2Array([point+aim*11,point+side*8,tail+side*4,tail-aim*8,point-side*8]),Color("#e56c37"));canvas.draw_circle(point,6,Color("#ffe2a0"));canvas.draw_line(tail,point,Color("#ffb95f"),3,true);return
	if bool(shot["stats"].get("prism_glass",false)):
		preload("res://scripts/hero_visuals1987.gd").prism(canvas,point,vec(shot.aim));return
	if bool(shot["stats"].get("golf_ball",false)):
		preload("res://scripts/hero_visuals1984.gd").ball(canvas,point,vec(shot.aim));return
	if bool(shot["stats"].get("river_stone",false)):
		preload("res://scripts/hero_visuals1984.gd").stone(canvas,point,vec(shot.aim));return
	if bool(shot["stats"].get("pistol",false)):
		var heading:=vec(shot["aim"]);var side:=heading.orthogonal()
		canvas.draw_line(point-heading*24,point-heading*6,Color("#e2af62",.6),3,true)
		canvas.draw_colored_polygon(PackedVector2Array([point+heading*6,point+side*2,point-heading*5,point-side*2]),Color("#fff0bc"));return
	if bool(shot["stats"].get("mirror_shard",false)):
		var heading:Vector2=vec(shot["aim"]);var side:Vector2=heading.orthogonal();var size:float=radius/6 if bool(shot["stats"].get("released_hold",false)) else 1.0
		canvas.draw_colored_polygon(PackedVector2Array([point+heading*16*size,point+side*7*size,point-heading*13*size,point-side*7*size]),Color("#c8edf2"))
		canvas.draw_line(point-heading*25,point,Color(.6,.85,1,.4),3,true);return
	if bool(shot["stats"].get("lantern_comet",false)):
		var heading:Vector2=vec(shot["aim"])
		var glow:=Color(str(shot.get("color","#e8d393")))
		canvas.draw_line(point-heading*27,point,Color(glow,.4),6,true)
		canvas.draw_rect(Rect2(point-Vector2(6,8),Vector2(12,16)),Color("#bb9756"))
		canvas.draw_rect(Rect2(point-Vector2(3,5),Vector2(6,10)),Color(glow.lightened(.3)));canvas.draw_arc(point,13,clock*3,clock*3+PI,16,glow,2,true)
		if str(shot["stats"].get("element",""))=="earth":
			for n in 3:canvas.draw_circle(point+Vector2.from_angle(clock*3+TAU*n/3)*17,2,Color("#a9d479"))
		elif str(shot["stats"].get("element",""))=="fire":canvas.draw_colored_polygon(PackedVector2Array([point-heading*10+heading.orthogonal()*6,point-heading*(28+sin(clock*15)*5),point-heading*10-heading.orthogonal()*6]),Color("#ff8741",.7))
		return
	if bool(shot.get("stats",{}).get("navigator_star",false)):
		starfield.draw_shot(canvas,shot,point,clock);return
	if str(shot["style"])=="silk_needle":
		var heading:Vector2=vec(shot["aim"]);var side:Vector2=heading.orthogonal()
		canvas.draw_line(point-heading*30,point,Color(.84,.7,.95,.4),2,true)
		canvas.draw_colored_polygon(PackedVector2Array([point+heading*14,point+side*4,point-heading*11,point-side*4]),Color("#ead9f7"))
		canvas.draw_line(point-heading*8,point+heading*9,Color("#fff2cf"),1,true);return
	if not str(shot["stats"].get("ice_visual","")).is_empty():
		preload("res://scripts/ice_projectiles.gd").draw(canvas,point,vec(shot["aim"]),str(shot["stats"].ice_visual),clock);return
	if bool(shot["stats"].get("thorn_arrow",false)):
		var heading:=vec(shot["aim"]);var side:=heading.orthogonal()
		canvas.draw_line(point-heading*15,point+heading*8,Color("#9eae72"),2,true)
		canvas.draw_colored_polygon(PackedVector2Array([point+heading*12,point+heading*4+side*4,point+heading*4-side*4]),Color("#d6e8b0"))
		for sign_value in [-1,1]:canvas.draw_line(point-heading*12,point-heading*17+side*sign_value*4,Color("#659b58"),2,true)
		return
	if bool(shot["stats"].get("tea_drop",false)):
		var heading:=vec(shot["aim"]);var side:=heading.rotated(PI*.5)
		canvas.draw_circle(point,7,Color("#9cbd63"));canvas.draw_colored_polygon(PackedVector2Array([point-heading*17,point+side*6,point-side*6]),Color("#9cbd63"));canvas.draw_circle(point-heading*2-side*2,2,Color("#e5efa6"));return
	if bool(shot["stats"].get("rune_hammer",false)):
		var heading:=Vector2.from_angle(clock*12);var side:=heading.rotated(PI*.5)
		canvas.draw_line(point-heading*15,point+heading*10,Color("#9a7855"),5,true)
		canvas.draw_line(point+heading*10-side*12,point+heading*10+side*12,Color("#c4d4d9"),12,true)
		canvas.draw_arc(point,22,clock*5,clock*5+PI,16,Color(.94,.75,.4,.5),2,true);return
	if bool(shot["stats"].get("flying_page",false)):
		var heading:=vec(shot["aim"]);var side:=heading.rotated(PI*.5)
		canvas.draw_colored_polygon(PackedVector2Array([point-heading*10-side*7,point+heading*10-side*6,point+heading*8+side*8,point-heading*9+side*7]),Color("#f2e7c8"))
		for n in 3:canvas.draw_line(point-heading*(5-n*5)-side*4,point-heading*(5-n*5)+side*4,Color("#8ca6ad"),1,true)
		return
	if bool(shot["stats"].get("chalk_shard",false)):
		var heading:=vec(shot["aim"]);canvas.draw_line(point-heading*8,point+heading*8,Color("#edf0c8"),5,true);return
	if bool(shot["stats"].get("flame_orb",false)):
		canvas.draw_circle(point,11,Color(1,.45,.15,.25));canvas.draw_arc(point,9,clock*5,clock*5+PI*1.5,16,Color("#ffd389"),2,true)
		var heading:=vec(shot["aim"])
		for n in 4:canvas.draw_circle(point-heading*(8+n*6),4-n*.7,Color(1,.5,.2,.35-n*.06))
	if str(shot["style"])=="weaving":
		var base:=vec(shot["base_aim"]);var side:=Vector2(-base.y,base.x);var trail:=PackedVector2Array()
		for n in 7:
			var behind:=maxf(0,float(shot["distance"])-n*5)
			trail.append(vec(shot["origin"])+base*behind+side*sin(behind*TAU/float(shot["stats"].get("wavelength",170)))*float(shot["stats"].get("amplitude",20))-camera)
		canvas.draw_polyline(trail,Color(Color(str(shot["color"])),.4),3,true)
	if bool(shot.get("stats",{}).get("pistol",false)):
		canvas.draw_line(point-vec(shot.aim)*12,point,Color("#ffd9a0"),3,true)
	if bool(shot.get("stats",{}).get("pistol",false)):
		var dir:Vector2=vec(shot.aim);var side:=dir.orthogonal()
		canvas.draw_colored_polygon(PackedVector2Array([point+dir*5,point-dir*6+side*2,point-dir*6-side*2]),Color("#ffe1ac"));return
	if bool(shot.get("stats",{}).get("ball_lightning",false)):
		for n in 4:
			var a:float=clock*3+n*PI/2
			canvas.draw_polyline(PackedVector2Array([point+Vector2.from_angle(a)*radius,point+Vector2.from_angle(a+.15)*(radius+8),point+Vector2.from_angle(a-.1)*(radius+16)]),Color("#d8eaff"),2,true)
	canvas.draw_circle(point,radius if str(shot["style"])=="rolling_snow" or bool(shot["stats"].get("released_hold",false)) else 5,Color(str(shot["color"])));canvas.draw_arc(point,maxf(3,radius*.7),clock*4,clock*4+PI,20,Color("#8cc5e4"),2,true)

func projectile_near(start:Vector2,finish:Vector2,key:String,point:Vector2,radius:float)->bool:
	var g=adventure.get_parent()
	if adventure.arcade and g.has_meta("fx_network_previous_positions"):return g.network_projectile_near(start,finish,key,point,radius)
	return Geometry2D.get_closest_point_to_segment(point,start,finish).distance_to(point)<=radius

func draw_effect_position(module:String,record:Dictionary,fallback:Vector2)->Vector2:
	return preload("res://network/effect_anchors.gd").position(adventure.game,module,record,fallback)

func draw_effect_records(module:String,collection:String,live:Array)->Array:
	if adventure.game.has_method("network_effect_records"):return adventure.game.network_effect_records(module,collection,live)
	return live
