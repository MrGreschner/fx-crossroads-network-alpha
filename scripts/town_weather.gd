extends RefCounted
## Four weather families shared by Town and Oldwater Lake. Calendar uses Edmonton civil days.
const TYPES=["Clear","Cloudy","Mist","Fog","Rain","Snow"]
const WEIGHTS={"Spring":[34,31,13],"Summer":[48,23,10],"Fall":[26,24,29],"Winter":[28,30,19]}

static func season(month:int,day:int)->String:
 if month==12 or month<=2 or (month==11 and day>=21):return "Winter"
 if month<=5:return "Spring"
 if month<=8:return "Summer"
 return "Fall"

static func legacy_at(day:int,hour:float)->String:
 return ["Clear","Cloudy","Rain","Mist"][posmod(day*7+int(hour/6)*3+int(day/7),4)]

static func at(day:int,hour:float)->String:
 var date:=Time.get_datetime_dict_from_unix_time(day*86400)
 var current:=season(int(date.month),int(date.day))
 var band:=int(hour/6)
 var roll:=posmod(hash("%d:%d:weather" % [day,band]),100)
 var weights:Array=WEIGHTS[current]
 if roll<int(weights[0]):return "Clear"
 roll-=int(weights[0])
 if roll<int(weights[1]):return "Cloudy"
 roll-=int(weights[1])
 if roll<int(weights[2]):return "Mist" if current=="Summer" else "Fog"
 var flurries:=posmod(hash("%d:%d:flurries" % [day,band]),100)
 if current=="Winter" or (date.month==11 and flurries<45) or (date.month==3 and date.day<=20 and flurries<28):return "Snow"
 return "Rain"

static func context(utc:float)->Dictionary:
 var civil=utc+preload("res://scripts/town_clock_math.gd").edmonton_offset(utc)
 var d=Time.get_datetime_dict_from_unix_time(int(civil));var hour=float(d.hour)+float(d.minute)/60.0
 var day=floori(civil/86400.0)
 return {"utc":utc,"hour":hour,"weekday":posmod(int(d.weekday)+6,7),"day":day,"season":season(int(d.month),int(d.day)),"weather":at(day,hour)}
