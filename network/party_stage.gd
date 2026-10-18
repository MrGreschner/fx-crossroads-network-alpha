extends Control
## World sprites in visible team lineups; no separate illustration assets.
const R=preload("res://network/party_rules.gd")
var game:Node
var clock:float=0
var cards:Array[Dictionary]=[]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_PASS;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta:float)->void:
 if not is_visible_in_tree() or game==null:return
 var count=R.preview(game).size()
 custom_minimum_size.y=(210 if count>2 else 155) if game.mode=="defense" else (210 if count>4 else 155) if R.teamed(game) else (175 if count>4 else 112)
 clock+=delta;queue_redraw()
func _draw()->void:
 if game==null:return
 cards.clear()
 draw_rect(Rect2(Vector2.ZERO,size),Color("#102732"))
 var members=R.preview(game)
 if R.teamed(game):
  for side in 2:
   var area=Rect2(Vector2(side*size.x/2,0),Vector2(size.x/2,size.y))
   var tint=R.colour(side)
   draw_rect(area,Color(tint,.08));draw_rect(area,tint,false,1)
   var own=game.local_lobby_team==side
   draw_string(game.font,area.position+Vector2(10,20),R.side_name(side)+(" • YOU" if own else " • click to join"),HORIZONTAL_ALIGNMENT_LEFT,area.size.x-20,14,tint)
   var team=members.filter(func(m):return int(m.get("team",0))==side)
   lineup(team,Rect2(area.position+Vector2(0,27),area.size-Vector2(0,27)))
 elif game.mode=="defense":
  for side in 2:
   var area=Rect2(Vector2(side*size.x/2,0),Vector2(size.x/2,size.y))
   draw_rect(area,R.colour(side),false,1)
   draw_string(game.font,area.position+Vector2(10,20),"DEFENDERS" if side==0 else "ENEMY RIVALS • WAVE 3",HORIZONTAL_ALIGNMENT_LEFT,area.size.x-20,13,R.colour(side))
   var entries=members
   if side==1:
    entries=[]
    for n in mini(4,members.size()):entries.append({"id":"rival:"+str(n),"hero":B_IDS()[n],"name":["Sable Voss","Brass Bastion","Cinder Oracle","Iona Stormglass"][n]})
   lineup(entries,Rect2(area.position+Vector2(0,27),area.size-Vector2(0,27)))
 else:lineup(members,Rect2(Vector2.ZERO,size))
static func B_IDS()->Array:return ["npc_sable","npc_bastion","npc_cinder","npc_iona"]
func lineup(members:Array,area:Rect2)->void:
 if members.is_empty():
  draw_string(game.font,area.position+Vector2(0,area.size.y*.6),"Open seats • invite players or add AI",HORIZONTAL_ALIGNMENT_CENTER,area.size.x,12,Color("#a0bbb9"));return
 var cols=mini(4,maxi(1,members.size()))
 if area.size.x<size.x*.75:cols=mini(2,maxi(1,members.size()))
 var rows=ceili(float(members.size())/cols);var tile=Vector2(area.size.x/cols,area.size.y/rows)
 for i in members.size():
  var member:Dictionary=members[i];var id=str(member.get("id","preview"));var local=id in [game.my_id,"preview"]
  var hero=game.selected_hero if local else str(member.get("hero","ram"));var spec:Dictionary=game.characters.get(hero,{})
  var sprite=str(spec.get("sprite",hero));var texture:Texture2D=game.art.get(sprite+"_idle",game.art.get(sprite+"_0"))
  var rect=Rect2(area.position+Vector2(i%cols,int(i/cols))*tile,tile);var p=rect.position+Vector2(tile.x*.5,tile.y*.43)
  var height=minf(60,tile.y-34)
  draw_circle(p+Vector2(0,height*.32),14,Color(0,0,0,.28))
  if texture!=null:draw_texture_rect(texture,Rect2(p-Vector2(height*.42,height*.65),Vector2(height*.84,height)),false)
  var cosmetic:Dictionary=game.local_cosmetic() if local else member.get("cosmetic",{})
  draw_set_transform(p-Vector2(0,height*.15),0,Vector2.ONE*minf(1,height/64))
  preload("res://scripts/rolling_crowns.gd").draw_on(self,Vector2.ZERO,clock,preload("res://scripts/rolling_crowns.gd").remote_tier(cosmetic))
  draw_set_transform(p+Vector2(0,height*.20),0,Vector2.ONE*minf(.65,height/80))
  preload("res://scripts/player_cosmetics.gd").draw_on(self,Vector2.ZERO,clock,str(cosmetic.get("extra_effect","")),str(cosmetic.get("weekly_week","")))
  draw_set_transform(p+Vector2(0,height*.12),0,Vector2.ONE*minf(1,height/64))
  preload("res://scripts/ranked_cosmetic_art.gd").draw_lobby(self,Vector2.ZERO,clock,cosmetic)
  draw_set_transform(Vector2.ZERO)
  var tint=Color("#f2d49c") if local else Color("#a6d7df")
  var text_pos=rect.position+Vector2(3,tile.y-17)
  draw_string(game.font,text_pos,str(member.get("name","Player"))+(" • You" if local else ""),HORIZONTAL_ALIGNMENT_CENTER,tile.x-6,11,tint)
  draw_string(game.font,text_pos+Vector2(0,14),str(spec.get("name",hero)),HORIZONTAL_ALIGNMENT_CENTER,tile.x-6,10,Color("#a0bbb9"))
  cards.append({"rect":rect,"member":member,"cosmetic":cosmetic})
func _gui_input(event:InputEvent)->void:
 if game==null or not R.teamed(game):return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  game.choose_lobby_team(0 if event.position.x<size.x/2 else 1);accept_event()
func _get_tooltip(at:Vector2)->String:
 for card in cards:
  if not card.rect.has_point(at):continue
  var words=PackedStringArray([str(card.member.get("name","Player"))])
  var labels={"rank_week_damage":"Vanguard Comets • current weekly top 10 damage","rank_week_fish":"Leviathan’s Wake • current weekly top 10 heaviest fish","rank_all_damage":"Eternal Constellation • current lifetime top 5 damage"}
  for id in preload("res://scripts/ranked_cosmetic_art.gd").active(card.cosmetic):words.append(labels[id])
  return "\n".join(words)
 return ""
