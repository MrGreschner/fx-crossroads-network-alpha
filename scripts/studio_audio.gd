extends Node
## Portable, bounded student SFX. No paths or executable code in ability files.
const MAX_BYTES=131072
const MAX_SECONDS=4.0
var cache:Dictionary={}
var voices:Array[AudioStreamPlayer]=[]
var last_play=-1000
var web_callback:JavaScriptObject
var imported:Callable
static func base64_ok(text:String)->bool:
 if text.is_empty() or text.length()%4!=0:return false
 var regex=RegEx.new();regex.compile("^[A-Za-z0-9+/]*={0,2}$")
 return regex.search(text)!=null
static func stream_for(sound:Dictionary)->AudioStream:
 if not base64_ok(str(sound.get("data",""))):return null
 var bytes=Marshalls.base64_to_raw(str(sound.get("data","")))
 if bytes.size()>MAX_BYTES or bytes.size()<16:return null
 if sound.get("format")=="wav":
  if bytes.slice(0,4).get_string_from_ascii()!="RIFF" or bytes.slice(8,12).get_string_from_ascii()!="WAVE":return null
  return AudioStreamWAV.load_from_buffer(bytes,{"force/max_rate":true,"force/max_rate_hz":22050,"force/mono":true})
 if sound.get("format")=="mp3":return AudioStreamMP3.load_from_buffer(bytes)
 return null
static func example(name:String)->Dictionary:
 if not name in ["swing","shot","heal","magic","flame","water","metal","bow"]:return {}
 var examples=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/example-sounds.json"))
 return examples.get(name,{}) if examples is Dictionary else {}
static func validate(sound:Variant)->String:
 if not sound is Dictionary:return "Sound must be a portable audio object."
 if sound.is_empty():return ""
 if sound.size()!=5 or not sound.has_all(["name","format","data","volume_db","pitch"]):return "Invalid sound fields."
 if not sound.name is String or sound.name.length()>80 or not sound.data is String or sound.data.length()>174764:return "Use a short sound under 128 KB."
 if not sound.format in ["wav","mp3"]:return "Export WAV from BandLab on the web, or WAV/MP3 from your audio editor."
 if not (sound.volume_db is float or sound.volume_db is int) or not is_finite(float(sound.volume_db)) or float(sound.volume_db)<-36 or float(sound.volume_db)>-6:return "Sound level must be −36 to −6 dB."
 if not (sound.pitch is float or sound.pitch is int) or not is_finite(float(sound.pitch)) or float(sound.pitch)<.5 or float(sound.pitch)>2:return "Pitch must be 0.5–2.0."
 var stream=stream_for(sound)
 if stream==null or stream.get_length()<=0 or stream.get_length()>MAX_SECONDS:return "Use a valid WAV/MP3 effect lasting at most four seconds."
 return ""
func play_sound(sound:Dictionary)->bool:
 if sound.is_empty() or Time.get_ticks_msec()-last_play<100:return false
 var key=str(sound.get("data","")).sha256_text()
 if not cache.has(key):
  if not validate(sound).is_empty():return false
  if cache.size()>=8:cache.clear()
  cache[key]=stream_for(sound)
 if voices.is_empty():
  for n in 4:
   var player=AudioStreamPlayer.new();add_child(player);voices.append(player)
 for player in voices:
  if player.playing:continue
  player.stream=cache[key];player.volume_db=float(sound.get("volume_db",-12));player.pitch_scale=float(sound.get("pitch",1));player.play();last_play=Time.get_ticks_msec();return true
 return false
func choose(done:Callable)->void:
 imported=done
 if OS.has_feature("web"):
  web_callback=JavaScriptBridge.create_callback(web_read);JavaScriptBridge.get_interface("window").fxStudioAudio=web_callback
  JavaScriptBridge.eval("(()=>{const p=document.createElement('input');p.type='file';p.accept='.wav,.mp3';p.onchange=()=>{const f=p.files[0];if(!f)return;if(f.size>2097152){window.fxStudioAudio('TOO_LARGE','');return;}const r=new FileReader();r.onload=()=>window.fxStudioAudio(f.name,String(r.result).split(',')[1]);r.readAsDataURL(f);};p.click();})()",true)
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;dialog.filters=PackedStringArray(["*.wav,*.mp3 ; Short attack sound"]);add_child(dialog)
  dialog.file_selected.connect(func(path:String):
   var f=FileAccess.open(path,FileAccess.READ)
   if f==null or f.get_length()>2097152:deliver("","");return
   deliver(path.get_file(),Marshalls.raw_to_base64(f.get_buffer(f.get_length())));dialog.queue_free())
  dialog.canceled.connect(dialog.queue_free)
  dialog.popup_centered(Vector2i(850,480))
func web_read(args:Array)->void:
 if args.size()>=2:deliver(str(args[0]),str(args[1]))
func deliver(filename:String,encoded:String)->void:
 var sound={"name":filename.left(80),"format":filename.get_extension().to_lower(),"data":prepare_wav(encoded,16000) if filename.get_extension().to_lower()=="wav" else encoded,"volume_db":-12.0,"pitch":1.0}
 var issue=validate(sound)
 if imported.is_valid():imported.call(sound if issue.is_empty() else {},issue)

static func prepare_wav(encoded:String,rate:int)->String:
 if not base64_ok(encoded) or encoded.length()>44739244:return ""
 var stream=AudioStreamWAV.load_from_buffer(Marshalls.base64_to_raw(encoded),{"force/max_rate":true,"force/max_rate_hz":rate,"force/mono":true,"compress/mode":0})
 if stream==null:return ""
 var path="user://fx_prepared_audio.wav"
 if stream.save_to_wav(path)!=OK:return ""
 var output=FileAccess.get_file_as_bytes(path);DirAccess.remove_absolute(path)
 return Marshalls.raw_to_base64(output)
