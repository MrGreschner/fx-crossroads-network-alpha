extends RefCounted
## Local saves retain a last-good copy; schema validation stays with the owning system.
static func dev_session()->Node:
 var tree:=Engine.get_main_loop() as SceneTree
 return tree.root.get_node_or_null("FXDevSession") if tree!=null else null
static func testing()->bool:
 var session:=dev_session()
 var research=(Engine.get_main_loop() as SceneTree).root.get_node_or_null("FXResearch")
 return (research!=null and (research.active or research.discarding)) or (session!=null and (session.active or session.discarding)) or (Engine.get_main_loop() as SceneTree).root.has_meta("fx_dev_match")
static func progression_blocked()->bool:
 var tree=Engine.get_main_loop() as SceneTree
 return testing() or (tree!=null and tree.root.has_meta("fx_practice_continue")) or preload("res://scripts/record_eligibility.gd").blocked()
static func read(path:String,accept:Callable=Callable())->Dictionary:
 var session:=dev_session()
 if session!=null and session.active and session.memory.has(path):
  var value:Dictionary=session.memory[path].duplicate(true)
  return value if not accept.is_valid() or bool(accept.call(value)) else {}
 for candidate in [path,path+".bak"]:
  if not FileAccess.file_exists(candidate):continue
  var parser:=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(candidate))!=OK:continue
  var parsed:Variant=parser.data
  if parsed is Dictionary and (not accept.is_valid() or bool(accept.call(parsed))):return parsed
 return {}
static func write(path:String,value:Dictionary,serialized:String="",accept:Callable=Callable())->Error:
 var tree=Engine.get_main_loop() as SceneTree
 if tree!=null and tree.root.has_meta("fx_local_recovery") and not path.begins_with("user://fx_cloud_") and path!="user://fx_before_cloud.json":return ERR_UNAUTHORIZED
 if testing():
  if dev_session()!=null and dev_session().active:dev_session().memory[path]=value.duplicate(true)
  return OK
 if FileAccess.file_exists(path) and not FileAccess.file_exists(path+".recovery"):
  var probe=JSON.new()
  if probe.parse(FileAccess.get_file_as_string(path))!=OK or not probe.data is Dictionary:DirAccess.copy_absolute(path,path+".recovery")
 if accept.is_valid() and not bool(accept.call(value)):return ERR_INVALID_DATA
 var temp:=path+".tmp";var file:=FileAccess.open(temp,FileAccess.WRITE)
 if file==null:return FileAccess.get_open_error()
 file.store_string(serialized if not serialized.is_empty() else JSON.stringify(value));file.flush();file.close()
 if FileAccess.file_exists(path):
  var parser:=JSON.new()
  var valid:bool=parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data is Dictionary
  if valid and accept.is_valid():valid=bool(accept.call(parser.data))
  if valid:
   var copied:=DirAccess.copy_absolute(path,path+".bak")
   if copied!=OK:DirAccess.remove_absolute(temp);return copied
 var error:=DirAccess.rename_absolute(temp,path)
 if error==OK:return OK
 # Some platforms cannot rename over an existing destination. The backup remains.
 if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
 error=DirAccess.rename_absolute(temp,path)
 if error!=OK and FileAccess.file_exists(path+".bak"):DirAccess.copy_absolute(path+".bak",path)
 return error
static func erase(path:String)->void:
 if testing():
  if dev_session()!=null and dev_session().active:dev_session().memory[path]={}
  return
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
