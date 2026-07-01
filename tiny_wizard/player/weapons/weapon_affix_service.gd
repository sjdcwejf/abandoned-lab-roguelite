class_name LabWeaponAffixService
extends RefCounted


const AFFIX_STABLE := &"stable"
const AFFIX_RAPID := &"rapid"
const AFFIX_PROTOMATTER_CHARGED := &"protomatter_charged"
const AFFIX_EXTENDED := &"extended"
const AFFIX_PRECISE := &"precise"

const IMPLEMENTED_AFFIXES := [
	AFFIX_STABLE,
	AFFIX_RAPID,
	AFFIX_PROTOMATTER_CHARGED,
]


static func roll_affixes(rng: RandomNumberGenerator, chance := 0.5, max_count := 1) -> Array:
	if rng == null or max_count <= 0 or rng.randf() > chance:
		return []

	var pool := IMPLEMENTED_AFFIXES.duplicate()
	_shuffle(pool, rng)
	var result := []
	for index in range(mini(max_count, pool.size())):
		result.append(pool[index])
	return result


static func normalize_affixes(raw_affixes: Array) -> Array:
	var normalized := []
	for affix in raw_affixes:
		var affix_id := StringName(str(affix))
		if affix_id == &"":
			continue
		if normalized.has(affix_id):
			continue
		normalized.append(affix_id)
	return normalized


static func format_weapon_name(base_name: String, affixes: Array) -> String:
	var normalized := normalize_affixes(affixes)
	if normalized.is_empty():
		return base_name
	return "%s [%s]" % [base_name, format_affix_labels(normalized)]


static func format_affix_labels(affixes: Array) -> String:
	var labels := []
	for affix in normalize_affixes(affixes):
		labels.append(get_affix_label(affix))
	return "、".join(labels)


static func format_affix_line(affixes: Array) -> String:
	var labels := format_affix_labels(affixes)
	if labels == "":
		return ""
	return "词条：%s" % labels


static func get_affix_label(affix: StringName) -> String:
	match affix:
		AFFIX_STABLE:
			return "稳定"
		AFFIX_RAPID:
			return "速射"
		AFFIX_PROTOMATTER_CHARGED:
			return "源质充能"
		AFFIX_EXTENDED:
			return "扩容"
		AFFIX_PRECISE:
			return "精准"
	return str(affix)


static func get_affix_description(affix: StringName) -> String:
	match affix:
		AFFIX_STABLE:
			return "伤害 +10%"
		AFFIX_RAPID:
			return "射速 +10%"
		AFFIX_PROTOMATTER_CHARGED:
			return "命中时 10% 概率额外造成 1 点源质伤害"
		AFFIX_EXTENDED:
			return "TODO：弹匣或弹药容量提升"
		AFFIX_PRECISE:
			return "TODO：暴击率或散射修正"
	return "未记录词条"


static func get_damage_multiplier(affixes: Array) -> float:
	var multiplier := 1.0
	if normalize_affixes(affixes).has(AFFIX_STABLE):
		multiplier *= 1.1
	return multiplier


static func get_cooldown_multiplier(affixes: Array) -> float:
	var multiplier := 1.0
	if normalize_affixes(affixes).has(AFFIX_RAPID):
		multiplier /= 1.1
	return multiplier


static func roll_extra_hit_damage(affixes: Array) -> int:
	if not normalize_affixes(affixes).has(AFFIX_PROTOMATTER_CHARGED):
		return 0
	if randf() <= 0.1:
		return 1
	return 0


static func has_visible_affixes(affixes: Array) -> bool:
	return not normalize_affixes(affixes).is_empty()


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
