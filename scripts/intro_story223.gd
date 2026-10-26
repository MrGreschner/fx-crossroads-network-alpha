extends RefCounted
## Pure cinematic state, shared beat data with the browser renderer.
static var data:Dictionary={}
static func spec()->Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://content/intro223.json"))
 return data
static func beat(key:String,t:float)->float:
 var b:Array=spec().beats[key];return smoothstep(float(b[0]),float(b[1]),t)
static func stage_point(p:Array)->Array:
 var d=spec();var f:float=d.encounter_scale
 return [float(d.encounter_origin[0])+(float(p[0])-float(d.encounter_origin[0]))*f+float(d.encounter_offset[0]),float(d.encounter_origin[1])+(float(p[1])-float(d.encounter_origin[1]))*f+float(d.encounter_offset[1])]
static func sample(t:float)->Dictionary:
 var d=spec();var b:Dictionary=d.beats
 var portal:=beat("portal",t);var emerge:=beat("emerge",t);var charge:=beat("charge",t)
 var recoil:=beat("recoil",t);var retreat:=beat("retreat",t);var fw:=beat("foe_warp",t);var rw:=beat("ram_warp",t)
 var ram_x:float=700.0-8*beat("windup",t)+58*beat("strike",t)
 ram_x=lerpf(ram_x,900.0,beat("follow",t))
 var foe_x:=lerpf(900.0,792.0,charge)+23*recoil
 foe_x=lerpf(foe_x,900.0,retreat)
 var jumping:bool=t>=float(b.fish[0]) and t<float(b.fish[1])
 var fish_u:=clampf((t-float(b.fish[0]))/(float(b.fish[1])-float(b.fish[0])),0,1)
 var moving_foe:bool=(t>=7.5 and t<9.8) or (t>=11.1 and t<13.4)
 var moving_ram:bool=t>=14.3 and t<16.35
 var ram_frame:int=4 if t>=10.08 and t<10.5 else 3 if t>=9.5 and t<10.08 else 1+int(t*7)%2 if moving_ram else 0
 var foe_frame:int=3 if t>=10.2 and t<11.1 else 4+int(t*7)%2 if t>=11.1 else 1+int(t*7)%2 if moving_foe else 0
 var cat_frame:int=int(t*3)%2 if t<2.87 else 2 if t<5.3 else 3
 var appear:float=smoothstep(6.8,7.0,t)*(1-fw) if t>=float(b.emerge[0]) else 0.0
 return {"portal":portal,"flash":sin(clampf((t-5.35)/.5,0,1)*PI)*.22,"ram_pos":stage_point([ram_x,458-80*rw-(absf(sin(t*14))*2 if moving_ram else 0)]),"ram_opacity":1-rw,"ram_scale":1-rw*.65,"ram_frame":ram_frame,"foe_pos":stage_point([foe_x,418+40*emerge-80*fw-(absf(sin(t*14))*2 if moving_foe else 0)]),"foe_opacity":appear,"foe_scale":(.5+.5*emerge)*(1-fw*.65),"foe_frame":foe_frame,"cat_frame":cat_frame,"fish_visible":jumping,"fish_u":fish_u,"title":beat("title",t),"fade":beat("fade",t),"impact":sin(clampf((t-10.2)/.42,0,1)*PI),"foe_moving":moving_foe,"ram_moving":moving_ram,"zoom":1.0,"pan_y":0.0,"pan_x":0.0}
