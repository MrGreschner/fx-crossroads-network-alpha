extends SceneTree
var failures=0
const Audio=preload("res://scripts/studio_audio.gd")
const Project=preload("res://scripts/workshop_project.gd")
const Portfolio=preload("res://scripts/media_portfolio.gd")
func check(v:bool,label:String)->void:
 print("PASS • " if v else "FAIL • ",label)
 if not v:failures+=1
func wav(seconds:float)->PackedByteArray:
 var count=int(8000*seconds);var b=PackedByteArray();b.resize(44+count*2)
 for i in 4:b[i]="RIFF".to_ascii_buffer()[i];b[8+i]="WAVE".to_ascii_buffer()[i];b[12+i]="fmt ".to_ascii_buffer()[i];b[36+i]="data".to_ascii_buffer()[i]
 b.encode_u32(4,b.size()-8);b.encode_u32(16,16);b.encode_u16(20,1);b.encode_u16(22,1);b.encode_u32(24,8000);b.encode_u32(28,16000);b.encode_u16(32,2);b.encode_u16(34,16);b.encode_u32(40,count*2)
 for i in count:b.encode_s16(44+i*2,int(sin(i*TAU*300/8000)*5000))
 return b
func _initialize()->void:call_deferred("run")
func run()->void:
 var sound={"name":"student.wav","format":"wav","data":Marshalls.raw_to_base64(wav(.3)),"volume_db":-12.0,"pitch":1.0}
 check(Audio.validate(sound).is_empty(),"valid FL Studio WAV accepted")
 var bad=sound.duplicate();bad.volume_db=0;check(not Audio.validate(bad).is_empty(),"unsafe level rejected")
 bad=sound.duplicate();bad.data=Marshalls.raw_to_base64(wav(5));check(not Audio.validate(bad).is_empty(),"long effect rejected")
 bad=sound.duplicate();bad.data="broken";check(not Audio.validate(bad).is_empty(),"corrupt audio rejected")
 var attack=Project.attack();attack.sound=sound;check(Project.validate_attack(attack).is_empty(),"portable ability carries sound")
 var project=Project.fresh();project.hero.primary=attack;check(Project.validate(project).is_empty(),"hero validates with custom sound")
 for name in ["swing","shot","heal","magic","flame","water","metal","bow"]:check(not Audio.example(name).is_empty() and Audio.validate(Audio.example(name)).is_empty(),"example sound "+name)
 var player=Audio.new();root.add_child(player);AudioServer.set_bus_mute(0,true);check(player.play_sound(sound),"sound uses normal muted master bus");check(not player.play_sound(sound),"repeat playback rate limited");check(player.voices.size()==4 and player.cache.size()==1,"audio voices and decoder cache bounded")
 var arena=preload("res://scripts/workshop_arena.gd").new();root.add_child(arena);arena.begin(project,[],"Cluster");arena.cast("primary");check(arena.audio.last_play>=0 and arena.casts.primary==1,"real attack cast triggers attached sound");arena.queue_free()
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 for n in 4:await process_frame
 game.set_process(false);game.presentation.close();game.session_menu.resume();game.legacy.answer("media")
 check(game.media.enabled() and not preload("res://scripts/profile_store.gd").testing(),"Media retains real account progression")
 game.media.open_tools();check(is_instance_valid(game.media.title_edit) and is_instance_valid(game.media.caption_edit),"photo captions and toolkit available")
 for index in 4:
  game.media.aspect=index;var rect=game.media.guides.frame();check(rect.size.x>0 and rect.size.y>0,"framing preset "+str(index))
 game.media.clean_view=true;game.media.apply_clean(true);check(game.media.clean_applied,"clean HUD activates")
 game.media.clean_view=false;game.media.apply_clean(false);check(not game.media.clean_applied,"HUD restores")
 var im=Image.create(640,360,false,Image.FORMAT_RGBA8);im.fill(Color("#586b94"))
 check(Portfolio.add(game,im,"First composition","Leading lines guide attention."),"captioned photo saved to normal profile")
 for n in 10:Portfolio.add(game,im,"Shot "+str(n),"Revision")
 check(game.legacy.data.media_portfolio.size()==8,"portfolio bounded to eight thumbnails")
 var portrait=Image.create(500,1000,false,Image.FORMAT_RGBA8);portrait.fill(Color.BLACK);check(Portfolio.add(game,portrait,"Portrait","Looking room"),"portrait thumbnail safely fits profile")
 var payload=game.legacy.bundle();check(game.legacy.validate(payload),"portfolio profile validates")
 var zip="user://media-audio.zip";preload("res://scripts/studio_library.gd").add_ability(attack)
 check(preload("res://scripts/studio_bundle.gd").make(payload,zip)==OK,"profile ZIP includes creative work")
 var imported=preload("res://scripts/studio_bundle.gd").read(zip);check(imported.error.is_empty() and imported.payload.progress.media_portfolio.size()==8,"photo portfolio roundtrip")
 check(imported.payload.studio.abilities[attack.name].sound.data==sound.data,"sound bytes roundtrip with saved ability")
 var z=ZIPReader.new();z.open(zip);check(z.get_files().has("photography/frame-1.png") and z.get_files().has("photography/reflections.md"),"teacher-friendly photography folder");z.close()
 game.legacy.answer("gameDev");game.legacy.answer("R4ms!90");check(game.media.enabled(),"Game Dev receives photography tools")
 game.media.apply_clean(true);check(not root.get_node("FXDevSession").overlay.visible,"clean capture hides Game Dev border");game.media.apply_clean(false)
 check(not Portfolio.add(game,im,"test","no account changes"),"testing mode does not save portfolio")
 var invalid=game.legacy.data.media_portfolio.duplicate(true);invalid[0].image="bad";check(not Portfolio.valid(invalid),"invalid thumbnail rejected")
 current_scene=null;game.queue_free();player.queue_free()
 for n in 3:await process_frame
 print("V136 FAILURES: ",failures);quit(failures)
