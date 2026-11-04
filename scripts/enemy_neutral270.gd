extends RefCounted
static func identity(key:String)->String:
 for suffix in preload("res://scripts/enemy_art235.gd").SUFFIXES:
  if key.ends_with(suffix):return key.trim_suffix(suffix)
 return key
static func draw_front(c:Node2D,key:String,pose:String,rect:Rect2,tint:Color=Color.WHITE,foe:Dictionary={})->bool:
 var id=identity(key);var art=preload("res://scripts/enemy_art235.gd");var motion=preload("res://scripts/neutral_art270.gd")
 if id=="bramble_boss" and str(c.get("region_id"))=="quarry":preload("res://scripts/quarry_art254.gd").draw_boss(c,pose,rect,tint);return true
 if preload("res://scripts/enemy_animation280.gd").has(id):
  preload("res://scripts/enemy_animation280.gd").draw(c,id,pose,rect,tint,foe);return true
 if preload("res://scripts/enemy_animation279.gd").has(id):
  preload("res://scripts/enemy_animation279.gd").draw(c,id,pose,rect,tint,foe);return true
 if preload("res://scripts/enemy_animation278.gd").has(id):
  preload("res://scripts/enemy_animation278.gd").draw(c,id,pose,rect,tint,foe);return true
 if preload("res://scripts/enemy_animation277.gd").has(id):
  preload("res://scripts/enemy_animation277.gd").draw(c,id,pose,rect,tint,foe);return true
 if preload("res://scripts/enemy_animation276.gd").has(id):
  preload("res://scripts/enemy_animation276.gd").draw(c,id,pose,rect,tint,foe);return true
 var animated=preload("res://scripts/enemy_animation275.gd")
 var distance=0.0
 if not foe.is_empty():distance=float(c.enemy_motion229.tracks.get(int(foe.get("uid",0)),{}).get("distance",0.0))
 if animated.has(id):
  var selected=animated.phase_pose(id,pose,distance);var box=animated.motion(c,id,pose,animated.fitted(id,rect),distance)
  c.draw_texture_rect(animated.texture(id,selected),box,false,tint);return true
 if c.adventure.quests.active and id in ["briar_bandit","glowcap_slinger","rootbound_keeper","summit_golem"]:
  preload("res://scripts/cast_art232.gd").draw_in_rect(c,id,pose,preload("res://scripts/enemy_visual227.gd").adjusted(id,rect),tint);return true
 var tex:Texture2D=art.texture(id,pose)
 if tex!=null:c.draw_texture_rect(tex,art.fitted(id,rect),false,tint);return true
 var bank:Dictionary=c.art;tex=bank.get(id+"_"+pose,bank.get(id+"_idle",bank.get(id+"_0",bank.get(id))))
 if tex==null:return false
 c.draw_texture_rect(tex,preload("res://scripts/enemy_visual227.gd").adjusted(id,rect),false,tint);return true
