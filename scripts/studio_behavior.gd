extends RefCounted
## Portable decisions: typed context, bounded branches/loops, whitelisted actions.
const FORMAT="fx-crossroads-behavior"
const VARIABLES={"preferred_range":[40,400],"retreat_range":[20,300],"chase_range":[100,700],"health_threshold":[10,80]}
const CONTEXT=["distance","health","time","charged","targets","cycle"]
const ENEMY_COMMANDS={"move":["chase","retreat","orbit","hold","patrol"],"use":["primary","secondary","special"],"guard":["on"]}
const ABILITY_COMMANDS={"flight":["straight","wave","homing","return","lob"],"aim":["direction","cursor","nearest"],"impact":["burst","direct"]}
static func fresh(kind:String="enemy")->Dictionary:
 return {"format":FORMAT,"version":1,"name":"Keep your distance" if kind=="enemy" else "Living flight","kind":kind,"program":template(kind)}
static func template(kind:String)->String:
 if kind=="ability":return "# Change flight according to the charged state.\nif charged > 0\n  flight homing\n  impact burst\nelif targets > 0\n  flight wave\nelse\n  flight straight\nend\naim direction\n"
 return "# A ranged enemy keeps space, then uses its attacks.\nlet preferred_range = 190\nlet retreat_range = 120\nif distance > preferred_range\n  move chase\nelif distance < retreat_range\n  move retreat\nelse\n  move orbit\nend\nif distance < 350\n  use primary\nend\nif health < 40\n  guard on\n  use secondary\n  use special\nend\n"
static func validate(value:Variant)->String:
 if not value is Dictionary or value.get("format")!=FORMAT or value.get("version")!=1:return "Not a Crossroads behaviour file."
 for key in value:
  if not key in ["format","version","name","kind","program","forced_balance"]:return "Unknown behaviour field: "+str(key)
 if not value.get("name") is String or value.name.strip_edges().is_empty() or value.name.length()>60:return "Give this behaviour a short name."
 if not value.get("kind") in ["enemy","ability"] or not value.get("program") is String:return "Choose an enemy or ability behaviour."
 if value.has("forced_balance") and not value.forced_balance is bool:return "Invalid balance toggle."
 return compile(value.program,value.kind).error
static func compile(source:String,kind:String)->Dictionary:
 if source.length()>6000:return fail(0,"Keep code below 6,000 characters.")
 var variables={"preferred_range":190.0,"retreat_range":120.0,"chase_range":500.0,"health_threshold":40.0}
 var root:Array=[];var stack:Array=[root];var blocks:Array=[];var count=0;var line_number=0
 var commands=ENEMY_COMMANDS if kind=="enemy" else ABILITY_COMMANDS
 for raw in source.split("\n"):
  line_number+=1;var line=raw.split("#")[0].strip_edges().replace("else if ","elif ")
  if line.is_empty():continue
  var parts=line.split(" ",false)
  if parts[0]=="let":
   if parts.size()!=4 or parts[2]!="=" or not VARIABLES.has(parts[1]) or not parts[3].is_valid_float():return fail(line_number,"Use let preferred_range = 190 or another supported setting.")
   var number=float(parts[3]);var limits:Array=VARIABLES[parts[1]]
   if not is_finite(number) or number<limits[0] or number>limits[1]:return fail(line_number,"Setting outside its supported range.")
   variables[parts[1]]=number
  elif parts[0] in ["if","elif"]:
   if parts.size()!=4 or not parts[1] in CONTEXT or not parts[2] in ["<",">","<=",">=","=="] or not (parts[3].is_valid_float() or variables.has(parts[3])):return fail(line_number,"Use if distance < 150, elif health < 40, or a named setting.")
   if parts[3].is_valid_float() and (not is_finite(float(parts[3])) or absf(float(parts[3]))>10000):return fail(line_number,"Comparison value is too large.")
   var branch={"test":parts.slice(1),"body":[]}
   if parts[0]=="if":
    if blocks.size()>=3:return fail(line_number,"Use at most three nested blocks.")
    var node={"branches":[branch]};stack.back().append(node);blocks.append({"type":"if","node":node,"else":false});stack.append(branch.body)
   else:
    if blocks.is_empty() or blocks.back().type!="if" or blocks.back().else:return fail(line_number,"elif must follow if, before else / end.")
    blocks.back().node.branches.append(branch);stack.pop_back();stack.append(branch.body)
  elif line=="else":
   if blocks.is_empty() or blocks.back().type!="if" or blocks.back().else:return fail(line_number,"else must follow an if branch.")
   var branch={"test":[],"body":[]};blocks.back().node.branches.append(branch);blocks.back().else=true;stack.pop_back();stack.append(branch.body)
  elif parts[0] in ["repeat","for"]:
   var token=parts[1] if parts.size()==2 and parts[0]=="repeat" else parts[3] if parts.size()==4 and parts[0]=="for" and parts[1]=="step" and parts[2]=="in" else ""
   if not token.is_valid_int() or int(token)<1 or int(token)>5 or blocks.size()>=3:return fail(line_number,"Use for step in 1–5; nesting is limited to three blocks.")
   var node={"repeat":int(token),"body":[]};stack.back().append(node);blocks.append({"type":"repeat"});stack.append(node.body)
  elif line=="end":
   if blocks.is_empty():return fail(line_number,"end has no matching block.")
   blocks.pop_back();stack.pop_back()
  elif parts.size()==2 and commands.has(parts[0]) and parts[1] in commands[parts[0]]:
   stack.back().append({"command":parts[0],"value":parts[1]});count+=1
   if count>24:return fail(line_number,"Keep at most 24 actions.")
  else:return fail(line_number,"Unknown instruction. Choose an action from the lab's guide.")
 if not blocks.is_empty():return fail(line_number,"Close each block with end.")
 if count==0:return fail(line_number,"Add an action such as move chase or flight wave.")
 return {"error":"","variables":variables,"instructions":root}
static func fail(line:int,message:String)->Dictionary:return {"error":"Line "+str(line)+": "+message}
static func evaluate(program:Dictionary,context:Dictionary)->Array:
 if not program.get("error","").is_empty():return []
 var values=program.variables.duplicate();values.merge(context,true);var result:Array=[];walk(program.instructions,values,result);return result
static func walk(nodes:Array,values:Dictionary,out:Array)->void:
 for node in nodes:
  if out.size()>=16:return
  if node.has("repeat"):
   for step in node.repeat:walk(node.body,values,out)
  elif node.has("branches"):
   for branch in node.branches:
    if matches(branch.test,values):walk(branch.body,values,out);break
  else:out.append(node)
static func matches(test:Variant,values:Dictionary)->bool:
 if test.is_empty():return true
 var left=float(values.get(test[0],0));var right=float(test[2]) if test[2].is_valid_float() else float(values.get(test[2],0))
 match test[1]:
  "<":return left<right
  ">":return left>right
  "<=":return left<=right
  ">=":return left>=right
  "==":return is_equal_approx(left,right)
 return false

static func presets()->Dictionary:
 return {
 "Attack": "# Close the gap and strike.\nmove chase\nif distance < 115\n use primary\n use secondary\n use special\nend",
 "Keep distance": template("enemy"),
 "Charge & flee": "# A six-second charge, hit and retreat cycle.\nif cycle < 2\n move chase\nelif cycle < 3\n move hold\n use primary\n use secondary\nelse\n move retreat\nend\nif health < 30\n use special\nend",
 "Sentry": "# Defend a position; strike approaching targets.\nmove hold\nguard on\nif distance < 400\n use primary\nend\nif distance < 110\n use secondary\n use special\nend",
 "Ambusher": "# Circle at distance, rush vulnerable targets.\nif distance > 260\n move chase\nelif cycle < 3\n move orbit\nelse\n move chase\n use primary\n use secondary\nend\nif health < 35\n move retreat\n use special\nend",
 "Support patrol": "# Patrol and use healing/buff/summoning attacks.\nmove patrol\nif distance < 450\n use primary\nend\nif health < 65\n use secondary\n use special\nend"}
