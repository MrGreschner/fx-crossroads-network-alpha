extends CanvasLayer
var frame:Control
var elapsed:=0.0
const DURATION=3.8
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
 var alpha:float=1.0-smoothstep(3.15,DURATION,elapsed)
 frame.draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.07,.09,alpha))
 var gold:=Color(.84,.72,.44,alpha)
 var blue:=Color(.35,.75,.78,alpha)
 var reveal:float=smoothstep(0,.45,elapsed)
 var title_size:int=clampi(int(size.x/17),28,72)
 var font:Font=display_font
 var text:="FX CROSSROADS"
 var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
 frame.draw_string(font,center+Vector2(-width/2,12+(1-reveal)*12),text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color(.96,.89,.72,alpha*reveal))
 for side in [-1,1]:
  frame.draw_line(center+Vector2(side*20,55),center+Vector2(side*width*.45,55),gold,2,true)
 frame.draw_arc(center+Vector2(0,-85),28,-PI*.75,PI*.75,32,blue,2,true)
 for side in [-1,1]:frame.draw_line(center+Vector2(side*32,-85),center+Vector2(side*54,-85),gold,2,true)
 frame.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-110),center+Vector2(12,-85),center+Vector2(0,-60),center+Vector2(-12,-85)]),gold)
 var sub:="EVERY PATH BEGINS HERE"
 var sw:float=ui_font.get_string_size(sub,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
 frame.draw_string(ui_font,center+Vector2(-sw/2,91),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.63,.78,.77,alpha*reveal))

 # A short hero/enemy encounter uses already-loaded walk art, not new particle nodes.
 var lane_y:float=center.y+minf(150,size.y*.32)
 var approach:float=smoothstep(.35,1.65,elapsed)
 var depart:float=smoothstep(2.45,3.7,elapsed)
 var ram_pos:=Vector2(lerpf(center.x-200,center.x-44,approach)+depart*170,lane_y)
 var foe_pos:=Vector2(lerpf(center.x+200,center.x+30,approach)+depart*250,lane_y)
 var striking:bool=elapsed>=1.65 and elapsed<2.25
 var pose:String="attack" if striking else "walk1" if int(elapsed*7)%2==0 else "walk2"
 var ram:Texture2D=art.get("ram_"+pose,art.get("ram_idle"))
 var foe:Texture2D=art.get("bramble_"+("0" if int(elapsed*5)%2==0 else "1"),art.get("bramble"))
 frame.draw_line(Vector2(center.x-235,lane_y+8),Vector2(center.x+235,lane_y+8),Color(.4,.6,.61,alpha*.3),2,true)
 frame.draw_circle(ram_pos+Vector2(0,5),18,Color(0,0,0,alpha*.3))
 if ram!=null:frame.draw_texture_rect(ram,Rect2(ram_pos-Vector2(30,62),Vector2(60,72)),false,Color(1,1,1,alpha))
 var wobble:float=sin((elapsed-1.65)*17)*5 if striking else 0
 if foe!=null:frame.draw_texture_rect(foe,Rect2(foe_pos-Vector2(30,60)+Vector2(wobble,0),Vector2(60,68)),false,Color(1,1,1,alpha))
 if striking:
  for n in 5:
   var angle:float=n*TAU/5+elapsed
   var spark:Vector2=foe_pos+Vector2(-14,-24)+Vector2.from_angle(angle)*12
   frame.draw_line(spark,spark+Vector2.from_angle(angle)*7,Color(1,.8,.36,alpha*(1-smoothstep(1.8,2.25,elapsed))),2,true)
