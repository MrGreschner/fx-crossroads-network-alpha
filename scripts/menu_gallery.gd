extends Control
## Opaque, lightweight title-page gallery. Art is cached once, never loaded per frame.
var game:Node
const SET_SECONDS=7.0
var clock:=0.0
var redraw_tick:=0.0
var heroes:Array=[]
var creatures:Array=[]
var display:Font=preload("res://assets/fonts/CrossroadsDisplay.ttf")
var ui:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func setup(owner:Node,multi:bool=false)->void:
 game=owner;mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 for id in ["ram","book","cat","ferryman","sunflower","robot","pippa","stormscribe","snail","monk","teacher","basketball","patch","beaver","ripplejaw","dustdevil","harbor","mosaic","bracken","gopher","cindervane","dustmarshal","teapot","cloudloom"]:
  if game.characters.has(id):heroes.append(entry(game.characters[id],str(id),true))
 # Fill from the full roster if a curated id is absent in a future expansion.
 for id in game.characters:
  if heroes.size()>=24:break
  if not heroes.any(func(e):return e.id==id):heroes.append(entry(game.characters[id],str(id),true))
 var enemies:Dictionary=game.enemy_defs if multi else game.enemy_types
 var curated:Array=["bramble","imp","lantern_moth","archer","warlock","rusher","frostling","ice_archer","snow_oracle","glacier_hound","spore_thrower","hazmat_raider","honey_beetle","glass_queen","cascade_heron","ripple_eel","lantern_crab","reed_stalker","mask_duelist","mirror_marquis","rift_weaver","comet_urchin","gongbreaker","silence_regent"]
 for id in enemies:
  if id not in curated:curated.append(id)
 for id in curated:
  if creatures.size()>=24:break
  if not enemies.has(id):continue
  if str(id).begins_with("training"):continue
  var e:Dictionary=entry(enemies[id],str(id),false)
  if e.first!=null:creatures.append(e)
func entry(data:Dictionary,id:String,hero:bool)->Dictionary:
 var sprite:=str(data.get("sprite",id));var first:Texture2D=game.art.get(sprite+"_walk1",game.art.get(sprite+"_0",game.art.get(sprite+"_idle")))
 var second:Texture2D=game.art.get(sprite+"_walk2",game.art.get(sprite+"_1",first))
 if not hero and id=="bramble":
  first=preload("res://scripts/minion_art215.gd").frame("bramble",1);second=preload("res://scripts/minion_art215.gd").frame("bramble",2)
 var caption_name:String=str(data.get("name",id.capitalize()))
 var lines:Array[String]=[];var line:=""
 for word in caption_name.split(" "):
  var candidate:String=(line+" "+word).strip_edges()
  if not line.is_empty() and ui.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x>124:lines.append(line);line=word
  else:line=candidate
 if not line.is_empty():lines.append(line)
 if lines.size()>2:lines=[lines[0],lines[1]+"…"]
 return {"caption_lines":lines,"caption":caption_name,"id":id,"name":str(data.get("name",id.capitalize())),"first":first,"second":second,"hero":hero}
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;redraw_tick+=delta
 if redraw_tick>=1.0/30.0:redraw_tick=0;queue_redraw()
func caption(p:Vector2,value:String,fs:int,width:float,col:Color)->void:
 draw_string(ui,p,value,HORIZONTAL_ALIGNMENT_CENTER,width,fs,col)
func _draw()->void:
 var view:=get_viewport_rect().size;var factor:=minf(view.x/1280,view.y/720);var offset:Vector2=(view-Vector2(1280,720)*factor)*.5
 draw_rect(Rect2(Vector2.ZERO,view),Color("#081b27"))
 draw_set_transform(offset,0,Vector2.ONE*factor)
 var backdrop:Texture2D=preload("res://scripts/title_art215.gd").background()
 if backdrop!=null:draw_texture_rect(backdrop,Rect2(0,0,1280,720),false,Color(1,1,1,.67))
 draw_rect(Rect2(370,95,540,540),Color(.025,.07,.1,.36))
 # Architectural lines, distant portal arcs, and slow drifting fireflies.
 for side in [-1,1]:
  var center:=Vector2(640+side*470,335)
  draw_circle(center,250,Color(.06,.17,.22,.38));draw_arc(center,246,.15,TAU-.15,72,Color("#284452"),2,true)
  draw_arc(center,213,clock*.035,clock*.035+PI*1.45,56,Color("#365659"),1,true)
 for n in 32:
  var p:=Vector2(fposmod(n*173+sin(clock*.12+n)*18,1260)+10,35+fposmod(n*97-clock*(3+n%3),660))
  draw_circle(p,1.2+float(n%2),Color(.7,.82,.65,.18+.12*sin(clock+n)))
 draw_rect(Rect2(18,18,1244,684),Color("#748575"),false,1)
 draw_rect(Rect2(25,25,1230,670),Color("#c0a572"),false,1)
 for x in [25,1255]:
  for y in [25,695]:
   draw_colored_polygon(PackedVector2Array([Vector2(x,y-8),Vector2(x+8,y),Vector2(x,y+8),Vector2(x-8,y)]),Color("#d2b57b"))
 caption(Vector2(55,105),"MEET YOUR HEROES",16,275,Color("#e0c38b"))
 caption(Vector2(950,105),"EXPLORE THEIR WORLDS",16,275,Color("#e0c38b"))
 for side in 2:
  var roster:Array=heroes if side==0 else creatures
  var cycle:int=int(clock/SET_SECONDS)%maxi(1,int(ceil(roster.size()/6.0)))
  for index in 6:
   if roster.is_empty():continue
   var e:Dictionary=roster[(cycle*6+index)%roster.size()]
   var p:=Vector2(52 if side==0 else 952,135)+Vector2((index%2)*145,int(index/2)*162)
   var card:=Rect2(p,Vector2(132,145))
   draw_style_box(card_skin(side),card)
   draw_line(p+Vector2(16,117),p+Vector2(116,117),Color("#536b68"),1,true)
   draw_circle(p+Vector2(66,102),25,Color(0,0,0,.23))
   var art:Texture2D=e.first if int(clock*4+index)%2==0 else e.second
   if art!=null:draw_texture_rect(art,Rect2(p+Vector2(28,20+sin(clock*2+index)*2),Vector2(76,84)),false)
   for n in e.caption_lines.size():caption(p+Vector2(4,128+n*12 if e.caption_lines.size()>1 else 135),str(e.caption_lines[n]),11,124,Color("#e1e5d5"))
 caption(Vector2(52,664),"Every hero starts unlocked",13,277,Color("#a1b9b9"))
 caption(Vector2(950,664),"Realms • Parties • Battlegrounds",12,277,Color("#a1b9b9"))
 # Ornament around the central menu, outside its interactive region.
 for x in [360,920]:
  draw_line(Vector2(x,100),Vector2(x,620),Color("#bca06c"),2,true)
  for y in [92,628]:draw_colored_polygon(PackedVector2Array([Vector2(x,y-9),Vector2(x+7,y),Vector2(x,y+9),Vector2(x-7,y)]),Color("#d9bc80"))
 draw_set_transform(Vector2.ZERO)
var skins:Dictionary={}
func card_skin(side:int)->StyleBoxFlat:
 if not skins.has(side):
  var s:=StyleBoxFlat.new();s.bg_color=Color("#18353d") if side==0 else Color("#263239");s.border_color=Color("#506d6c");s.set_border_width_all(1);s.set_corner_radius_all(10);skins[side]=s
 return skins[side]
