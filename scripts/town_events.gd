extends RefCounted
## Discoveries are awarded only by being near an active town event.
const EVENTS={"marina_trade":{"name":"Marina Delivery Mornings","days":[1,3],"hours":[10,12],"at":Vector2(1535,2380),"text":"Tuesday and Thursday, 10:00–12:00: neighbours collect deliveries and trade by the marina bait stand."},"marina_fishing":{"name":"Sunday at the Marina","days":[6],"hours":[15,18],"at":Vector2(1870,2304),"text":"Sunday, 15:00–18:00: town anglers fish and swap stories along the marina dock."},"music":{"name":"Wednesday on the Square","days":[2],"hours":[19,22],"at":Vector2(960,800),"text":"Neighbours gather for music every Wednesday, 19:00–22:00."},"picnic":{"name":"The Reedbank Picnic","days":[1,3],"hours":[12,14],"at":Vector2(380,680),"text":"A family brings a covered picnic to the pond garden on Tuesday and Thursday, 12:00–14:00."},"visitors":{"name":"Faraway Flavours","days":[0,3],"hours":[10,15],"at":Vector2(1700,1120),"text":"Monday and Thursday, 10:00–15:00: a travelling stall sells exotic fruit and fishing fish bait."},"fair":{"name":"Saturday Makers' Fair","days":[5],"hours":[11,16],"at":Vector2(1060,1295),"text":"Saturday, 11:00–16:00: makers and neighbours fill the square with handmade wares."},"lanterns":{"name":"The Lantern Walk","days":[4],"hours":[20,22],"at":Vector2(1700,1180),"text":"Friday, 20:00–22:00: residents carry lanterns along the eastern street."},"stars":{"name":"Stories Under Stars","days":[5],"hours":[22,24],"at":Vector2(2810,1360),"text":"Saturday, 22:00–midnight: a small group shares constellations beside the forest."},"anglers":{"name":"Sunday Anglers","days":[6],"hours":[9,12],"at":Vector2(230,520),"text":"Sunday, 09:00–12:00: neighbours swap fishing stories at the pond."},"fireflies":{"name":"Midnight Fireflies","days":[4],"hours":[23,24],"at":Vector2(2660,1440),"text":"Friday, 23:00–midnight: fireflies trace a message by the river."},"inscription":{"name":"First-Light Letters","days":[0],"hours":[6,7],"at":Vector2(-1030,1010),"text":"Monday, 06:00–07:00: the old courtyard fountain reveals an inscription."},"dawn_shoal":{"name":"The Northern Dawn Shoal","days":[0,1,2,3,4,5,6],"hours":[4,6],"at":Vector2(2475,480),"text":"Every day, 04:00–06:00: the northern river shoal appears, with fish found nowhere else."}}
var elapsed=0.0
func active(id:String,cal:RefCounted)->bool:
 var e=EVENTS[id]
 return cal.weekday in e.days and cal.hour>=float(e.hours[0]) and cal.hour<float(e.hours[1])
func step(g:Node,delta:float)->void:
 elapsed+=delta
 if elapsed<1:return
 elapsed=0
 if g.mode!="town" or not g.menu.is_empty() or g.has_node("FXIntro"):return
 var records=g.legacy.fishing_records;var changed=false
 for id in EVENTS:
  if not active(id,g.town_life.calendar) or g.position_in_world.distance_to(EVENTS[id].at)>190:continue
  if records.state().discoveries.has(id):continue
  if preload("res://scripts/profile_store.gd").progression_blocked() and not bool(g.legacy.data.get("teacher",false)):continue
  records.state().discoveries[id]=Time.get_date_string_from_unix_time(int(g.town_life.calendar.now));changed=true
  g.message="Town discovery • "+str(EVENTS[id].name);g.message_time=5
 if changed:records.save()
func interact(g:Node)->bool:
 if not active("visitors",g.town_life.calendar) or g.position_in_world.distance_to(EVENTS.visitors.at)>90:return false
 g.hint="E • Faraway Flavours • fruit & fish bait"
 if Input.is_action_just_pressed("interact"):g.fishing.open_workshop()
 return true
func draw_on(g:Node2D,camera:Vector2)->void:
 var cal=g.town_life.calendar;var view=Rect2(camera,g.VIEW).grow(200)
 for id in EVENTS:
  if not active(id,cal) or not view.has_point(EVENTS[id].at):continue
  var p:Vector2=EVENTS[id].at-camera
  match id:
   "picnic":
    g.draw_rect(Rect2(p-Vector2(62,35),Vector2(124,70)),Color("#8e718c"))
    for x in 6:
     for y in 3:
      if (x+y)%2==0:g.draw_rect(Rect2(p+Vector2(-60+x*20,-33+y*22),Vector2(20,22)),Color("#d9be9f"))
    for n in 5:g.draw_circle(p+Vector2(-38+n*18,sin(n)*12),6,Color("#d4aa67"))
   "visitors","fair":
    var count=3 if id=="fair" else 1
    for n in count:
     var q=p+Vector2((n-(count-1)*.5)*(105 if id=="fair" else 150),0)
     var width=45.0 if id=="fair" else 60.0;var scale_x=width/60.0
     g.draw_rect(Rect2(q+Vector2(-56*scale_x,-28),Vector2(112*scale_x,47)),Color("#79674e"))
     for side in [-1,1]:g.draw_line(q+Vector2(side*52*scale_x,20),q+Vector2(side*52*scale_x,-88),Color("#c5a473"),4)
     for stripe in 8:g.draw_rect(Rect2(q+Vector2((-60+stripe*15)*scale_x,-88),Vector2(15*scale_x,29)),Color("#93bfad") if stripe%2==0 else Color("#ecd49d"))
     for fruit in 6:g.draw_circle(q+Vector2((-40+fruit*15)*scale_x,-33),5 if id=="fair" else 7,Color("#eab367") if fruit%2 else Color("#c9a0cf"))
     g.draw_string(ThemeDB.fallback_font,q+Vector2(-57*scale_x,42),"FRUIT & FISH BAIT" if id=="visitors" else "MAKERS' FAIR",HORIZONTAL_ALIGNMENT_LEFT,-1,10 if id=="fair" else 13,Color("#ffe6b1"))
   "lanterns","stars":
    for n in 5:
     var q=p+Vector2((n-2)*32,sin(n)*18)
     g.draw_circle(q-Vector2(0,20),7,Color("#efc67c"));g.draw_arc(q-Vector2(0,20),8,PI,TAU,12,Color("#7b6b57"),2,true)
   "anglers":g.draw_string(ThemeDB.fallback_font,p+Vector2(-60,-55),"FISHING STORIES",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#d5e4be"))
