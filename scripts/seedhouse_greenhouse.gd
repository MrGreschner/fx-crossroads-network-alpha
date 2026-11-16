extends Control
## The town greenhouse shares the profile's existing crops and real-time timers.
const UI=preload("res://scripts/studio_ui.gd")
const CAST=preload("res://scripts/town_cast230.gd")
const CROPS=preload("res://scripts/town_art246.gd")
const NATURE=preload("res://scripts/town_nature243.gd")
const GARDEN_UI=preload("res://scripts/garden_ui.gd")
const ROUTES=preload("res://scripts/town_resident_routes.gd")
const ROOM=Vector2(1040,650)
const EXIT=Vector2(510,575)
const COUNTER=Vector2(160,470)
const GATE=Vector2(850,350)
const PRIVATE_BAY=Rect2(754,170,230,151)
const PUBLIC_CROPS=["orchard0","flowers0","river0","astral_orchid","aurora_quince"]
const GROW_BENCH=Rect2(70,153,651,65)
const PLANTER_SIZE=Vector2(104,45)
const GOLD=Color("#f4da9f")
var game:Node
var garden:RefCounted
var player=Vector2(510,535)
var clock=0.0
var moving=false
var hud:PanelContainer
var status:Label
var nearby_bed=-1
var nearby_person=""
var residents:Dictionary={}
var beds:Array[Rect2]=[]
var texture_cache:Dictionary={}

func setup(owner:Node)->void:
 game=owner
 garden=game.legacy.gardening
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in garden.SHARED_BEDS:
  beds.append(Rect2(Vector2(77+(i%5)*132,251+(i/5)*108),PLANTER_SIZE))
 beds.append(Rect2(Vector2(767,229),PLANTER_SIZE-Vector2(13,0)))
 beds.append(Rect2(Vector2(879,229),PLANTER_SIZE-Vector2(13,0)))
 hud=PanelContainer.new()
 UI.apply(hud)
 add_child(hud)
 var col=VBoxContainer.new()
 hud.add_child(col)
 var heading=HBoxContainer.new()
 col.add_child(heading)
 GARDEN_UI.label(heading,"SEEDHOUSE GREENHOUSE",24).modulate=GOLD
 var nav=HBoxContainer.new()
 col.add_child(nav)
 UI.accent(GARDEN_UI.button(nav,"Garden beds",open_garden.bind("beds")))
 GARDEN_UI.button(nav,"Seed shop",open_garden.bind("shop"))
 GARDEN_UI.button(nav,"Return to town",leave)
 status=GARDEN_UI.label(col,"",17)
 game.menu="seedhouse_room"
 game.mobile.reset_controls()
 refresh_residents()

func open_garden(page:String,bed:int=-1)->void:
 garden.page=page
 garden.open(bed)

func leave()->void:
 game.menu=""
 game.mobile.reset_controls()

func refresh_residents()->void:
 residents.clear()
 for index in ROUTES.GARDENERS:
  var state:Dictionary=game.town_life.resident_state(index)
  if state.task!="water" or state.visible:continue
  var slot:int=ROUTES.GARDENERS.find(index)
  var phase=fposmod(clock+float(slot)*5.0,18.0)
  var p=Vector2(290+slot*245,230)
  var walking=phase>9 and phase<13 or phase>14 and phase<18
  var walk_ratio=clampf((phase-9)/4.0,0,1) if phase<14 else 1.0-clampf((phase-14)/4.0,0,1)
  p.x+=walk_ratio*82
  residents[state.name]={"position":p,"walking":walking}

func standable(p:Vector2)->bool:
 if GROW_BENCH.grow(9).has_point(p):return false
 if COUNTER.distance_to(p)<24:return false
 if PRIVATE_BAY.has_point(p) and not garden.owns_plot():return false
 for bed in beds:
  if bed.grow(8).has_point(p):return false
 return true

func _process(delta:float)->void:
 clock+=delta
 var view=size
 var width=maxf(575,hud.get_combined_minimum_size().x)
 var factor=minf(1.0,(view.x-18.0)/width)
 hud.size=Vector2(width,0)
 hud.scale=Vector2.ONE*factor
 hud.position=Vector2((view.x-width*factor)*.5,8)
 moving=false
 if game.menu!="seedhouse_room":return
 refresh_residents()
 var direction:Vector2=game.mobile.movement+Input.get_vector("move_left","move_right","move_up","move_down")
 var step=direction.limit_length()*174.0*minf(delta,.05)
 var next=player+Vector2(step.x,0)
 if standable(next):player.x=clampf(next.x,53,982)
 next=player+Vector2(0,step.y)
 if standable(next):player.y=clampf(next.y,145,580)
 moving=direction.length_squared()>.01
 if player.y>569 and absf(player.x-EXIT.x)<51:
  leave()
  return
 nearby_bed=-1
 nearby_person=""
 var nearest=64.0
 for i in garden.state().beds.size():
  var distance=player.distance_to(beds[i].get_center())
  if distance<nearest and (garden.bed_available(i) or not garden.state().beds[i].is_empty()):
   nearest=distance
   nearby_bed=i
 if nearby_bed<0:
  if player.distance_to(COUNTER)<70:nearby_person="Rowan"
  for id in residents:
   if player.distance_to(residents[id].position)<52:nearby_person=id
 status.text=hint()
 if Input.is_action_just_pressed("interact"):interact()
 queue_redraw()

func hint()->String:
 if not garden.owns_plot() and player.distance_to(GATE)<65:
  return "E • Private bay   |   Gardening Lv %d + %d Glimmers" % [garden.PRIVATE_LEVEL,garden.PRIVATE_PRICE]
 if nearby_bed>=0:
  var label="Private bed %d" % (nearby_bed-garden.SHARED_BEDS+1) if nearby_bed>=garden.SHARED_BEDS else "Bed %d" % (nearby_bed+1)
  return "E • %s   |   %s" % [label,garden.bed_text(nearby_bed)]
 if not nearby_person.is_empty():return "E • Talk to "+nearby_person
 return "Gardening Lv %d   •   %d Glimmers" % [garden.level(),game.legacy.glimmers.balance()]

func interact()->void:
 if not garden.owns_plot() and player.distance_to(GATE)<65:
  open_lease()
 elif nearby_bed>=0:open_garden("beds",nearby_bed)
 elif not nearby_person.is_empty():
  game.town_conversations.open(game,nearby_person,"Browse seeds" if nearby_person=="Rowan" else "")

func open_lease()->void:
 var ui=game.presentation
 ui.window("Private greenhouse bay","town_conversation")
 ui.label(ui.content,"Reserve two permanent growing beds inside the greenhouse. Each bed can grow crops year-round.",18)
 ui.label(ui.content,"Gardening level %d / %d   •   %d / %d Glimmers" % [garden.level(),garden.PRIVATE_LEVEL,game.legacy.glimmers.balance(),garden.PRIVATE_PRICE],17)
 var button:Button=ui.button(ui.content,"Unlock for %d Glimmers" % garden.PRIVATE_PRICE,func():
  ui.close()
  if garden.buy_plot():game.message="Private greenhouse bay unlocked.")
 UI.accent(button)
 button.disabled=garden.level()<garden.PRIVATE_LEVEL or game.legacy.glimmers.balance()<garden.PRIVATE_PRICE or not garden.allowed()

func _unhandled_input(event:InputEvent)->void:
 if game.menu=="seedhouse_room" and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  leave()
  get_viewport().set_input_as_handled()

func caption(at:Vector2,value:String,points:int=16,colour:Color=GOLD)->void:
 draw_string(UI.FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,points,colour)

func crop(id:String,stage:int,at:Vector2,extent:float)->void:
 var key=id+"_"+str(stage)
 if not texture_cache.has(key):texture_cache[key]=CROPS.texture(key,"crops")
 var art:Texture2D=texture_cache[key]
 if art!=null:draw_texture_rect(art,Rect2(at-Vector2(extent*.5,extent*.84),Vector2.ONE*extent),false)

func planter(at:Rect2)->void:
 var art:Texture2D=NATURE.texture("garden_bed")
 if art!=null:draw_texture_rect(art,at,false)

func _draw()->void:
 if game==null:return
 draw_rect(Rect2(Vector2.ZERO,size),Color("#112b2e"))
 var scale_factor=minf(size.x/ROOM.x,maxf(1,size.y-64)/ROOM.y)
 draw_set_transform((size-ROOM*scale_factor)*.5+Vector2(0,26),0,Vector2.ONE*scale_factor)
 draw_structure()
 draw_growing_beds()
 draw_occupants()

func draw_structure()->void:
 draw_rect(Rect2(32,68,976,525),Color("#274644"))
 draw_rect(Rect2(43,131,954,452),Color("#7d856d"))
 for y in range(131,583,28):
  for x in range(43,997,48):
   var shift=(y/28)%2*15
   var colour=Color("#929881").lerp(Color("#646e5e"),.5+.35*sin(x*15.7+y*8.3))
   var left=x+shift
   draw_rect(Rect2(left,y, maxf(0,minf(46,997-left)),26),colour)
 draw_rect(Rect2(43,76,954,68),Color("#375853"))
 for n in 10:
  var pane=Vector2(54+n*95,81)
  draw_rect(Rect2(pane,Vector2(88,53)),Color("#86ada0"))
  draw_rect(Rect2(pane+Vector2(3,49),Vector2(82,3)),Color("#bfd4ac"))
  draw_line(pane+Vector2(58,2),pane+Vector2(22,48),Color(.87,.98,.79,.25),7)
  draw_line(pane+Vector2(0,26),pane+Vector2(88,26),Color("#506657"),3)
 for x in [41,325,628,991]:
  draw_rect(Rect2(x,71,9,74),Color("#67533c"))
  draw_circle(Vector2(x+4,135),3,Color("#d8b778"))
 draw_rect(Rect2(43,141,954,6),Color("#a38459"))
 draw_colored_polygon(PackedVector2Array([Vector2(335,147),Vector2(407,147),Vector2(535,437),Vector2(398,437)]),Color(.94,.96,.67,.065))
 draw_colored_polygon(PackedVector2Array([Vector2(722,147),Vector2(793,147),Vector2(977,460),Vector2(817,460)]),Color(.94,.96,.67,.06))
 draw_rect(Rect2(43,145,954,438),Color("#47534a"),false,3)
 draw_rect(Rect2(436,550,148,33),Color("#48635a"))
 caption(Vector2(453,569),"TOWN EXIT",15)
 draw_rect(Rect2(54,456,85,63),Color("#5e4536"))
 draw_rect(Rect2(50,450,95,15),Color("#b39465"))
 for n in 3:
  draw_rect(Rect2(56+n*27,467,23,43),Color("#836746"))
  draw_rect(Rect2(63+n*27,475,8,2),Color("#cba978"))
 crop("flowers0",2,Vector2(83,453),58)
 caption(Vector2(64,542),"SEED SHOP")
 draw_rect(PRIVATE_BAY,Color("#5f6858") if garden.owns_plot() else Color("#685d48"))
 draw_rect(PRIVATE_BAY,Color("#c3a478"),false,3)
 caption(Vector2(767,200),"PRIVATE GROWING BAY")
 if not garden.owns_plot():
  draw_rect(Rect2(749,315,242,9),Color("#796045"))
  for i in 8:draw_rect(Rect2(750+i*33,301,5,27),Color("#a98b59"))
  caption(Vector2(778,352),"E • Unlock private bay",15)

func draw_growing_beds()->void:
 for i in PUBLIC_CROPS.size():
  var base=Vector2(77+i*132,171)
  planter(Rect2(base,PLANTER_SIZE))
  for n in 3:crop(PUBLIC_CROPS[i],2,base+Vector2(22+n*31,34),66)
 var stamp:float=garden.now()
 var record:Array=garden.state().beds
 for i in beds.size():
  var box=beds[i]
  planter(box)
  if i>=record.size():
   caption(box.position+Vector2(18,24),"Reserved",14)
   continue
  var bed:Dictionary=record[i]
  if not bed.is_empty():
   crop(str(bed.seed),CROPS.crop_stage(bed,stamp),box.get_center()+Vector2(0,13),84)
   if stamp>=float(bed.end):draw_circle(box.end-Vector2(11,10),4,Color("#e8c882"))
  elif not garden.bed_available(i):caption(box.position+Vector2(20,24),"Locked",14)
  if i==nearby_bed:draw_rect(box.grow(2),Color("#edcf8e"),false,2)
  caption(box.position+Vector2(3,box.size.y+11),str(i+1 if i<garden.SHARED_BEDS else i-garden.SHARED_BEDS+1),12)

func draw_occupants()->void:
 var actors:Array=[{"id":"Rowan","position":COUNTER,"moving":false}]
 for id in residents:
  var resident:Dictionary=residents[id]
  actors.append({"id":id,"position":resident.position,"moving":resident.walking})
 actors.append({"id":"","position":player,"moving":moving})
 actors.sort_custom(func(a,b):return a.position.y<b.position.y)
 for actor in actors:
  var p:Vector2=actor.position
  draw_circle(p+Vector2(0,2),12,Color(0,0,0,.22))
  if actor.id.is_empty():draw_player(p)
  else:
   CAST.draw(self,actor.id,p,clock,actor.moving)
   caption(p+Vector2(-19,18),actor.id,14)
   if actor.id!="Rowan" and not actor.moving:
    for n in 3:
     var drop=fposmod(clock*1.6+float(n)/3.0,1.0)
     draw_rect(Rect2(p+Vector2(12+drop*12,-28+drop*18),Vector2(2,3)),Color(.64,.89,.91,1.0-drop))

func draw_player(p:Vector2)->void:
 var key=str(game.characters.get(game.selected_character,{}).get("sprite","ram"))
 var pose=("walk1" if int(clock*7.0)%2==0 else "walk2") if moving else "idle"
 var art:Texture2D=game.art.get(key+"_"+pose,game.art.get(key+"_0"))
 if art==null:return
 var rect=Rect2(p-Vector2(28,64),Vector2(56,64))
 rect=preload("res://scripts/hero_visual_scale.gd").apply(key,rect)
 rect.position.y=p.y-rect.size.y
 draw_texture_rect(art,rect,false)
