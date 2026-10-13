extends RefCounted
## Leaf changes preserve independent edits; same leaf is ordered by the server.
static func diff(before:Variant,after:Variant,path:Array=[])->Array:
 var ops:Array=[]
 if before is Dictionary and after is Dictionary:
  for key in before:
   if not after.has(key):ops.append({"path":path+[key],"erase":true})
  for key in after:
   if key=="revision":continue
   if not before.has(key):ops.append({"path":path+[key],"value":after[key]})
   else:ops.append_array(diff(before[key],after[key],path+[key]))
 elif before!=after:ops.append({"path":path,"value":after})
 return ops
static func get_at(value:Variant,path:Array)->Variant:
 for key in path:
  if value is Dictionary:value=value.get(key)
  elif value is Array and (key is int or key is float) and key>=0 and key<value.size():value=value[int(key)]
  else:return null
 return value
static func set_at(value:Variant,path:Array,content:Variant,erase:bool=false)->bool:
 if path.is_empty():return false
 var parent=get_at(value,path.slice(0,-1));var key=path.back()
 if parent is Array and (key is float or key is int):key=int(key)
 if parent is Dictionary:
  if erase:parent.erase(key)
  else:parent[key]=content
  return true
 if parent is Array and (key is int or key is float) and key>=0 and key<=parent.size():
  if key==parent.size() and not erase:parent.append(content)
  elif key<parent.size():
   if erase:parent.remove_at(key)
   else:parent[key]=content
  return true
 return false
static func merge_into(target:Dictionary,source:Dictionary)->void:
 for key in target.keys():
  if not source.has(key):target.erase(key)
 for key in source:
  if target.get(key) is Dictionary and source[key] is Dictionary:merge_into(target[key],source[key])
  else:target[key]=source[key]
