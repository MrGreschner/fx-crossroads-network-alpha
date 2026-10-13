extends RefCounted
## Data-driven browse metadata. New student heroes receive sensible fallbacks.
var meta:Dictionary={}
var numbers:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/hero_numbers.json"))
func number(game:Node,id:String)->int:return int(numbers.get(id,game.manifest.characters.find(id)+1))
func _init()->void:
 var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://content/hero_library.json"))
 if parsed is Dictionary:meta=parsed
func entry(id:String,hero:Dictionary)->Dictionary:
 if meta.has(id):return meta[id]
 var close:bool=str(hero.get("primary",{}).get("style","")) in ["melee","slash","punch","scratch","kick","identity_strike"]
 return {"role":"Melee" if close else "Ranged","tags":["Melee" if close else "Ranged"],"difficulty":"Some practice","home_realm":"","summary":"Try this hero in the training yard."}
func entries(game:Node,role:String="All",difficulty:String="Any difficulty",query:String="",favourites_only:bool=false)->Array:
 var result:Array=[];var favourites:Array=game.legacy.data.get("favourites",[])
 for id in game.manifest.get("characters",[]):
  var hero:Dictionary=game.characters.get(str(id),{});var info:=entry(str(id),hero)
  if role!="All" and role not in info.tags:continue
  if difficulty!="Any difficulty" and str(info.difficulty)!=difficulty:continue
  if favourites_only and id not in favourites:continue
  if not query.strip_edges().is_empty() and query.strip_edges()!=str(number(game,str(id))) and not str(hero.get("name",id)).to_lower().contains(query.to_lower().strip_edges()):continue
  result.append(id)
 # Stable partitions preserve authored roster order within each group.
 return result.filter(func(id):return id in favourites)+result.filter(func(id):return id not in favourites)
func progress(game:Node,id:String)->Dictionary:
 var rec:Dictionary=game.legacy.record(id);var spec:Dictionary=game.characters[id].mastery
 if game.legacy.final_eligible(id):return {"label":"Final technique earned","ratio":1.0}
 var first:bool=game.legacy.eligible(id);var req:Dictionary=spec.get("final_requirements" if first else "technique_requirements",{})
 if not first and req.has("duet_realm"):return {"label":"Foundry duo + 10,000 damage","ratio":minf(1,float(rec.damage)/10000) if bool(rec.get("duet_clear",false)) else 0.0,"detail":"Clear Foundry together • %d/10,000 damage" % int(rec.damage)}
 var ratio:float=minf(float(rec.clears)/maxf(1,float(req.get("clears",12 if first else 3))),minf(float(rec.realms.size())/maxf(1,float(req.get("distinct_realms",6 if first else 2))),float(rec.damage)/maxf(1,float(req.get("damage",85000 if first else 10000)))))
 return {"label":"Final technique" if first else "First technique","ratio":clampf(ratio,0,1),"detail":"%d/%d clears • %d/%d realms • %d/%d damage" % [int(rec.clears),int(req.get("clears",12 if first else 3)),rec.realms.size(),int(req.get("distinct_realms",6 if first else 2)),int(rec.damage),int(req.get("damage",85000 if first else 10000))]}
func ability_brief(a:Dictionary,kind:String)->String:
 if a.has("ui_brief"):return str(a.ui_brief)
 var style:String=str(a.get("style",""));var damage:String=str(a.get("damage",0)).trim_suffix(".0")
 if style=="heal_wave":return "Heal you and allies • %s HP" % float(a.get("heal",35 if kind=="special" else 25))
 if style=="wick_fire":return "Fireball • "+damage+" damage + burn"
 if style=="wick_face":return "Fright • forward stun, then 3s slow"
 if style=="wick_treats":return "Volley • bouncing treats open mixed fields"
 if style=="crab_pincers":return "Melee • two claw snaps • "+damage+" damage each"
 if style=="crab_shell":return "Counter • 3.5s brace; catch 4 shots"
 if style=="crab_crush":return "Scuttle • "+damage+" damage + banked shards"
 if style=="crab_nursery":return "Refuge • heal and protect nearby allies"
 var utility:Dictionary={"twister_charge":"Charge / release • drifting damage and slow funnels","twister_stride":"Transform • steer a fast damaging tornado","twister_hail":"Channel • warned hail impacts and stuns","twister_sleet":"Channel • directed ice corridor and slows","block":"Guard • reduce damage / stop shots","stealth":"Escape • stealth, speed and healing","heal_zone":"Support • healing ground for allies","chill_aura":"Aura • slow foes and protect yourself","rune_cycle":"Support • cycle through three rune buffs","rune_step":"Teleport • return to your first rune","spell_snare":"Counter • catch and return enemy spells","saw_transform":"Transform • damaging saw and slowing stomp","corner_lens":"Setup • bend your laser shots","change_of_heart":"Capture • turn a non-boss into an ally","rally_banner":"Support • rally and protect nearby allies","sluice_pool":"Water field • damage and team synergy","relay_field":"Lightning field • damage and team synergy","history_rewind":"Rewind • return along your recent path","raise_remains":"Summon • raise fallen foes as allies","life_lattice":"Link • share health with raised allies","red_covenant":"Empower • trade health for stronger hits","master_key":"Teleport • heal and gain protection","classroom_management":"Control • hold to pull; release to repel","rescue_buoy":"Support • deploy a rescue buoy","safe_passage":"Support • moving projectile cover","lumen_relay":"Support • place a healing lantern relay","mosaic_scatter":"Control • split and reposition your tiles","traffic_order":"Control • direct enemies with flowing gates","monk_poison_form":"Transform • poison stance for 12s","mirror_guard":"Counter • time your guard to build Poise","v90_pot":"Area • damage foes and heal allies","v90_steps":"Support • plant safe stepping lights","v90_haven":"Support • create a lantern refuge","v90_puppets":"Summon • call two understudies","mosaic_seed":"Summon • grow tiles; up to five pieces","hive_lantern":"Summon • deploy a clockwork hive","walking_chronicle":"Replay • repeat your route and switch element","twin_self":"Duplicate • two matching selves for 6s"}
 if utility.has(style):return str(utility[style])
 if style=="summon":return "Summon • %d allies • %s damage / hit" % [int(a.get("count",1)),damage]
 if style=="ice_wall":return "Hold to aim • lobbed ice • "+damage+" area damage and a barrier"
 if style=="waterfall_wave":return "Water wave • "+damage+" damage, push and slow"
 if style=="blink_bomb":return "Teleport • leave a "+damage+"-damage bomb behind"
 if style=="agent_ambush":return "Ambush • three delayed piercing laser beams"
 if style=="scatterlight":return "Laser cone • each thin beam stops at first hit"
 if style=="v90_lasso":return "Pull + stun • "+damage+" damage"
 if a.has("hold_charge"):
  var cfg:Dictionary=a.hold_charge;var seconds:float=float(cfg.get("seconds",0))
  if seconds>0:return "Hold + release • %s–%s damage • %.1fs charge" % [damage,str(snappedf(float(a.get("damage",0))*float(cfg.get("damage",1)),.1)),seconds]
  return "Hold to aim • release to cast • "+damage+" damage"
 if style=="mirror_fan":return "Mirror fan • 3 piercing shards • "+damage+" damage each"
 if style=="page_channel":return "Hold • homing pages; stand still while casting"
 if style=="body_bounce":return "Melee • bounce between three foes • "+damage+" damage"
 if style=="bloom_seed":return "Plant • delayed fireballs and a healing aura"
 if style=="kindred_dart" or style=="kindred_fan":return "Darts • damage foes or heal friends"
 var melee:Array=["melee","slash","punch","scratch","kick","identity_strike","beaver_bite","tail_slap","piston_jab","hearth_combo","gopher_claw","quill_claw","scissor_feint","v90_chop","v90_reed","v91_scissors","rune_slash","rune_hammer","chain_sweep"]
 var area:Array=["stomp","pulse_wave","pulse_burst","target_aoe","dawn_circle","fish_splash","ground_sequence","meteor_shower","v90_phoenix","gopher_cave","brush_crush","iron_haul","bitter_bloom","quiet_court","v90_feast","v90_curtain","rune_domain","vortex_field","chalk_grid","rift_triangle","rolling_rampart"]
 var moving:Array=["charge","body_bounce","gopher_dive","grapnel_rush","shell_lob","windlass_swing","quill_lunge","v90_ascent","v90_stampede","seam_ride","canopy_crossing","shield_march"]
 var continuous:Array=["flame","fire_breath","magma_breath","beam","charged_beam","page_channel","magnet_wire","orbit_shards","spiral_shards","silk_tripline","lunar_loom","v90_wing"]
 var label:String="Melee" if style in melee else "Area" if style in area else "Movement attack" if style in moving else "Beam / channel" if style in continuous else "Ranged" 
 if style in ["magnet_pull","gathering_knot","rewind_chime","time_bubble","grand_draw","erase_release","rift_rotate","prism_fold","latchline","v90_lasso"]:label="Control"
 if style in ["harbor_note","pocket_rain","tailwind_seam","ribbon_stitch","fern_double","maypole_waltz"]:label="Support / damage"
 if style=="manual_mines":return "Mines • place two, then detonate • %s damage" % damage
 if style=="rolling_snow":return "Growing snowball • blast, knockback and fragments"
 if style=="timber_fall":return "Falling tree • %s damage and stun in a line" % damage
 if style=="monk_primary":return "Changing stance • triple punches or ranged daggers"
 if style=="monk_secondary":return "Changing stance • bouncing kicks or fire breath"
 if style=="tidal_maw":return "Delayed bite • %s damage, pull and stun" % damage
 if style=="vacuum_intake":return "Intake • slow foes and catch enemy projectiles"
 if style=="mosaic_guardian":return "Summon • command a colourful guardian"
 if style=="swarm_relay":return "Swarm • aim a relay volley from your drones"
 if style=="back_volcano":return "Area • erupt lava for six seconds"
 return label+" • %s base damage" % damage+(" + poison" if a.has("poison_damage") else "")
