extends CanvasLayer
## A staged 2D opening film. Scenery, actors and effects have independent motion.
const Story=preload("res://scripts/intro_story223.gd")
const DURATION=22.5
var frame:Control
var stage:Control
var overlay:Control
var skip:Button
var elapsed:=0.0
var night:=false
var reduced:=false
var display_font:Font=preload("res://assets/fonts/CrossroadsDisplay.ttf")
var ui_font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var textures:Dictionary={}
var background:TextureRect
var energy:TextureRect
var water_material:ShaderMaterial
var energy_material:ShaderMaterial
var jumping_fish:Texture2D
var fish_region:Rect2
func image_file(path:String)->Texture2D:
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
 return ImageTexture.create_from_image(im)
func _ready()->void:
 name="FXIntro";layer=100;night=get_parent().town_life.calendar.night_amount()>.5
 stage=Control.new();stage.size=Vector2(1280,720);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stage)
 for asset in ["scene","leaves_left","leaves_right"]:textures[asset]=image_file("res://assets/cinematic223/"+asset+".png")
 textures.gate=image_file("res://assets/cinematic220/portal.png")
 for h in ["cat","ram","bramble"]:
  for n in (4 if h=="cat" else 6):textures[h+str(n)]=image_file("res://assets/cinematic223/"+h+"_%02d.png"%n)
 background=TextureRect.new();background.texture=textures.scene;background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.size=Vector2(1280,720);background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;stage.add_child(background)
 var shader=Shader.new();shader.code="shader_type canvas_item; uniform float film_time=0.; uniform float night=0.; void fragment(){vec2 uv=UV;float water=smoothstep(.78,.81,uv.y);uv.x+=water*sin(uv.y*170.-film_time*2.5)*.0017;uv.y+=water*sin(uv.x*90.+film_time*1.7)*.001;vec4 c=texture(TEXTURE,uv);c.rgb*=mix(vec3(1.),vec3(.48,.62,.79),night);COLOR=c;}"
 water_material=ShaderMaterial.new();water_material.shader=shader;background.material=water_material
 energy=TextureRect.new();energy.texture=image_file("res://assets/cinematic220/portal_window.png");energy.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;var g:Array=Story.spec().gate;energy.position=Vector2(g[0],g[1]);energy.size=Vector2(g[2],g[3]);stage.add_child(energy)
 shader=Shader.new();shader.code="shader_type canvas_item; uniform float film_time=0.; uniform float strength=0.; void fragment(){vec2 p=UV-vec2(.5,.48);float r=length(p*vec2(1.,.72));float a=atan(p.y,p.x);float w=.5+.5*sin(a*2.-r*27.+film_time*2.);vec3 glow=mix(vec3(.04,.22,.32),vec3(.3,.92,.76),w);vec3 c=mix(vec3(.025,.055,.08),glow,strength);COLOR=vec4(c,texture(TEXTURE,UV).a); }"
 energy_material=ShaderMaterial.new();energy_material.shader=shader;energy.material=energy_material
 frame=Control.new();frame.size=Vector2(1280,720);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.draw.connect(paint);stage.add_child(frame)
 overlay=Control.new();overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.draw.connect(paint_overlay);add_child(overlay)
 skip=Button.new();skip.text="Skip intro";skip.pressed.connect(finish);add_child(skip)
 skip.add_theme_font_override("font",ui_font);skip.add_theme_font_size_override("font_size",16);skip.modulate=Color(1,1,1,.8)
 var box=StyleBoxFlat.new();box.bg_color=Color(.03,.1,.13,.75);box.border_color=Color(.6,.7,.7,.6);box.set_border_width_all(1);box.set_corner_radius_all(5);skip.add_theme_stylebox_override("normal",box)
 var hover=box.duplicate();hover.bg_color=Color(.12,.25,.3,.9);skip.add_theme_stylebox_override("hover",hover)
 jumping_fish=preload("res://scripts/fishing_catalog.gd").texture("reedlight_minnow" if night else "sunspot_koi")
 if jumping_fish!=null:fish_region=Rect2(jumping_fish.get_image().get_used_rect())
 _process(0)
func finish()->void:queue_free()
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:finish();get_viewport().set_input_as_handled();return
 if (event is InputEventMouse or event is InputEventScreenTouch) and skip.visible and skip.get_global_rect().has_point(event.position):return
 if event is InputEventKey and skip.has_focus():return
 get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 elapsed+=minf(delta,.05)
 var size:Vector2=get_viewport().get_visible_rect().size;var fit:=minf(size.x/1280,size.y/720);var s:=Story.sample(elapsed)
 stage.scale=Vector2.ONE*fit;stage.position=(size-Vector2(1280,720)*fit)*.5
 water_material.set_shader_parameter("film_time",elapsed);water_material.set_shader_parameter("night",1.0 if night else 0.0);energy_material.set_shader_parameter("film_time",elapsed);energy_material.set_shader_parameter("strength",s.portal)
 skip.size=Vector2(136,34);skip.position=size-Vector2(154,52);skip.visible=elapsed>.75 and elapsed<21.7
 frame.queue_redraw();overlay.queue_redraw()
 if elapsed>=DURATION:finish()
func actor(tex:Texture2D,p:Vector2,size:Vector2,alpha:float=1.0,stretch:Vector2=Vector2.ONE,angle:float=0)->void:
 if tex==null or alpha<=0:return
 frame.draw_set_transform(p,angle,stretch)
 frame.draw_circle(Vector2(0,1),size.x*.13,Color(0,0,0,.13*alpha))
 frame.draw_texture_rect(tex,Rect2(-size*Vector2(.5,.925),size),false,Color(1,1,1,alpha));frame.draw_set_transform(Vector2.ZERO)
func paint()->void:
 var t:=elapsed;var s:=Story.sample(t);var d:=Story.spec();var g:Array=d.gate;var depth:float=d.encounter_scale
 # The entire stone frame is behind actors. Entering is a visible shrink/fade at its centre.
 frame.draw_texture_rect(textures.gate,Rect2(g[0],g[1],g[2],g[3]),false)
 if night:
  for p in [Vector2(82,232),Vector2(135,252),Vector2(292,275)]:frame.draw_circle(p,7,Color(1,.7,.3,.19+.03*sin(t*2)))
 # Reflected current streaks drift DOWNSTREAM, rather than a stationary river illustration.
 for n in 22:
  var p:=Vector2(fposmod(n*83.7-t*(24+n%4*6),1320)-20,571+fposmod(n*17.3+t*7.0,131))
  var a:=.09+.09*(.5+.5*sin(t*1.8+n))
  frame.draw_line(p,p+Vector2(18+n%5*6,-2),Color(.78,.93,.96,a),1.2,true)
 var core=preload("res://scripts/core_hero_art.gd")
 var ep:=Vector2(d.elder[0],d.elder[1]);var elder_pose:="talk" if t<2.4 or t>=5.3 and t<6.5 or t>=10.2 and t<11.2 else "idle"
 actor(core.texture("elder_ram",elder_pose),ep,Vector2(d.cast_size.elder[0],d.cast_size.elder[1]),1,Vector2(1,1+sin(t*2)*.004))
 var rp:=Vector2(s.ram_pos[0],s.ram_pos[1]);var fp:=Vector2(s.foe_pos[0],s.foe_pos[1])
 var rs:=Vector2(d.cast_size.ram[0],d.cast_size.ram[1])*float(s.ram_scale)
 var fs:=Vector2(d.cast_size.bramble[0],d.cast_size.bramble[1])*float(s.foe_scale)
 var ram_stretch:=Vector2(1.035,.97) if t>=9.5 and t<10.08 else Vector2.ONE
 actor(textures["ram"+str(s.ram_frame)],rp,rs,float(s.ram_opacity),ram_stretch)
 var stomp:float=maxf(0,sin(clampf((t-7.12)/.55,0,1)*PI))
 var fstretch:=Vector2(1+stomp*.12,1-stomp*.1)
 actor(textures["bramble"+str(s.foe_frame)],fp,fs,float(s.foe_opacity),fstretch)
 actor(textures["cat"+str(s.cat_frame)],Vector2(d.cat[0],d.cat[1]),Vector2(d.cast_size.cat[0],d.cast_size.cat[1]))
 # Dust makes each Bramble footfall read as weight on the path.
 if s.foe_moving or stomp>0:
  for n in 6:
   var age:=fposmod(t*2.8+n*.17,1.0);var p:=fp+Vector2((n-2.5)*7,age*-12+5)*depth
   frame.draw_circle(p,(2+age*3)*depth,Color(.68,.53,.33,(1-age)*.25))
 var u:float=s.fish_u;var fish_p:=Vector2(lerpf(d.fish_start[0],d.fish_end[0],u),625-sin(u*PI)*88)
 if s.fish_visible and jumping_fish!=null:
  frame.draw_set_transform(fish_p,(u-.5)*1.1,Vector2.ONE);frame.draw_texture_rect_region(jumping_fish,Rect2(-48,-21,96,42),fish_region,Color(1,1,1,smoothstep(0,.08,u)*(1-smoothstep(.92,1,u))));frame.draw_set_transform(Vector2.ZERO)
 for start in [2.7,4.2]:
  var a:=t-float(start)
  if a>=0 and a<.65:
   var p:=Vector2(445 if start==2.7 else 600,625)
   frame.draw_arc(p,9+a*43,0,TAU,24,Color(.75,.95,.98,(1-a/.65)*.7),1.5,true)
   for n in 6:
    var q:=p+Vector2((n-2.5)*a*25,-sin(a/.65*PI)*(16+n%3*6));frame.draw_circle(q,1.8,Color(.86,.97,1,(1-a/.65)*.7))
 if float(s.impact)>0:
  for n in 7:
   var dir:=Vector2.from_angle(n*TAU/7);var p:=Vector2(d.impact[0],d.impact[1])+dir*float(s.impact)*22*depth
   frame.draw_line(p,p+dir*13*depth,Color(1,.86,.53,s.impact),3,true)
 # Foreground branches sway separately; a few leaves drift with the wind.
 for side in 2:
  var p:=Vector2(-8 if side==0 else 900,-10);var ang:=0.0 if reduced else sin(t*.9+side*1.4)*.012
  frame.draw_set_transform(p,ang,Vector2.ONE);frame.draw_texture_rect(textures.leaves_left if side==0 else textures.leaves_right,Rect2(0,0,390,220),false,Color(.6,.72,.83) if night else Color.WHITE);frame.draw_set_transform(Vector2.ZERO)
 if not reduced:
  for n in 8:
   var y:=fposmod(t*18+n*87,540)-30;var x:=fposmod(n*151+t*22+sin(t+n)*13,1280)
   frame.draw_line(Vector2(x,y),Vector2(x+4,y+2),Color(.76,.62,.25,.48),2,true)
 if not reduced and float(s.flash)>0:frame.draw_rect(Rect2(0,0,1280,720),Color(.72,1,.91,s.flash))
func paint_overlay()->void:
 var size:Vector2=get_viewport().get_visible_rect().size;var fit:=minf(size.x/1280,size.y/720);var s:=Story.sample(elapsed)
 overlay.draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.035,.05,float(s.title)*.62))
 overlay.draw_set_transform((size-Vector2(1280,720)*fit)*.5,0,Vector2.ONE*fit)
 var a:float=s.title
 if a>0:
  for entry in [["CROSSROADS",display_font,78,340],["REALMS BEYOND",ui_font,28,390]]:
   var label:String=entry[0];var f:Font=entry[1];var n:int=entry[2];var x:=640-f.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,n).x*.5
   overlay.draw_string(f,Vector2(x+2,entry[3]+3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,n,Color(0,0,0,a*.6));overlay.draw_string(f,Vector2(x,entry[3]),label,HORIZONTAL_ALIGNMENT_LEFT,-1,n,Color(.96,.89,.71,a))
 overlay.draw_set_transform(Vector2.ZERO);overlay.draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.05,.07,1-smoothstep(0,1.1,elapsed)));overlay.draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.05,.07,s.fade))
