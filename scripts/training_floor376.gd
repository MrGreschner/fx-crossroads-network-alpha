extends Node2D
## Three familiar materials, one retained draw: grass, worn earth and a small work deck.
## Presentation only; the existing yard's boundaries, targets and exit do not move.
var game:Node
var grass:Texture2D
const CODE="""
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D grass_tex : repeat_enable, filter_nearest;
uniform sampler2D earth_tex : repeat_enable, filter_nearest;
uniform sampler2D wood_tex : repeat_enable, filter_nearest;
float box_distance(vec2 p, vec2 center, vec2 half_size, float radius) {
 vec2 q=abs(p-center)-half_size+vec2(radius);
 return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-radius;
}
float lane(vec2 p, vec2 a, vec2 b, float radius) {
 vec2 v=b-a;
 return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0))-radius;
}
void fragment() {
 vec2 p=UV*vec2(1800.0,1200.0);
 float yard=box_distance(p,vec2(1200.0,615.0),vec2(500.0,330.0),68.0);
 float approach=min(lane(p,vec2(-60.0,600.0),vec2(280.0,600.0),53.0),lane(p,vec2(280.0,600.0),vec2(470.0,650.0),53.0));
 float front=lane(p,vec2(365.0,650.0),vec2(365.0,400.0),72.0);
 float porch=box_distance(p,vec2(393.0,405.0),vec2(176.0,99.0),42.0);
 float book=lane(p,vec2(410.0,435.0),vec2(660.0,400.0),52.0);
 float join=lane(p,vec2(660.0,400.0),vec2(830.0,470.0),52.0);
 float ally=lane(p,vec2(470.0,650.0),vec2(870.0,650.0),65.0);
 float work=lane(p,vec2(470.0,640.0),vec2(470.0,818.0),48.0);
 float courtyard=box_distance(p,vec2(470.0,515.0),vec2(245.0,220.0),80.0);
 float d=min(courtyard,min(min(min(yard,approach),min(front,porch)),min(min(book,join),min(ally,work))));
 vec2 cell=floor(p/3.0);
 float grit=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 float blend=1.0-smoothstep(-5.0,10.0,d+(grit-.5)*9.0);
 vec3 green=texture(grass_tex,p/256.0).rgb*vec3(.9,.94,.91);
 vec3 soil=texture(earth_tex,p/256.0).rgb;
 float grey=dot(soil,vec3(.299,.587,.114));
 soil=mix(vec3(.49,.465,.39),mix(vec3(grey),soil,.40),.44);
 vec3 result=mix(green,soil,blend);
 float deck=box_distance(p,vec2(510.0,821.0),vec2(275.0,72.0),6.0);
 vec3 timber=texture(wood_tex,p/256.0).rgb*vec3(.86,.88,.84);
 if(deck<0.0)result=mix(timber*.69,timber,smoothstep(0.0,5.0,-deck));
 COLOR=vec4(result,1.0);
}
"""
static func sync(g:Node2D,camera:Vector2,green:Texture2D,earth:Texture2D,wood:Texture2D)->void:
 var floor_node=g.get_node_or_null("TrainingFloor376")
 if floor_node==null:
  floor_node=load("res://scripts/training_floor376.gd").new();floor_node.name="TrainingFloor376";floor_node.game=g;floor_node.grass=green;floor_node.show_behind_parent=true;floor_node.z_index=-2
  var shader=Shader.new();shader.code=CODE
  var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("grass_tex",green.diffuse_texture if green is CanvasTexture else green);material.set_shader_parameter("earth_tex",earth.diffuse_texture if earth is CanvasTexture else earth);material.set_shader_parameter("wood_tex",wood.diffuse_texture if wood is CanvasTexture else wood);floor_node.material=material
  g.add_child(floor_node)
 floor_node.visible=true;floor_node.position=g.media.offset()-camera*g.media.factor();floor_node.scale=Vector2.ONE*g.media.factor()
func _process(_delta:float)->void:
 visible=game.mode=="run" and game.practice and game.menu!="workshop" and not game.has_meta("fx_hero_quest") and not game.has_node("FXIntro") and game.session_menu.page not in ["main","clear","options"]
 if visible:position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor()
func _draw()->void:draw_texture_rect(grass,Rect2(0,0,1800,1200),false)
