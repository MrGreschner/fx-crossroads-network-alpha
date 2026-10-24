extends RefCounted
## Expedition echoes have self-contained AI. Authored-realm controllers only own their original actors.
const ORIGINALS=["bramble","archer","imp","warlock","reed_stalker","sluice_crab","frostling","ice_archer","wick_wisp","bog_bellringer","star_mine","comet_urchin"]
static func type_for(id:String)->String:
 if id=="waylight_reed":id="reed_stalker"
 if id=="waylight_crab":id="sluice_crab"
 if id=="boss":id="bramble"
 return "between_"+id if id in ORIGINALS else id
static func install(g:Node,multi:bool)->void:
 preload("res://scripts/between_guardians.gd").install(g,multi)
 var definitions:Dictionary=g.enemy_defs if multi else g.enemy_types
 for id in ORIGINALS:
  var alias=type_for(id);var def:Dictionary=definitions.get(id,{}).duplicate(true)
  def.id=alias;def.expansion_only=true
  if id in ["wick_wisp","bog_bellringer"]:def.behaviour="ranged";def.shot_speed=260;def.shot_cooldown=2.5
  if str(def.get("behaviour","chase")) not in ["ranged","chase","homing","burst_ranged","dual_ranged"]:def.behaviour="chase"
  def.erase("custom_attack");definitions[alias]=def
  if not multi:g.load_sprite_pair(str(def.get("sprite",id)))
  for pose in (["idle","walk1","walk2","attack"] if multi else ["0","1"]):g.art[alias+"_"+pose]=g.art.get(str(def.get("sprite",id))+"_"+pose)
static func normalize(foe:Dictionary)->Dictionary:
 foe.type=type_for(str(foe.type));return foe
