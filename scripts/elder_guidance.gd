extends RefCounted
## Profile-backed conversations. Presentation only; grants no progression or rewards.
var game:Node
var topic:=""
var step:=0
const WELCOME=[
 ["Welcome home, traveler", "Welcome to Crossroads! I am Elder Ram, keeper of the town’s stories. This is your home between adventures: meet its people, try fishing, or discover something of your own."],
 ["Your first realm • Whispering Grove", "The central portal leads to the realms. I recommend starting with Whispering Grove: learn your hero, explore its paths and face the guardian. Return stronger, then try the other realms as they open."],
 ["Other adventures are waiting", "Cave Descent is another path: battle deeper through its floors and see how far you can go. Gate Defence, the arena and the Challenge Lodge offer other adventures too. You can find your destinations in Adventures whenever you are ready."],
 ["Find your own path", "My advice? Begin with the Grove through the central portal. There is no hurry — explore town first if you like. Come and speak with me whenever you need a guide. Watch for a glowing chat bubble when I have something new to share."]]
const BETWEEN=[
 ["A new path • The Between", "Your victory has opened the medium realms — and The Between. Beyond that fractured portal is a changing wilderness made from pieces of many realms. Explore solo or with a partner; the farther you travel, the greater the danger."],
 ["Bring back Waylight Shards", "Collect Waylight Shards and return to the entrance to extract. Extraction banks your whole haul; defeat keeps only half. These shards stay with your profile and pay for attempts at the day’s Overcharged realm. Ordinary realms remain available without spending shards."],
 ["Prove your attunement", "Choose Attunement Challenge in The Between’s portal panel. This is a solo trial that starts you at combat level 10. Defeat six elite Wardens deeper inside, collect their six Crossing Seals and extract with all six. That proves you are ready for Overcharged realms. Successful repeat trials also award bonus shards."],
 ["Relics • power worth pursuing", "Once attuned, spend shards to enter the day’s Overcharged realm. Defeating it gives a chance at a relic — it is not guaranteed. Relics give lasting build bonuses, and you can equip two in Profile → Inventory. Exploring The Between earns shards; attunement opens the next step; Overcharged victories are where you hunt relics."]]
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size()!=3:return false
 for key in ["welcome_pending","welcome_seen","between_seen"]:
  if not value.get(key) is bool:return false
 return true
func state()->Dictionary:
 if not game.legacy.data.has("elder_guidance"):
  game.legacy.data.elder_guidance={"welcome_pending":false,"welcome_seen":false,"between_seen":false}
 return game.legacy.data.elder_guidance
func earned_between()->bool:
 return preload("res://scripts/realm_access.gd").count(game.legacy,preload("res://scripts/realm_access.gd").INTRO_MODERATE)>0
func pending()->String:
 if preload("res://scripts/profile_store.gd").progression_blocked():return ""
 var s=state()
 if s.welcome_pending and not s.welcome_seen:return "welcome"
 if earned_between() and not s.between_seen:return "between"
 return ""
func elder_position()->Vector2:
 for landmark in game.town_art:
  if str(landmark.sprite)=="elder_ram":return landmark.pos
 return Vector2(740,660)
func welcome()->void:
 if game.mode!="town":return
 state().welcome_pending=true;game.legacy.save()
 game.position_in_world=elder_position()+Vector2(0,85)
 game.update_camera()
 game.message="";game.message_time=0
 begin("welcome")
func begin(which:String)->void:
 if game.mode!="town" or which=="between" and not earned_between():return
 game.legacy.close();topic=which;step=0;game.legacy.talk("elder");show_page()
func show_page()->void:
 var p=game.presentation
 var lines:Array=BETWEEN if topic=="between" else WELCOME
 p.window("ELDER RAM • "+("A new path awaits" if topic=="between" else "Welcome to Crossroads"),"elder_guidance")
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);p.content.add_child(row)
 var portrait_col=VBoxContainer.new();portrait_col.custom_minimum_size.x=190;row.add_child(portrait_col)
 var frame=PanelContainer.new();frame.custom_minimum_size=Vector2(190,210);portrait_col.add_child(frame)
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#254752");skin.border_color=Color("#cbb479");skin.set_border_width_all(2);skin.set_corner_radius_all(16);frame.add_theme_stylebox_override("panel",skin)
 var art=TextureRect.new();art.name="ElderPortrait";art.texture=game.art.get("elder_ram");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;frame.add_child(art)
 p.label(portrait_col,"ELDER RAM",20).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 p.label(portrait_col,"Town guide",16).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",20);row.add_child(words)
 p.label(words,"CONVERSATION  %d / %d" % [step+1,lines.size()],15).modulate=Color("#91c7cb")
 p.label(words,str(lines[step][0]),27).modulate=Color("#ffdb96")
 p.label(words,str(lines[step][1]),22)
 var footer=HBoxContainer.new();footer.add_theme_constant_override("separation",12);p.content.add_child(footer)
 p.button(footer,"Back",func():step-=1;show_page()).disabled=step==0
 var next=p.button(footer,"I’m ready" if step==lines.size()-1 else "Continue",advance)
 next.name="ElderContinue";next.size_flags_horizontal=Control.SIZE_EXPAND_FILL;preload("res://scripts/studio_ui.gd").accent(next);next.grab_focus()
 p.button(p.content,"Talk later • Esc",p.close)
func advance()->void:
 var lines:Array=BETWEEN if topic=="between" else WELCOME
 if step<lines.size()-1:step+=1;show_page();return
 if not preload("res://scripts/profile_store.gd").progression_blocked():
  if topic=="welcome":state().welcome_seen=true;state().welcome_pending=false
  else:state().between_seen=true
  game.legacy.save()
 game.presentation.close()
 game.message="The central portal is just beside me. Choose Whispering Grove to begin." if topic=="welcome" else "The Between awaits in the central portal. Prepare, explore, then return to extract."
 game.message_time=8
func draw_marker(g:Node2D,camera:Vector2)->void:
 if pending().is_empty():return
 var at=elder_position()-camera+Vector2(0,-73+sin(game.visual_clock*2.5)*3)
 var box=Rect2(at-Vector2(18,24),Vector2(36,37))
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#fff1bb");skin.border_color=Color("#9d742e");skin.set_border_width_all(2);skin.set_corner_radius_all(11)
 g.draw_style_box(skin,box)
 g.draw_colored_polygon(PackedVector2Array([at+Vector2(-6,11),at+Vector2(0,21),at+Vector2(6,11)]),Color("#fff1bb"))
 g.draw_string(g.font,at+Vector2(-5,3),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("#5b391b"))
