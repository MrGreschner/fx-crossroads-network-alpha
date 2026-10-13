extends RefCounted
var game:Node
var active:=false
var wave:=0
var timer:=0.0
var defeated:=0
var used:Dictionary={}
var saved_pack:Array=[]
var saved_food:=""
var unlock_queue:Array[String]=[]
func start(id:String)->void:
 if id not in game.manifest.characters.slice(0,9):return
 saved_pack=game.loadout.duplicate();saved_food=game.provisions.packed
 game.selected_character=id;game.save_profile();active=true;wave=0;timer=1;defeated=0;used.clear();unlock_queue.clear()
 game.start_run(false,"first_steps");game.level=1;game.highest_level=1;game.inventory.clear();game.provisions.packed="";game.enemies.clear();game.boss_spawned=true;game.health=game.max_health();game.menu=""
func spawn_wave()->void:
 wave+=1
 var count:int=3 if wave==1 else 4 if wave<4 else 1
 for n in count:
  var kind:String="bramble" if wave==1 or n%3!=2 else "archer"
  var point:=Vector2(650+n*110,380 if wave%2 else 780)
  game.enemies.append({"uid":900000+wave*10+n,"pos":point,"hp":190.0 if wave==4 else 30.0+wave*6,"max_hp":190.0 if wave==4 else 30.0+wave*6,"attack_timer":1.5,"secondary_timer":3.0,"windup":0.0,"boss":wave==4,"type":"boss" if wave==4 else kind,"tutorial":true})
 game.health=minf(game.max_health(),game.health+20)
 game.message="MINI-BOSS • Watch its warning and dodge!" if wave==4 else "Wave %d / 3 • %s" % [wave,"Move and use your primary." if wave==1 else "Try your secondary and dodge." if wave==2 else "Your special is ready — give it a try!"]
 game.message_time=5
func step(delta:float)->void:
 if not active or not game.menu.is_empty():return
 if not unlock_queue.is_empty():game.presentation.skill_unlock(unlock_queue.pop_front());return
 if game.enemies.is_empty():
  if wave>=4:finish(true);return
  timer-=delta
  if timer<=0:timer=1.6;spawn_wave()
func damage(index:int,amount:float)->void:
 if index<0 or index>=game.enemies.size():return
 var foe:Dictionary=game.enemies[index];var actual:=minf(maxf(0,amount),float(foe.hp))
 game.adventure.combat.feedback.hit(foe.pos,actual)
 game.dealt_damage+=actual;foe.hp=float(foe.hp)-amount;game.enemy_flashes[int(foe.uid)]=.16
 game.add_float_text(foe.pos-Vector2(18,42),"−"+str(int(actual)),Color("#ffe3ae"));game.journey.cue("hit")
 if float(foe.hp)>0:return
 game.enemies.remove_at(index);defeated+=1;game.kills+=1
 var next:int=mini(6,1+int(defeated*.75));var old:int=game.level
 game.level=next;game.highest_level=next;game.experience=defeated*10
 if old<3 and next>=3:unlock_queue.append("secondary")
 if old<5 and next>=5:unlock_queue.append("passive")
 if old<6 and next>=6:unlock_queue.append("special")
 if not unlock_queue.is_empty() and game.menu.is_empty():game.presentation.skill_unlock(unlock_queue.pop_front())

func finish(won:bool,skipped:bool=false)->void:
 if not active:return
 unlock_queue.clear();active=false;game.provisions.packed=saved_food;game.loadout.assign(saved_pack);game.profile["tutorial_seen"]=true;game.save_profile();game.menu="";game.gold=100;game.enter_region("town");game.health=game.max_health()
 game.journey.data.skipped=true;game.journey.save()
 game.message="Welcome to Crossroads! Choose your next adventure from the Adventure board." if won or skipped else "Nice first attempt! You can retry First Steps from the Adventure board."
 game.message_time=8;game.presentation.tutorial_end(won,skipped)
func draw_on(c:Node2D)->void:
 if not active:return
 var font:=ThemeDB.fallback_font
 c.draw_rect(Rect2(20,150,790,85),Color(.025,.08,.12,.92))
 c.draw_string(font,Vector2(36,179),"FIRST STEPS • "+("Mini-boss" if wave==4 else "Wave %d / 3" % maxi(1,wave)),HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#ecd397"))
 var hint:="WASD / left stick move • Mouse / right stick aim • Primary attack"
 if game.level>=3:hint="Try "+str(game.hero.secondary.name)+" • Right click / Secondary • Shift / Dodge avoids danger"
 if game.level>=6:hint="Try "+str(game.hero.special.name)+" • Space / Special • Watch the mini-boss warning"
 c.draw_string(font,Vector2(36,213),hint,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c4dcde"))
