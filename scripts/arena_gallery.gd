extends HBoxContainer
const INFO={
 "shatterfloor":["Shatterfloor","SURVIVAL • SHOVES + HOPS","Three collapsing floors. Stepping on a tile starts a visible crack timer. Keep moving, shove rivals off their route and hop across gaps. Equal speed and shared controls for every hero; no health damage or hero abilities. Three short rounds; survival placement earns points. Up to eight players, FFA / teams / AI."],
 "sand":["Sinking Sands","TERRAIN • OPEN DUELS","Wide sightlines with slowing sand pits. Easy to learn; every route stays open."],
 "crossroads":["Crossroads Coliseum","PVE + PVP • LARGE MAP","The town-scale coliseum: woodland cover, long paths and roaming enemies alongside rival heroes."],
 "storm":["Stormcoil Pit","HAZARDS • KEEP MOVING","Patrolling storm drones warn before striking. Avoid the expanding electrical fields."],
 "forest":["Wildbloom Glade","PVE + PVP • LIVING HAZARDS","A forest arena with creatures and fire-spitting blooms. Use the open clearings between attacks."],
 "clock":["Clockwork Crucible","TIMING • LIGHTNING LANES","Crossing strike lanes reward good timing. Watch the warning stripes before lightning lands."],
 "maze":["Shifting Labyrinth","CLOSE COMBAT • TIMED GATES","Tight stone chambers and shifting gates. Amber warns before a gate closes; teal means open. Two ambush chambers trap visitors until the fight ends or the 14-second safety timer expires."],
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
  var area=Rect2(Vector2(8,8),size-Vector2(16,16));draw_style_box(preload("res://scripts/studio_ui.gd").box("#142e3b","#6b9199",8,0),area)
  if map=="shatterfloor" and detailed:
   var unit=minf(area.size.x/42,area.size.y/6.2)
   for layer in 3:
    var base=Vector2(area.position.x+area.size.x*(.04+layer*.33),area.position.y+12)
    var tint=[Color("#76cebc"),Color("#8296dc"),Color("#d6a063")][layer]
    for y in 3:
     for x in 10:
      if layer==0 and (x+y*3)%8==0:continue
      var p=base+Vector2(x,y)*unit;draw_rect(Rect2(p,Vector2(unit-1,unit-1)),tint.darkened(.25))
      if (x+y)%5==0:draw_line(p+Vector2(2,1),p+Vector2(unit*.6,unit-2),Color("#f9e0a0"),1.5)
    var runner=base+Vector2(5.3,.4)*unit;draw_circle(runner,unit*.4,Color("#ffe9ae"));draw_arc(runner+Vector2(unit*1.5,-unit*.4),unit*.75,PI,TAU,20,Color("#e5f5ed"),2)
    draw_string(ThemeDB.fallback_font,base+Vector2(0,unit*3+15),["01 • JADE","02 • TWILIGHT","03 • LAST CHANCE"][layer],HORIZONTAL_ALIGNMENT_LEFT,area.size.x*.31,11,tint)
   return
  if map=="shatterfloor":
   var unit=minf(area.size.x/18,area.size.y/9);var origin=area.get_center()-Vector2(6,2.8)*unit
   for layer in [2,1,0]:
    var base=origin+Vector2(layer*.65,layer*.8)*unit
    var tint=[Color("#76cebc"),Color("#8296dc"),Color("#d6a063")][layer]
    for y in 4:
     for x in 11:
      if layer==0 and (x+y*3)%9 in [0,1]:continue
      var p=base+Vector2(x,y)*unit;draw_rect(Rect2(p,Vector2.ONE*(unit-1)),tint.darkened(.35))
      if layer==0 and (x+y)%4==0:draw_polyline(PackedVector2Array([p+Vector2(2,1),p+Vector2(unit*.6,unit*.4),p+Vector2(unit*.35,unit*.6),p+Vector2(unit*.7,unit-2)]),Color("#fbe3a6"),1.5,true)
   var runner=origin+Vector2(6.5,.7)*unit;draw_circle(runner,unit*.42,Color("#f5d893"));draw_arc(runner+Vector2(unit*1.5,-unit*.5),unit*.9,PI,TAU,20,Color("#ebf7e6"),2)
   return
  if map=="lanternfall":
   var p=area.get_center();draw_circle(p,area.size.y*.36,Color("#243e4b"))
   for n in 5:draw_arc(p,area.size.y*(.13+n*.055),.4+n*.4,3.5+n*.4,24,Color(.4,.7,.8,.2),2)
   draw_line(p+Vector2(0,22),p-Vector2(0,5),Color("#b18758"),7);draw_colored_polygon(PackedVector2Array([p+Vector2(-11,0),p+Vector2(0,-30),p+Vector2(12,0),p+Vector2(0,10)]),Color("#ffd986"));draw_string(ThemeDB.fallback_font,p+Vector2(-76,area.size.y*.40),"UNCHARTED • RANDOMIZED",HORIZONTAL_ALIGNMENT_LEFT,180,12,Color("#c1d4dc"));return
  var field=Vector2(2560,1920) if map in ["colour_clash","crown_chase"] else Vector2(6200,4200) if map=="crossroads" else Vector2(3200,2300) if map=="forest" else Vector2(2880,2160) if map=="maze" else Vector2(2400,1800)
  var ratio=minf((area.size.x-16)/field.x,(area.size.y-16)/field.y);var origin=area.get_center()-field*ratio*.5;var floor=Rect2(origin,field*ratio)
  draw_rect(floor,Color("#314d48") if map in ["forest","crossroads"] else Color("#6a614c") if map=="sand" else Color("#354653"))
  if map in ["colour_clash","crown_chase"]:
   if map=="colour_clash":
    for y in 8:
     for x in 10:
      var tint=Color("#6cbdf2") if x<4 else Color("#ef8d88") if x>5 else Color("#b9a2f2") if y>4 else Color("#8fcfaa")
      tint.a=.65;draw_rect(Rect2(origin+Vector2(x,y)*field*ratio/Vector2(10,8),field*ratio/Vector2(10,8)-Vector2(1,1)),tint)
    for p in [Vector2(820,960),Vector2(1740,960)]:draw_arc(origin+p*ratio,8 if detailed else 4,0,TAU,24,Color("#fff0b8"),2)
   else:
    var p=origin+field*ratio*.5;draw_arc(p,22 if detailed else 13,0,TAU,32,Color("#b9a479"),2);draw_colored_polygon(PackedVector2Array([p+Vector2(-12,-7),p+Vector2(-6,0),p+Vector2(0,-16),p+Vector2(6,0),p+Vector2(12,-7),p+Vector2(9,10),p+Vector2(-9,10)]),Color("#f2cf79"))
   for p in [Vector2(560,450),Vector2(2000,450),Vector2(560,1470),Vector2(2000,1470),Vector2(1050,650),Vector2(1510,650),Vector2(1050,1270),Vector2(1510,1270)]:draw_circle(origin+p*ratio,maxf(2,48*ratio),Color("#314653"))
  elif map=="maze":
   var geometry=preload("res://scripts/arena_variants.gd").new();geometry.build_maze()
   for r in geometry.walls:draw_rect(Rect2(origin+r.position*ratio,r.size*ratio),Color("#b6b6ac"))
   for d in geometry.doors:draw_rect(Rect2(origin+d.rect.position*ratio,d.rect.size*ratio).grow(1),Color("#e8bd72"))
   for room in [5,6]:draw_circle(origin+Vector2(room%4*720+360,room/4*720+360)*ratio,13 if detailed else 5,Color("#bd7775"))
  elif map=="crossroads":
   var scene=preload("res://scenes/realms/arena_world.tscn").instantiate()
   for patch in scene.get_node("GroundPaint").get_children():
    var points=PackedVector2Array()
    for vertex in patch.polygon:points.append(origin+vertex*ratio)
    draw_colored_polygon(points,Color("#b4a981"))
   for obstacle in scene.get_node("Obstacles").get_children():draw_circle(origin+obstacle.position*ratio,maxf(1.5,float(obstacle.get_meta("radius",30))*ratio),Color("#6c9482"))
   scene.free()
  else:
   for n in 8:
    var angle=TAU*n/8;draw_circle(origin+(field*.5+Vector2(cos(angle)*field.x*.42,sin(angle)*field.y*.41))*ratio,maxf(2,36*ratio),Color("#a1ada1"))
   if map=="sand":
    for p in [Vector2(850,720),Vector2(1550,1080),Vector2(1230,1420)]:draw_circle(origin+p*ratio,150*ratio,Color("#b99868"));draw_arc(origin+p*ratio,150*ratio,0,TAU,24,Color("#d4be8b"),2)
   if map=="storm":
    for n in 3:draw_circle(origin+Vector2(650+n*500,600+n*180)*ratio,170*ratio,Color(.4,.75,.95,.3));draw_circle(origin+Vector2(650+n*500,600+n*180)*ratio,5,Color("#a9e3f4"))
   if map=="clock":
    draw_rect(Rect2(origin+Vector2(field.x*.4,0)*ratio,Vector2(140,field.y)*ratio),Color(.8,.6,.35,.6));draw_rect(Rect2(origin+Vector2(0,field.y*.6)*ratio,Vector2(field.x,140)*ratio),Color(.5,.8,.9,.5))
   if map=="forest":
    for p in [Vector2(1150,1000),Vector2(2000,1300)]:draw_circle(origin+p*ratio,9 if detailed else 4,Color("#e1ad8f"))
  draw_rect(floor,Color("#8ba9a3"),false,1)
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
