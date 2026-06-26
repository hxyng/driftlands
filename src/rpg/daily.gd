class_name Daily
extends RefCounted
## Daily-unlock reward with a calendar streak. Claiming on consecutive days
## grows the streak (and the payout); a missed day resets it. Date math is
## parameterised so it can be tested without waiting for tomorrow.

const BASE_REWARD := 25
const STREAK_BONUS := 10


static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


static func can_claim(meta: MetaProgress, today_str := "") -> bool:
	var t := today_str if today_str != "" else today()
	return meta.daily_last_claim != t


## Claims today's reward, updating streak + souls on [param meta]. Returns a
## result dict: {claimed, souls, streak}.
static func claim(meta: MetaProgress, today_str := "") -> Dictionary:
	var t := today_str if today_str != "" else today()
	if meta.daily_last_claim == t:
		return {"claimed": false, "souls": 0, "streak": meta.daily_streak}

	if meta.daily_last_claim != "" and _days_between(meta.daily_last_claim, t) == 1:
		meta.daily_streak += 1
	else:
		meta.daily_streak = 1
	meta.daily_last_claim = t

	var souls := BASE_REWARD + meta.daily_streak * STREAK_BONUS
	meta.souls += souls
	return {"claimed": true, "souls": souls, "streak": meta.daily_streak}


static func _days_between(a: String, b: String) -> int:
	var ua := Time.get_unix_time_from_datetime_string(a + "T00:00:00")
	var ub := Time.get_unix_time_from_datetime_string(b + "T00:00:00")
	return int(round((ub - ua) / 86400.0))
