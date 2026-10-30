extends CanvasLayer
## Screen-space interaction and dialogue cards. Reflow only when text/layout changes.
var game:Node
var arcade=false
var action:PanelContainer
var notice:PanelContainer
var keycap:Button
var prompt:Label
var speaker:Label
var text:Label
var scroll:ScrollContainer
var signature=""
var settle=0
var released=false
var reflows=0
var state:Dictionary={}
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
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",6);notice.add_child(col)
 speaker=label(14,"#e8cd91");speaker.name="Speaker";col.add_child(speaker)
 scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 text=label(18,"#f0f4ec");text.name="DialogueText";text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(text)
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
func allowed()->bool:
 if not is_instance_valid(game) or not game.is_visible_in_tree():return false
 if game.get("media")!=null and game.media.clean_view and not game.has_meta("qa_show_notices"):return false
 if game.has_node("FXIntro"):return false
 if not arcade and game.fishing!=null and is_instance_valid(game.fishing.room):return false
 if game.session_menu!=null and game.session_menu.page in ["main","options","clear"]:return false
 return game.started and game.shop_open.is_empty() if arcade else game.menu.is_empty()
func _process(_dt:float)->void:
 if released:
  var event=InputEventAction.new();event.action="interact";event.pressed=false;Input.parse_input_event(event);released=false
 visible=allowed()
 if not visible:return
 var hint=hint_text().strip_edges();var message=""
 if arcade:
  if game.mode not in ["arena","battlegrounds"] or game.arena_notice_left>0:message=str(game.status_label.text).strip_edges()
 elif game.message_time>0:message=str(game.message).strip_edges()
 var viewport=get_viewport().get_visible_rect().size;var mobile=game.mobile.enabled;var run=arcade or game.mode=="run"
 var changed=state.is_empty() or hint!=str(state.get("hint","")) or message!=str(state.get("message","")) or viewport!=state.get("viewport",Vector2.ZERO) or mobile!=bool(state.get("mobile",false)) or run!=bool(state.get("run",false))
 if changed:
  signature=hint;reflows+=1;state={"hint":hint,"message":message,"viewport":viewport,"mobile":mobile,"run":run};reflow();settle=3
 if settle>0:settle-=1;place()
func reflow()->void:
 var v:Vector2=state.viewport;var compact:bool=bool(state.mobile) or v.x<760;var margin=16.0 if compact else 24.0
 var width=minf(760,v.x-margin*2);var action_width=minf(680,v.x-margin*2)
 var hint=str(state.hint)
 var interactable=hint.begins_with("E ") or hint.begins_with("E•") or hint.begins_with("E·")
 if interactable:hint=hint.substr(1).strip_edges().trim_prefix("•").trim_prefix("·").strip_edges()
 var pad=10 if compact else 14
 action.get_theme_stylebox("panel").set_content_margin_all(pad);notice.get_theme_stylebox("panel").set_content_margin_all(pad);keycap.get_theme_stylebox("normal").set_content_margin_all(6);keycap.get_theme_stylebox("disabled").set_content_margin_all(6)
 prompt.text=hint;prompt.add_theme_font_size_override("font_size",17 if compact else 20);prompt.custom_minimum_size.x=maxf(80,action_width-108);keycap.text=("TAP" if bool(state.mobile) else "E") if interactable else "TIP";keycap.disabled=not interactable;keycap.mouse_filter=Control.MOUSE_FILTER_STOP
 action.visible=not str(state.hint).is_empty();action.size=Vector2(action_width,0)
 var parts=split_notice(str(state.message));speaker.text=parts[0];text.text=parts[1];text.add_theme_font_size_override("font_size",16 if compact else 18);text.custom_minimum_size.x=maxf(100,width-36)
 scroll.custom_minimum_size=Vector2(width-28,0);scroll.size=Vector2(width-28,0);scroll.scroll_vertical=0
 notice.visible=not str(state.message).is_empty();notice.size=Vector2(width,0)
 var line_height=FONT.get_height(16 if compact else 18);var max_height=minf(140,maxf(70,v.y*.24));var estimated=FONT.get_multiline_string_size(text.text,HORIZONTAL_ALIGNMENT_LEFT,width-40,16 if compact else 18).y
 # The scroll region keeps long dialogue readable without covering the whole game.
 scroll.custom_minimum_size.y=minf(max_height,maxf(line_height,estimated));scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
func place()->void:
 var v:Vector2=state.viewport;var base=88.0 if bool(state.mobile) else 116.0 if bool(state.run) else 22.0
 action.size.y=action.get_combined_minimum_size().y
 var budget=maxf(24,v.y-base-108-(action.size.y+10 if action.visible else 0)-48)
 if notice.visible:scroll.custom_minimum_size.y=minf(scroll.custom_minimum_size.y,budget)
 var notice_size=notice.get_combined_minimum_size();notice.size.y=notice_size.y
 notice.position=Vector2((v.x-notice.size.x)*.5,v.y-base-notice.size.y)
 var bottom=v.y-base-(notice.size.y+12 if notice.visible else 0)
 action.size.y=action.get_combined_minimum_size().y;action.position=Vector2((v.x-action.size.x)*.5,bottom-action.size.y)
 # Small landscape screens retain a clear gap below the top HUD.
 if action.visible and action.position.y<112:action.position.y=112
