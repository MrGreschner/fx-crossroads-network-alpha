extends CanvasLayer
const Library=preload("res://scripts/music_library.gd")
const UI=preload("res://scripts/studio_ui.gd")
var game:Node
var workshop:Node
var data:Dictionary
var selected=""
var panel:PanelContainer
var body:VBoxContainer
var notice:Label
var targets:Array=[]
var target="mode:town"
var callback:JavaScriptObject
var prior_menu=""
var playback:Label
var position_bar:ProgressBar
func setup(owner:Node,studio:Node=null)->void:
 game=owner;workshop=studio;layer=95;data=Library.load_data();prior_menu=game.menu;game.menu="music_studio"
 panel=PanelContainer.new();add_child(panel);panel.custom_minimum_size=Vector2(850,660);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col)
 var title=Label.new();title.text="MUSIC STUDIO • compose a world";title.add_theme_font_size_override("font_size",28);col.add_child(title)
 var help=Label.new();help.text="BandLab web: Project → Download → Mixdown As → WAV.\nUpload a piece up to 3 minutes. WAV is prepared automatically; short pieces loop.\nFour tracks / 8 MB combined. Keep your original BandLab project for final production.";help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(help)
 var row=HBoxContainer.new();col.add_child(row);button(row,"Upload WAV / MP3",choose_audio);button(row,"Import submission",choose_submission)
 playback=Label.new();col.add_child(playback)
 position_bar=ProgressBar.new();position_bar.show_percentage=false;position_bar.custom_minimum_size.y=8;col.add_child(position_bar)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=340;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll);body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(notice)
 var footer=HBoxContainer.new();col.add_child(footer);button(footer,"Listen",func():if data.tracks.has(selected):game.music.preview(data.tracks[selected]));button(footer,"Stop listening",func():game.music.stop_preview());button(footer,"Play realm",test_realm);button(footer,"Save & return",close)
 targets=[["Town","mode:town"],["Training Yard","mode:training"],["Cave Descent","mode:descent"],["North Gate Defence","mode:defense"],["Gladiator Arena","mode:arena"],["Battlegrounds","mode:battlegrounds"]]
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 for id in manifest.get("regions",[]):
  if id=="town":continue
  var realm=JSON.parse_string(FileAccess.get_file_as_string("res://content/regions/"+str(id)+".json"))
  if realm is Dictionary:targets.append([str(realm.get("name",id)),"realm:"+str(id)])
 if not data.tracks.is_empty():selected=data.tracks.keys()[0]
 render()
func button(parent:Node,text:String,action:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=40;parent.add_child(b);b.pressed.connect(action);return b
func edit(parent:Node,label:String,value:String,change:Callable)->void:
 var l=Label.new();l.text=label;parent.add_child(l)
 var e=LineEdit.new();e.text=value;parent.add_child(e);e.text_changed.connect(change)
func render()->void:
 for child in body.get_children():child.queue_free()
 var enabled=CheckButton.new();enabled.text="Use my prototype soundtrack (host selects music in multiplayer)";enabled.button_pressed=data.enabled;body.add_child(enabled);enabled.toggled.connect(func(value:bool):data.enabled=value;save())
 var picker=OptionButton.new();body.add_child(picker)
 for id in data.tracks:picker.add_item(data.tracks[id].title);picker.set_item_metadata(picker.item_count-1,id);if id==selected:picker.select(picker.item_count-1)
 picker.item_selected.connect(func(index:int):selected=picker.get_item_metadata(index);render())
 if selected.is_empty() or not data.tracks.has(selected):return
 var track:Dictionary=data.tracks[selected]
 edit(body,"Title",track.title,func(value:String):track.title=value.left(80))
 edit(body,"Student / composer",track.author,func(value:String):track.author=value.left(80))
 edit(body,"Production note • mood, instruments, audience",track.notes,func(value:String):track.notes=value.left(1200))
 var gain=HSlider.new();gain.min_value=-36;gain.max_value=-6;gain.step=1;gain.value=track.volume_db;body.add_child(gain)
 var gain_label=Label.new();gain_label.text="Music level: "+str(gain.value)+" dB";body.add_child(gain_label);gain.value_changed.connect(func(value:float):track.volume_db=value;gain_label.text="Music level: "+str(value)+" dB")
 var destination=OptionButton.new();body.add_child(destination)
 for item in targets:destination.add_item(item[0]);if item[1]==target:destination.select(destination.item_count-1)
 destination.item_selected.connect(func(index:int):target=targets[index][1])
 var row=HBoxContainer.new();body.add_child(row);button(row,"Listen",func():game.music.preview(track));button(row,"Assign to selected location",func():data.assignments[target]=selected;save();notice.text="Assigned to "+target+". Enter that location to hear it.")
 button(body,"Play selected realm with this music",test_realm)
 var assigned=Label.new();assigned.text="Assigned: "+", ".join(data.assignments.keys());assigned.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(assigned)
 var export_row=HBoxContainer.new();body.add_child(export_row);button(export_row,"Download submission",export_track);button(export_row,"Remove track",remove_track)
func remove_track()->void:
 data.tracks.erase(selected)
 for key in data.assignments.keys():
  if data.assignments[key]==selected:data.assignments.erase(key)
 selected="" if data.tracks.is_empty() else data.tracks.keys()[0]
 save();render()

func save()->bool:
 var issue=Library.save_data(data);notice.text=issue if not issue.is_empty() else "Saved locally. Download your player ZIP to take music to another computer."
 return issue.is_empty()
func close()->void:
 if not save():return
 game.music.stop_preview();game.menu=prior_menu
 if is_instance_valid(workshop):workshop.show_hub()
 queue_free()
func test_realm()->void:
 if not target.begins_with("realm:"):notice.text="Choose a realm for instant solo testing. Other modes use their usual entrance.";return
 if game.get("started")!=null:notice.text="Return to town to start a solo music test.";return
 data.assignments[target]=selected
 if not save():return
 game.music.stop_preview();game.menu=""
 if is_instance_valid(workshop):workshop.close()
 game.start_run(false,target.trim_prefix("realm:"));queue_free()
func choose_audio()->void:choose(false)
func choose_submission()->void:choose(true)
func choose(submission:bool)->void:
 if OS.has_feature("web"):
  callback=JavaScriptBridge.create_callback(func(args:Array):if args.size()>=2:receive(str(args[0]),str(args[1]),submission))
  JavaScriptBridge.get_interface("window").fxMusicUpload=callback
  JavaScriptBridge.eval("(()=>{const p=document.createElement('input');p.type='file';p.accept='"+(".json" if submission else ".wav,.mp3")+"';p.onchange=()=>{const f=p.files[0];if(!f)return;if(f.size>33554432){window.fxMusicUpload('TOO_LARGE','');return;}const r=new FileReader();r.onload=()=>window.fxMusicUpload(f.name,String(r.result).split(',')[1]);r.readAsDataURL(f);};p.click();})()",true)
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;dialog.filters=PackedStringArray(["*.json ; Music submission"] if submission else ["*.wav,*.mp3 ; BandLab WAV or MP3"]);add_child(dialog)
  dialog.file_selected.connect(func(path:String):var file=FileAccess.open(path,FileAccess.READ);if file!=null and file.get_length()<=33554432:receive(path.get_file(),Marshalls.raw_to_base64(file.get_buffer(file.get_length())),submission)
  );dialog.file_selected.connect(func(_path:String):dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(850,500))
func receive(name:String,encoded:String,submission:bool)->void:
 var result:Dictionary
 if submission:
  var track=JSON.parse_string(Marshalls.base64_to_raw(encoded).get_string_from_utf8());result={"error":Library.validate_track(track),"track":track}
 else:result=Library.prepare(name,encoded)
 if not result.error.is_empty():notice.text=result.error;return
 var updated=data.duplicate(true);updated.tracks[result.track.id]=result.track
 var issue=Library.validate(updated)
 if not issue.is_empty():notice.text=issue;return
 data=updated;selected=result.track.id;save();render()
func export_track()->void:
 if not save():return
 if preload("res://scripts/profile_store.gd").testing():notice.text="Exit testing mode before exporting a submission.";return
 var text=JSON.stringify(data.tracks[selected],"  ");var filename=str(data.tracks[selected].title).validate_filename()+".music.json"
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const a=document.createElement('a');a.href=URL.createObjectURL(new Blob(["+JSON.stringify(text)+"],{type:'application/json'}));a.download="+JSON.stringify(filename)+";a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);})()",true)
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;dialog.current_file=filename;add_child(dialog);dialog.file_selected.connect(func(path:String):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_string(text)
  );dialog.file_selected.connect(func(_path:String):dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(850,500))
func _process(_delta:float)->void:
 if game.music.voice!=null and game.music.voice.stream!=null:
  var length=game.music.voice.stream.get_length();var elapsed=game.music.voice.get_playback_position();playback.text="Listening • "+str(roundi(elapsed))+" / "+str(roundi(length))+" sec • global Sound mute applies";position_bar.max_value=maxf(1,length);position_bar.value=elapsed
 else:playback.text="Listen, assign a location, then test in the game.";position_bar.value=0
 panel.scale=Vector2.ONE*minf(1,minf((game.VIEW.x-32)/850,(game.VIEW.y-32)/maxf(660,panel.size.y)));panel.position=(game.VIEW-panel.size*panel.scale)*.5
