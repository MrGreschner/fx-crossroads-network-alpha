extends RefCounted
static func open(legacy:Node)->void:
 var A=preload("res://scripts/education_access.gd")
 if not A.student() and not A.review_allowed():return
 var S=preload("res://scripts/learning_store.gd");var game=legacy.game;game.presentation.window("EDUCATION GUIDE • CHOOSE YOUR PROJECT","education_guide");var body=game.presentation.content;var d=S.load_data()
 game.presentation.label(body,"Build, test, reflect and submit. Progress shows evidence collected; a teacher decides outcome achievement.",17)
 for code in S.catalog():
  var m=S.catalog()[code]
  if m.get("archived",false):continue
  var card=preload("res://scripts/studio_ui.gd").card(body,code+" • "+m.name,m.brief)
  var ready=0;var marks=0;var rs=S.readiness(d,code,S.work(d,code))
  for o in S.assessed_outcomes(code):if rs[o.id].ready:ready+=1
  for sub in d.submissions:
   if sub.module==code:marks=maxi(marks,sub.marks.keys().filter(func(key):return S.assessed_outcomes(code).any(func(o):return o.id==key)).size())
  for pair in [["Evidence",ready],["Teacher reviewed",marks]]:
   game.presentation.label(card,pair[0]+" • "+str(pair[1])+" / "+str(S.assessed_outcomes(code).size()),16);var bar=ProgressBar.new();bar.max_value=S.assessed_outcomes(code).size();bar.value=pair[1];bar.custom_minimum_size.y=20;card.add_child(bar)
  if code in preload("res://scripts/education_business.gd").MODULES:game.presentation.button(card,"Open "+preload("res://scripts/education_business.gd").TITLES[code],func():preload("res://scripts/education_business_page.gd").open(legacy,code))
  if A.student():game.presentation.button(card,"Open assignment",func():d.active=code;S.save(d);game.presentation.close();legacy.learning_open())
 game.presentation.button(body,"Join teacher submission room",func():get_tree_root(legacy).get_node("FXEducationRoom").open())
static func get_tree_root(node:Node)->Node:return node.get_tree().root
