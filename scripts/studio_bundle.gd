extends RefCounted
const Library=preload("res://scripts/studio_library.gd")
const Project=preload("res://scripts/workshop_project.gd")
const Music=preload("res://scripts/music_library.gd")
const MAX_BYTES=134217728
static func make(payload:Dictionary,path:String)->Error:
 var writer=ZIPPacker.new();var issue=writer.open(path)
 if issue!=OK:return issue
 put(writer,"profile.json",JSON.stringify(payload,"  "))
 put(writer,"READ-ME.txt","FX Crossroads player bundle\n\nUpload this entire ZIP in the game's main menu to restore progress and Studio work.\nheroes/ contains individual portable hero projects: send one of these JSON files to your teacher or a friend.\nobjects/ and realms/ contain editable portable world designs.\nabilities/ contains saved custom attacks and their animations.\nenemies/ and behaviors/ contain portable enemy designs and decision programs.\nTo add a shared hero, import its JSON in Crossroads Studio, then Add to Custom Hall.\nYou may also put valid hero JSON files in heroes/ and re-ZIP with profile.json at the root. No script files are executed.\nphotography/ contains small portfolio images and written reflections; full-resolution photos download separately.\nmusic/ contains portable student recordings and location assignments.\nlearning/ contains an outcome portfolio, teacher feedback, report and vector card exports.\nKeep a backup before sharing a computer.\n")
 var photos:Array=payload.get("progress",{}).get("media_portfolio",[])
 if preload("res://scripts/media_portfolio.gd").valid(photos):
  put(writer,"photography/reflections.md",preload("res://scripts/media_portfolio.gd").report(photos))
  for i in photos.size():
   writer.start_file("photography/frame-"+str(i+1)+".png");writer.write_file(Marshalls.base64_to_raw(photos[i].image));writer.close_file()
 var music=Music.load_data()
 put(writer,"music/settings.json",JSON.stringify({"assignments":music.assignments,"enabled":music.enabled}))
 for id in music.tracks:put(writer,"music/"+str(id).validate_filename()+".music.json",JSON.stringify(music.tracks[id]))
 var data=Library.load_data()
 put(writer,"studio/creation-journey.json",JSON.stringify(data.cycle,"  "))
 for id in data.heroes:put(writer,"heroes/"+str(data.heroes[id].hero.name).validate_filename().left(40)+"-"+str(id)+".hero.json",JSON.stringify(data.heroes[id],"  "))
 for id in data.abilities:put(writer,"abilities/"+str(id).validate_filename().left(50)+".ability.json",JSON.stringify({"format":"fx-crossroads-ability","version":1,"attack":data.abilities[id]},"  "))
 for key in data.get("enemies",{}):put(writer,"enemies/"+str(data.enemies[key].name).validate_filename().left(40)+"-"+str(key).validate_filename().left(30)+".enemy.json",JSON.stringify(data.enemies[key],"  "))
 for key in data.get("behaviors",{}):put(writer,"behaviors/"+str(key).validate_filename().left(50)+".behavior.json",JSON.stringify(data.behaviors[key],"  "))
 if FileAccess.file_exists(Project.PATH):
  var draft=JSON.parse_string(FileAccess.get_file_as_string(Project.PATH))
  if Project.validate(draft).is_empty():put(writer,"studio/draft.hero.json",JSON.stringify(draft,"  "))
 for collection in ["objects","realms"]:
  for key in data.get(collection,{}):put(writer,collection+"/"+str(key).validate_filename().left(50)+".json",JSON.stringify(data[collection][key],"  "))
 for entry in [["enemy","res://scripts/studio_enemy_project.gd"],["behavior","res://scripts/studio_behavior.gd"]]:
  var path_draft="user://fx_"+entry[0]+"_lab.json"
  if FileAccess.file_exists(path_draft):
   var draft=JSON.parse_string(FileAccess.get_file_as_string(path_draft))
   if load(entry[1]).validate(draft).is_empty():put(writer,"studio/draft."+entry[0]+".json",JSON.stringify(draft))
 for kind in ["object","realm"]:
  var draft_path="user://fx_"+kind+"_lab.json"
  if FileAccess.file_exists(draft_path):
   var f=FileAccess.open(draft_path,FileAccess.READ)
   if f!=null and f.get_length()<=Project.MAX_BYTES:
    var v=JSON.parse_string(f.get_as_text())
    if preload("res://scripts/studio_world_project.gd").validate(kind,v).is_empty():put(writer,"studio/draft."+kind+".json",JSON.stringify(v))
 var learning=preload("res://scripts/learning_store.gd").load_data()
 put(writer,"learning/portfolio.json",JSON.stringify(learning,"  "))
 put(writer,"learning/outcome-report.md",preload("res://scripts/learning_store.gd").report(learning))
 for id in learning.artifacts:
  var a:Dictionary=learning.artifacts[id]
  if a.kind=="graphic":
   put(writer,"learning/"+str(id).left(12)+".svg",a.value.svg)
   writer.start_file("learning/"+str(id).left(12)+".png");writer.write_file(Marshalls.base64_to_raw(a.value.image));writer.close_file()
 writer.close();return OK
static func put(writer:ZIPPacker,path:String,text:String)->void:
 writer.start_file(path);writer.write_file(text.to_utf8_buffer());writer.close_file()
static func read(path:String)->Dictionary:
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>MAX_BYTES:return {"error":"ZIP exceeds 128 MB."}
 var archive_bytes=FileAccess.get_file_as_bytes(path)
 var safety=zip_size_check(archive_bytes)
 if not safety.is_empty():return {"error":safety}
 var reader=ZIPReader.new()
 if reader.open(path)!=OK:return {"error":"Choose a valid Crossroads player ZIP."}
 var names=reader.get_files();var data={"heroes":{},"abilities":{},"enemies":{},"behaviors":{},"objects":{},"realms":{}};var total=0;var payload:Variant={};var draft:Dictionary={};var music=Music.fresh()
 if names.size()>256 or not "profile.json" in names:reader.close();return {"error":"ZIP needs profile.json at its root and at most 256 entries."}
 for name in names:
  if name.ends_with("/"):continue
  # Read only into memory; never extract user-controlled paths onto the filesystem.
  if ".." in name or name.begins_with("/") or "\\" in name:reader.close();return {"error":"Unsafe ZIP path."}
  if name!="profile.json" and not (name.begins_with("objects/") or name.begins_with("realms/") or name.begins_with("heroes/") or name.begins_with("abilities/") or name.begins_with("enemies/") or name.begins_with("behaviors/") or name.begins_with("music/") or name in ["studio/creation-journey.json","studio/draft.hero.json","studio/draft.enemy.json","studio/draft.behavior.json","studio/draft.object.json","studio/draft.realm.json"]):continue
  # ZIPReader has no metadata API. A compressed archive can be hostile; count/total/per-file decoded caps are checked before validation.
  var bytes=reader.read_file(name);total+=bytes.size()
  if bytes.size()>(67108864 if name=="profile.json" else 16777216 if name=="studio/creation-journey.json" else 12582912 if name.begins_with("music/") else Project.MAX_BYTES) or total>MAX_BYTES:reader.close();return {"error":"Expanded ZIP data exceeds the supported size."}
  var value=JSON.parse_string(bytes.get_string_from_utf8())
  if name=="profile.json":payload=value
  elif name=="studio/creation-journey.json":
   if not preload("res://scripts/studio_cycle.gd").valid(value):reader.close();return {"error":"Invalid creation journey."}
   data.cycle=value
  elif name=="music/settings.json":
   if not value is Dictionary or not value.get("assignments") is Dictionary or not value.get("enabled") is bool:reader.close();return {"error":"Invalid music settings."}
   music.assignments=value.assignments;music.enabled=value.enabled
  elif name.begins_with("music/"):
   var error=Music.validate_track(value)
   if not error.is_empty():reader.close();return {"error":error}
   music.tracks[value.id]=value
  elif name.begins_with("objects/") or name.begins_with("realms/"):
   var kind="object" if name.begins_with("objects/") else "realm"
   var issue=preload("res://scripts/studio_world_project.gd").validate(kind,value)
   if not issue.is_empty():reader.close();return {"error":issue}
   data["objects" if kind=="object" else "realms"][value.id]=value
  elif name.begins_with("heroes/"):
   var issue=Project.validate(value)
   if not issue.is_empty():reader.close();return {"error":name+": "+issue}
   data.heroes[Library.hero_id(value)]=value
  elif name.begins_with("abilities/"):
   if not value is Dictionary or value.get("format")!="fx-crossroads-ability":reader.close();return {"error":"Invalid ability file."}
   var issue=Project.validate_attack(value.get("attack"))
   if not issue.is_empty():reader.close();return {"error":issue}
   data.abilities[str(value.attack.name)]=value.attack
  elif name.begins_with("enemies/"):
   var issue=preload("res://scripts/studio_enemy_project.gd").validate(value)
   if not issue.is_empty():reader.close();return {"error":issue}
   data.enemies[value.id]=value
  elif name.begins_with("behaviors/"):
   var issue=preload("res://scripts/studio_behavior.gd").validate(value)
   if not issue.is_empty():reader.close();return {"error":issue}
   data.behaviors[value.name]=value
  elif name in ["studio/draft.object.json","studio/draft.realm.json"]:
   var kind="object" if name.ends_with("object.json") else "realm"
   var issue=preload("res://scripts/studio_world_project.gd").validate(kind,value)
   if not issue.is_empty():reader.close();return {"error":issue}
   draft[kind]=value
  elif name=="studio/draft.enemy.json" or name=="studio/draft.behavior.json":
   var kind="enemy" if name.ends_with("enemy.json") else "behavior"
   var issue=load("res://scripts/studio_"+("enemy_project" if kind=="enemy" else "behavior")+".gd").validate(value)
   if not issue.is_empty():reader.close();return {"error":issue}
   draft[kind]=value
  else:
   var issue=Project.validate(value)
   if not issue.is_empty():reader.close();return {"error":issue}
   draft["hero"]=value
 reader.close()
 var issue=Library.validate(data)
 if not issue.is_empty():return {"error":issue}
 if not payload is Dictionary:return {"error":"Invalid player profile."}
 var music_issue=Music.validate(music)
 if not music_issue.is_empty():return {"error":music_issue}
 payload.music=music
 payload.studio=data
 if draft.has("hero"):payload.studio_draft=draft.hero
 for kind in ["enemy","behavior","object","realm"]:
  if draft.has(kind):payload["studio_"+kind+"_draft"]=draft[kind]
 return {"error":"","payload":payload}

static func zip_size_check(bytes:PackedByteArray)->String:
 # Inspect central-directory sizes BEFORE Godot inflates any member.
 var end=-1
 for offset in range(bytes.size()-22,maxi(-1,bytes.size()-65558),-1):
  if offset>=0 and bytes.decode_u32(offset)==0x06054b50:end=offset;break
 if end<0:return "Missing ZIP directory."
 var count=int(bytes.decode_u16(end+10));var offset=int(bytes.decode_u32(end+16));var total=0
 if count>256 or bytes.decode_u16(end+4)!=0 or bytes.decode_u16(end+6)!=0:return "Unsupported split or oversized ZIP."
 for n in count:
  if offset<0 or offset+46>bytes.size() or bytes.decode_u32(offset)!=0x02014b50:return "Invalid ZIP directory."
  var flags=int(bytes.decode_u16(offset+8));var method=int(bytes.decode_u16(offset+10));var size=int(bytes.decode_u32(offset+24))
  if flags&1 or not method in [0,8]:return "Encrypted or unsupported ZIP compression."
  var name_end=offset+46+int(bytes.decode_u16(offset+28))
  if name_end>bytes.size():return "Invalid ZIP filename."
  var filename=bytes.slice(offset+46,name_end).get_string_from_utf8()
  total+=size
  if size>(67108864 if filename=="profile.json" else 16777216 if filename=="studio/creation-journey.json" else 12582912 if filename.begins_with("music/") or filename=="learning/portfolio.json" else Project.MAX_BYTES) or total>MAX_BYTES:return "Expanded ZIP data exceeds the supported size."
  offset+=46+int(bytes.decode_u16(offset+28))+int(bytes.decode_u16(offset+30))+int(bytes.decode_u16(offset+32))
 return ""
