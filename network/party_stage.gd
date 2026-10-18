extends Control
## The actual T4 roster, drawn with the same sprites as the town.
var game:Node
var clock:float=0
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;queue_redraw()
func _draw()->void:
 if game==null:return
 draw_rect(Rect2(Vector2.ZERO,size),Color("#102732"))
 draw_rect(Rect2(Vector2.ZERO,size),Color("#45636a"),false,1)
 var members:Array=game.roster if not game.roster.is_empty() else [{"id":"preview","hero":game.selected_hero,"name":game.net_name.text}]
 var cols:int=mini(4,maxi(1,members.size()));var rows:int=ceili(float(members.size())/cols)
 var tile:Vector2=Vector2(size.x/cols,size.y/rows)
 for i in members.size():
  var member:Dictionary=members[i];var id:String=str(member.get("id","preview"));var local:bool=id in [game.my_id,"preview"]
  var hero:String=game.selected_hero if local else str(member.get("hero","ram"))
  var spec:Dictionary=game.characters.get(hero,{})
  var sprite:String=str(spec.get("sprite",hero));var pose:String="walk1" if int(clock*4+i)%2==0 else "walk2"
  var texture:Texture2D=game.art.get(sprite+"_"+pose,game.art.get(sprite+"_0",game.art.get(sprite+"_idle")))
  var p:Vector2=Vector2((i%cols+.5)*tile.x,(int(i/cols)+.5)*tile.y)
  var height:float=minf(64,tile.y-37)
  draw_circle(p+Vector2(0,height*.32),18,Color(0,0,0,.28))
  if texture!=null:draw_texture_rect(texture,Rect2(p-Vector2(height*.42,height*.65),Vector2(height*.84,height)),false)
  var cosmetic:Dictionary=game.local_cosmetic() if local else member.get("cosmetic",{})
  draw_set_transform(p-Vector2(0,height*.15),0,Vector2.ONE*minf(1,height/64))
  preload("res://scripts/rolling_crowns.gd").draw_on(self,Vector2.ZERO,clock,preload("res://scripts/rolling_crowns.gd").remote_tier(cosmetic))
  draw_set_transform(Vector2.ZERO)
  draw_set_transform(p+Vector2(0,height*.20),0,Vector2.ONE*minf(.65,height/80))
  preload("res://scripts/player_cosmetics.gd").draw_on(self,Vector2.ZERO,clock,str(cosmetic.get("extra_effect","")),str(cosmetic.get("weekly_week","")))
  draw_set_transform(p+Vector2(0,height*.12),0,Vector2.ONE*minf(1,height/64))
  preload("res://scripts/ranked_cosmetic_art.gd").draw_lobby(self,Vector2.ZERO,clock,cosmetic)
  draw_set_transform(Vector2.ZERO)
  var tint:Color=Color("#f2d49c") if local else Color("#a6d7df")
  draw_string(game.font,p+Vector2(-tile.x*.46,height*.55),str(member.get("name","Player"))+(" • You" if local else ""),HORIZONTAL_ALIGNMENT_CENTER,tile.x*.92,13,tint)
  draw_string(game.font,p+Vector2(-tile.x*.46,height*.55+16),str(spec.get("name",hero)),HORIZONTAL_ALIGNMENT_CENTER,tile.x*.92,11,Color("#a0bbb9"))

func _get_tooltip(at:Vector2)->String:
 if game==null:return ""
 var members:Array=game.roster if not game.roster.is_empty() else [{"id":"preview","hero":game.selected_hero}]
 var cols=mini(4,maxi(1,members.size()));var tile=Vector2(size.x/cols,size.y/ceili(float(members.size())/cols))
 var index=int(at.y/tile.y)*cols+int(at.x/tile.x)
 if index<0 or index>=members.size():return ""
 var member:Dictionary=members[index];var local=str(member.get("id","preview")) in [game.my_id,"preview"]
 var cosmetic:Dictionary=game.local_cosmetic() if local else member.get("cosmetic",{})
 var words=PackedStringArray()
 var labels={"rank_week_damage":"Vanguard Comets • current weekly top 10 damage","rank_week_fish":"Leviathan’s Wake • current weekly top 10 heaviest fish","rank_all_damage":"Eternal Constellation • current lifetime top 5 damage"}
 for id in preload("res://scripts/ranked_cosmetic_art.gd").active(cosmetic):words.append(labels[id])
 return "\n".join(words)
