extends CanvasLayer
## One short river-path encounter; sprites and scenery are cached once.
var frame:Control
var elapsed:=0.0
const DURATION=7.2
var display_font:Font=preload("res://assets/fonts/CrossroadsDisplay.ttf")
var ui_font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var art:Dictionary={}
var scene:Texture2D
var gate:Texture2D
var night:=false
var jumping_fish:Texture2D
var fish_region:Rect2
var energy:TextureRect
var energy_material:ShaderMaterial
func image_file(path:String)->Texture2D:
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
 return ImageTexture.create_from_image(image)
func _ready()->void:
 name="FXIntro";art=get_parent().art;layer=100
 scene=image_file("res://assets/cinematic220/scene.png");gate=image_file("res://assets/cinematic220/portal.png")
 night=get_parent().town_life.calendar.night_amount()>.5
 jumping_fish=preload("res://scripts/fishing_catalog.gd").texture("reedlight_minnow" if night else "sunspot_koi")
 if jumping_fish!=null:fish_region=Rect2(jumping_fish.get_image().get_used_rect())
 frame=Control.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(frame);frame.draw.connect(paint);set_process_input(true)
 energy=TextureRect.new();energy.mouse_filter=Control.MOUSE_FILTER_IGNORE;energy.texture=image_file("res://assets/cinematic220/portal_window.png");energy.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;frame.add_child(energy)
 var shader=Shader.new();shader.code="shader_type canvas_item; uniform float strength=0.0; uniform float scene_time=0.0; void fragment(){vec2 p=UV-vec2(.5,.48);float r=length(p*vec2(1.0,.7));float w=.5+.5*sin(atan(p.y,p.x)*2.0-r*23.0+scene_time*1.6);vec3 c=mix(vec3(.04,.15,.32),vec3(.23,.75,.68),w*.65+.2);COLOR=vec4(c,texture(TEXTURE,UV).a*strength);}"
 energy_material=ShaderMaterial.new();energy_material.shader=shader;energy.material=energy_material
func _input(_event:InputEvent)->void:get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 elapsed+=delta;frame.queue_redraw()
 if elapsed>=DURATION:queue_free()
func actor(tex:Texture2D,p:Vector2,size:Vector2,opacity:float=1)->void:
 if tex==null:return
 frame.draw_circle(p+Vector2(0,1),size.x*.17,Color(0,0,0,.18*opacity))
 frame.draw_texture_rect(tex,Rect2(p-size*Vector2(.5,.925),size),false,Color(1,1,1,opacity))
func paint()->void:
 var size:Vector2=get_viewport().get_visible_rect().size
 frame.modulate=Color(1,1,1,1-smoothstep(6.65,DURATION,elapsed))
 frame.draw_rect(Rect2(Vector2.ZERO,size),Color("#101f28"))
 var scale=minf(size.x/1280,size.y/720);frame.draw_set_transform((size-Vector2(1280,720)*scale)*.5,0,Vector2.ONE*scale)
 if scene!=null:frame.draw_texture_rect(scene,Rect2(0,0,1280,720),false,Color(.51,.65,.82) if night else Color.WHITE)
 var t=elapsed;var approach=smoothstep(.7,2.2,t);var leave=smoothstep(3.4,5.8,t);var strike=t>=2.25 and t<2.8
 var portal_on=smoothstep(3.1,4.0,t)
 energy.position=(size-Vector2(1280,720)*scale)*.5+Vector2(864,235)*scale;energy.size=Vector2(192,245)*scale;energy_material.set_shader_parameter("strength",portal_on);energy_material.set_shader_parameter("scene_time",t)
 if gate!=null:frame.draw_texture_rect(gate,Rect2(864,235,192,245),false)
 var core=preload("res://scripts/core_hero_art.gd")
 actor(core.texture("elder_ram","talk" if t<1.4 or t>3.1 else "idle"),Vector2(375,480),Vector2(154,178))
 var ram_p=Vector2(lerpf(510,650,approach)+leave*310,480)
 var ram_pose="attack" if strike else "walk1" if int(t*7)%2==0 else "walk2"
 actor(core.texture("ram",ram_pose),ram_p,Vector2(136,156),1-smoothstep(5.55,6.1,t))
 var escape=smoothstep(2.9,4.25,t)
 var foe_p=Vector2(lerpf(lerpf(900,752,approach),960,escape),480)
 if strike:foe_p.x+=sin(t*27)*5
 var foe_pose="attack" if strike else "walk1" if int(t*6)%2==0 else "walk2"
 actor(art.get("bramble_"+foe_pose,art.get("bramble_idle")),foe_p,Vector2(136,136),1-smoothstep(4.02,4.4,t))
 if strike:
  for n in 5:
   var angle=n*TAU/5+t;var p=Vector2(711,416)+Vector2.from_angle(angle)*17
   frame.draw_line(p,p+Vector2.from_angle(angle)*9,Color(1,.86,.5,1-smoothstep(2.4,2.8,t)),2,true)
 if gate!=null:frame.draw_texture_rect(gate,Rect2(864,235,192,245),false)
 var cat_p=Vector2(448+smoothstep(4.0,6.1,t)*210,505)
 actor(core.texture("cat","walk1" if int(t*6)%2==0 else "walk2"),cat_p,Vector2(90,104))
 var jump_time=t-1.0 if t<4.5 else t-4.8
 var swim=clampf(jump_time/1.7,0,1)
 var fish_p=Vector2(540+swim*190,656-sin(swim*PI)*88)
 var fish=jumping_fish
 if fish!=null and jump_time>=0 and jump_time<1.7:
  frame.draw_set_transform((size-Vector2(1280,720)*scale)*.5+fish_p*scale,(swim-.5)*1.1,Vector2.ONE*scale)
  frame.draw_texture_rect_region(fish,Rect2(-60,-26,120,52),fish_region,Color(1,1,1,smoothstep(0,.1,jump_time)*(1-smoothstep(1.58,1.7,jump_time))))
  frame.draw_set_transform((size-Vector2(1280,720)*scale)*.5,0,Vector2.ONE*scale)
 var splash_time=jump_time if jump_time<.5 else jump_time-1.7
 var splash_p=Vector2(540 if jump_time<.5 else 730,656)
 if splash_time>=0 and splash_time<.45:
  var fade=1-splash_time/.45
  frame.draw_arc(splash_p,8+splash_time*48,0,TAU,24,Color(.78,.95,.96,fade*.65),2,true)
  for n in 5:
   var angle=-PI+.4+n*.6
   var droplet=splash_p+Vector2.from_angle(angle)*(12+splash_time*60)+Vector2(0,splash_time*splash_time*95)
   frame.draw_circle(droplet,2.0,Color(.85,.98,1,fade*.8))
 for n in 5:
  var p=Vector2(475+n*63,674+sin(t+n)*2);frame.draw_arc(p,12+fposmod(t*8+n*7,12),0,PI,14,Color(.73,.9,.87,.25),1,true)
 # Both sky cues remain visible; the actual clock sets the dominant light.
 frame.draw_circle(Vector2(186,95),23,Color(1,.82,.5,.4 if night else .85))
 frame.draw_circle(Vector2(1105,102),19,Color(.81,.9,1,.9 if night else .45));frame.draw_circle(Vector2(1113,96),17,Color(.13,.23,.27))
 for n in 12:
  var p=Vector2(250+n*67,570+sin(t*.8+n*2.1)*28)
  frame.draw_circle(p,1.4,Color(.94,.85,.48,.2+.12*sin(t+n)))
 var reveal=smoothstep(4.6,5.35,t)
 if reveal>0:
  frame.draw_rect(Rect2(239,65,620,119),Color(.04,.12,.16,reveal*.7))
  frame.draw_string(display_font,Vector2(270,126),"CROSSROADS",HORIZONTAL_ALIGNMENT_LEFT,-1,53,Color(.96,.89,.72,reveal))
  frame.draw_string(ui_font,Vector2(274,158),"REALMS BEYOND",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color(.8,.84,.7,reveal))
 frame.draw_set_transform(Vector2.ZERO)
