extends RefCounted
const UI=preload("res://scripts/garden_ui.gd")
const SKIN=preload("res://scripts/studio_ui.gd")
const P=preload("res://scripts/fishing_progress.gd")
class Emblem extends Control:
 var kind="rod"
 func _draw()->void:
  var at=size*.5;var ink=Color("#9ed8d0");draw_circle(at,24,Color("#244b56"));draw_arc(at,24,0,TAU,32,Color("#668e91"),1,true)
  match kind:
   "net":
    draw_circle(at-Vector2(0,4),13,Color("#3c6d72"));draw_arc(at-Vector2(0,4),13,0,TAU,24,ink,2,true);draw_line(at+Vector2(8,6),at+Vector2(18,20),Color("#d1b47d"),4,true)
    for n in [-6,0,6]:draw_line(at+Vector2(n,-15),at+Vector2(n,7),ink,1,true);draw_line(at+Vector2(-11,n-4),at+Vector2(11,n-4),ink,1,true)
   "worms":
    var points=PackedVector2Array()
    for n in 24:points.append(at+Vector2((n-12)*1.1,sin(n*.4)*8))
    draw_polyline(points,Color("#deaa93"),6,true);draw_circle(points[-1],3,Color("#efd0af"))
   "insects":
    for x in [-1,1]:
     for y in [-1,1]:draw_circle(at+Vector2(x*8,y*6),6,Color("#bad8b7"))
    draw_line(at-Vector2(0,12),at+Vector2(0,14),Color("#d2b77f"),5,true);draw_circle(at-Vector2(0,13),3,ink)
   "dough":
    for offset in [Vector2(-8,6),Vector2(8,6),Vector2(0,-7)]:draw_circle(at+offset,8,Color("#e1cb8e"));draw_arc(at+offset,8,PI,TAU,12,Color("#f1dfa6"),2,true)
   "scraps":
    draw_line(at-Vector2(15,0),at+Vector2(13,0),Color("#ced5bd"),3,true);draw_circle(at+Vector2(12,0),5,Color("#a4c6bd"))
    for x in [-8,0,7]:draw_line(at+Vector2(x,-8),at+Vector2(x,8),Color("#ced5bd"),2,true)
   "tree":
    for n in 3:draw_line(at+Vector2(0,14),at+Vector2((n-1)*15,-11),ink,1.5,true);draw_circle(at+Vector2((n-1)*15,-11),4,Color("#dac587"))
    draw_circle(at+Vector2(0,14),4,ink)
   "pot":
    draw_rect(Rect2(at-Vector2(14,5),Vector2(28,18)),ink,false,2);draw_arc(at-Vector2(0,5),10,PI,TAU,18,ink,2,true)
    for n in [-7,0,7]:draw_line(at+Vector2(n,-4),at+Vector2(n,12),ink,1,true)
   "coins":
    for n in 3:draw_circle(at+Vector2((n-1)*10,(n%2)*7),7,Color("#d8bd7e"));draw_line(at+Vector2((n-1)*10,-4+(n%2)*7),at+Vector2((n-1)*10,4+(n%2)*7),Color("#89764f"),1.5,true)
   "bait":
    draw_arc(at,13,0,TAU,28,Color("#e2b193"),5,true);draw_line(at+Vector2(-4,-4),at+Vector2(6,6),Color("#e6cd9b"),2,true)
   "journal":
    draw_rect(Rect2(at-Vector2(14,17),Vector2(28,34)),Color("#95bba5"),false,2);draw_line(at+Vector2(-7,-16),at+Vector2(-7,16),Color("#d9c88f"),2,true)
    for y in [-7,0,7]:draw_line(at+Vector2(-2,y),at+Vector2(9,y),ink,1,true)
   _:
    draw_line(at+Vector2(-14,14),at+Vector2(7,-15),Color("#d1b47d"),3,true);draw_line(at+Vector2(7,-15),at+Vector2(14,7),ink,1,true);draw_arc(at+Vector2(10,7),4,0,PI,14,ink,2,true)
static func icon(parent:Node,kind:String)->void:
 var art=Emblem.new();art.kind=kind;art.custom_minimum_size=Vector2(55,55);parent.add_child(art)
static func build(legacy:Node,parent:Node)->void:
 var f=legacy.game.fishing;var rec=legacy.fishing_records;var prog=rec.progress;var level=prog.level();var xp=int(prog.state().xp)
 var header=SKIN.card(parent,"FISHING • Lv %d / 80" % level,"");var row=HBoxContainer.new();header.add_child(row)
 var favorite=rec.favorite()
 if favorite.is_empty() and not rec.state().kept.is_empty():favorite=rec.state().kept[0]
 if not favorite.is_empty():f.picture(row,str(favorite.species),Vector2(110,60))
 else:icon(row,"rod")
 var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
 UI.label(details,"%s • %d XP • %d / %d fish carried" % [prog.title(),xp,rec.bag_count(),rec.capacity()],17)
 UI.label(details,"%d species discovered • %d mastery points ready • %d Glimmers" % [rec.state().journal.size(),prog.available_points(),legacy.glimmers.balance()],14)
 var bar=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.value=100 if level==80 else 100.0*(xp-prog.threshold(level))/maxi(1,prog.threshold(level+1)-prog.threshold(level));details.add_child(bar)
 var tiles=GridContainer.new();tiles.columns=3;tiles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(tiles)
 var entries=[
  ["Your catches","journal","%d kept • tanks & journal" % rec.state().kept.size(),f.open_journal],
  ["Mastery tree","tree","Six branches • choose your style",f.open_mastery],
  ["Gear & fish bait","rod","Rod, net & basket equipment",func():open_tab(f,0)],
  ["Basket watch","pot","%d placed • check & collect" % prog.state().pots.size(),func():open_tab(f,2)],
  ["Trade catches","coins","Visit Ripple & Reel Sales",f.open_sales],
  ["Weekly catch","bait","A new fishing challenge",legacy.weekly.open_board]]
 for entry in entries:
  var card=SKIN.card(tiles,"","");card.get_parent().custom_minimum_size.x=275;var line=HBoxContainer.new();card.add_child(line);icon(line,entry[1]);var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(words);UI.label(words,entry[0],18);UI.label(words,entry[2],13);UI.button(card,"Open",entry[3]).custom_minimum_size.y=30
 var inventory=SKIN.card(parent,"EQUIPMENT & FISH BAIT","");var gear=HFlowContainer.new();gear.name="FishingEquipmentCards";gear.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gear.add_theme_constant_override("h_separation",10);gear.add_theme_constant_override("v_separation",10);inventory.add_child(gear)
 for id in ["rod","net","pot"]:
  equipment_card(gear,id,"Basket" if id=="pot" else id.capitalize(),"Ready" if prog.method_unlocked(id) else "Unlocks at level %d" % (5 if id=="net" else 10))
 for id in preload("res://scripts/fishing_ecology.gd").BAITS:
  var spec=preload("res://scripts/fishing_ecology.gd").BAITS[id]
  equipment_card(gear,id,str(spec.name),"Unlimited" if id=="basic" else "%d stocked" % int(prog.state().bait.get(id,0)) if prog.bait_unlocked(id) else "Unlocks at level %d" % int(P.BAIT_LEVELS[id]))
 UI.label(parent,"Bare hook is free. Keep or release catches for XP. Selling fish makes room while keeping your journal and XP.",14)
static func open_tab(f:Node,index:int)->void:
 f.open_workshop();f.workshop.selected_tab=index;f.workshop.build()

static func equipment_card(parent:Node,kind:String,title:String,status:String)->void:
 var card=PanelContainer.new();card.custom_minimum_size=Vector2(235,88);card.add_theme_stylebox_override("panel",SKIN.box("#20434e","#426773",8,10));parent.add_child(card)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);card.add_child(row);icon(row,kind)
 var words=VBoxContainer.new();words.custom_minimum_size.x=150;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(words)
 UI.label(words,title,16);UI.label(words,status,13).modulate=Color("#a9dac5")
