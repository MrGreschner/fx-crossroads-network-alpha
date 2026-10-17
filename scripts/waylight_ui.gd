extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/waylight_catalog.gd")
var manager:Node
var panel:PanelContainer
var previous=""
var tab=0
var tier=1
var notice=""
var countdown:Label
var rendered_day=-1
var selected_realm="grove"
class RelicIcon extends Control:
 var type="stormglass"
 func _draw()->void:
  var spec=C.RELICS[type];var c=Color(spec.color);var p=size*.5;var radius=minf(size.x,size.y)*.34
  draw_circle(p,radius*1.35,Color(c,.08));draw_arc(p,radius*1.2,0,TAU,40,Color(c,.5),1.5,true)
  match spec.kind:
   "comb":
    for offset in [Vector2(-10,-6),Vector2(10,-6),Vector2(0,11)]:draw_arc(p+offset,radius*.44,0,TAU,6,c,3,true)
   "vial":
    draw_style_box(UI.box(spec.color,"#f7e8bb",5,1),Rect2(p+Vector2(-radius*.45,-radius*.4),Vector2(radius*.9,radius*1.2)));draw_rect(Rect2(p+Vector2(-radius*.22,-radius),Vector2(radius*.44,radius*.6)),c)
   "sun":
    draw_circle(p,radius*.5,c)
    for n in 8:
     var dir=Vector2.from_angle(n*TAU/8);draw_line(p+dir*radius*.7,p+dir*radius,c,2,true)
   "bolt":draw_colored_polygon(PackedVector2Array([p+Vector2(3,-radius),p+Vector2(-radius*.5,2),p+Vector2(0,2),p+Vector2(-3,radius),p+Vector2(radius*.5,-3),p+Vector2(1,-3)]),c)
   "fire":draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius*.7,0),p+Vector2(radius*.4,radius),p+Vector2(-radius*.6,radius*.6),p+Vector2(-radius*.8,-radius*.1),p+Vector2(-radius*.2,radius*.2)]),c)
   "pearl":draw_circle(p,radius*.7,c);draw_circle(p-Vector2(radius*.2,radius*.25),radius*.22,Color("#f5f1d8"));draw_arc(p,radius,-.2,PI+.2,28,c,3,true)
   "snow":
    for n in 6:
     var dir=Vector2.from_angle(n*TAU/6);draw_line(p,p+dir*radius,c,3,true);draw_line(p+dir*radius*.55,p+dir.rotated(.35)*radius*.85,c,2,true)
   "thorns":
    draw_arc(p,radius*.75,0,TAU,32,c,4,true)
    for n in 7:
     var dir=Vector2.from_angle(n*TAU/7);draw_line(p+dir*radius*.65,p+dir.rotated(.2)*radius*1.1,c,3,true)
   "seed":draw_circle(p,radius*.65,c);draw_line(p,p-Vector2(0,radius),Color("#e6dfa0"),3,true);draw_arc(p-Vector2(radius*.3,radius*.6),radius*.35,PI,TAU,16,c,4,true)
   "fish":
    draw_colored_polygon(PackedVector2Array([p+Vector2(-radius,0),p+Vector2(-radius*.3,-radius*.5),p+Vector2(radius*.7,-radius*.3),p+Vector2(radius,0),p+Vector2(radius*.7,radius*.4),p+Vector2(-radius*.3,radius*.5)]),c)
    draw_circle(p+Vector2(radius*.6,-radius*.1),3,Color("#173347"));draw_line(p+Vector2(-radius*.7,-radius*.6),p+Vector2(-radius*.7,radius*.6),c,3)
   _:draw_colored_polygon(PackedVector2Array([p-Vector2(0,radius),p+Vector2(radius*.8,-radius*.2),p+Vector2(radius*.5,radius*.8),p+Vector2(-radius*.4,radius),p-Vector2(radius*.8,radius*.2)]),c);draw_line(p-Vector2(0,radius*.8),p+Vector2(radius*.2,radius*.7),Color("#fff1d0"),2,true)
func text(parent:Node,value:String,size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,value:String,call:Callable)->Button:
 var b=Button.new();b.text=value;b.custom_minimum_size.y=44;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(call);return b
func setup(owner:Node,selected:int)->void:
 manager=owner;tab=selected;layer=93;previous=manager.game.menu;manager.game.menu="waylight";manager.game.mobile.reset_controls();build()
func close()->void:
 if manager.game.menu=="waylight":manager.game.menu=previous
 manager.window=null;queue_free()
func feedback(value:String)->void:
 if value.is_empty():return
 notice=value;rebuild()
func confirm(title:String,description:String,call:Callable)->void:
 var d=ConfirmationDialog.new();d.title=title;d.dialog_text=description;add_child(d);d.confirmed.connect(func():d.queue_free();call.call());d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(490,220))
func build()->void:
 for child in get_children():remove_child(child);child.queue_free()
 rendered_day=manager.today();countdown=null
 var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(.02,.05,.08,.97);add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);panel.add_theme_stylebox_override("panel",UI.box("#102c38","#bba777",12,14));add_child(panel)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",7);panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header);text(header,"THE CROSSING • PORTAL EXPEDITIONS",22)
 var close_button=button(header,"Close",close);close_button.size_flags_horizontal=0;close_button.custom_minimum_size=Vector2(90,34)
 var s=manager.progress.state()
 text(body,"%d Waylight Shards    •    %d Waydust    •    %s" % [s.shards,s.dust,"Attuned" if s.attuned else "Attunement awaits"],16).modulate=Color("#edd6a2")
 if not notice.is_empty():text(body,notice,15).modulate=Color("#b6dfd4")
 if not s.run.is_empty():
  var row=HBoxContainer.new();body.add_child(row)
  text(row,"Expedition saved • "+str(C.NAMES.get(s.run.realm,"The Between")),15)
  button(row,"Resume",func():feedback(manager.resume()))
  button(row,"Forfeit…",func():confirm("Forfeit expedition?","Started overcharge entry is not refunded. The Between banks half your last saved haul. Unstarted co-op reservations refund.",func():feedback(manager.forfeit())))
 if bool(manager.game.legacy.data.get("teacher",false)):
  var dev=HBoxContainer.new();body.add_child(dev)
  button(dev,"DEV • expedition kit",func():manager.dev_kit();rebuild())
  button(dev,"DEV • next day",func():manager.utc_for_test=manager.now()+86400;rebuild())
 var between_open=manager.progress.between_unlocked();var over_open=bool(s.attuned) or manager.progress.blocked()
 if tab==3:tab=1
 if tab==1 and not between_open or tab==2 and not over_open:tab=0
 var nav=HBoxContainer.new();nav.name="PortalRoutes";nav.add_theme_constant_override("separation",8);body.add_child(nav)
 var small=manager.game.VIEW.y<500
 for n in 3:
  var locked=n==1 and not between_open or n==2 and not over_open
  var tile=Button.new();tile.clip_contents=true;tile.name=["RealmsRoute","BetweenRoute","OverchargeRoute"][n];tile.toggle_mode=true;tile.button_pressed=tab==n;tile.disabled=locked;tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.custom_minimum_size.y=68 if small else 100;nav.add_child(tile)
  tile.tooltip_text="Clear Sunfield Expanse or Frostbound Rink." if n==1 and locked else "Complete Portal Attunement in The Between." if n==2 and locked else ["Hand-built adventures, solo or co-op.","Gather shards in a changing world.","Today's charged realm; personal entry fee."][n]
  var inset=MarginContainer.new();inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);inset.add_theme_constant_override("margin_left",8);inset.add_theme_constant_override("margin_right",8);inset.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.add_child(inset)
  var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;inset.add_child(row)
  var icon=preload("res://scripts/portal_route_art.gd").new();icon.variant=n;icon.muted=locked;icon.custom_minimum_size=Vector2(42,54) if small else Vector2(76,84);row.add_child(icon)
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.size_flags_vertical=Control.SIZE_SHRINK_CENTER;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col)
  text(col,["REALMS","THE BETWEEN","OVERCHARGE REALM"][n],14 if small else 17).mouse_filter=Control.MOUSE_FILTER_IGNORE
  text(col,("Sunfield or Frostbound clear" if n==1 else "Attunement required") if locked else ["Start your journey","Explore • gather shards","Today's challenge"][n],11 if small else 13).mouse_filter=Control.MOUSE_FILTER_IGNORE
  if locked:tile.modulate=Color("#839193")
  tile.pressed.connect(func():tab=n;rebuild())
  if n==tab:UI.accent(tile)
 var area=HBoxContainer.new();area.name="PortalContent";area.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(area)
 if tab==0:standard(area)
 else:
  var scroll=ScrollContainer.new();scroll.name="ExpeditionDetailsScroll";scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;area.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(col)
  if tab==1:between_ui(col)
  else:overcharge_ui(col)
 fit()
func standard(area:Node)->void:
 var left=VBoxContainer.new();left.custom_minimum_size.x=200 if manager.game.VIEW.x<950 else 250;area.add_child(left)
 text(left,"REALMS • scroll to browse",15)
 var scroll=ScrollContainer.new();scroll.name="RealmListScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;left.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 var active_index=0;var index=0
 for id in manager.game.manifest.regions:
  if id in ["town","practice","first_steps","mistglass_rift","between"]:continue
  var data=manager.game.realms.get(id,{})
  if data.is_empty():continue
  var unlocked=preload("res://scripts/realm_access.gd").unlocked(manager.game.legacy,str(id))
  var entry=button(list,("" if unlocked else "○ ")+str(data.get("name",id)),func():selected_realm=str(id);rebuild());entry.name="Realm_"+str(id);entry.toggle_mode=true;entry.button_pressed=selected_realm==str(id);entry.add_theme_font_size_override("font_size",15);entry.custom_minimum_size.y=37
  if not unlocked:entry.modulate=Color("#9cacaf")
  if selected_realm==str(id):active_index=index;UI.accent(entry)
  index+=1
 scroll.set_deferred("scroll_vertical",maxi(0,(active_index-2)*44))
 var details=ScrollContainer.new();details.name="RealmDetailsScroll";details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;area.add_child(details);preload("res://scripts/touch_list_scroll.gd").attach(details)
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_child(col)
 var data=manager.game.realms.get(selected_realm,{})
 text(col,str(data.get("name",selected_realm)),24)
 text(col,str(data.get("difficulty_label","Explore"))+" • Solo or 2-player co-op",16).modulate=Color("#e3cc95")
 var unlocked=preload("res://scripts/realm_access.gd").unlocked(manager.game.legacy,selected_realm)
 text(col,str(data.get("description","Discover its creatures and defeat its guardian.")) if unlocked else preload("res://scripts/realm_access.gd").reason(manager.game.legacy,selected_realm),16)
 var actions=HBoxContainer.new();col.add_child(actions)
 var solo=button(actions,"Enter solo",func():close();manager.game.legacy.close();manager.game.start_run(false,selected_realm));UI.accent(solo)
 var co=button(actions,"Co-op • 2 players",func():feedback(manager.launch_coop(selected_realm)))
 solo.disabled=not unlocked or not manager.progress.state().run.is_empty();co.disabled=solo.disabled
 var art=preload("res://scripts/realm_landscape.gd").new();art.realm=selected_realm;art.game=manager.game;art.name="RealmLandscape";art.custom_minimum_size=Vector2(0,125);col.add_child(art)
 var fair=CheckButton.new();fair.text="Competition rules • relics disabled";fair.button_pressed=bool(manager.progress.state().fair);col.add_child(fair);fair.toggled.connect(func(on:bool):manager.progress.state().fair=on;manager.progress.save())
 text(col,"First visit? Start with Whispering Grove. Select any realm on the left to see its route and unlock requirements.",15)
func between_ui(col:Node)->void:
 var reach=preload("res://scripts/between_access.gd").depth(manager.game.legacy)
 text(col,"PORTAL STRENGTH • ring %d • co-op follows the host" % reach,18)
 text(col,preload("res://scripts/between_access.gd").next(manager.game.legacy),15)
 var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",8);col.add_child(actions)
 var b=button(actions,"Explore solo",func():feedback(manager.launch("between")));UI.accent(b);b.disabled=not manager.progress.state().run.is_empty()
 var co=button(actions,"Explore together • co-op",func():feedback(manager.launch_coop("between")));co.disabled=b.disabled
 var trial=button(actions,"Attunement Challenge",func():feedback(manager.launch("attunement")));trial.name="TrialLaunch";trial.disabled=not manager.progress.can_attune() or b.disabled;trial.tooltip_text="Replay for bonus shards" if manager.progress.state().attuned else "Solo level-10 trial • collect six Crossing Seals";UI.accent(trial)
 var box=UI.card(col,"THE BETWEEN","Grove, Quarry and Frostbound fragments form a fresh expedition. Realm milestones add Silverfall, Lantern Marsh and Astral biomes as the portal strengthens. Follow connected crossings into darkness; farther rings bring tougher foes and richer Waylight deposits (5–10 shards, depending on distance).")
 text(box,"Walk over an unguarded crystal to gather it. Defeat guardians for more. Return to the luminous entrance and Interact to bank your whole haul. Defeat banks half. Resume an interrupted expedition from this menu.")
 text(box,"Solo or two-player expedition • outward difficulty scales with portal strength. Co-op shares one map and haul; return together to bank it for each player.",15)
 attunement_ui(col)
 text(col,"Overcharge entry costs 100 / 200 / 300 shards. An early deposit yields 5; deeper crossings offer more. Bank several short trips or risk a longer expedition. Remote fishing waters may appear from ring 4 onward; combat stays live while you fish.")
 text(col,"Best depth: ring %d • successful expeditions: %d" % [manager.progress.state().best_ring,manager.progress.state().expeditions])
func overcharge_ui(col:Node)->void:
 var day=manager.today();var realm=C.featured(day);var s=manager.progress.state();var unlocked=preload("res://scripts/realm_access.gd").unlocked(manager.game.legacy,realm)
 var box=UI.card(col,"TODAY • OVERCHARGED "+str(C.NAMES[realm]).to_upper(),"Only this realm can be overcharged today. Every new attempt costs shards. There are no daily free entries; normal realm unlock requirements still apply.")
 countdown=text(box,"",16);update_countdown()
 var row=HBoxContainer.new();box.add_child(row);var picker=OptionButton.new();picker.custom_minimum_size=Vector2(260,44);row.add_child(picker)
 for n in 3:picker.add_item("Tier %d • %d shards • %d%% relic chance" % [n+1,C.COSTS[n],C.CHANCES[n]*100])
 picker.select(tier-1);picker.item_selected.connect(func(i:int):tier=i+1;rebuild())
 text(box,"Defeat the original realm boss, then use its exit. Optional charged packs, springs and rituals award extra Waydust on completion. Bosses also gain a marked surge attack.")
 if not unlocked:text(box,preload("res://scripts/realm_access.gd").reason(manager.game.legacy,realm)).modulate=Color("#e8bd98")
 if tier>1 and (not s.attuned or int(s.best_ring)<(tier-1)*3):text(box,"Tier %d requires attunement and a banked expedition reaching ring %d." % [tier,(tier-1)*3])
 text(box,"Eligible for relics • %d / 10 unsuccessful clears toward a guaranteed drop in this realm." % int(s.pity.get(realm,0)) if s.attuned else "Complete Portal Attunement to unlock this route.",16)
 var b=button(box,"Activate • %d Waylight Shards" % C.COSTS[tier-1],func():confirm("Activate this overcharge?","Spend %d shards for one attempt. Defeat ends the attempt; resuming an interrupted run costs nothing extra.%s" % [C.COSTS[tier-1]," Relic drops are currently locked." if not s.attuned else " Relics are a chance, not guaranteed."],func():feedback(manager.launch("overcharge",tier) if manager.today()==day else "The daily rotation changed. Reopen its new preview before paying.")))
 b.disabled=(not s.attuned and not manager.progress.blocked()) or not unlocked or int(s.shards)<C.COSTS[tier-1] or not s.run.is_empty() or (tier>1 and (not s.attuned or int(s.best_ring)<(tier-1)*3))
 var co=button(box,"Overcharge together • %d shards EACH" % C.COSTS[tier-1],func():feedback(manager.launch_coop("overcharge",tier)));co.disabled=b.disabled
 text(box,"Both players must meet entry requirements and confirm their own payment. Relic rolls and pity belong to each profile.",16)
 text(col,"Today's relic family",22)
 for id in C.FAMILIES[realm]+["stormglass"]:relic_preview(col,str(id))
 text(col,"Rare Waylight Conclave • 12% encounter chance. Defeat its four champions and finish the realm for +3 Waydust and a separate 35% rank-1 Conclave-forged relic roll. Ordinary boss drops and pity remain unchanged.",16)
 text(col,"Upcoming crossings",21)
 for n in range(1,4):text(col,Time.get_date_string_from_unix_time((day+n)*86400)+" • "+str(C.NAMES[C.featured(day+n)]),16)
func relic_preview(parent:Node,type:String)->void:
 var row=HBoxContainer.new();parent.add_child(row);var icon=RelicIcon.new();icon.type=type;icon.custom_minimum_size=Vector2(74,74);row.add_child(icon)
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col);text(col,C.RELICS[type].name,20).modulate=Color(C.RELICS[type].color);text(col,C.RELICS[type].effect,16)
func attunement_ui(col:Node)->void:
 var p=manager.progress;var s=p.state()
 var box=UI.card(col,"ATTUNEMENT CHALLENGE" if not s.attuned else "ATTUNEMENT • REPEATABLE TRIAL","A dedicated solo Between expedition. Begin at combat level 10 with your hero's abilities. Six elite Wardens hold Crossing Seals across rings 3–5. Defeat each Warden, collect all six seals, then return to the entrance and extract.")
 text(box,"First completion: unlock Overcharged Realms and relic drop eligibility.",16)
 text(box,"Every successful six-seal extraction: +60% of carried shards within 10 minutes, +40% within 15 minutes, or +25% at any pace. Bonus capped at 60 shards. No bonus on defeat or an incomplete trial; no guaranteed relic.",16)
 text(box,"Solo only • seals are tracked on your map and saved with the run • timer pauses with menus",15)
 if s.attuned:text(box,"ATTUNED • overcharge remains unlocked",18).modulate=Color("#eddda1")
func update_countdown()->void:
 if not is_instance_valid(countdown):return
 var utc=manager.now();var offset=preload("res://scripts/town_clock_math.gd").edmonton_offset(utc);var left=maxi(0,int((manager.today()+1)*86400-offset-utc))
 countdown.text="Rotation changes in %02d:%02d:%02d • shared town clock" % [left/3600,(left%3600)/60,left%60]
func fit()->void:
 var view=manager.game.get_viewport_rect().size;panel.size=Vector2(minf(1150,view.x-24),minf(690,view.y-24));panel.position=(view-panel.size)*.5
func _process(_delta:float)->void:
 fit();update_countdown()
 if rendered_day!=manager.today():build()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()

func rebuild()->void:call_deferred("build")
