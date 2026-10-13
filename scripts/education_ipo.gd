extends CanvasLayer
const FORMAT="fx-ipo-program"
const UI=preload("res://scripts/studio_ui.gd")
var page:Node
var panel:PanelContainer
var code:CodeEdit
var inputs:LineEdit
var expected:LineEdit
var failure:CheckButton
var title:LineEdit
var status:Label
var cases:Array=[]
static func execute(source:String,data:Dictionary)->Dictionary:
 var variables={};var output=[]
 if source.length()>3000 or data.size()>8:return {"error":"Program or inputs too large.","output":[]}
 for key in data:
  if not data[key] is String and not data[key] is int and not data[key] is float:return {"error":"Inputs must be numbers or text.","output":[]}
  if str(data[key]).length()>200:return {"error":"Input too long.","output":[]}
 var lines=source.split("\n");var line_number=0
 if lines.size()>40:return {"error":"Use at most 40 lines.","output":[]}
 var names=RegEx.new();names.compile("^[A-Za-z_][A-Za-z_0-9]{0,24}$")
 for raw in lines:
  line_number+=1;var line=raw.strip_edges()
  if line.is_empty() or line.begins_with("#"):continue
  if line.begins_with("input "):
   var name=line.substr(6).strip_edges()
   if names.search(name)==null or not data.has(name):return {"error":"Line "+str(line_number)+": provide input "+name,"output":output}
   variables[name]=data[name]
  elif line.begins_with("let "):
   var pair=line.substr(4).split("=",true,1)
   if pair.size()!=2 or names.search(pair[0].strip_edges())==null:return {"error":"Line "+str(line_number)+": use let total = expression","output":output}
   var result=expression(pair[1].strip_edges(),variables)
   if not result.error.is_empty():return {"error":"Line "+str(line_number)+": "+result.error,"output":output}
   variables[pair[0].strip_edges()]=result.value
  elif line.begins_with("output "):
   var result=expression(line.substr(7).strip_edges(),variables)
   if not result.error.is_empty():return {"error":"Line "+str(line_number)+": "+result.error,"output":output}
   output.append(result.value)
  else:return {"error":"Line "+str(line_number)+": use input, let or output.","output":output}
  if variables.size()>16 or output.size()>10:return {"error":"Too many variables or outputs.","output":output}
 return {"error":"" if not output.is_empty() else "Add an output instruction.","output":output}
static func expression(source:String,variables:Dictionary)->Dictionary:
 if source.length()>200:return {"error":"Expression too long."}
 var values=variables.duplicate();var clean="";var index=0;var literal=0
 while index<source.length():
  var character=source[index]
  if character=='"':
   var end=source.find('"',index+1)
   if end<0:return {"error":"Close the text literal."}
   var name="_text"+str(literal);literal+=1;values[name]=source.substr(index+1,end-index-1);clean+=name;index=end+1
  else:clean+=character;index+=1
 var token=RegEx.new();token.compile("[0-9]+(?:\\.[0-9]+)?|[A-Za-z_][A-Za-z_0-9]*|[+*/() -]")
 var position=0
 for match_result in token.search_all(clean):
  if match_result.get_start()!=position:return {"error":"Only variables, literals and + - * / ( ) are supported."}
  var text=match_result.get_string();position=match_result.get_end()
  if text[0].is_valid_identifier() and not text.is_valid_float() and not text in ["+","-","*","/","(",")"," "]:
   if not values.has(text):return {"error":"Unknown variable: "+text}
   var tail=clean.substr(position).strip_edges()
   if tail.begins_with("("):return {"error":"Function calls are not supported."}
 if position!=clean.length() or clean.is_empty():return {"error":"Invalid expression."}
 var expr=Expression.new();var keys=PackedStringArray(values.keys())
 if expr.parse(clean,keys)!=OK:return {"error":expr.get_error_text()}
 var args=[]
 for key in keys:args.append(values[key])
 var value=expr.execute(args,null,false,true)
 if expr.has_execute_failed():return {"error":expr.get_error_text()}
 if value is float or value is int:
  if not is_finite(float(value)) or absf(float(value))>1000000:return {"error":"Result outside ±1,000,000."}
 elif not value is String or value.length()>300:return {"error":"Output must be a number or short text."}
 return {"error":"","value":value}
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.get("format")!=FORMAT or value.get("version")!=1 or not value.get("name") is String or value.name.length()>80 or not value.get("code") is String or value.code.length()>3000 or not value.get("cases") is Array or value.cases.size()>12:return false
 for test in value.cases:
  if not test is Dictionary or not test.get("inputs") is Dictionary or test.inputs.size()>8 or not test.get("expected") is Array or test.expected.size()>10 or not test.get("error") is bool or JSON.stringify(test).length()>3000:return false
 return true
func setup(owner:Node)->void:
 page=owner;layer=115;panel=PanelContainer.new();panel.size=Vector2(1000,660);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);page.label(col,"IPO WORKBENCH • sequential programming",24)
 page.label(col,"INPUT → PROCESS → OUTPUT. This bounded interpreter runs your instructions in order. No external code, file access or function calls. Build your pseudocode in the Journal first.",16)
 title=LineEdit.new();title.text="My damage calculator";title.max_length=80;col.add_child(title)
 code=CodeEdit.new();code.custom_minimum_size.y=230;code.size_flags_vertical=Control.SIZE_EXPAND_FILL;code.text="# Predict damage from several hits\ninput damage\ninput hits\nlet total = damage * hits\noutput total";col.add_child(code)
 page.label(col,"Inputs: JSON object • Expected output: JSON list",15)
 var row=HBoxContainer.new();col.add_child(row);inputs=LineEdit.new();inputs.text='{"damage":12,"hits":3}';inputs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(inputs);expected=LineEdit.new();expected.text='[36]';expected.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(expected)
 failure=CheckButton.new();failure.text="Expect an error (failure test)";col.add_child(failure)
 status=page.label(col,"Try normal, boundary and failure data. Change your code, then rerun all saved cases.",16)
 row=HBoxContainer.new();col.add_child(row);page.button(row,"Run & save case",run_case);page.button(row,"Rerun all cases",rerun);page.button(row,"Clear cases",func():cases.clear();status.text="Cases cleared.");page.button(row,"Save assignment snapshot",capture);page.button(row,"Close",queue_free)
func run_case()->void:
 var data=JSON.parse_string(inputs.text);var prediction=JSON.parse_string(expected.text)
 if not data is Dictionary or not prediction is Array:status.text="Inputs need a JSON object; expected output needs a JSON list.";return
 if cases.size()>=12:status.text="Twelve cases saved. Clear cases or save this version first.";return
 cases.append({"inputs":data,"expected":prediction,"error":failure.button_pressed});rerun()
func rerun()->void:
 var passed=0;var details=[]
 for test in cases:
  var result=execute(code.text,test.inputs);var ok=not result.error.is_empty() if test.error else result.error.is_empty() and preload("res://scripts/learning_store.gd").fingerprint(result.output)==preload("res://scripts/learning_store.gd").fingerprint(test.expected)
  if ok:passed+=1
  details.append(("PASS" if ok else "CHECK")+" • "+JSON.stringify(result.output)+(" • "+result.error if not result.error.is_empty() else ""))
 status.text=str(passed)+" / "+str(cases.size())+" predictions verified\n"+"\n".join(details).left(750)
func capture()->void:
 var value={"format":FORMAT,"version":1,"name":title.text,"code":code.text,"cases":cases.duplicate(true)}
 page.attach("program",value,title.text,"IPO Workbench • sequential source & predictions")
func _process(_dt:float)->void:
 panel.size=Vector2(1000,660)
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/1000,(view.y-24)/660));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
