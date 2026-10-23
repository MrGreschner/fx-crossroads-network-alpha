extends RefCounted
## Bounded source interpreter shared by the public Studio and assessed programming work.
const FORMAT="crossroads-structured-program"
const LIMIT=4096
static var programs:Dictionary={}
static var expressions:Dictionary={}
static var token_regex:RegEx
static func sample()->String:
 return "# @structured\n# Pick up to three different targets, then show total damage.\ninput base_damage\ninput jump_limit\ninput reach\ninput target_count\ninput distances\ninput shields\ninput used\nlet total = 0\nrepeat jump_limit\n  let chosen = -1\n  let nearest = reach\n  for enemy in target_count\n    if used[enemy] == false and distances[enemy] < nearest\n      let chosen = enemy\n      let nearest = distances[enemy]\n    end\n  end\n  if chosen >= 0\n    let used[chosen] = true\n    let damage = base_damage * (1 - index * 0.2)\n    if shields[chosen]\n      let damage = damage * 0.5\n    end\n    emit zap at chosen\n    let total = total + damage\n  end\nend\noutput total\n"
static func sample_inputs(count:int=3)->Dictionary:
 var distances=[];var shields=[];var used=[]
 for n in count:distances.append(100+n*80);shields.append(n==1);used.append(false)
 return {"base_damage":20,"jump_limit":3,"reach":600,"target_count":count,"distances":distances,"shields":shields,"used":used,"charged":true,"targets":count>0}
static func compile(source:String)->Dictionary:
 if programs.has(source):return programs[source]
 if source.length()>6000 or source.split("\n").size()>160:return {"error":"Use at most 6,000 characters / 160 lines."}
 var nodes=[];var stack=[nodes];var blocks=[];var number=0
 var identifier=RegEx.new();identifier.compile("^[A-Za-z_][A-Za-z_0-9]{0,24}$")
 for raw in source.split("\n"):
  number+=1;var line=raw.strip_edges()
  if line.is_empty() or line.begins_with("#"):continue
  var op=line.get_slice(" ",0);var arg=line.substr(op.length()).strip_edges();var node={"line":number,"op":op,"arg":arg}
  if op in ["repeat","while","if","for"]:
   if arg.is_empty() or stack.size()>6:return {"error":"Line "+str(number)+": missing condition or too many nested blocks."}
   node.body=[]
   if op=="if":node.branches=[{"condition":arg,"body":node.body}]
   if op=="for":
    var parts=arg.split(" in ")
    if parts.size()!=2 or identifier.search(parts[0])==null:return {"error":"Line "+str(number)+": use for enemy in target_count."}
    node.variable=parts[0];node.arg=parts[1]
   stack.back().append(node);stack.append(node.body);blocks.append(node)
  elif op in ["else","elif"]:
   if blocks.is_empty() or blocks.back().op!="if" or blocks.back().get("else",false):return {"error":"Line "+str(number)+": unmatched else / elif."}
   var branch={"condition":arg if op=="elif" else "true","body":[]};blocks.back().branches.append(branch);blocks.back()["else"]=op=="else";stack.pop_back();stack.append(branch.body)
  elif op=="end":
   if stack.size()==1:return {"error":"Line "+str(number)+": unmatched end."}
   stack.pop_back();blocks.pop_back()
  elif op in ["input","let","output","emit"]:
   if arg.is_empty():return {"error":"Line "+str(number)+": add the instruction's value."}
   if op=="input" and identifier.search(arg)==null:return {"error":"Line "+str(number)+": invalid input name."}
   if op=="let" and arg.split("=",true,1).size()!=2:return {"error":"Line "+str(number)+": use let total = expression."}
   if op=="emit" and not (arg.begins_with("zap at ") or arg.get_slice(" ",0) in ["projectile","pulse","beam","heal","chain"]):return {"error":"Line "+str(number)+": use emit zap at chosen, projectile, pulse, beam, heal or chain."}
   stack.back().append(node)
  else:return {"error":"Line "+str(number)+": unknown instruction "+op}
 if stack.size()!=1:return {"error":"Close each if or loop with end."}
 if programs.size()>=24:programs.clear()
 var result={"error":"","nodes":nodes};programs[source]=result;return result
static func value_ok(v:Variant)->bool:
 if v is bool:return true
 if v is int or v is float:return is_finite(float(v)) and absf(float(v))<=1000000
 if v is String:return v.length()<=300
 if v is Array:return v.size()<=40 and v.all(func(x):return (x is bool or x is String or x is int or x is float) and value_ok(x))
 return false
static func expression(source:String,vars:Dictionary)->Dictionary:
 if source.length()>300:return {"error":"Expression too long."}
 var cache_key=source+"|"+",".join(PackedStringArray(vars.keys()))
 if expressions.has(cache_key):return execute_expression(expressions[cache_key],vars)
 if token_regex==null:
  token_regex=RegEx.new();token_regex.compile('"[^"\\\\]*(?:\\\\.[^"\\\\]*)*"|[0-9]+(?:\\.[0-9]+)?|[A-Za-z_][A-Za-z_0-9]*|==|!=|<=|>=|[+*/%()<>!\\[\\], -]')
 var tokens=token_regex
 var end=0
 for token in tokens.search_all(source):
  if token.get_start()!=end:return {"error":"Unsupported expression character."}
  end=token.get_end();var word=token.get_string()
  if word.is_valid_identifier() and word not in ["true","false","and","or","not"] and not vars.has(word):return {"error":"Unknown variable: "+word}
  if word.is_valid_identifier() and source.substr(end).strip_edges().begins_with("("):return {"error":"Function calls are not supported; use variables and operators."}
 if end!=source.length() or source.is_empty():return {"error":"Invalid expression."}
 var parser=Expression.new();var names=PackedStringArray(vars.keys())
 if parser.parse(source,names)!=OK:return {"error":parser.get_error_text()}
 if expressions.size()>=128:expressions.clear()
 var cached={"parser":parser,"names":names};expressions[cache_key]=cached;return execute_expression(cached,vars)
static func execute_expression(cached:Dictionary,vars:Dictionary)->Dictionary:
 var parser:Expression=cached.parser;var args=[]
 for key in cached.names:args.append(vars[key])
 var result=parser.execute(args,null,false,true)
 if parser.has_execute_failed():return {"error":parser.get_error_text()}
 if not value_ok(result):return {"error":"Result exceeds the number, text or list limit."}
 return {"error":"","value":result}
static func run(source:String,inputs:Dictionary)->Dictionary:
 var program=compile(source);var state={"error":program.error,"vars":{},"output":[],"actions":[],"trace":[],"steps":0,"inputs":inputs.duplicate(true)}
 if not program.error.is_empty():return state
 if inputs.size()>20 or not inputs.values().all(value_ok):state.error="Inputs must be small numbers, text, Boolean values or lists.";return state
 walk(program.nodes,state)
 state.erase("inputs");return state
static func evaluate(source:String,s:Dictionary,line:int)->Variant:
 var result=expression(source,s.vars)
 if not result.error.is_empty():s.error="Line "+str(line)+": "+result.error;return null
 return result.value
static func walk(nodes:Array,s:Dictionary)->void:
 for node in nodes:
  s.steps+=1
  if s.steps>LIMIT:s.error="Execution limit reached. Check your loop condition.";return
  if not s.error.is_empty():return
  var op:String=node.op;var line:int=node.line;var arg:String=node.arg
  if s.trace.size()<100:s.trace.append({"line":line,"step":s.steps})
  if op=="input":
   if not s.inputs.has(arg):s.error="Line "+str(line)+": missing input "+arg;return
   s.vars[arg]=s.inputs[arg].duplicate(true) if s.inputs[arg] is Array else s.inputs[arg]
  elif op=="let":
   var pair=arg.split("=",true,1);var target=pair[0].strip_edges();var v=evaluate(pair[1].strip_edges(),s,line)
   if not s.error.is_empty():return
   var names=RegEx.new();names.compile("^([A-Za-z_][A-Za-z_0-9]{0,24})(?:\\[(.+)\\])?$");var match_result=names.search(target)
   if match_result==null:s.error="Line "+str(line)+": invalid variable.";return
   var key=match_result.get_string(1)
   if match_result.get_string(2).is_empty():s.vars[key]=v
   else:
    var at=evaluate(match_result.get_string(2),s,line)
    if not s.vars.get(key) is Array or not (at is int or at is float) or at!=floor(float(at)) or at<0 or at>=s.vars[key].size():s.error="Line "+str(line)+": invalid list index.";return
    s.vars[key][int(at)]=v
   if s.vars.size()>40:s.error="Use at most 40 variables.";return
  elif op=="if":
   for branch in node.branches:
    var test=evaluate(branch.condition,s,line)
    if not s.error.is_empty():return
    if not test is bool:s.error="Line "+str(line)+": a condition must be true or false.";return
    if test:walk(branch.body,s);break
  elif op in ["for","repeat"]:
   var count=evaluate(arg,s,line)
   if not s.error.is_empty():return
   if not (count is int or count is float) or count!=floor(float(count)) or count<0 or count>40:s.error="Line "+str(line)+": loop count must be 0–40.";return
   var key:String=node.get("variable","index");var old=s.vars.get(key);var existed=s.vars.has(key)
   for n in int(count):s.vars[key]=n;walk(node.body,s);if not s.error.is_empty():return
   if existed:s.vars[key]=old
   else:s.vars.erase(key)
  elif op=="while":
   for guard in LIMIT+1:
    var test=evaluate(arg,s,line)
    if not s.error.is_empty():return
    if not test is bool:s.error="Line "+str(line)+": while requires a Boolean condition.";return
    if not test:break
    s.steps+=1
    if s.steps>LIMIT:s.error="Execution limit reached. Check your loop condition.";return
    walk(node.body,s)
    if not s.error.is_empty():return
  elif op=="output":
   var v=evaluate(arg,s,line)
   if not s.error.is_empty():return
   if s.output.size()>=24:s.error="Use at most 24 outputs.";return
   s.output.append(v)
  elif op=="emit":
   if s.actions.size()>=32:s.error="Use at most 32 effects per cast.";return
   var target=-1;var command=arg.get_slice(" ",0)
   if command=="zap":
    var v=evaluate(arg.substr(7),s,line)
    if not (v is int or v is float) or v!=floor(float(v)) or v<0 or v>39:s.error="Line "+str(line)+": invalid target index.";return
    target=int(v)
   var stats={}
   for key in ["damage","heal","range","radius","speed","count","duration"]:
    if s.vars.get(key) is int or s.vars.get(key) is float:stats[key]=s.vars[key]
   s.actions.append({"command":command,"target":target,"angle":0,"stats":stats})
static func valid(v:Variant)->bool:
 return v is Dictionary and v.get("format")==FORMAT and v.get("version")==1 and v.get("name") is String and v.name.length()<=80 and v.get("code") is String and v.code.length()<=6000 and v.get("cases") is Array and v.cases.size()<=12 and v.cases.all(func(c):return c is Dictionary and c.get("inputs") is Dictionary and c.inputs.size()<=20 and c.inputs.values().all(value_ok) and c.get("expected") is Array and c.expected.size()<=24 and c.expected.all(value_ok) and c.get("error") is bool)

static func same_output(a:Variant,b:Variant)->bool:
 if (a is int or a is float) and (b is int or b is float):return absf(float(a)-float(b))<=.000001
 if a is Array and b is Array:
  if a.size()!=b.size():return false
  for n in a.size():
   if not same_output(a[n],b[n]):return false
  return true
 return typeof(a)==typeof(b) and a==b
