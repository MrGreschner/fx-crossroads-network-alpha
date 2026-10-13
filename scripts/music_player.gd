extends Node
## One music voice, one decoded track. Transfers are handled outside gameplay snapshots.
const Library=preload("res://scripts/music_library.gd")
var game:Node
var voice:AudioStreamPlayer
var library:Dictionary={}
var revision=-1
var tick=0.0
var current=""
var audition=false
var remote:Dictionary={}
var remote_position=0.0
var remote_position_at=0
var selected:Dictionary={}
var testing_before=false
func setup(owner:Node)->void:
 game=owner;voice=AudioStreamPlayer.new();add_child(voice)
 voice.finished.connect(func():if voice.stream!=null:voice.play())
func context()->String:
 if game.get("started")!=null and not game.started:return ""
 if game.session_menu!=null and not game.session_menu.page.is_empty():return ""
 if game.mode=="run":return "mode:training" if game.trial else "realm:"+str(game.active_realm)
 if game.mode=="coop":return "realm:"+str(game.realm_id)
 return "mode:"+str(game.mode)
func _process(delta:float)->void:
 if voice==null:return
 tick+=delta
 if tick<.25:return
 tick=0
 var testing=preload("res://scripts/profile_store.gd").testing()
 if testing!=testing_before:testing_before=testing;revision=-1
 if revision!=Library.revision:revision=Library.revision;library=Library.load_data();current=""
 if audition:return
 var target=context()
 var track:Dictionary={}
 if game.get("role")=="guest":track=remote if remote.get("context")==target else {}
 elif library.get("enabled",true):track=library.get("tracks",{}).get(library.get("assignments",{}).get(target,""),{})
 var key=target+":"+str(track.get("id",""))+":"+str(track.get("volume_db",0))
 if key==current:return
 current=key;selected=track;voice.stop();voice.stream=null
 if not track.is_empty():voice.stream=Library.stream(track);voice.volume_db=float(track.volume_db);voice.play(fmod(remote_position+(Time.get_ticks_msec()-remote_position_at)/1000.0,maxf(.1,voice.stream.get_length())) if game.get("role")=="guest" else 0.0)
 elif not target.is_empty():
  var official=JSON.parse_string(FileAccess.get_file_as_string("res://content/music/official.json"))
  if official is Dictionary and official.has(target):
   var entry:Dictionary=official[target]
   var path=str(entry.get("path",""))
   if path.ends_with(".music.json") and FileAccess.file_exists(path):
    var submission=JSON.parse_string(FileAccess.get_file_as_string(path))
    if Library.validate_track(submission).is_empty():voice.stream=Library.stream(submission);voice.volume_db=clampf(float(entry.get("volume_db",submission.volume_db)),-36,-6);voice.play()
   elif ResourceLoader.exists(path):
    voice.stream=load(entry.path);voice.volume_db=clampf(float(entry.get("volume_db",-18)),-36,-6);voice.play()
func preview(track:Dictionary)->void:
 audition=true;voice.stop();voice.stream=Library.stream(track);voice.volume_db=float(track.get("volume_db",-18));voice.play()
func stop_preview()->void:audition=false;voice.stop();current=""
