extends RefCounted
## Small, bounded teaching language. Never executes GDScript, JS, paths or system calls.
const COMMANDS=["projectile","homing","boomerang","beam","pulse","melee","field","heal","summon","dash","chain","lob","healing_field","slow_field","burn_field","stun_field","buff_field","vortex","mine","protect","siphon","burst"]
const VARIABLES={"damage":[0,60],"heal":[0,30],"range":[40,600],"radius":[20,180],"speed":[100,700],"count":[1,5],"duration":[.5,8],"cooldown":[.3,20],"charge":[0,2],"angle":[-180,180]}
static func template(a:Dictionary)->String:
 var command={"spin":"pulse","spread":"projectile","target_aoe":"lob","trap":"field","heal_wave":"heal","heal_zone":"heal","slow_aura":"field","flame":"melee","block":"heal"}.get(str(a.style),str(a.style))
 if not command in COMMANDS:command="projectile"
 var code="# Crossroads Script — bounded attack instructions\n"
 for key in ["damage","heal","range","radius","speed","count","duration","cooldown","charge"]:code+="let "+key+" = "+str(a[key])+"\n"
 code+="\n# A loop repeats an action. index starts at zero.\nrepeat count\n  emit "+command+" angle index * 12 - 12\nend\n\n# Logic: reward a nearly full charge.\nif charged\n  emit pulse\nelif targets\n  # Add an action here for a nearby target.\nelse\n  # Add a fallback action here.\nend\n"
 return code
static func compile(code:String)->Dictionary:
 if code.begins_with("# @structured"):
  var result=preload("res://scripts/structured_program.gd").compile(code)
  return {"error":result.error,"variables":{},"instructions":[{"structured":code}]}
 if code.length()>6000:return {"error":"Code is limited to 6,000 characters."}
 var vars={"damage":18.0,"heal":8.0,"range":180.0,"radius":70.0,"speed":350.0,"count":3.0,"duration":3.0,"cooldown":1.0,"charge":0.0,"angle":0.0}
 var root:Array=[];var stack:Array=[root];var blocks:Array=[];var line_number=0;var instructions=0
 for raw in code.split("\n"):
  line_number+=1;var line=raw.split("#")[0].strip_edges()
  if line.is_empty():continue
  line=line.replace("else if ","elif ")
  var parts=line.split(" ",false)
  if parts[0]=="let":
   if parts.size()!=4 or parts[2]!="=" or not VARIABLES.has(parts[1]) or not parts[3].is_valid_float():return fail(line_number,"Use let damage = 18, with a supported variable and number.")
   var value=float(parts[3]);var bounds:Array=VARIABLES[parts[1]]
   if not is_finite(value) or value<float(bounds[0]) or value>float(bounds[1]):return fail(line_number,parts[1]+" is outside its safe range.")
   if parts[1]=="count" and value!=floorf(value):return fail(line_number,"count must be a whole number.")
   vars[parts[1]]=value
  elif parts[0]=="repeat" or parts[0]=="for":
   if parts[0]=="for":
    if parts.size()!=4 or parts[1]!="index" or parts[2]!="in":return fail(line_number,"Use for index in count or for index in 1–5.")
    parts=PackedStringArray(["repeat",parts[3]])
   if parts.size()!=2 or stack.size()>3:return fail(line_number,"Use repeat count or repeat 1–5; nesting is limited to three blocks.")
   var times=int(vars.count) if parts[1]=="count" else int(parts[1]) if parts[1].is_valid_int() else 0
   if times<1 or times>5:return fail(line_number,"Repeat must be between 1 and 5.")
   var node={"repeat":times,"body":[],"uses_count":parts[1]=="count"};stack.back().append(node);stack.append(node.body);blocks.append({"type":"repeat"})
  elif line=="if charged" or line=="if targets":
   if stack.size()>3:return fail(line_number,"Too many nested blocks.")
   var branch={"condition":parts[1],"body":[]};var node={"branches":[branch]};stack.back().append(node);stack.append(branch.body);blocks.append({"type":"if","node":node,"else":false})
  elif parts[0]=="elif" or line=="else":
   if blocks.is_empty() or blocks.back().type!="if" or blocks.back().else:return fail(line_number,"elif / else must follow an if branch, before end.")
   if parts[0]=="elif" and (parts.size()!=2 or not parts[1] in ["charged","targets"]):return fail(line_number,"Use elif charged or elif targets.")
   var branch={"condition":parts[1] if parts[0]=="elif" else "always","body":[]};blocks.back().node.branches.append(branch);blocks.back().else=line=="else";stack.pop_back();stack.append(branch.body)
  elif line=="end":
   if stack.size()==1:return fail(line_number,"end has no matching repeat / if.")
   stack.pop_back();blocks.pop_back()
  elif parts[0]=="emit":
   if parts.size()<2 or not parts[1] in COMMANDS:return fail(line_number,"Choose an emit action from the command list.")
   var expression="0"
   if parts.size()>2:
    if parts[2]!="angle" or parts.size()<4:return fail(line_number,"After an action, use angle followed by a number or arithmetic.")
    expression=" ".join(parts.slice(3)).replace("angle",str(vars.angle))
    if not math_value(expression,0).ok:return fail(line_number,"Angles use numbers, index and + - * / only.")
   stack.back().append({"emit":parts[1],"angle":expression});instructions+=1
   if instructions>24:return fail(line_number,"Keep at most 24 emit instructions.")
  else:return fail(line_number,"Unknown instruction. Use let, repeat, if, emit or end.")
 if stack.size()!=1:return fail(line_number,"Close each repeat / if with end.")
 if instructions==0:return fail(line_number,"Add at least one emit action.")
 return {"error":"","variables":vars,"instructions":root}
static func fail(line:int,message:String)->Dictionary:return {"error":"Line "+str(line)+": "+message}
static func math_value(source:String,index:int)->Dictionary:
 # A whitelist precedes Expression: no identifiers except a numeric index, no functions or property access.
 var expression=source.replace("index",str(index))
 for character in expression:
  if not character in "0123456789.+-*/ ()":return {"ok":false,"value":0}
 var parser=Expression.new()
 if parser.parse(expression)!=OK:return {"ok":false,"value":0}
 var result=parser.execute([],null,false)
 if parser.has_execute_failed() or not (result is float or result is int) or not is_finite(float(result)):return {"ok":false,"value":0}
 return {"ok":true,"value":clampf(float(result),-180,180)}
static func actions(nodes:Array,charged:bool,targets:bool,index:int=0,output:Array=[],count_override:int=-1)->Array:
 for node in nodes:
  if node.has("structured"):continue
  if output.size()>=32:break
  if node.has("repeat"):
   for n in (count_override if node.get("uses_count",false) and count_override>0 else int(node.repeat)):actions(node.body,charged,targets,n,output,count_override)
  elif node.has("branches"):
   for branch in node.branches:
    if branch.condition=="always" or (charged if branch.condition=="charged" else targets):actions(branch.body,charged,targets,index,output,count_override);break
  elif node.has("condition"):
   if (charged if node.condition=="charged" else targets):actions(node.body,charged,targets,index,output,count_override)
  else:output.append({"command":node.emit,"angle":math_value(node.angle,index).value})
 return output
