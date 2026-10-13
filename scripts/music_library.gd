extends RefCounted
## Portable recordings, not executable content. Keep large audio outside profile.json.
const PATH="user://fx_music_library.json"
const MAX_BYTES=8388608
const MAX_SECONDS=180.0
const Audio=preload("res://scripts/studio_audio.gd")
static var revision=0
static func fresh()->Dictionary:return {"tracks":{},"assignments":{},"enabled":true}
static func stream(track:Dictionary)->AudioStream:
 var bytes=Marshalls.base64_to_raw(str(track.get("data","")))
 if bytes.size()<16 or bytes.size()>MAX_BYTES:return null
 if track.get("audio_format")=="wav":
  if bytes.slice(0,4).get_string_from_ascii()!="RIFF" or bytes.slice(8,12).get_string_from_ascii()!="WAVE":return null
  return AudioStreamWAV.load_from_buffer(bytes,{"force/mono":true,"force/max_rate":true,"force/max_rate_hz":22050})
 if track.get("audio_format")=="mp3":return AudioStreamMP3.load_from_buffer(bytes)
 return null
static func validate_track(value:Variant)->String:
 if not value is Dictionary or not value.has_all(["format","version","id","title","author","notes","audio_format","data","volume_db"]):return "Choose a Crossroads music submission."
 if value.format!="fx-crossroads-music" or value.version!=1:return "Unsupported music version."
 for key in ["id","title","author","notes","audio_format","data"]:
  if not value[key] is String:return "Invalid music text."
 if value.id.is_empty() or value.id.length()>80 or value.title.length()>80 or value.author.length()>80 or value.notes.length()>1200:return "Music names or notes are too long."
 if value.data.length()>11184812 or not Audio.base64_ok(value.data):return "Prepared recording exceeds 8 MB."
 if not value.audio_format in ["wav","mp3"]:return "Use WAV from BandLab on the web, or MP3. M4A is not supported."
 if not (value.volume_db is int or value.volume_db is float) or not is_finite(float(value.volume_db)) or float(value.volume_db)<-36 or float(value.volume_db)>-6:return "Set music volume between −36 and −6 dB."
 var decoded=stream(value)
 if decoded==null or not is_finite(decoded.get_length()) or decoded.get_length()<=0 or decoded.get_length()>MAX_SECONDS+.05:return "Use a recording up to three minutes; shorter pieces loop."
 return ""
static func validate(data:Variant)->String:
 if not data is Dictionary or not data.get("tracks") is Dictionary or not data.get("assignments") is Dictionary or not data.get("enabled") is bool:return "Invalid music library."
 if data.tracks.size()>4 or data.assignments.size()>100:return "Keep up to four prototype tracks."
 var total=0
 for key in data.tracks:
  var issue=validate_track(data.tracks[key])
  if not issue.is_empty():return issue
  if key!=data.tracks[key].id:return "Music ID mismatch."
  total+=Marshalls.base64_to_raw(data.tracks[key].data).size()
 if total>MAX_BYTES:return "The four tracks must fit within 8 MB combined. Use MP3 for longer collections."
 for key in data.assignments:
  if not key is String or key.length()>100 or not data.assignments[key] is String or not data.tracks.has(data.assignments[key]):return "Invalid music assignment."
 return ""
static func load_data()->Dictionary:
 var data=preload("res://scripts/profile_store.gd").read(PATH)
 return data if data.has("tracks") else fresh()
static func save_data(data:Dictionary)->String:
 var issue=validate(data)
 if not issue.is_empty():return issue
 var error=preload("res://scripts/profile_store.gd").write(PATH,data)
 if error!=OK:return "Could not save music. Download your submission as a backup."
 revision+=1;return ""
static func prepare(name:String,encoded:String)->Dictionary:
 if encoded.length()>44739244 or not Audio.base64_ok(encoded):return {"error":"Import WAV up to 32 MB or MP3 up to 8 MB."}
 var kind=name.get_extension().to_lower()
 var track={"format":"fx-crossroads-music","version":1,"id":encoded.sha256_text().left(20),"title":name.get_basename().left(80),"author":"","notes":"","audio_format":kind,"data":Audio.prepare_wav(encoded,22050) if kind=="wav" else encoded,"volume_db":-18.0}
 var issue=validate_track(track)
 return {"error":issue,"track":track if issue.is_empty() else {}}
