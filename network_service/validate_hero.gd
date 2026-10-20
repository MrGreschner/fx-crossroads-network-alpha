extends SceneTree
func _initialize()->void:
 var args=OS.get_cmdline_user_args();var result={"error":"Missing submission"}
 if args.size()==1:
  var raw=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
  if raw is Dictionary:
   var issue=preload("res://scripts/community_validation.gd").issue(raw)
   result={"error":issue}
   if issue.is_empty():
    raw.author="";raw.notes={"hypothesis":"","method":"","observations":"","next_change":""};raw.reports=[]
    result.project=raw;result.coverage={}
    for pose in preload("res://scripts/community_validation.gd").POSES:result.coverage[pose]=preload("res://scripts/community_validation.gd").coverage(raw.hero.art[pose])
 print("HERO_VALIDATION "+JSON.stringify(result));quit()
