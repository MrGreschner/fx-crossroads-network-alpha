extends SceneTree
const Audio=preload("res://scripts/studio_audio.gd")
const Music=preload("res://scripts/music_library.gd")
const Bundle=preload("res://scripts/studio_bundle.gd")
var failures=0
func check(value:bool,label:String)->void:
 print("PASS • " if value else "FAIL • ",label)
 if not value:failures+=1
func wav(seconds:float)->PackedByteArray:
 var count=int(44100*seconds);var b=PackedByteArray();b.resize(44+count*4)
 for i in 4:b[i]="RIFF".to_ascii_buffer()[i];b[8+i]="WAVE".to_ascii_buffer()[i];b[12+i]="fmt ".to_ascii_buffer()[i];b[36+i]="data".to_ascii_buffer()[i]
 b.encode_u32(4,b.size()-8);b.encode_u32(16,16);b.encode_u16(20,1);b.encode_u16(22,2);b.encode_u32(24,44100);b.encode_u32(28,176400);b.encode_u16(32,4);b.encode_u16(34,16);b.encode_u32(40,count*4)
 return b
func _initialize()->void:call_deferred("run")
func run()->void:
 var audio=Audio.new();root.add_child(audio)
 var result:Dictionary={}
 audio.imported=func(sound:Dictionary,issue:String):result.sound=sound;result.issue=issue
 audio.deliver("BandLab.wav",Marshalls.raw_to_base64(wav(4)))
 check(result.issue.is_empty(),"BandLab 44.1 kHz stereo WAV effect prepared automatically")
 check(Marshalls.base64_to_raw(result.sound.get("data","")).size()<=Audio.MAX_BYTES,"prepared effect remains under 128 KB")
 check(absf(Audio.stream_for(result.sound).get_length()-4)<.02,"preparation preserves effect duration")
 var prepared=Music.prepare("River song.wav",Marshalls.raw_to_base64(wav(10)))
 check(prepared.error.is_empty(),"BandLab WAV music accepted")
 var track:Dictionary=prepared.track
 var data=Music.fresh();data.tracks[track.id]=track;data.assignments["realm:grove"]=track.id
 check(Music.save_data(data).is_empty(),"music library saved")
 check(Music.load_data().tracks.has(track.id),"music restores on device")
 var invalid=track.duplicate();invalid.volume_db=INF;check(not Music.validate_track(invalid).is_empty(),"invalid music volume rejected")
 invalid=track.duplicate();invalid.audio_format="m4a";check(not Music.validate_track(invalid).is_empty(),"unsupported M4A gives useful error")
 invalid=track.duplicate();invalid.data="broken";check(not Music.validate_track(invalid).is_empty(),"corrupt audio rejected")
 invalid=data.duplicate(true);invalid.assignments["realm:grove"]="missing";check(not Music.validate(invalid).is_empty(),"missing music assignment rejected")
 check(not Music.prepare("Long.wav",Marshalls.raw_to_base64(wav(181))).error.is_empty(),"long music rejected")
 for path in ["fellowship_v109","relay_v109","mistglass_v109","barracks_v109","mill_v109","training_outpost","training_hero_book","guard_melee","guard_ranged"]:
  check(preload("res://scripts/source_art.gd").texture("res://assets/"+path+".svg")!=null,"import-independent startup art "+path)
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 for n in 5:await process_frame
 game.set_process(false);game.presentation.close();game.session_menu.resume();game.music._process(.3)
 check(game.music.context()=="mode:town","town music context correct")
 var studio=preload("res://scripts/music_studio.gd").new();game.add_child(studio);studio.setup(game)
 check(studio.targets.size()>20,"all realm music destinations available")
 check(game.menu=="music_studio","music UI prevents accidental attacks")
 studio.target="realm:grove";studio.test_realm()
 await process_frame
 game.music._process(.3)
 check(game.mode=="run" and game.active_realm=="grove","music test enters selected realm")
 check(game.music.voice.stream!=null and game.music.selected.id==track.id,"realm plays assigned prototype")
 game.music.preview(track);check(game.music.audition,"preview player runs")
 game.music.stop_preview();check(not game.music.audition,"preview stop restores gameplay music")
 game.enter_region("town");game.menu="";game.music._process(.3)
 check(game.music.voice.stream==null,"unassigned location stops prototype")
 var payload=game.legacy.bundle()
 check(Bundle.make(payload,"user://v137-test.zip")==OK,"music included in player ZIP")
 var reader=ZIPReader.new();reader.open("user://v137-test.zip")
 check(reader.file_exists("music/"+track.id+".music.json"),"teacher-friendly recording file in ZIP")
 reader.close()
 var imported=Bundle.read("user://v137-test.zip")
 check(imported.error.is_empty(),"music player ZIP validates")
 check(imported.payload.music.tracks.has(track.id),"music bytes roundtrip")
 check(game.legacy.validate(imported.payload),"player profile accepts music payload")
 var dev=root.get_node("FXDevSession");dev.active=true
 var temporary=data.duplicate(true);temporary.enabled=false;Music.save_data(temporary)
 check(not Music.load_data().enabled,"Game Dev music changes are session-only")
 dev.active=false
 check(Music.load_data().enabled,"normal music library survives Dev session")
 game.queue_free();audio.queue_free();await process_frame
 print("V137 FAILURES: ",failures);quit(1 if failures else 0)
