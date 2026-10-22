extends Control
## A species-relative weight dial. Rarity is independent of body size.
const FISH=preload("res://scripts/fishing_catalog.gd")
var compact:=false
var species=""
var kg=0.0
static func rarity_color(grade:String)->Color:
 return {"Common":Color("#d0e4e8"),"Uncommon":Color("#89dbac"),"Rare":Color("#86c8ff"),"Very rare":Color("#c3a1ff"),"Legendary":Color("#ffd17e"),"Fabled":Color("#f4d28a"),"Mystical":Color("#ffa6e5")}.get(grade,Color.WHITE)
static func fraction(id:String,weight:float)->float:
 return clampf(weight/maxf(.001,float(FISH.fish().get(id,{}).get("max_kg",1))*4),0,1)
func _ready()->void:
 custom_minimum_size=Vector2(246,72) if compact else Vector2(300,125);mouse_filter=Control.MOUSE_FILTER_IGNORE
 tooltip_text="Needle: catch weight. Teal tick: ordinary species average. Gold tick: trophy threshold (250% of average). Full scale: maximum possible weight for this species. Size does not change its rarity."
 resized.connect(queue_redraw)
func point(center:Vector2,radius:float,value:float)->Vector2:
 var angle=PI+PI*clampf(value,0,1)
 return center+Vector2(cos(angle),sin(angle))*radius
func _draw()->void:
 if not FISH.fish().has(species):return
 if compact:
  draw_compact();return
 var font=ThemeDB.fallback_font;var center=Vector2(size.x*.5,77);var radius=64.0
 draw_arc(center,radius,PI,TAU,64,Color("#314f5d"),10,true)
 var amount=fraction(species,kg)
 if amount>0:draw_arc(center,radius,PI,PI+amount*PI,64,Color("#69d6d0"),7,true)
 for n in 11:
  var value=n/10.0
  draw_line(point(center,radius-9,value),point(center,radius+6,value),Color("#8daab8"),1.5,true)
 var average=FISH.mean_kg(species);var trophy=FISH.trophy_threshold_kg(species)
 for marker in [[average,Color("#69d6d0")],[trophy,Color("#ffd17e")]]:
  var value=fraction(species,float(marker[0]));draw_line(point(center,radius-13,value),point(center,radius+9,value),marker[1],3,true)
 draw_line(center,point(center,radius-15,amount),Color("#fff1cd"),3,true);draw_circle(center,5,Color("#fff1cd"))
 draw_string(font,Vector2(center.x-96,83),"0",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b5cbd3"))
 draw_string(font,Vector2(center.x+75,83),"%.1f kg" % (float(FISH.fish()[species].max_kg)*4),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b5cbd3"))
 var text="%.0f%% of species average" % (kg/maxf(.001,average)*100)
 draw_string(font,Vector2((size.x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x)*.5,105),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e4eef1"))
 var legend="Average %.2f kg  •  Trophy %.2f+ kg" % [average,trophy]
 draw_string(font,Vector2((size.x-font.get_string_size(legend,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)*.5,123),legend,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b5cbd3"))

func draw_compact()->void:
 var font=ThemeDB.fallback_font;var width:=maxf(100,size.x-20);var average=FISH.mean_kg(species)
 draw_string(font,Vector2(10,16),"%.0f%% of species average" % (kg/maxf(.001,average)*100),HORIZONTAL_ALIGNMENT_LEFT,width,13,Color("#e4eef1"))
 draw_style_box(preload("res://scripts/studio_ui.gd").box("#314f5d","#314f5d",4,0),Rect2(10,25,width,9))
 draw_rect(Rect2(10,25,width*fraction(species,kg),9),Color("#69d6d0"))
 for marker in [[average,Color("#69d6d0")],[FISH.trophy_threshold_kg(species),Color("#ffd17e")]]:
  var x:=10+width*fraction(species,float(marker[0]));draw_line(Vector2(x,22),Vector2(x,38),marker[1],2,true)
 var x:=10+width*fraction(species,kg);draw_circle(Vector2(x,29),4,Color("#fff1cd"))
 draw_string(font,Vector2(10,54),"Avg %.2f • Trophy %.2f+ kg" % [average,FISH.trophy_threshold_kg(species)],HORIZONTAL_ALIGNMENT_LEFT,width,12,Color("#b5cbd3"))
 draw_string(font,Vector2(10,69),"0 — %.2f kg" % (float(FISH.fish()[species].max_kg)*4),HORIZONTAL_ALIGNMENT_LEFT,width,11,Color("#8daab8"))
