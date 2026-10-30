extends CanvasLayer
## Dedicated cosmetic catalogue. Locked items can be inspected without being equipped.
const C=preload("res://scripts/player_cosmetics.gd")
const W=preload("res://scripts/weekly_activities.gd")
const R=preload("res://scripts/cosmetic_rankings.gd")
const A=preload("res://scripts/ranked_cosmetic_art.gd")
var manager:RefCounted
var legacy:Node
var panel:PanelContainer
var preview:Control
var details:VBoxContainer
var gallery:GridContainer
var sync_label:Label
var previous=""
var selected="auto"
var filter:=0
var lobby_preview:=false
var clock:=0.0
var refresh:=0.0
var entries:Array=[]
var signature=""
var catalogue_scroll:ScrollContainer
var detail_scroll:ScrollContainer
class Preview extends Control:
 var page:CanvasLayer
 func _draw()->void:
  var m=page.manager;var g=page.legacy.game;var hero=str(g.selected_hero) if page.legacy.arcade else str(g.selected_character)
  var p=Vector2(size.x*.5,218);draw_circle(p-Vector2(0,65),100,Color("#1e414c"));draw_arc(p-Vector2(0,65),98,0,TAU,72,Color("#597a7e"),1.5,true)
  var sprite=str(g.characters.get(hero,{}).get("sprite",hero));var tex:Texture2D=g.art.get(sprite+"_idle",g.art.get(sprite+"_0",g.art.get(sprite+"_walk1")))
  draw_set_transform(Vector2(p.x,p.y),0,Vector2.ONE*1.65)
  var hero_rect=preload("res://scripts/core_hero_art.gd").body_rect(sprite,Rect2(-Vector2(27,65),Vector2(54,65)),page.clock)
  var cosmetic_body=preload("res://scripts/hero_layout250.gd").body(tex,hero_rect)
  if page.lobby_preview:A.draw_lobby(self,Vector2.ZERO,page.clock,m.rankings.lobby_payload(),cosmetic_body)
  if tex!=null:draw_texture_rect(tex,hero_rect,false)
  var id=str(page.selected)
  if id=="crown" or page.lobby_preview or not bool(m.state().get("hide_town_crown",false)):
   var crown_rank=preload("res://scripts/rolling_crowns.gd").tier_from(page.legacy.crowns.total())
   preload("res://scripts/rolling_crowns.gd").draw_town(self,preload("res://scripts/hero_layout250.gd").crown(cosmetic_body),page.clock,crown_rank)
  if id=="crown":pass
  elif id in R.IDS:
   if page.lobby_preview and id not in A.active(m.rankings.lobby_payload()):A.draw_single(self,Vector2.ZERO,page.clock,id,3,cosmetic_body)
  elif id=="daily" or id=="auto":
   if page.legacy.daily.earned():preload("res://scripts/daily_challenge.gd").draw_on(self,Vector2.ZERO,page.clock,page.legacy.daily.today,cosmetic_body)
   if id=="auto":C.draw_on(self,Vector2.ZERO,page.clock,m.effect(),m.effect_week(m.effect()),cosmetic_body)
  else:C.draw_on(self,Vector2.ZERO,page.clock,id,m.effect_week(id),cosmetic_body)
  draw_set_transform(Vector2.ZERO)
class Swatch extends Control:
 var id=""
 var page:CanvasLayer
 func _draw()->void:
  draw_circle(Vector2(26,26),23,Color("#24444e"))
  if id=="crown":preload("res://scripts/rolling_crowns.gd").draw_on(self,Vector2(26,65),page.clock,maxi(1,preload("res://scripts/rolling_crowns.gd").tier_from(page.legacy.crowns.total())))
  elif id in R.IDS:A.draw_icon(self,Vector2(26,26),page.clock,id)
  elif id in ["none","auto","daily"]:draw_arc(Vector2(26,26),13,page.clock*.4,page.clock*.4+PI*1.7,24,Color("#e1c78c"),2,true)
  else:
   draw_set_transform(Vector2(0,0),0,Vector2.ONE*.65);C.draw_on(self,Vector2(40,125),page.clock,id,page.manager.effect_week(id));draw_set_transform(Vector2.ZERO)
func text(parent:Node,value:String,size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,value:String,call:Callable)->Button:
 var b=Button.new();b.text=value;b.custom_minimum_size.y=42;preload("res://scripts/top_button_style.gd").apply(b);parent.add_child(b);b.pressed.connect(call);return b
func setup(owner:RefCounted)->void:
 manager=owner;legacy=owner.legacy;layer=81;previous=str(legacy.game.menu);legacy.game.menu="atelier";legacy.game.mobile.reset_controls();selected=str(manager.state().selected)
 var shade=ColorRect.new();shade.color=Color(.02,.05,.08,.93);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 var shell=VBoxContainer.new();shell.add_theme_constant_override("separation",12);panel.add_child(shell)
 var title=HBoxContainer.new();shell.add_child(title);text(title,"GLEAM ATELIER",30).size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(title,"Back to profile" if previous=="legacy" else "Back to town" if not legacy.arcade else "Back to lobby",close)
 text(shell,"Make your hero your own. Inspect any style; equip the ones you have earned.",17).modulate=Color("#bfd3cf")
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;shell.add_child(row)
 var left=VBoxContainer.new();left.custom_minimum_size.x=240;row.add_child(left)
 var hero=str(legacy.game.selected_hero) if legacy.arcade else str(legacy.game.selected_character)
 text(left,str(legacy.game.characters[hero].name),21).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var modes=HBoxContainer.new();left.add_child(modes)
 for mode in [false,true]:
  var b=button(modes,"Lobby" if mode else "Town",func():lobby_preview=mode;detail());b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 preview=Preview.new();preview.page=self;preview.name="AtelierHeroPreview";preview.custom_minimum_size=Vector2(240,275);preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;left.add_child(preview)
 text(left,"Competitive styles appear in multiplayer lobbies only. Preview them here without changing gameplay.",15).modulate=Color("#b8d7d6")
 var links=HBoxContainer.new();left.add_child(links)
 var weekly=button(links,"Weekly goals",func():close();legacy.close();legacy.weekly.open_board());weekly.tooltip_text="See goals for the existing activity rewards."
 button(links,"Titles",func():close();legacy.close();legacy.game.menu="journey_cosmetics")
 var centre=VBoxContainer.new();centre.custom_minimum_size.x=365;centre.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(centre)
 var tabs=TabBar.new();centre.add_child(tabs)
 for name in ["All styles","Earned","Competitive"]:tabs.add_tab(name)
 tabs.tab_changed.connect(func(n):filter=n;populate())
 catalogue_scroll=scroll_area(centre,"STYLE CATALOGUE","Scroll to browse • select a style",false)
 gallery=GridContainer.new();gallery.columns=1;gallery.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gallery.add_theme_constant_override("h_separation",8);gallery.add_theme_constant_override("v_separation",8);catalogue_scroll.add_child(gallery)
 var right=VBoxContainer.new();right.custom_minimum_size.x=420;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(right)
 detail_scroll=scroll_area(right,"SELECTED STYLE","Scroll for requirements, powers and progress",true)
 details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",14);detail_scroll.add_child(details)
 sync_label=text(shell,"",14);sync_label.modulate=Color("#a5c3c4")
 entries=catalogue();populate();manager.rankings.delay=0;layout()
func scroll_area(parent:Node,heading:String,hint:String,accent:bool)->ScrollContainer:
 var frame=PanelContainer.new();frame.name="StyleDetailsFrame" if accent else "StyleCatalogueFrame";frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
 frame.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#0c2530","#d8bd7c" if accent else "#6aadb8",10,12));parent.add_child(frame)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",7);frame.add_child(col)
 text(col,heading,16).modulate=Color("#f4d599" if accent else "#b2e4e9")
 text(col,hint,13).modulate=Color("#b9cfd4")
 var rule=HSeparator.new();col.add_child(rule)
 var scroll=ScrollContainer.new();scroll.name="StyleDetailsScroll" if accent else "StyleCatalogueScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.custom_minimum_size.y=360;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;col.add_child(scroll)
 var bar=scroll.get_v_scroll_bar();bar.custom_minimum_size.x=14
 for state in ["grabber","grabber_highlight","grabber_pressed"]:bar.add_theme_stylebox_override(state,preload("res://scripts/studio_ui.gd").box("#dbbf7d" if accent else "#7bbdca","#e4d19f" if accent else "#9fd5df",6,3))
 bar.add_theme_stylebox_override("scroll",preload("res://scripts/studio_ui.gd").box("#071b25","#32505b",6,3))
 preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 return scroll
func catalogue()->Array:
 var list=[{"id":"auto","name":"Automatic daily reward","need":"Show today’s completed Daily Mission effect."},{"id":"none","name":"No extra effect","need":"A clean look for your selected hero."},{"id":"daily","name":legacy.daily.reward_name(),"need":"Complete today’s Daily Mission. Available until local midnight."}]
 for n in 3:list.append({"id":C.IDS[n],"name":C.NAMES[n],"need":["Remain undefeated this week across solo and multiplayer adventures. Everyone starts the week eligible; your first death removes it until Monday.","Reach floor 50 in Cave Descent. Permanent unlock.","Clear Astral Rift and complete Attunement. Permanent unlock."][n]})
 for id in W.REWARDS:list.append({"id":id,"name":str(W.REWARDS[id].name),"need":legacy.weekly.goal_text(id)+(". No weekly reset; retain a top place to display it. Lobby only." if id in ["week_descent","week_market"] else ". Server comparison; lobby only. Weekly rankings reset Monday." if id in R.IDS else ". Resets Sunday on this device.")})
 for n in 3:list.append({"id":C.LODGE_IDS[n],"name":["Bronze Laurel","Silver Laurel","Golden Laurel"][n],"need":"Earn %d Challenge Lodge medal points. Permanent unlock." % [15,30,50][n]})
 list.append({"id":"lodge_week","name":"Weekly Lantern","need":"Complete all three featured Challenge Lodge trials this week."})
 list.append({"id":"easter","name":"Echo of the Four Paths","need":"Earn all four Expert realm badges. Permanent unlock."})
 list.append({"id":R.IDS[0],"name":"Vanguard Comets","need":"Be in the current top 5 for damage since Monday. Compared across connected profiles; resets Monday 00:00. Lobby only."})
 list.append({"id":R.IDS[1],"name":"Leviathan’s Wake","need":"Be in the current top 10 for the heaviest single fish (kg) caught this week. Kept and released catches count. Resets Monday 00:00. Lobby only."})
 list.append({"id":R.IDS[2],"name":"Eternal Constellation","need":"Be in the current top 5 for lifetime damage across connected profiles. No weekly reset; stays visible while you hold a top-five place. Lobby only."})
 list.insert(2,{"id":"crown","name":"Damage Crown","need":"Your current rolling seven-day damage crown. Keep playing to maintain it; expired crowns cannot be worn. Hide or show it in town without changing crown power or lobby display."})
 return list
func earned(id:String)->bool:return legacy.crowns.total()>=1000 if id=="crown" else id in manager.rankings.badges() if id in R.IDS else manager.eligible(id)
func populate()->void:
 for node in gallery.get_children():gallery.remove_child(node);node.queue_free()
 for spec in entries:
  var id=str(spec.id)
  if filter==1 and not earned(id) or filter==2 and id not in R.IDS:continue
  var tile=button(gallery,"",func():selected=id;lobby_preview=id in R.IDS;detail())
  tile.custom_minimum_size=Vector2(280,76);tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.tooltip_text=str(spec.need);tile.set_meta("style_id",id)
  if id==selected:tile.add_theme_stylebox_override("normal",preload("res://scripts/studio_ui.gd").box("#315562","#edcd88",8,12))
  var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.offset_left=8;row.offset_top=6;row.offset_right=-8;row.offset_bottom=-6;tile.add_child(row)
  var art=Swatch.new();art.id=id;art.page=self;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.custom_minimum_size=Vector2(52,52);row.add_child(art)
  var words=VBoxContainer.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
  text(words,str(spec.name),16).mouse_filter=Control.MOUSE_FILTER_IGNORE
  var rank_label=("Hidden in town" if bool(manager.state().get("hide_town_crown",false)) else "Shown in town") if id=="crown" and earned(id) else "Eligible • lobby style" if id in R.IDS and earned(id) else "Equipped" if str(manager.state().selected)==id and earned(id) else "Available" if earned(id) else "Locked • tap to inspect"
  text(words,rank_label,13).modulate=Color("#dcd092") if earned(id) else Color("#a4babf")
 detail()
func detail()->void:
 for tile in gallery.get_children():tile.add_theme_stylebox_override("normal",preload("res://scripts/studio_ui.gd").box("#315562" if str(tile.get_meta("style_id",""))==selected else "#294653","#edcd88" if str(tile.get_meta("style_id",""))==selected else "#577a82",8,12))
 if is_instance_valid(detail_scroll):detail_scroll.scroll_vertical=0
 for node in details.get_children():details.remove_child(node);node.queue_free()
 var spec:Dictionary={}
 for entry in entries:
  if str(entry.id)==selected:spec=entry;break
 if spec.is_empty():return
 text(details,str(spec.name),22).modulate=Color("#f4d599")
 if selected in R.IDS:text(details,"LIVE SERVER RANKING • lobby style",13).modulate=Color("#aacfd2")
 text(details,str(spec.need),16)
 if selected=="crown":
  button(details,"Show crown in town" if bool(manager.state().get("hide_town_crown",false)) else "Hide crown in town",func():manager.state().hide_town_crown=not bool(manager.state().get("hide_town_crown",false));legacy.save();detail())
  legacy.crowns.ui(details)
 elif selected in R.IDS:
  var key=R.RANK_KEYS[selected];var rank=manager.rankings.snapshot.get("ranks",{}).get(key,null)
  text(details,("Your current position: #"+str(int(rank)) if rank!=null and manager.rankings.fresh() else "Connect to compare this profile")+" • server comparison refreshed every minute",14)
  if selected=="week_arena_1" and manager.rankings.fresh() and int(manager.rankings.snapshot.get("pennant",0))>0:
   text(details,["Bronze pennant • Top 30","Silver pennant • Top 15","Gold pennant • Top 5"][clampi(int(manager.rankings.snapshot.pennant),1,3)-1],16).modulate=Color("#e3cc94")
  var b=button(details,("Hide in lobbies" if manager.rankings.enabled(selected) else "Show in lobbies") if earned(selected) else "Not currently eligible • preview only",func():manager.rankings.toggle(selected);detail());b.disabled=not earned(selected)
 else:
  var b=button(details,"Equipped" if str(manager.state().selected)==selected and earned(selected) else "Equip this style" if earned(selected) else "Locked • preview only",func():manager.select(selected);populate());b.disabled=not earned(selected) or str(manager.state().selected)==selected
func layout()->void:
 var size=legacy.game.get_viewport_rect().size;panel.size=Vector2(1160,670);var logical=panel.get_combined_minimum_size().max(Vector2(1160,670));panel.size=logical;var fit=minf(1,minf((size.x-20)/logical.x,(size.y-20)/logical.y));panel.scale=Vector2.ONE*fit;panel.position=(size-panel.size*fit)*.5
func _process(delta:float)->void:
 if manager==null:return
 clock+=delta;layout();preview.queue_redraw()
 for child in gallery.get_children():
  for art in child.find_children("*","Control",true,false):
   if art is Swatch:art.queue_redraw()
 sync_label.text=manager.rankings.status+" • Ranked week: "+manager.rankings.week()+" • Resets Monday"
 refresh+=delta
 if refresh>=1:
  refresh=0;var current=JSON.stringify(manager.rankings.badges())+str(manager.state().selected)+str(legacy.crowns.display_tier())+str(manager.competitive.state().defeated)+manager.rankings.week()
  if current!=signature:signature=current;populate()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func close()->void:
 legacy.game.menu=previous;legacy.game.mobile.reset_controls();manager.atelier=null;queue_free()
