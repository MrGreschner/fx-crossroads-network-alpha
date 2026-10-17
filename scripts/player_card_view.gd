extends Control
var legacy:Node
var portrait:Texture2D
var favorite_art:Texture2D
var icon_id:=""
const METALS=["#687e87","#bb8052","#c3d3dc","#edc363","#b6eeed","#cbb2f1"]
func _ready()->void:
 custom_minimum_size=Vector2(0,545)
 var favourite:Dictionary=legacy.fishing_records.favorite()
 if not favourite.is_empty():favorite_art=preload("res://scripts/fishing_catalog.gd").texture(str(favourite.species))
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 icon_id=str(legacy.card.state().portrait)
 if not legacy.card.portrait_unlocked(icon_id):icon_id=""
 if not icon_id.is_empty():portrait=legacy.game.art.get(str(legacy.game.characters[icon_id].get("sprite",icon_id))+"_idle")
 resized.connect(queue_redraw)
func label(p:Vector2,value:String,size:int=17,tint:Color=Color("#e2e9df"))->void:draw_string(ThemeDB.fallback_font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
func star(p:Vector2,radius:float,colour:Color)->void:
 var points:=PackedVector2Array()
 for n in 10:points.append(p+Vector2.from_angle(-PI*.5+n*PI/5)*(radius if n%2==0 else radius*.45))
 draw_colored_polygon(points,colour)
func trophy(p:Vector2,tier:int,random_mode:bool)->void:
 var metal:=Color(METALS[clampi(tier,0,5)])
 draw_arc(p+Vector2(-13,-17),11,PI*.5,PI*1.5,16,metal,4);draw_arc(p+Vector2(13,-17),11,-PI*.5,PI*.5,16,metal,4)
 draw_colored_polygon(PackedVector2Array([p+Vector2(-17,-35),p+Vector2(17,-35),p+Vector2(12,-11),p+Vector2(0,-3),p+Vector2(-12,-11)]),metal)
 draw_rect(Rect2(p+Vector2(-4,-3),Vector2(8,17)),metal);draw_rect(Rect2(p+Vector2(-21,12),Vector2(42,7)),metal)
 if random_mode:label(p+Vector2(-6,-16),"?",19,Color("#293a49"))
 else:star(p+Vector2(0,-20),8,Color("#324654"))
 if tier>=4:
  for side in [-1,1]:draw_arc(p+Vector2(side*23,-9),16,-PI*.8 if side<0 else -PI*.2,PI*.8 if side<0 else PI*.2,16,metal,3)
 if tier==5:
  star(p+Vector2(-26,-38),4,metal);star(p+Vector2(27,-34),5,metal);star(p+Vector2(0,-48),6,metal)
func badge(p:Vector2,id:String)->void:
 var spec:Dictionary=legacy.card.BADGES[id];var colour:=Color(str(spec.color))
 draw_colored_polygon(PackedVector2Array([p+Vector2(-25,-20),p+Vector2(0,-29),p+Vector2(25,-20),p+Vector2(24,16),p+Vector2(0,28),p+Vector2(-24,16)]),colour.darkened(.55))
 draw_arc(p,22,0,TAU,32,colour,2)
 match str(spec.symbol):
  "rift":draw_line(p+Vector2(-5,-16),p+Vector2(6,-1),colour,4);draw_line(p+Vector2(6,-1),p+Vector2(-7,17),colour,4);star(p+Vector2(12,-13),4,colour)
  "bell":draw_colored_polygon(PackedVector2Array([p+Vector2(-14,9),p+Vector2(-9,-12),p+Vector2(9,-12),p+Vector2(14,9)]),colour);draw_circle(p+Vector2(0,14),4,colour)
  "flame":draw_colored_polygon(PackedVector2Array([p+Vector2(0,-20),p+Vector2(15,7),p+Vector2(0,17),p+Vector2(-14,8),p+Vector2(-9,-6)]),colour);draw_circle(p+Vector2(0,7),5,Color("#f4d7aa"))
  "crown":draw_colored_polygon(PackedVector2Array([p+Vector2(-16,-12),p+Vector2(-10,2),p+Vector2(0,-17),p+Vector2(10,2),p+Vector2(16,-12),p+Vector2(13,13),p+Vector2(-13,13)]),colour)
 var name:=str(spec.name);var width:=ThemeDB.fallback_font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x;label(p+Vector2(-width*.5,46),name,13)
func _draw()->void:
 if legacy==null:return
 draw_set_transform(Vector2.ZERO,0,Vector2(1,.85))
 var w:=size.x
 draw_style_box(style(),Rect2(0,0,w,625))
 draw_rect(Rect2(18,19,118,132),Color("#223e47"));draw_rect(Rect2(18,19,118,132),Color("#b4b694"),false,2)
 if portrait!=null:draw_texture_rect(portrait,Rect2(28,28,98,112),false)
 else:draw_circle(Vector2(77,68),20,Color("#819a98"));draw_rect(Rect2(50,92,54,35),Color("#819a98"));label(Vector2(34,171),"TRAVELER",15)
 if legacy.card.portrait_star(icon_id):star(Vector2(25,26),13,Color("#f5ce63"));star(Vector2(25,26),8,Color("#fff1af"))
 label(Vector2(157,43),str(legacy.data.name),27,Color("#f4db98"));label(Vector2(157,70),str(legacy.data.title),18,Color("#9ecfc6"))
 label(Vector2(157,103),"LIFETIME DAMAGE",13,Color("#afc2be"));label(Vector2(157,130),str(int(legacy.data.tasks.get("damage",0))),24)
 label(Vector2(390,103),"REALM CLEARS • V70+",13,Color("#afc2be"));label(Vector2(390,130),str(int(legacy.data.tasks.get("realm_clears",0))),24)
 label(Vector2(600,103),"HEROES FULLY MASTERED",13,Color("#afc2be"));label(Vector2(600,130),str(legacy.card.mastered())+" / "+str(legacy.game.characters.size()),24)
 var progress=legacy.fishing_records.progress;var level=progress.level();var xp=int(progress.state().xp)
 label(Vector2(157,164),"FISHING LV %d • %d XP • %d/%d FISH" % [level,xp,legacy.fishing_records.state().kept.size(),legacy.fishing_records.capacity()],16,Color("#9edbd3"))
 var ratio=1.0 if level==40 else float(xp-progress.threshold(level))/maxi(1,progress.threshold(level+1)-progress.threshold(level))
 draw_rect(Rect2(w-200,151,170,10),Color("#29434b"));draw_rect(Rect2(w-200,151,170*clampf(ratio,0,1),10),Color("#8bcbb7"))
 draw_line(Vector2(18,181),Vector2(w-18,181),Color("#476267"),1)
 for index in 2:
  var random_mode:=index==1;var rec:Dictionary=legacy.card.state().arena["random" if random_mode else "standard"];var x:=24+index*(w-48)*.5
  var tier:int=legacy.card.tier(int(rec.best_streak));trophy(Vector2(x+27,239),tier,random_mode)
  label(Vector2(x+67,203),"RANDOM HERO ARENA" if random_mode else "REGULAR ARENA",15,Color("#efdaa5"))
  label(Vector2(x+67,226),legacy.card.TROPHIES[tier]+" • best win streak "+str(rec.best_streak),16)
  label(Vector2(x+67,249),"Current "+str(rec.streak)+" • W "+str(rec.wins)+" / L "+str(rec.losses)+" / D "+str(rec.draws),15)
  label(Vector2(x+67,272),"KOs "+str(rec.kills)+" • deaths "+str(rec.deaths)+" • best KO streak "+str(rec.best_kill_streak),14)
 var ids:Array=legacy.card.badges()
 label(Vector2(24,305),"EXPERT & EXTREME REALM STICKERS",13,Color("#afc2be"))
 if ids.is_empty():label(Vector2(24,343),"Clear an Expert or Extreme realm to earn your first sticker.",16)
 else:
  for n in ids.size():badge(Vector2(83+n*155,345),str(ids[n]))
 depth_badge(Vector2(60,436))
 label(Vector2(24,492),"MINE • ORE LV %d / GEM LV %d • %dm DEEP" % [legacy.commerce.ore_level(),legacy.commerce.gem_level(),legacy.mine.depth()*30],17,Color("#e8cc90"))
 label(Vector2(24,517),"MARKET • SALES %.0f / PROFIT %.0f / %d UNITS SOLD" % [legacy.commerce.state().revenue,legacy.commerce.state().profit,legacy.commerce.state().units],16,Color("#9dcec3"))
 var favourite:Dictionary=legacy.fishing_records.favorite()
 draw_line(Vector2(24,535),Vector2(w-24,535),Color("#476267"),1)
 if not favourite.is_empty():
  var spec:Dictionary=preload("res://scripts/fishing_catalog.gd").fish()[favourite.species]
  if favorite_art!=null:draw_texture_rect(favorite_art,Rect2(22,543,136,76),false)
  label(Vector2(180,566),("TROPHY CATCH • " if preload("res://scripts/fishing_catalog.gd").is_trophy(favourite) else "FAVOURITE CATCH • ")+str(spec.name),18,Color(str(spec.color)))
  label(Vector2(180,594),"%.2f kg • %.1f cm • %s" % [favourite.kg,favourite.cm,spec.rarity],17)
 else:label(Vector2(24,580),"FAVOURITE CATCH • Choose a kept fish at Ripple & Reel.",17,Color("#9dcec3"))
func depth_badge(p:Vector2)->void:
 var floor:int=int(legacy.card.state().descent_best);var tier:int=legacy.card.descent_tier();var metal:=Color(METALS[tier])
 draw_colored_polygon(PackedVector2Array([p+Vector2(-28,-22),p+Vector2(28,-22),p+Vector2(34,8),p+Vector2(0,32),p+Vector2(-34,8)]),metal.darkened(.55))
 for n in range(tier+1):draw_line(p+Vector2(-22+n*6,2),p+Vector2(-18+n*6,18),metal,3)
 draw_arc(p,27,PI,TAU,24,metal,3);star(p+Vector2(0,-8),10,metal)
 if tier>=4:
  for n in [-1,1]:star(p+Vector2(n*38,-18),7,metal)
 label(p+Vector2(55,-8),"RAM’S DESCENT • FLOOR "+str(floor)+" CLEARED",18,metal)
 label(p+Vector2(55,16),["First descent","Cavern Bronze","Depth Silver","Deep Gold","Sovereign Crystal","Abyss Crown"][tier],14)
func style()->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=Color("#10262e");s.border_color=Color("#b9a574");s.set_border_width_all(2);s.set_corner_radius_all(10);return s
