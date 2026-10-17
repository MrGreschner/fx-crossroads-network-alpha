extends RefCounted
static func edmonton_offset(utc:float)->int:
 # Alberta.ca: permanent UTC-6 from November 2026; historical MST/MDT before that.
 var date=Time.get_datetime_dict_from_unix_time(int(utc));var year=int(date.year)
 var first=Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict({"year":year,"month":3,"day":1,"hour":0,"minute":0,"second":0}))
 var march_day=8+posmod(7-int(first.weekday),7)
 var spring=Time.get_unix_time_from_datetime_dict({"year":year,"month":3,"day":march_day,"hour":9,"minute":0,"second":0})
 if year>2026 or (year==2026 and utc>=spring):return -21600
 first=Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict({"year":year,"month":11,"day":1,"hour":0,"minute":0,"second":0}))
 var november_day=1+posmod(7-int(first.weekday),7)
 var autumn=Time.get_unix_time_from_datetime_dict({"year":year,"month":11,"day":november_day,"hour":8,"minute":0,"second":0})
 return -21600 if utc>=spring and utc<autumn else -25200
