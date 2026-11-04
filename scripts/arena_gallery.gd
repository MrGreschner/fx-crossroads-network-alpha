extends HBoxContainer
const INFO={
 "shatterfloor":["Shatterfloor","SURVIVAL • SHOVES + HOPS","Three collapsing floors. Stepping on a tile starts a visible crack timer. Keep moving, shove rivals off their route and hop across gaps. Equal speed and shared controls for every hero; no health damage or hero abilities. Three short rounds; survival placement earns points. Up to eight players, FFA / teams / AI."],
 "sand":["Sinking Sands","TERRAIN • OPEN DUELS","Wide sightlines with slowing sand pits. Easy to learn; every route stays open."],
 "crossroads":["Crossroads Coliseum","PVE + PVP • LARGE MAP","The town-scale coliseum: woodland cover, long paths and roaming enemies alongside rival heroes."],
 "storm":["Stormcoil Pit","HAZARDS • KEEP MOVING","Patrolling storm drones warn before striking. Avoid the expanding electrical fields."],
 "forest":["Wildbloom Glade","PVE + PVP • WOODLAND COVER","Dense groves surround two broad crossing clearings. Fight creatures and rival heroes between trees while avoiding fire-spitting blooms."],
 "clock":["Clockwork Crucible","TIMING • GEAR OVERLOADS","Glowing gears charge wide paired lightning lanes across the map. Amber is the warning; blue lanes stay live briefly. Leave the marked lanes before the gears strike."],
 "maze":["Shifting Labyrinth","CLOSE COMBAT • TIMED GATES","All 17 gates shift on staggered cycles of 14 seconds. Amber panels close, red gates block heroes and creatures, teal passages open. Wait for a gate to shift to reach an enemy beyond it. Two chambers still have creature ambushes."],
 "lanternfall":["Lanternfall","MYSTERY • NEW TERRAIN EACH MATCH","Your light slowly fades. Walk over torches to restore sight. Cliffs block heroes but shots fly across them. Follow the directional echo beacon: faster pulses mean danger is closer. No player-location minimap."],
 "colour_clash":["Colour Clash","TERRITORY • MOVEMENT + COMBAT","Paint the floor by walking. Slower heroes paint wider trails; movement bursts have a painting limit. Hold the two paint beacons, steal enemy tiles and flip nearby territory when you defeat a rival. Most floor after five minutes wins. FFA or teams, up to eight players."],
 "crown_chase":["Crown Chase","KEEP-AWAY • PASS + PURSUE","Carry the crown to score time. It gradually slows you, so escort your carrier or throw it to an ally with E or the on-screen button. Intercept throws and chase the broadcast crown. Most carrying time after five minutes wins. FFA or teams, up to eight players."]}
const STYLES={"crossroads":["PVE + PVP","#8cc397"],"sand":["DUELS","#d9bf87"],"storm":["HAZARDS","#8ac9e9"],"forest":["PVE + PVP","#8cc397"],"clock":["TIMING","#b3ade9"],"maze":["LABYRINTH","#d9bf87"],"lanternfall":["EXPLORATION","#b3ade9"],"colour_clash":["PAINT TERRITORY","#ef9fa5"],"crown_chase":["KEEP-AWAY","#efd080"],"shatterfloor":["FLOOR SURVIVAL","#8cddcc"]}
const SHORT={"sand":"Slow sand changes your routes. Defeat rival heroes to score.","crossroads":"Explore woodland paths, fight creatures and duel rival heroes.","storm":"Drones mark danger before striking. Keep moving and fight back.","forest":"Fight creatures and rival heroes while dodging fire-spitting blooms.","clock":"Watch lightning warnings and time your crossings between attacks.","maze":"Timed gates change close-combat routes. Watch for chamber ambushes.","lanternfall":"Explore randomized darkness. Relight at torches and follow the enemy echo.","colour_clash":"Walk to paint; hold beacons to spread your colour. Most floor at five minutes wins.","crown_chase":"Carry the crown to score time. Pass with E; intercept throws. Most time wins.","shatterfloor":"Three collapsing floors. Shove and hop; equal speed, no health damage. Three-round survival score wins."}
const RULES={"sand":["CROSS SLOW SAND","OUTMANOEUVRE RIVALS","SCORE KOs"],"crossroads":["EXPLORE THE TOWN","FIGHT CREATURES","DUEL RIVALS"],"storm":["WATCH DRONES","DODGE WARNINGS","KEEP MOVING"],"forest":["FIND CLEARINGS","DODGE FIRE BLOOMS","FIGHT FOES"],"clock":["WATCH THE STRIPES","TIME YOUR CROSSING","STRIKE BACK"],"maze":["CHOOSE A CHAMBER","WATCH TIMED GATES","SURVIVE AMBUSHES"],"lanternfall":["EXPLORE THE DARK","RELIGHT AT TORCHES","FOLLOW THE ECHO"],"colour_clash":["WALK TO PAINT","CLAIM BEACONS","MOST FLOOR WINS"],"crown_chase":["GRAB THE CROWN","PASS OR INTERCEPT","CARRY TIME WINS"],"shatterfloor":["STEP / CRACK","SHOVE + HOP","SURVIVE 3 ROUNDS"]}
var game:Node
var cards:Dictionary={}
var title:Label
var detail:Label
var badge:Label
var preview:Control
var rules:Control
var last=""
var maps_scroll:ScrollContainer
class RuleStrip extends Control:
 var map="sand"
 func _draw()->void:
  var items=RULES.get(map,RULES.sand);var w=size.x/3
  for n in 3:
   var p=Vector2(n*w+3,4);var tint=Color(STYLES.get(map,STYLES.sand)[1]);draw_style_box(preload("res://scripts/studio_ui.gd").box("#102733","#3d6471",6,4),Rect2(p,Vector2(w-6,54)))
   var at=p+Vector2(19,20)
   if map=="shatterfloor":
    if n==0:draw_rect(Rect2(at-Vector2(10,7),Vector2(23,15)),tint);draw_line(at-Vector2(4,7),at+Vector2(5,7),Color("#243541"),2)
    elif n==1:draw_arc(at,12,PI,TAU,20,tint,3);draw_line(at+Vector2(12,0),at+Vector2(19,0),tint,3)
    else:
     for k in 3:draw_line(at+Vector2(-11,k*4-6),at+Vector2(14,k*4-6),tint,2)
   else:
    draw_arc(at,11,0,TAU,24,tint,2);draw_string(ThemeDB.fallback_font,at+Vector2(-4,5),str(n+1),HORIZONTAL_ALIGNMENT_LEFT,20,15,tint)
   draw_string(ThemeDB.fallback_font,p+Vector2(8,46),items[n],HORIZONTAL_ALIGNMENT_LEFT,w-18,11,tint)
class MapPreview extends Control:
 var map="sand"
 var detailed=false
 func _draw()->void:
  var area=Rect2(Vector2(8,8),size-Vector2(16,16))
  draw_style_box(preload("res://scripts/studio_ui.gd").box("#142e3b","#6b9199",8,0),area)
  var names=["crossroads","sand","storm","forest","clock","maze","lanternfall","colour_clash","crown_chase","shatterfloor"]
  var n=maxi(0,names.find(map))
  var t=preload("res://scripts/arena_art261.gd").region("previews","preview:"+map,Rect2(n%2*320,n/2*180,320,180))
  var fit=Vector2(320,180)*minf((area.size.x-6)/320,(area.size.y-6)/180)
  draw_texture_rect(t,Rect2(area.get_center()-fit*.5,fit),false)

func _ready()->void:
 name="ArenaGallery";add_theme_constant_override("separation",12);size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var scroll=ScrollContainer.new();maps_scroll=scroll;scroll.name="ArenaMapsScroll";scroll.custom_minimum_size=Vector2(210,286);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for id in game.arena_world.MAPS:
  var card=Button.new();card.custom_minimum_size=Vector2(190,139);card.tooltip_text=str(INFO[id][2]);list.add_child(card);cards[id]=card
  var image=MapPreview.new();image.map=id;image.position=Vector2(4,4);image.size=Vector2(186,85);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(image)
  var label=Label.new();label.text=str(INFO[id][0]);label.position=Vector2(9,92);label.add_theme_font_size_override("font_size",13);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(label)
  var style=Label.new();style.text=str(STYLES[id][0]);style.position=Vector2(9,114);style.add_theme_font_size_override("font_size",10);style.modulate=Color(STYLES[id][1]);style.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(style)
  card.pressed.connect(func():
   if game.net_ready and not game.net_host:return
   game.test_arena.select(game.arena_world.MAPS.keys().find(id));game._test_arena_changed(game.test_arena.selected);refresh())
 var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#152f3b","#63858f",9,12));add_child(panel)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",4);panel.add_child(body)
 var heading=Label.new();heading.text="CHOOSE YOUR PLAY STYLE • %d ARENAS" % game.arena_world.MAPS.size();heading.add_theme_font_size_override("font_size",13);heading.modulate=Color("#8fc5cb");body.add_child(heading)
 title=Label.new();title.add_theme_font_size_override("font_size",22);body.add_child(title)
 badge=Label.new();badge.add_theme_font_size_override("font_size",12);badge.modulate=Color("#f4d395");body.add_child(badge)
 preview=MapPreview.new();preview.detailed=true;preview.custom_minimum_size=Vector2(210,95);preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(preview)
 rules=RuleStrip.new();rules.custom_minimum_size=Vector2(210,60);rules.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(rules)
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",13);body.add_child(detail)
 var hint=Label.new();hint.text="Scroll cards to explore • FFA / teams / AI practice";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",12);hint.modulate=Color("#a6bdc3");body.add_child(hint)
 refresh()
func refresh()->void:
 if not is_instance_valid(title):return
 var chosen=str(game.test_arena.get_item_metadata(game.test_arena.selected));chosen=chosen if INFO.has(chosen) else "sand"
 for id in cards:
  cards[id].disabled=game.net_ready and not game.net_host
  for state in ["normal","hover","pressed","focus","disabled"]:cards[id].add_theme_stylebox_override(state,preload("res://scripts/studio_ui.gd").box("#315661" if id==chosen else "#1a3442","#f2ce85" if id==chosen else "#537780",7,3))
 title.text=INFO[chosen][0];badge.text=INFO[chosen][1]+(" • HOST CHOOSES" if game.net_ready and not game.net_host else "");detail.text=SHORT[chosen];detail.tooltip_text=INFO[chosen][2];preview.map=chosen;preview.queue_redraw();rules.map=chosen;rules.queue_redraw()
 if last!=chosen:maps_scroll.call_deferred("ensure_control_visible",cards[chosen])
 last=chosen
