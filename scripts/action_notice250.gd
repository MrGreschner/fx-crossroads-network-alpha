extends CanvasLayer
## Screen-space interaction and dialogue cards. Reflow only when text/layout changes.
var game:Node
var arcade=false
var action:PanelContainer
var notice:PanelContainer
var keycap:Button
var prompt:Label
var speaker:Label
var text:RichTextLabel
var signature=""
var settle=0
var released=false
var reflows=0
var state:Dictionary={}
var last_message259=""
var context259=""
var notice_left259=0.0
const NOTICE_SECONDS259=6.0
const FONT=preload("res://assets/fonts/CrossroadsUI.ttf")
func skin(ink:String,border:String)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(ink);s.border_color=Color(border);s.set_border_width_all(1);s.set_corner_radius_all(9);s.set_content_margin_all(14);s.shadow_color=Color(0,0,0,.35);s.shadow_size=4;s.shadow_offset=Vector2(0,3);return s
func label(size_value:int,color:String)->Label:
 var n=Label.new();n.add_theme_font_override("font",FONT);n.add_theme_font_size_override("font_size",size_value);n.add_theme_color_override("font_color",Color(color));n.mouse_filter=Control.MOUSE_FILTER_IGNORE;return n
func _ready()->void:
 if game.get("dedicated")==true:visible=false;set_process(false);return
 layer=65
 action=PanelContainer.new();action.name="InteractionCard";action.add_theme_stylebox_override("panel",skin("#102932","#d6bf83"));add_child(action)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);action.add_child(row)
 keycap=Button.new();keycap.name="InteractKey";keycap.text="E";keycap.focus_mode=Control.FOCUS_NONE;keycap.custom_minimum_size=Vector2(44,40);keycap.add_theme_font_override("font",FONT);keycap.add_theme_font_size_override("font_size",21);keycap.add_theme_color_override("font_color",Color("#fff2c6"));keycap.add_theme_stylebox_override("normal",skin("#3c4b46","#eed394"));keycap.add_theme_stylebox_override("disabled",skin("#283d43","#799d9d"));keycap.add_theme_color_override("font_color_disabled",Color("#e0e9e0"));keycap.pressed.connect(interact);row.add_child(keycap)
 prompt=label(20,"#fff4d4");prompt.name="InteractionText";prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;prompt.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(prompt)
 notice=PanelContainer.new();notice.name="DialogueCard";notice.add_theme_stylebox_override("panel",skin("#102932","#799d9d"));add_child(notice)
 var heading:=HBoxContainer.new()
 heading.add_theme_constant_override("separation",12)
 notice.add_child(heading)
 var col:=VBoxContainer.new()
 col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 col.add_theme_constant_override("separation",6)
 heading.add_child(col)
 speaker=label(14,"#e8cd91");speaker.name="Speaker";speaker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_child(speaker)
 var dismiss=Button.new();dismiss.name="DismissNotice";dismiss.text="×";dismiss.tooltip_text="Dismiss notice";dismiss.focus_mode=Control.FOCUS_NONE;dismiss.custom_minimum_size=Vector2(28,24);dismiss.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;heading.add_child(dismiss)
 dismiss.pressed.connect(func():
  if arcade:notice_left259=0
  else:game.message_time=0
  notice.hide()
 )
 text=RichTextLabel.new()
 text.name="DialogueText"
 text.add_theme_font_override("normal_font",FONT)
 text.add_theme_color_override("default_color",Color("#f0f4ec"))
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 text.fit_content=false
 col.add_child(text)
 action.hide();notice.hide()
func interact()->void:
 if not action.visible or keycap.disabled:return
 var event=InputEventAction.new();event.action="interact";event.pressed=true;Input.parse_input_event(event);released=true
func hint_text()->String:
 if not arcade:return str(game.hint)
 for b in game.world_buildings:
  if str(b.name)!="Gate" and game.local_pos.distance_to(b.pos)<220:return "E  Visit "+str(b.name)
 return ""
static func split_notice(value:String)->Array:
 var colon=value.find(":")
 if colon>0 and colon<36 and not value.substr(0,colon).contains("/"):
  return [value.substr(0,colon),value.substr(colon+1).strip_edges()]
 return ["NOTICE",value]
static func display_notice(value:String)->String:
 value=value.strip_edges()
 var body:=str(split_notice(value)[1]).replace("\u200b","").replace("\u200c","").replace("\u200d","").replace("\u2060","").replace("\ufeff","").replace("\u00a0"," ").strip_edges()
 if body.to_lower()=="crossroads update":return ""
 for i in body.length():
  if not body[i] in [" ","\t","\n","\r",".","…","-","—","–","•",":"]:return value
 return ""

func allowed()->bool:
 if not is_instance_valid(game) or not game.is_visible_in_tree():return false
 if game.get("media")!=null and game.media.clean_view and not game.has_meta("qa_show_notices"):return false
 if game.has_node("FXIntro"):return false
 if not arcade and game.fishing!=null and is_instance_valid(game.fishing.room):return false
 if game.session_menu!=null and game.session_menu.page in ["main","options","clear"]:return false
 return game.started and game.shop_open.is_empty() if arcade else game.menu.is_empty()
func transient_message259(value:String,context:String,dt:float)->String:
 value=display_notice(value)
 if context!=context259:context259=context;last_message259="";notice_left259=0
 if value!=last_message259:
  last_message259=value;notice_left259=NOTICE_SECONDS259 if not value.is_empty() else 0.0
 else:notice_left259=maxf(0,notice_left259-maxf(0,dt))
 return value if notice_left259>0 else ""
func _process(_dt:float)->void:
 if released:
  var event=InputEventAction.new();event.action="interact";event.pressed=false;Input.parse_input_event(event);released=false
 var arcade_message=""
 if arcade:
  var status:="" if game.mode=="descent" else str(game.status_label.text)
  arcade_message=transient_message259(status,str(game.mode)+":"+str(game.started),_dt)
 visible=allowed()
 if not visible:return
 var hint=hint_text().strip_edges();var message=""
 if arcade:
  message=arcade_message
 elif game.message_time>0:
  message=display_notice(str(game.message))
 var viewport=get_viewport().get_visible_rect().size;var mobile=game.mobile.enabled;var run=arcade or game.mode=="run"
 var changed=state.is_empty() or hint!=str(state.get("hint","")) or message!=str(state.get("message","")) or viewport!=state.get("viewport",Vector2.ZERO) or mobile!=bool(state.get("mobile",false)) or run!=bool(state.get("run",false))
 if changed:
  signature=hint;reflows+=1;state={"hint":hint,"message":message,"viewport":viewport,"mobile":mobile,"run":run};reflow();settle=3
 if settle>0:settle-=1;place()
func reflow()->void:
 var v:Vector2=state.viewport;var compact:bool=bool(state.mobile) or v.x<760;var margin=16.0 if compact else 24.0
 var width=minf(760,v.x-margin*2);var action_width=minf(680,v.x-margin*2)
 var hint=str(state.hint)
 var marina:bool=hint==preload("res://scripts/water_voyage.gd").PIER_HINT
 if marina:action_width=minf(280.0,v.x-margin*2)
 var interactable=hint.begins_with("E ") or hint.begins_with("E•") or hint.begins_with("E·")
 if interactable:hint=hint.substr(1).strip_edges().trim_prefix("•").trim_prefix("·").strip_edges()
 var pad=10 if compact else 14
 action.get_theme_stylebox("panel").set_content_margin_all(8 if marina else pad);notice.get_theme_stylebox("panel").set_content_margin_all(pad);keycap.get_theme_stylebox("normal").set_content_margin_all(6);keycap.get_theme_stylebox("disabled").set_content_margin_all(6)
 prompt.text=hint;prompt.add_theme_font_size_override("font_size",16 if marina else 17 if compact else 20);prompt.custom_minimum_size.x=maxf(80,action_width-108);keycap.text=("TAP" if bool(state.mobile) else "E") if interactable else "TIP";keycap.disabled=not interactable;keycap.mouse_filter=Control.MOUSE_FILTER_STOP
 action.visible=not str(state.hint).is_empty();action.size=Vector2(action_width,0)
 var parts:=split_notice(str(state.message))
 speaker.text=str(parts[0]) if parts[0]!="NOTICE" and str(parts[0]).strip_edges().to_lower()!="crossroads update" else ""
 speaker.visible=not speaker.text.is_empty()
 text.text=str(parts[1])
 var font_size:=16 if compact else 18
 text.add_theme_font_size_override("normal_font_size",font_size)
 var line_height:=FONT.get_height(font_size)+4
 var message_width:=maxf(64,width-pad*2-54)
 var estimated:=FONT.get_multiline_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,message_width,font_size).y
 text.custom_minimum_size.y=clampf(estimated+4,line_height,minf(140.0,maxf(line_height,v.y*.24)))
 text.scroll_to_line(0)
 notice.visible=not str(state.message).is_empty()
 notice.size=Vector2(width,0)

func place()->void:
 var v:Vector2=state.viewport;var base=88.0 if bool(state.mobile) else 116.0 if bool(state.run) else 22.0
 action.size.y=action.get_combined_minimum_size().y
 var available:float=v.y-base-108-(action.size.y+10 if action.visible else 0)-60
 if notice.visible:
  var minimum:=FONT.get_height(text.get_theme_font_size("normal_font_size"))+4
  text.custom_minimum_size.y=minf(text.custom_minimum_size.y,maxf(minimum,available))
 var notice_size=notice.get_combined_minimum_size();notice.size.y=notice_size.y
 notice.position=Vector2((v.x-notice.size.x)*.5,v.y-base-notice.size.y)
 var bottom=v.y-base-(notice.size.y+12 if notice.visible else 0)
 action.size.y=action.get_combined_minimum_size().y;action.position=Vector2((v.x-action.size.x)*.5,bottom-action.size.y)
 # Small landscape screens retain a clear gap below the top HUD.
 if action.visible and action.position.y<112:action.position.y=112
