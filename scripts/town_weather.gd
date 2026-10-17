extends RefCounted
## Shared deterministic game weather, independent of device locale and frame rate.
const TYPES=["Clear","Cloudy","Rain","Mist"]
static func at(day:int,hour:float)->String:
 return TYPES[posmod(day*7+int(hour/6)*3+int(day/7),4)]
static func context(utc:float)->Dictionary:
 var civil=utc+preload("res://scripts/town_clock_math.gd").edmonton_offset(utc)
 var d=Time.get_datetime_dict_from_unix_time(int(civil));var hour=float(d.hour)+float(d.minute)/60.0
 var day=floori(civil/86400.0)
 return {"utc":utc,"hour":hour,"weekday":posmod(int(d.weekday)+6,7),"day":day,"weather":at(day,hour)}
