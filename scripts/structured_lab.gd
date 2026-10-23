extends CanvasLayer
const S=preload("res://scripts/structured_program.gd")
const UI=preload("res://scripts/studio_ui.gd")
const PATH="user://fx_structured_program.json"
var game:Node
var panel:PanelContainer
var code:CodeEdit
var inputs:TextEdit
var expected:LineEdit
var errors:CheckBox
var name_edit:LineEdit
var status:Label
var stage:Control
var cases:Array=[]
var on_capture:Callable
var on_use:Callable
var previous_menu=""
var previous_process=true
var host:Node
func button(parent:Node,text:String,fn:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=40;parent.add_child(b);b.pressed.connect(fn);return b
func label(parent:Node,text:String)->Label:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func setup(owner:Node,capture:Callable=Callable(),use:Callable=Callable(),sequential:bool=false)->void:
 host=owner;game=owner.game if owner.get("game")!=null else owner;on_capture=capture;on_use=use;layer=125;process_mode=Node.PROCESS_MODE_ALWAYS
 previous_menu=game.menu;previous_process=game.is_processing();game.menu="coding_studio";game.set_process(false)
 var background=ColorRect.new();background.color=Color("#10232f");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 panel=PanelContainer.new();add_child(panel);UI.apply(panel);var col=VBoxContainer.new();panel.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);var title=label(top,"CODE PLAYGROUND • build, test, play");title.add_theme_font_size_override("font_size",24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(top,"Close",close)
 label(col,"Your code controls the spell. Run a cast, predict outputs, and try different targets. School assignments are optional.")
 var tools=HFlowContainer.new();col.add_child(tools)
 button(tools,"Sequential calculator",func():code.text="# @structured\ninput damage\ninput hits\nlet total = damage * hits\noutput total";inputs.text='{"damage":12,"hits":3}';expected.text='[36]')
 button(tools,"Chain spell example",func():code.text=S.sample();set_targets(3);expected.text='[40]')
 for n in [0,1,3,5]:button(tools,str(n)+" targets",set_targets.bind(n))
 var split=HSplitContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 var left=VBoxContainer.new();left.custom_minimum_size.x=500;split.add_child(left);var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(right)
 name_edit=LineEdit.new();name_edit.text="My chain spell";name_edit.max_length=80;left.add_child(name_edit)
 code=CodeEdit.new();code.text=S.sample();code.gutters_draw_line_numbers=true;code.custom_minimum_size.y=280;code.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.add_child(code)
 inputs=TextEdit.new();inputs.custom_minimum_size.y=105;inputs.text=JSON.stringify(S.sample_inputs(),"  ");left.add_child(inputs)
 label(left,"Inputs above • change values or use a target preset.")
 expected=LineEdit.new();expected.placeholder_text="Predicted outputs, e.g. [40]";expected.text="[40]";left.add_child(expected)
 errors=CheckBox.new();errors.text="This test should report an error";left.add_child(errors)
 stage=ProgramStage.new();stage.custom_minimum_size=Vector2(480,310);stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(stage)
 status=label(right,"Trace the nearest eligible target, then compare the output with your prediction.")
 var help=label(right,"input name • let total = expression\nif / elif / else / end • repeat count / end\nfor enemy in target_count / end • while condition / end\noutput value • emit zap at chosen\nArithmetic, comparisons, Boolean values and small lists. Text joins with +. Loops have a test limit.");help.add_theme_font_size_override("font_size",15)
 var actions=HFlowContainer.new();col.add_child(actions)
 UI.accent(button(actions,"▶ Run cast",run_cast));button(actions,"Save predicted test",save_case);button(actions,"Rerun all tests",rerun);button(actions,"Clear test cases",func():cases.clear();status.text="Cases cleared.")
 button(actions,"Save code & tests",save_document)
 if on_use.is_valid():button(actions,"Use this spell in Ability Lab",func():var result=run_cast();if result.get("error","").is_empty():on_use.call(code.text);close())
 if on_capture.is_valid():button(actions,"Attach code & tests to module",capture)
 button(actions,"Download source",download)
 var document=preload("res://scripts/profile_store.gd").read(PATH,S.valid)
 if sequential:
  code.text="# @structured\ninput damage\ninput hits\nlet total = damage * hits\noutput total";inputs.text='{"damage":12,"hits":3}';expected.text="[36]"
 elif not document.is_empty():name_edit.text=document.name;code.text=document.code;cases=document.cases.duplicate(true)
func set_targets(n:int)->void:inputs.text=JSON.stringify(S.sample_inputs(n),"  ");run_cast()
func run_cast()->Dictionary:
 var data=JSON.parse_string(inputs.text)
 if not data is Dictionary:status.text="Inputs must be a JSON object of named values.";return {"error":status.text}
 var result=S.run(code.text,data);stage.data=data;stage.result=result;stage.age=0;stage.queue_redraw()
 status.text=("Line-by-line run: "+str(result.steps)+" steps • output "+JSON.stringify(result.output)+" • "+str(result.actions.size())+" effects") if result.error.is_empty() else result.error
 return result
func save_case()->void:
 var data=JSON.parse_string(inputs.text);var prediction=JSON.parse_string(expected.text)
 if not data is Dictionary or not prediction is Array:status.text="Enter named inputs and a predicted output list first.";return
 if cases.size()>=12:status.text="Twelve cases saved. Clear cases or save this version first.";return
 cases.append({"inputs":data,"expected":prediction,"error":errors.button_pressed});rerun()
func evaluated_cases()->Array:
 var rows=[]
 for test in cases:
  var result=S.run(code.text,test.inputs);var row=test.duplicate(true);row.actual=result.output;row.actual_error=result.error;row.steps=result.steps;row.passed=not result.error.is_empty() if test.error else result.error.is_empty() and JSON.stringify(result.output)==JSON.stringify(test.expected)
  # Normalize numerical JSON representations (40 and 40.0 compare as equal in Godot).
  if not test.error and result.error.is_empty():row.passed=S.same_output(result.output,test.expected)
  rows.append(row)
 return rows
func rerun()->void:
 var rows=evaluated_cases();var passed=0;var lines=[]
 for row in rows:
  if row.passed:passed+=1
  lines.append(("PASS" if row.passed else "CHECK")+" predicted "+JSON.stringify(row.expected)+" → "+JSON.stringify(row.actual)+(" • "+row.actual_error if not row.actual_error.is_empty() else ""))
 status.text=str(passed)+" / "+str(rows.size())+" predictions matched\n"+"\n".join(lines).left(900)
func document()->Dictionary:return {"format":S.FORMAT,"version":1,"name":name_edit.text,"code":code.text,"cases":evaluated_cases()}
func save_document()->void:
 var d=document()
 if not S.valid(d):status.text="Check the code/test size and input values before saving.";return
 var error=preload("res://scripts/profile_store.gd").write(PATH,d)
 status.text="Code and test cases saved on this device." if error==OK else "Could not save. Download your source before closing."
func capture()->void:
 var d=document()
 if not S.valid(d):status.text="Check the program before attaching.";return
 save_document();on_capture.call(d);status.text="Frozen code and rerun test cases attached."
func download()->void:
 var text=JSON.stringify(document(),"  ")
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(text.to_utf8_buffer(),"crossroads-program.json","application/json")
 else:
  var d=FileDialog.new();d.access=FileDialog.ACCESS_FILESYSTEM;d.file_mode=FileDialog.FILE_MODE_SAVE_FILE;d.current_file="crossroads-program.json";add_child(d);d.file_selected.connect(func(path):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_string(text);f.close();d.queue_free());d.popup_centered(Vector2i(700,500))
func close()->void:
 game.menu=previous_menu;game.set_process(previous_process);queue_free()
func _process(_dt:float)->void:
 var size=get_viewport().get_visible_rect().size;panel.size=Vector2(1280,850);var fit=minf(1,minf((size.x-20)/1280,(size.y-20)/850));panel.scale=Vector2.ONE*fit;panel.position=(size-panel.size*fit)*.5
class ProgramStage extends Control:
 var data={}
 var result={}
 var age=0.0
 func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _process(delta):
  if not is_visible_in_tree():return
  age+=delta
  if age<3:queue_redraw()
 func _draw():
  draw_style_box(UI.box("#243d46"),Rect2(Vector2.ZERO,size));var start=Vector2(55,size.y*.5)
  draw_texture_rect(preload("res://assets/ram_idle.png"),Rect2(start-Vector2(22,32),Vector2(44,58)),false)
  var points=[];var n=mini(12,int(data.get("target_count",0)))
  for i in n:
   var point=Vector2(size.x*.38+(i%3)*size.x*.20,70+(i/3)*90);points.append(point)
   draw_circle(point,19,Color("#b5968c"));draw_rect(Rect2(point-Vector2(12,22),Vector2(24,37)),Color("#6b7f86"),false,3)
   if data.get("shields",[]).size()>i and data.shields[i]:draw_arc(point,26,0,TAU,24,Color("#8fc4e8"),3,true)
   draw_string(UI.FONT,point+Vector2(-22,40),"#"+str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e9dfbf"))
  var from=start;var index=0
  if not result.get("error","").is_empty():return
  for action in result.get("actions",[]):
   if action.command!="zap" or action.target<0 or action.target>=points.size():continue
   var to:Vector2=points[action.target]
   if age>index*.18:
    var normal=(to-from).orthogonal().normalized()*10;var mid=from.lerp(to,.5);draw_polyline(PackedVector2Array([from,from.lerp(to,.3)+normal,mid-normal,to]),Color("#9be6ed"),3,true)
    draw_string(UI.FONT,to+Vector2(-25,-34),"−"+str(snappedf(float(action.stats.get("damage",0)),.1)),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f5d68b"))
   from=to;index+=1
  draw_string(UI.FONT,Vector2(20,size.y-22),"OUTPUT  "+JSON.stringify(result.get("output",[])),HORIZONTAL_ALIGNMENT_LEFT,size.x-40,20,Color("#e8d49f"))
