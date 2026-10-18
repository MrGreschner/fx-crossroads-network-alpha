extends CanvasLayer
var frame:Control
var elapsed:=0.0
const DURATION=5.6
var display_font:Font=preload("res://assets/fonts/CrossroadsDisplay.ttf")
var ui_font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var art:Dictionary={}
func _ready()->void:
 name="FXIntro"
 art=get_parent().art
 layer=100
 frame=Control.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(frame)
 frame.draw.connect(paint)
 set_process_input(true)
func _input(_event:InputEvent)->void:
 get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 elapsed+=delta;frame.queue_redraw()
 if elapsed>=DURATION:queue_free()
func paint()->void:
 var size:Vector2=get_viewport().get_visible_rect().size
 var center:Vector2=size*.5
 var alpha:float=1.0-smoothstep(4.9,DURATION,elapsed)

 var journey=clampf(elapsed/DURATION,0,1)
 var is_night=get_parent().town_life.calendar.night_amount()>.5
 var orbit=Vector2(center.x+cos(PI-journey*PI)*minf(size.x*.35,390),center.y-100-sin(journey*PI)*minf(size.y*.3,180))
 var altitude=sin(journey*PI)
 paint_sky(size,alpha,altitude,is_night)
 # Broad screen illumination follows height, with warm horizons and a cool night.
 for n in range(14,0,-1):
  var radius=minf(size.x,size.y)*(.15+n*.075)
  frame.draw_circle(orbit,radius,Color(.62,.78,1,alpha*altitude*.004) if is_night else Color(1,.81,.43,alpha*altitude*.013))
 var celestial=Color(.72,.85,1,alpha) if is_night else Color(1,.79,.40,alpha)
 for n in range(10,0,-1):frame.draw_circle(orbit,19+n*9,Color(celestial,(.012+.02*altitude)*alpha))
 frame.draw_circle(orbit,19,celestial)
 if is_night:frame.draw_circle(orbit+Vector2(8,-5),17,Color(.025,.07,.09,alpha))
 else:
  for n in 10:
   var dir=Vector2.from_angle(n*TAU/10+elapsed*.08);frame.draw_line(orbit+dir*24,orbit+dir*31,Color(celestial,alpha*.5),2,true)
 paint_landscape(size,alpha,altitude,is_night)
 var gold:=Color(.84,.72,.44,alpha)
 var blue:=Color(.35,.75,.78,alpha)
 var reveal:float=smoothstep(0,.45,elapsed)
 var title_size:int=clampi(int(size.x/15),28,88)
 var font:Font=display_font
 var text:="CROSSROADS"
 var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
 frame.draw_string(font,center+Vector2(-width/2,12+(1-reveal)*12)+Vector2((center.x-orbit.x)*.025,7),text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color(0,0,0,alpha*.5))
 frame.draw_string(font,center+Vector2(-width/2,12+(1-reveal)*12),text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color(.96,.89,.72,alpha*reveal))
 for side in [-1,1]:
  frame.draw_line(center+Vector2(side*20,65),center+Vector2(side*width*.45,65),gold,2,true)
 frame.draw_arc(center+Vector2(0,-85),28,-PI*.75,PI*.75,32,blue,2,true)
 for side in [-1,1]:frame.draw_line(center+Vector2(side*32,-85),center+Vector2(side*54,-85),gold,2,true)
 frame.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-110),center+Vector2(12,-85),center+Vector2(0,-60),center+Vector2(-12,-85)]),gold)
 var subtitle:="REALMS BEYOND"
 var subtitle_width:float=ui_font.get_string_size(subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
 frame.draw_string(ui_font,center+Vector2(-subtitle_width/2,48),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color(.9,.77,.5,alpha*reveal))
 var sub:="FIND YOUR PATH. CREATE WHAT’S NEXT."
 var sw:float=ui_font.get_string_size(sub,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
 frame.draw_string(ui_font,center+Vector2(-sw/2,91),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.63,.78,.77,alpha*reveal))

 # A short hero/enemy encounter uses already-loaded walk art, not new particle nodes.
 var lane_y:float=center.y+minf(175,size.y*.32)
 var approach:float=smoothstep(.35,1.65,elapsed)
 var depart:float=smoothstep(2.45,3.7,elapsed)
 var ram_pos:=Vector2(lerpf(center.x-200,center.x-44,approach)+depart*170,lane_y)
 var foe_pos:=Vector2(lerpf(center.x+200,center.x+30,approach)+depart*250,lane_y)
 var striking:bool=elapsed>=1.65 and elapsed<2.25
 var pose:String="attack" if striking else "walk1" if int(elapsed*7)%2==0 else "walk2"
 var ram:Texture2D=art.get("ram_"+pose,art.get("ram_idle"))
 var foe:Texture2D=art.get("bramble_"+("0" if int(elapsed*5)%2==0 else "1"),art.get("bramble"))
 var platform=PackedVector2Array([Vector2(center.x-265,lane_y+6),Vector2(center.x-230,lane_y-8),Vector2(center.x+230,lane_y-8),Vector2(center.x+265,lane_y+6),Vector2(center.x+243,lane_y+24),Vector2(center.x-243,lane_y+24)])
 frame.draw_colored_polygon(platform,Color(.18,.31,.33,alpha));frame.draw_polyline(platform,Color(.46,.60,.57,alpha*.5),1.5,true)
 frame.draw_line(Vector2(center.x-230,lane_y+6),Vector2(center.x+230,lane_y+6),Color(.55,.69,.63,alpha*.3),1,true)
 frame.draw_circle(ram_pos+Vector2(0,5),18,Color(0,0,0,alpha*.3))
 if ram!=null:frame.draw_texture_rect(ram,Rect2(ram_pos-Vector2(30,62),Vector2(60,72)),false,Color(1,1,1,alpha))
 var wobble:float=sin((elapsed-1.65)*17)*5 if striking else 0
 if foe!=null:frame.draw_texture_rect(foe,Rect2(foe_pos-Vector2(30,60)+Vector2(wobble,0),Vector2(60,68)),false,Color(1,1,1,alpha))
 if striking:
  for n in 5:
   var angle:float=n*TAU/5+elapsed
   var spark:Vector2=foe_pos+Vector2(-14,-24)+Vector2.from_angle(angle)*12
   frame.draw_line(spark,spark+Vector2.from_angle(angle)*7,Color(1,.8,.36,alpha*(1-smoothstep(1.8,2.25,elapsed))),2,true)

 var water_y=size.y-28
 frame.draw_line(Vector2(center.x-130,water_y),Vector2(center.x+130,water_y),Color(.37,.74,.78,alpha*.5),2,true)
 var swim=fposmod(elapsed*.34,1);var fish_pos=Vector2(center.x-100+swim*200,water_y-8-sin(swim*PI)*35)
 var fish=preload("res://scripts/fishing_catalog.gd").texture("reedlight_minnow" if is_night else "sunspot_koi")
 if fish!=null:frame.draw_texture_rect(fish,Rect2(fish_pos-Vector2(31,18),Vector2(62,36)),false,Color(1,1,1,alpha))
 for n in 3:frame.draw_arc(Vector2(center.x-70+n*65,water_y),8+fposmod(elapsed*8+n*4,16),0,PI,16,Color(.55,.85,.88,alpha*.25),1,true)
 var caption="A LIVING TOWN • WATERS TO DISCOVER"
 var caption_width=ui_font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
 frame.draw_string(ui_font,Vector2(center.x-caption_width*.5,water_y-53),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(.7,.85,.83,alpha))

func paint_sky(size:Vector2,alpha:float,altitude:float,night:bool)->void:
 var high=Color("#0d293b").lerp(Color("#628889"),altitude*(.13 if night else .55))
 var low=Color("#1c4259").lerp(Color("#c7bd99"),altitude*(.10 if night else .8))
 for n in 26:
  var u=float(n)/25;var colour=high.lerp(low,u)
  frame.draw_rect(Rect2(0,size.y*n/26,size.x,size.y/26+1),Color(colour,alpha))
 for n in 36:
  var p=Vector2(fposmod(n*149.0+45,size.x),fposmod(n*67.0+25,size.y*.31))
  frame.draw_circle(p,.8+(n%3)*.25,Color(.8,.9,.85,alpha*(.13 if not night else .55)*(1-altitude*.65)))
func paint_landscape(size:Vector2,alpha:float,altitude:float,night:bool)->void:
 for layer in 3:
  var points=PackedVector2Array([Vector2(0,size.y)])
  for n in 31:
   var x=size.x*n/30;var y=size.y*(.59+layer*.07)+sin(n*.73+layer*2)*size.y*.035+sin(n*1.7)*size.y*(.025 if layer==0 else .012)
   points.append(Vector2(x,y))
  points.append(size)
  var colour=Color("#294c54").lerp(Color("#14353f"),float(layer)/2)
  frame.draw_colored_polygon(points,Color(colour,alpha*(.65 if layer==0 else 1)))
 var water_y=size.y-95
 for n in 14:
  var u=float(n)/13;var colour=Color("#397d82").lerp(Color("#0a2e40"),u)
  if night:colour=colour.darkened(.3)
  frame.draw_rect(Rect2(0,water_y+n*95.0/14,size.x,95.0/14+1),Color(colour,alpha))
 for n in 5:
  var spread=125-n*20
  frame.draw_line(Vector2(size.x*.5-spread,water_y+18+n*10),Vector2(size.x*.5+spread,water_y+18+n*10),Color(.77,.86,.72,alpha*(.13+altitude*.16)),1,true)
 for side in [-1,1]:
  for n in 3:
   var p=Vector2(size.x*.5+side*(size.x*.36+n*37),size.y*.79);var h=60+n*13
   frame.draw_line(p,p-Vector2(0,h),Color(.07,.21,.24,alpha),5,true)
   frame.draw_colored_polygon(PackedVector2Array([p+Vector2(-22,-h*.30),p-Vector2(0,h+20),p+Vector2(22,-h*.30)]),Color(.07,.21,.24,alpha))
 # Soft, bounded firefly accents add depth without particle nodes or shaders.
 for n in 10:
  var p=Vector2(size.x*.5+sin(n*1.71)*size.x*.42,size.y*.69+sin(elapsed*.8+n)*16+n%3*18)
  frame.draw_circle(p,1+(n%2)*.35,Color(.85,.89,.66,alpha*(.2+.15*sin(elapsed+n))))
