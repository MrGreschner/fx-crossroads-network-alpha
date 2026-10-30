extends RefCounted
## Shared static artwork only. Gameplay catalogues/owners stay authoritative.
static var sheet:Texture2D
static var specs:Dictionary={}
static var frames:Dictionary={}
static func prepare()->void:
 if sheet!=null:return
 specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items245/items.json"))
 var image=Image.new();image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/items245/items.png"));sheet=ImageTexture.create_from_image(image)
 for id in specs:
  var a:Array=specs[id].region;var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2(a[0],a[1],a[2],a[3]);t.filter_clip=true;frames[id]=t
static func texture(id:String)->Texture2D:
 prepare();return frames.get(id)
static func legacy_path(path:String)->Texture2D:
 var id=""
 if path.begins_with("res://assets/v191_item_"):id=path.get_file().trim_prefix("v191_item_").trim_suffix(".svg")
 elif path.begins_with("res://assets/lodges/lodge_"):id=path.get_file().trim_suffix(".svg")
 elif path.begins_with("res://assets/fishing/bait_") or path.begins_with("res://assets/items/bg_"):id=path.get_file().trim_suffix(".svg")
 return null if id.is_empty() else texture(id)
static func draw(canvas:CanvasItem,id:String,r:Rect2)->bool:
 var t=texture(id)
 if t==null:return false
 canvas.draw_texture_rect(t,r,false);return true
static func emblem(canvas:Control,id:String)->bool:
 if id=="rod":id="rod_base"
 elif id=="bait":id="bait_worms"
 elif id in ["basic","worms","insects","dough","scraps","honeygrain","moonmoth","saltflash","kelp_crumble","roe"]:id="bait_"+id
 if texture(id)==null:return false
 var edge=minf(canvas.size.x,canvas.size.y);return draw(canvas,id,Rect2((canvas.size-Vector2.ONE*edge)*.5,Vector2.ONE*edge))
static func relic(canvas:Control,id:String)->void:
 var edge=minf(canvas.size.x,canvas.size.y);draw(canvas,"relic_"+id,Rect2((canvas.size-Vector2.ONE*edge)*.5,Vector2.ONE*edge))
static func icon(parent:Node,id:String,edge:float=72)->TextureRect:
 var art=TextureRect.new();art.name="Artwork_"+id;art.texture=texture(id);art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(edge,edge);art.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(art);return art
static func card_art(card:VBoxContainer,id:String,edge:float=72)->void:
 var labels=card.get_children();var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 for child in labels:card.remove_child(child);words.add_child(child)
 card.add_child(row);icon(row,id,edge);row.add_child(words)
static func rod_style(progress:RefCounted)->String:
 var choice=str(progress.state().cosmetic)
 for level in preload("res://scripts/fishing_progress.gd").COSMETICS:
  if choice==str(preload("res://scripts/fishing_progress.gd").COSMETICS[level].id) and progress.level()>=int(level):return choice
 return "base"
static func rod(canvas:CanvasItem,hand:Vector2,tip:Vector2,style:String)->void:
 canvas.draw_set_transform(hand,(tip-hand).angle(),Vector2.ONE*(hand.distance_to(tip)/104.0));draw(canvas,"rod_body_"+style,Rect2(Vector2(-12,-64),Vector2(128,128)));canvas.draw_set_transform(Vector2.ZERO)
