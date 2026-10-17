extends RefCounted
const A=preload("res://scripts/realm_access.gd")
static func depth(legacy:Node)->int:
 if A.unrestricted(legacy):return 14
 if A.count(legacy,A.EXPERT)>=2:return 14
 if A.count(legacy,A.HARD)>=4:return 12
 if A.count(legacy,A.CHALLENGING)>=1:return 10
 if A.count(legacy,A.MEDIUM)>=3:return 8
 return 6
static func themes(reach:int)->Array:
 var result=[0,1,3]
 if reach>=8:result.append(2)
 if reach>=10:result.append(4)
 if reach>=12:result.append(5)
 return result
static func next(legacy:Node)->String:
 match depth(legacy):
  6:return "Clear 3 different medium realms → ring 8 and Silverfall fragments"
  8:return "Clear a challenging realm → ring 10 and Lantern Marsh fragments"
  10:return "Clear 4 different hard realms → ring 12 and Astral fragments"
  12:return "Clear 2 different expert realms → ring 14 and the deepest fractures"
 return "Portal fully strengthened • ring 14"
