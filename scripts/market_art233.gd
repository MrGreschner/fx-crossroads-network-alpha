extends RefCounted
## Cached marketplace sprites and native-SVG material polish. No simulation changes.
static var sheet:Texture2D
static var equipment_sheet:Texture2D
static var mask_sheet:Image
static var metadata:Dictionary={}
static var equipment:Dictionary={}
static var frames:Dictionary={}
static var variants:Dictionary={}
static var props:Dictionary={}
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/market233/people.json"));equipment=JSON.parse_string(FileAccess.get_file_as_string("res://assets/market233/equipment.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/market233/people.png"));sheet=ImageTexture.create_from_image(im)
 im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/market233/equipment.png"));equipment_sheet=ImageTexture.create_from_image(im)
 mask_sheet=Image.new();mask_sheet.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/market233/cloth_masks.png"))
static func pose_index(pose:int)->int:return 3 if pose==8 else 0 if pose in [0,9] else 2 if pose==2 else 1
static func base_texture(index:int,pose:int)->Texture2D:
 prepare();var n=pose_index(pose);var key=str(index)+":"+str(n)
 if not frames.has(key):
  var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2(n*80,index*80,80,80);frames[key]=tex
 return frames[key]
static func texture(index:int,pose:int)->Texture2D:
 var C=preload("res://scripts/business_district/catalog.gd");var info:Dictionary=C.person(index) if index>=0 else {};var base=8 if index==-1 else posmod(-index-2,8) if index<0 else maxi(0,["ram","badger","cat","newt","human","fox","hare","owl"].find(info.species));var tex=base_texture(base,pose)
 if index<100:return tex
 var coat=Color("#"+str(info.coat).trim_prefix("#").left(6));var key=str(index)+":"+str(pose_index(pose))+":"+coat.to_html()
 if variants.has(key):return variants[key]
 var image=tex.get_image();var region=Rect2i(pose_index(pose)*80,base*80,80,80);var mask=mask_sheet.get_region(region);var base_color=Color("#"+str(metadata[str(base)].coat))
 for y in 80:
  for x in 80:
   if mask.get_pixel(x,y).a<.5:continue
   var c=image.get_pixel(x,y);var shade=clampf(c.v/maxf(.1,base_color.v),.35,1.5);image.set_pixel(x,y,Color.from_hsv(coat.h,coat.s,clampf(coat.v*shade,0,1),c.a))
 var result=ImageTexture.create_from_image(image)
 if variants.size()>256:variants.clear()
 variants[key]=result;return result
static func dog(index:int,pose:int)->Texture2D:return base_texture(9+posmod(index,4),pose)
static func prop(id:String)->Texture2D:
 prepare()
 if not equipment.has(id):return null
 if not props.has(id):
  var index=int(equipment[id].index);var tex=AtlasTexture.new();tex.atlas=equipment_sheet;tex.region=Rect2(index%4*96,int(index/4)*96,96,96);props[id]=tex
 return props[id]
static func draw_prop(c:CanvasItem,id:String,rect:Rect2)->void:
 var tex=prop(id)
 if tex==null:return
 var b:Array=equipment[id].box;var scale=minf(rect.size.x/(float(b[2])-b[0]),rect.size.y/(float(b[3])-b[1]));var side=96*scale
 c.draw_texture_rect(tex,Rect2(Vector2(rect.get_center().x-side*.5,rect.end.y-float(b[3])*scale),Vector2.ONE*side),false)
static func matte_svg(source:String)->String:
 var regex=RegEx.new();regex.compile('fill="(#[0-9a-fA-F]{6})"');var colors:Dictionary={};var defs=""
 for match_value in regex.search_all(source):colors[match_value.get_string(1)]=true
 var index=0
 for hex in colors:
  var color=Color(hex);var id="m233_"+str(index);var light=color.lightened(.07);var dark=color.darkened(.12)
  defs+='<linearGradient id="'+id+'" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#'+light.to_html(false)+'"/><stop offset="1" stop-color="#'+dark.to_html(false)+'"/></linearGradient>'
  source=source.replace('fill="'+hex+'"','fill="url(#'+id+')"');index+=1
 var end=source.find(">")
 return source.substr(0,end+1)+"<defs>"+defs+"</defs>"+source.substr(end+1)
