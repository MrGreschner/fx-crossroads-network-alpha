extends RefCounted
## Presentation-only fatal-hit provenance. No XP, scoring or damage changes.
static func hazard(name:String)->Dictionary:
 return {"kind":"environment","name":"Environment","attack":name.left(96),"sprite":""}
static func resolve(game:Node,source:String,attack:String="Attack",actor_key:String="")->Dictionary:
 var key:String=actor_key if not actor_key.is_empty() else source
 if key.begins_with("p:"):key=key.substr(2)
 var multi:bool=game.get("hero_ids")!=null
 if multi and game.hero_ids.has(key):
  var id:String=str(game.hero_ids[key]);var hero:Dictionary=game.characters.get(id,{})
  var player:="Player"
  for member in game.roster:
   if str(member.get("id",""))==key:player=str(member.get("name","Player")).left(32);break
  return {"kind":"hero","name":str(hero.get("name",id)),"player":player,"attack":attack.left(96),"sprite":str(hero.get("sprite",id))}
 var foes:Array=game.opponents if multi else game.enemies
 for foe in foes:
  if key=="e:"+str(foe.get("uid",0)) or key==str(foe.get("type","")):
   var kind:String=str(foe.get("type",""));var defs:Dictionary=game.enemy_defs if multi else game.enemy_types
   var d:Dictionary=defs.get(kind,{})
   var region:Dictionary=game.regions.get(game.realm_id,{}) if multi else game.region
   var boss:bool=bool(foe.get("boss",false)) and kind in ["boss","fragment"]
   return {"kind":"enemy","name":str(foe.get("name",region.get("boss_name","Realm guardian"))) if boss else str(foe.get("name",d.get("name",kind.replace("_"," ").capitalize()))),"attack":attack.left(96),"sprite":str(foe.get("sprite",region.get("boss_sprite","bramble_boss"))) if boss else str(foe.get("sprite",d.get("sprite",kind)))}
 if key=="environment":return hazard(attack)
 if key=="self":return {"kind":"self","name":"Your own ability","attack":attack.left(96),"sprite":""}
 return {"kind":"unknown","name":"Unidentified attacker","attack":attack.left(96),"sprite":""}
static func texture(game:Node,credit:Dictionary)->Texture2D:
 var sprite:String=str(credit.get("sprite",""))
 if sprite.is_empty():return null
 for suffix in ["_idle","_0",""]:
  if game.art.has(sprite+suffix):return game.art[sprite+suffix]
  for ext in [".png",".svg"]:
   var path:String="res://assets/"+sprite+suffix+ext
   if ResourceLoader.exists(path):return load(path)
 return null
static func card(parent:Node,game:Node,credit:Dictionary)->void:
 if credit.is_empty():return
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);parent.add_child(row)
 var portrait:=TextureRect.new();portrait.texture=texture(game,credit);portrait.custom_minimum_size=Vector2(56,56);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(portrait)
 if portrait.texture==null:
  portrait.hide();var badge:=Label.new();badge.text="!" if credit.get("kind","")=="environment" else "?";badge.custom_minimum_size=Vector2(40,48);badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.add_theme_font_size_override("font_size",30);row.add_child(badge)
 var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",17);label.add_theme_color_override("font_color",Color("#ffd3ae"))
 label.text="LAST DEFEAT • "+str(credit.get("name","Unknown source"))
 if not str(credit.get("player","")).is_empty():label.text+=" • "+str(credit.player)
 label.text+="\n"+str(credit.get("attack","Attack"));row.add_child(label)
