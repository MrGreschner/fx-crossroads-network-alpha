extends RefCounted
## Higher levels display actual runtime code, not simulated or executable uploads.
static func ability(level:int,program:String)->String:
 if level==1:return program
 if level==2:
  return "# LEVEL 2: actual functions, lists and vector physics used by your attack.\n# This source view is read-only. Edit Level 1 or the GUI to change the test.\n# Position is a Vector2. Speed is distance / second. delta is seconds per frame.\n# next_position = position + direction * speed * delta\n# Lob visual height = -sin(progress * PI) * 60; collision follows the ground path.\n\n"+section("workshop_arena.gd","func spawn_shot", "func add_field")+section("workshop_arena.gd","func closest", "func hurt")+section("workshop_arena.gd","func execute_attack", "func spawn_shot")+section("studio_graphics.gd","static func shot", "static func minion")+section("workshop_arena.gd","func tick", "func take_hit")
 return "# LEVEL 3: classes and object references in the actual runtime.\n# Arena is a Control object. It owns lists of shots, fields and minions.\n# Each Dictionary is a state object shared by the update and draw functions.\n# Project describes the hero; Graphics is a class with reusable static methods.\n\n"+section("workshop_arena.gd","extends Control","func _ready")+section("workshop_arena.gd","func tick", "func take_hit")+source_file("studio_passives.gd")+"\n# Bounded sound playback: cached resources and a small voice pool.\n"+source_file("studio_audio.gd")
static func behavior(level:int,program:String)->String:
 if level==1:return program
 if level==2:return "# LEVEL 2: functions, branches, arrays and distances used by the running enemy.\n# Read-only source view. Your Level 1 program feeds these functions.\n# offset = target - position; distance = offset.length()\n# normalized direction * speed * delta gives this frame's displacement.\n\n"+source_file("studio_enemy_agent.gd")+section("studio_behavior.gd","static func evaluate","static func matches")
 return "# LEVEL 3: each EnemyAgent owns a definition and body reference.\n# The battle stores one object per enemy in its agents list.\n# body is the same Dictionary that collision and damage update.\n# An actor runtime owns this enemy's projectiles and abilities.\n\n"+source_file("studio_enemy_agent.gd")+source_file("studio_battle.gd")
static func section(file:String,start:String,finish:String)->String:
 var source=source_file(file);var first=source.find(start);var last=source.find(finish,first+start.length())
 return source.substr(first,last-first if last>=0 else -1)+"\n" if first>=0 else ""

static func source_file(file:String)->String:
 var values=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/runtime-sources.json"))
 return str(values.get(file,"Source unavailable.")) if values is Dictionary else "Source unavailable."
