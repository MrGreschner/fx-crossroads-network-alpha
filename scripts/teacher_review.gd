extends RefCounted
static func open(legacy:Node)->void:
 if not preload("res://scripts/education_access.gd").review_allowed():return
 var page=load("res://scripts/learning_page.gd").new();legacy.add_child(page);page.setup(legacy,true)
static func open_overview(legacy:Node)->void:
 var game=legacy.game;game.presentation.window("TEACHER REVIEW • LOCAL EVIDENCE","teacher_review")
 game.presentation.label(game.presentation.content,"Read-only overview for this player's device. Local passcodes are a classroom shortcut, not secure authentication. Time means active Studio use since v139; it is not attendance or a grade.",16)
 game.presentation.button(game.presentation.content,"Creation review & Showcase",func():load("res://scripts/studio_showcase.gd").open(game.hero_workshop))
 var library=preload("res://scripts/studio_library.gd").load_data()
 var education:Dictionary=legacy.data.get("education",{})
 game.presentation.label(game.presentation.content,"STUDIO ACTIVITY • "+str(int(float(education.get("studio_seconds",0))/60))+" active minutes",20)
 game.presentation.label(game.presentation.content,"Heroes "+str(library.heroes.size())+" • Abilities "+str(library.abilities.size())+" • Enemies "+str(library.enemies.size())+" • Behaviours "+str(library.behaviors.size()),18)
 var mine=legacy.mine
 game.presentation.label(game.presentation.content,"Mine depth "+str(mine.depth())+" • ore level "+str(mine.level())+" • workers "+str(mine.workers()),17)
 game.presentation.label(game.presentation.content,"Commerce evidence: open the player's Market Reports to review forecasts, profit and decisions.",16)
 for id in library.heroes:
  var p:Dictionary=library.heroes[id];var card=preload("res://scripts/studio_ui.gd").card(game.presentation.content,str(p.hero.name),str(p.author)+" • revision "+str(p.revision)+" • "+str(p.reports.size())+" tests")
  game.presentation.label(card,str(p.concept).left(400),16)
  game.presentation.label(card,"Budget: "+("checked" if preload("res://scripts/studio_balance.gd").hero_checked(p) else "experimental")+" • hypothesis: "+str(p.notes.hypothesis).left(300),15)
  if not p.reports.is_empty():
   var report:Dictionary=p.reports.back();game.presentation.label(card,"Last test • "+str(report.get("scenario",""))+" • damage "+str(report.get("damage",0))+" • "+str(report.get("seconds",0))+"s\nObservation: "+str(p.notes.observations).left(300),15)
  game.presentation.button(card,"Quick test in Training Yard",func():preload("res://scripts/studio_library.gd").install(game);game.presentation.close();legacy.close();game.selected_character=str(id);game.hero_preview=str(id);game.start_training())
 for collection in ["enemies","abilities","behaviors"]:
  for id in library[collection]:game.presentation.label(game.presentation.content,collection.capitalize()+" • "+str(library[collection][id].get("name",id)),16)
 game.presentation.label(game.presentation.content,"Nothing is submitted or graded here. Save test reports and download the profile before leaving a shared computer.",16)
