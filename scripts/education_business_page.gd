extends CanvasLayer
const B=preload("res://scripts/education_business.gd")
const UI=preload("res://scripts/studio_ui.gd")
var panel:PanelContainer
var content:VBoxContainer
var legacy:Node
var portfolio:Node
var exercise:Dictionary
var status:Label
var animation=0.0
var previous_menu=""
var visual:Control
static func open(owner:Node,code:String="ENT1010",page:Node=null)->void:
 var A=preload("res://scripts/education_access.gd")
 if not A.student() and not A.review_allowed():return
 var view=load("res://scripts/education_business_page.gd").new();owner.add_child(view);view.setup(owner,code,page)
func label(parent:Node,t:String,size:int=17)->Label:
 var l=Label.new();l.text=t;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,t:String,f:Callable)->Button:
 var b=Button.new();b.text=t;b.custom_minimum_size.y=44;parent.add_child(b);b.pressed.connect(f);return b
func setup(owner:Node,code:String,page:Node=null)->void:
 legacy=owner;portfolio=page;exercise=B.fresh(code);layer=116;previous_menu=legacy.game.menu;legacy.game.menu="education_business"
 var shade=ColorRect.new();shade.color=Color(.01,.04,.06,.92);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1080,680);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);var row=HBoxContainer.new();col.add_child(row);label(row,"BUSINESS CHALLENGES",25);UI.accent(button(row,"Run trial",run_trial));button(row,"Close",queue_free)
 label(col,"Practice sandbox • your mine goods and market cash stay safe. Forecasts are teaching models, not real market research.",16)
 var modes=HBoxContainer.new();col.add_child(modes)
 for module in B.MODULES:button(modes,B.TITLES[module],func():exercise=B.fresh(module);render())
 var sc=ScrollContainer.new();sc.size_flags_vertical=Control.SIZE_EXPAND_FILL;sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(sc);preload("res://scripts/touch_list_scroll.gd").attach(sc).form_controls=true
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sc.add_child(content)
 status=label(col,"Choose decisions, predict a result, then run. Save each trial to compare revisions.",15)
 render();UI.enter(panel)
func number(parent:Node,title:String,value:float,lo:float,hi:float,setter:Callable,step:float=1)->void:
 var row:BoxContainer=VBoxContainer.new() if parent is HBoxContainer else HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(row);label(row,title,16);var spin=SpinBox.new();spin.min_value=lo;spin.max_value=hi;spin.step=step;spin.value=value;spin.custom_minimum_size=Vector2(155,42);row.add_child(spin);spin.value_changed.connect(func(v:float):setter.call(v);exercise.results={};status.text="Decisions changed • run again to capture these settings.")
func choose(parent:Node,title:String,items:Array,current:int,setter:Callable)->void:
 label(parent,title,16);var pick=OptionButton.new();pick.fit_to_longest_item=false;pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(pick)
 for item in items:pick.add_item(item)
 pick.select(current);pick.item_selected.connect(func(i:int):setter.call(i);exercise.results={};render())
func render()->void:
 for n in content.get_children():content.remove_child(n);n.queue_free()
 label(content,exercise.module+" • "+B.TITLES[exercise.module],23)
 var s:Dictionary=exercise.settings
 if exercise.module=="ENT1010":
  label(content,"Discover a need BEFORE planning a business. Compare three ideas using 0–5 ratings. Ratings are your assumptions: support them with interviews or cited research.",17)
  var weights=HBoxContainer.new();content.add_child(weights)
  for i in 3:number(weights,["Need weight","Resources weight","Feasibility weight"][i],s.weights[i],1,5,func(v:float):s.weights[i]=int(v))
  for i in 3:
   var idea:Dictionary=s.ideas[i];var card=UI.card(content,"Idea "+str(i+1));var name=LineEdit.new();name.text=idea.name;name.max_length=80;name.custom_minimum_size.y=42;card.add_child(name);name.text_changed.connect(func(t:String):idea.name=t;exercise.results={})
   var row=HBoxContainer.new();card.add_child(row)
   for key in ["need","resources","feasibility"]:number(row,key.capitalize(),idea[key],0,5,func(v:float):idea[key]=int(v))
 elif exercise.module=="ENT1020":
  label(content,"Plan operations and test a contingency. Keep a cash reserve, buy stock, then sell. Compare the normal case with a supplier delay or a demand drop; explain your response.",17)
  choose(content,"Pilot scenario",["Normal demand","Supplier delay • unit cost +35%","Demand drops 40%"],s.scenario,func(i:int):s.scenario=i)
  var columns=HBoxContainer.new();content.add_child(columns);var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(left);var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(right)
  for key in ["cash","fixed","reserve"]:number(left,{"cash":"Starting cash","fixed":"Operating overhead","reserve":"Cash reserve"}[key],s[key],0,10000,func(v:float):s[key]=v)
  for key in ["cost","price","stock","demand"]:number(right,key.capitalize(),s[key],1 if key in ["cost","price"] else 0,200 if key in ["cost","price"] else 500,func(v:float):s[key]=int(v) if key in ["stock","demand"] else v)
 else:
  label(content,"Run a controlled A/B comparison of ONE merchandising decision. Audience, stock and advertising budget are identical. Decide which result matters: sales, profit, service or customer access.",17)
  choose(content,"Only this factor changes",B.FACTORS,s.factor,func(i:int):s.factor=i;s.a=12 if i==0 else 1;s.b=10 if i==0 else 2)
  var columns=HBoxContainer.new();content.add_child(columns);var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(left);var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(right)
  for key in ["visitors","stock","cost","price","budget"]:
   if key=="price" and s.factor==0:continue
   var bounds={"visitors":[10,500],"stock":[0,500],"cost":[1,200],"price":[1,200],"budget":[0,500]}[key]
   number(left,key.capitalize()+" • same for A/B" if key!="price" else "Reference price",s[key],bounds[0],bounds[1],func(v:float):s[key]=int(v) if key in ["visitors","stock"] else v)
  label(right,"A and B variants",19)
  if s.factor!=0:label(right,"0 = basic; 1–3 = stronger choice with added per-unit cost. Price elasticity and conversion are simplified.",16)
  for key in ["a","b"]:number(right,key.to_upper()+" • "+B.FACTORS[s.factor],s[key],1 if s.factor==0 else 0,200 if s.factor==0 else 3,func(v:float):s[key]=v)
 UI.accent(button(content,"Run comparison / pilot",run_trial))
 if not exercise.results.is_empty():
  visual=Control.new();visual.custom_minimum_size=Vector2(0,130);content.add_child(visual);visual.draw.connect(draw_results)
  label(content,B.summary(exercise),19)
 label(content,"Prediction, evidence and next step",18);var reflection=TextEdit.new();reflection.custom_minimum_size.y=105;reflection.placeholder_text="Before: I predicted… Evidence/source… After: results show… Limitation… Next revision…";reflection.text=exercise.reflection;content.add_child(reflection);reflection.text_changed.connect(func():exercise.reflection=reflection.text.left(3000))
 var actions=HBoxContainer.new();content.add_child(actions)
 var take=button(actions,"Attach this trial to "+exercise.module,save_trial);take.disabled=exercise.results.is_empty() or not preload("res://scripts/education_access.gd").student() or preload("res://scripts/profile_store.gd").testing() or (is_instance_valid(portfolio) and portfolio.teacher)
 take.tooltip_text="Student Mode records assessed work. Teacher/Game Dev practice does not change a student's portfolio."
 button(actions,"Download exercise",func():legacy.game.hero_workshop.write_download(JSON.stringify(exercise,"  "),"crossroads-"+exercise.module+"-exercise.json"))
func run_trial()->void:
 if not B.valid_settings(exercise.module,exercise.settings):status.text="Give each idea a name and check all decisions.";return
 B.run(exercise);render();status.text="Simulation complete. Explain assumptions and what you would change next."
func save_trial()->void:
 var S=preload("res://scripts/learning_store.gd");var d=portfolio.data if is_instance_valid(portfolio) and not portfolio.teacher else S.load_data()
 var issue=S.attach(d,exercise.module,"business",exercise,B.TITLES[exercise.module],"Classroom sandbox • reproducible decisions")
 status.text="Trial attached to "+exercise.module+". Use the journal to explain your research and conclusions." if issue.is_empty() else issue
func draw_results()->void:
 if not is_instance_valid(visual):return
 var width=visual.size.x;var r:Dictionary=exercise.results;var t=animation
 if exercise.module=="ENT1010":
  for i in 3:
   var x=width*(i+.1)/3;visual.draw_rect(Rect2(x,110-r.scores[i]*2,width*.24,r.scores[i]*2),Color("#76d4bf") if i==int(r.best) else Color("#628fa2"));visual.draw_string(ThemeDB.fallback_font,Vector2(x,126),"Idea "+str(i+1)+" • "+str(r.scores[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 else:
  for i in 2:
   var x=width*(i*.5+.1);var color=Color("#72d7bf") if i==0 else Color("#e6bd74");visual.draw_rect(Rect2(x,35,width*.30,60),Color("#213e49"));visual.draw_rect(Rect2(x-8,27,width*.30+16,14),color)
   var title="Stock purchased" if i==0 else "Sales received"
   if exercise.module=="MAM1010":title="Shop "+["A","B"][i]+" • sold "+str(r[["a","b"][i]].sold)
   visual.draw_string(ThemeDB.fallback_font,Vector2(x,119),title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
   for n in 5:
    var px=x+fmod(t*17+n*31,width*.3);visual.draw_circle(Vector2(px,83),4,color);visual.draw_rect(Rect2(px-3,89,6,10),color)
func _process(dt:float)->void:
 panel.size=Vector2(1080,680);var v=get_viewport().get_visible_rect().size;var f=minf(1,minf((v.x-24)/1080,(v.y-24)/680));panel.scale=Vector2.ONE*f;panel.position=(v-panel.size*f)*.5
 animation+=dt
 if is_instance_valid(visual):visual.queue_redraw()
func _unhandled_input(e:InputEvent)->void:
 if e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()

func _exit_tree()->void:
 if is_instance_valid(legacy) and legacy.game.menu=="education_business":legacy.game.menu=previous_menu
