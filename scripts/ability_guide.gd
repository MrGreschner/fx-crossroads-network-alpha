extends CanvasLayer
## Inspection-only HUD. Local input is gated while inspecting; the world keeps running.
const KINDS=["primary","secondary","special","passive"]
const TINTS=["#e5c47f","#9cd9e5","#c7ace5","#9bc5ac"]
var game:Node
var arcade:=false
var strip:GridContainer
var buttons:Array[Button]=[]
var panel:Panel
var title:RichTextLabel
var subtitle:RichTextLabel
var message:RichTextLabel
var close_button:Button
var footer:RichTextLabel
var selected:=-1
var release_guard:=false
var tick:=0.0
var identity:=""
static func nice(value:float)->String:return str(int(value)) if is_equal_approx(value,roundf(value)) else str(snappedf(value,.01))
static func blocks(g:Node)->bool:
 var guide=g.get_node_or_null("AbilityGuide")
 return guide!=null and guide.blocked()
func setup(g:Node)->void:
 game=g;arcade=g.has_method("_attack_request");name="AbilityGuide";layer=36
 strip=GridContainer.new();strip.name="AbilityButtons";strip.columns=4;strip.add_theme_constant_override("h_separation",6);strip.add_theme_constant_override("v_separation",5);add_child(strip)
 for n in 4:
  var b=Button.new();b.name=KINDS[n].capitalize()+"Info";b.custom_minimum_size=Vector2(0,44);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.clip_text=true;b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",12)
  b.add_theme_color_override("font_color",Color(TINTS[n]));b.add_theme_stylebox_override("normal",skin("#19323d","#45626e"));b.add_theme_stylebox_override("hover",skin("#284c58",TINTS[n]));b.add_theme_stylebox_override("pressed",skin("#34505c",TINTS[n]));b.button_down.connect(func():release_guard=true);b.pressed.connect(show_info.bind(n));strip.add_child(b);buttons.append(b)
 panel=Panel.new();panel.name="AbilityDetails";panel.clip_contents=true;panel.add_theme_stylebox_override("panel",skin("#122b36","#b7b08b"));add_child(panel);panel.visible=false
 title=rich(19);panel.add_child(title)
 close_button=Button.new();close_button.text="×";close_button.focus_mode=Control.FOCUS_NONE;panel.add_child(close_button);close_button.button_down.connect(func():release_guard=true);close_button.pressed.connect(close_info)
 subtitle=rich(13);subtitle.modulate=Color("#b3c7ce");panel.add_child(subtitle)
 message=rich(15);message.name="Description";message.scroll_active=true;message.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_child(message)
 footer=rich(12);footer.text="Click outside or Esc to close · Combat continues";footer.modulate=Color("#a3b6b9");panel.add_child(footer)
 refresh()
static func rich(font_size:int)->RichTextLabel:
 var label=RichTextLabel.new();label.fit_content=false;label.bbcode_enabled=false;label.scroll_active=false;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_size_override("normal_font_size",font_size);label.add_theme_color_override("default_color",Color("#e0e6dc"));return label
static func skin(fill:String,edge:String)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(fill);s.border_color=Color(edge);s.set_border_width_all(1);s.set_corner_radius_all(6);s.content_margin_left=6;s.content_margin_right=6;return s
static func for_side(m:MarginContainer,pad:int)->void:
 for side in ["left","right","top","bottom"]:m.add_theme_constant_override("margin_"+side,pad)
func hero_context()->Dictionary:
 var id:String=str(game.hero_ids.get(game.my_id,game.selected_hero)) if arcade else str(game.character_id)
 var hero:Dictionary=game.characters.get(id,{}) if arcade else game.hero
 return {"id":id,"hero":hero,"owner":str(game.my_id) if arcade else "solo","level":int(game.levels.get(game.my_id,1)) if arcade else int(game.level)}
func model(index:int)->Dictionary:
 var ctx:=hero_context();var kind:String=KINDS[index];var hero:Dictionary=ctx.hero;var needed:int=[1,3,6,5][index]
 if index==3:
  var passive:String=str(hero.get("passive","No passive recorded for this hero."));var parts=passive.split(":",true,1)
  return {"name":parts[0] if parts.size()>1 else "Passive","description":passive,"subtitle":"PASSIVE · "+("ACTIVE" if int(ctx.level)>=needed else "Unlocks at level 5")+" · Automatic effect","locked":int(ctx.level)<needed}
 var stats:Dictionary=game.adventure.combat.effective_stats(str(ctx.owner),kind,hero.get(kind,{}))
 var text:String=str(stats.get("description",""))
 if text.is_empty():text=preload("res://scripts/hero_library.gd").new().ability_brief(stats,kind)
 var numbers:Array[String]=[]
 if float(stats.get("damage",0))>0:numbers.append("Ability damage: "+nice(float(stats.damage)))
 if stats.has("healing"):numbers.append("Ally healing: "+nice(float(stats.healing)))
 if stats.has("return_damage"):numbers.append("Return damage: "+nice(float(stats.return_damage)))
 if stats.has("cooldown"):numbers.append("Cooldown: "+nice(float(stats.cooldown))+"s")
 if stats.has("range"):numbers.append("Reach: "+nice(float(stats.range)))
 var label:String=["LMB / Primary","RMB / Secondary","Space / Special"][index]
 return {"name":str(stats.get("name",kind.capitalize())),"description":text+("\n\n"+" · ".join(numbers) if not numbers.is_empty() else ""),"subtitle":label+" · "+("Unlocked" if int(ctx.level)>=needed else "Unlocks at level "+str(needed)),"locked":int(ctx.level)<needed}
func active()->bool:
 if game==null or not is_instance_valid(game.presentation) or not is_instance_valid(game.session_menu):return false
 if not game.presentation.page.is_empty() or not game.session_menu.page.is_empty() or game.media.clean_view or game.media.capturing or game.has_node("FXIntro"):return false
 return game.started and game.shop_open.is_empty() and not game.spectating() and not game.arena_world.shatter.active() if arcade else game.mode=="run" and game.menu.is_empty()
func blocked()->bool:
 if strip==null or not strip.visible:return false
 if selected>=0 or release_guard:return true
 var cursor=game.get_viewport().get_mouse_position()
 return strip.get_global_rect().has_point(cursor)
func refresh()->void:
 strip.visible=active()
 if not strip.visible:close_info();return
 var ctx:=hero_context();var key:String=str(ctx.id)+":"+str(ctx.level)
 if identity!=key:identity=key;close_info()
 for n in 4:
  var item:=model(n);var shortcut:String=(["AIM · PRIMARY","2ND · SECONDARY","SPC · SPECIAL","AUTO · PASSIVE"] if game.mobile.enabled else ["LMB · PRIMARY","RMB · SECONDARY","SPACE · SPECIAL","AUTO · PASSIVE"])[n]
  buttons[n].text=KINDS[n].capitalize()+"\n"+str(item.name);buttons[n].tooltip_text=shortcut+" · "+str(item.name)+" · Click for details";buttons[n].modulate=Color("#a7b1b8") if item.locked else Color.WHITE
 if selected>=0:fill_details()
 layout()
func layout()->void:
 var view:Vector2=game.get_viewport_rect().size
 strip.columns=2
 var rect=preload("res://scripts/combat_hud.gd").info_rect(view)
 # Touch controls retain their own clear area above the corner buttons.
 strip.position=rect.position;strip.size=rect.size
 var pw:=minf(520,view.x-24);var ph:=minf(264,view.y-24)
 var top:=maxf(12,strip.position.y-ph-8)
 panel.position=Vector2(clampf(strip.position.x+strip.size.x-pw,12,maxf(12,view.x-pw-12)),top);panel.size=Vector2(pw,ph)
 title.position=Vector2(12,10);title.size=Vector2(pw-60,42)
 close_button.position=Vector2(pw-44,10);close_button.size=Vector2(32,30)
 subtitle.position=Vector2(12,54);subtitle.size=Vector2(pw-24,32)
 message.position=Vector2(12,92);message.size=Vector2(pw-24,maxf(20,panel.size.y-130))
 footer.position=Vector2(12,panel.size.y-30);footer.size=Vector2(pw-24,26)
func fill_details()->void:
 var item:=model(selected);title.text=str(item.name);subtitle.text=str(item.subtitle);message.text=str(item.description);title.modulate=Color(TINTS[selected]);panel.visible=true
func show_info(index:int)->void:
 if index<0 or index>3 or not strip.visible:return
 if selected==index:close_info();return
 selected=index;fill_details();layout()
func close_info()->void:
 selected=-1
 if panel!=null:panel.visible=false
func _process(delta:float)->void:
 if release_guard and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):release_guard=false
 tick+=delta
 if tick>=.12:tick=0;refresh()
func _input(event:InputEvent)->void:
 if selected<0:return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  close_info();get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.pressed and not panel.get_global_rect().has_point(event.position) and not strip.get_global_rect().has_point(event.position):
  release_guard=true;close_info();get_viewport().set_input_as_handled()
