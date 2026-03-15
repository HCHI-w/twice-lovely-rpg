extends Node
class_name BuffRegistry


# ---------------------------------------------------
static func get_buff(buff_id: String) -> BuffData:
	match buff_id:
		"bard_inspire":
			return _bard_inspire()
		"druid_blessing":
			return _druid_blessing()
		"knight_guard":
			return _knight_guard()
		"mage_focus":
			return _mage_focus()
		"martial_artist_stance":
			return _martial_artist_stance()
		"priest_bless":
			return _priest_bless()
		"ranger_focus":
			return _ranger_focus()
		"summoner_preparation":
			return _summoner_preparation()
		"thief_ambush":
			return _thief_ambush()
		_:
			push_error("Unknown buff id: %s" % buff_id)
			return null

# ---------------------------------------------------
#職業專屬 Buff
#Bard 激勵士氣
static func _bard_inspire() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "bard_inspire"
	buff.target_class_id = "bard"
	buff.name = "Inspiring Song"
	buff.description = "防禦與幸運提升，魔法攻擊小幅提升"
	buff.duration = 3
	buff.stats_flat.int = 5
	buff.stats_flat.dex = 10
	buff.stats_flat.luk = 10
	return buff

#Druid 自然祝福
static func _druid_blessing() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "druid_blessing"
	buff.target_class_id = "druid"
	buff.name = "Nature's Blessing"
	buff.description = "全能力小幅提升"
	buff.duration = 3
	buff.stats_flat.str = 5
	buff.stats_flat.def = 5
	buff.stats_flat.int = 5
	buff.stats_flat.dex = 5
	buff.stats_flat.luk = 5
	return buff
	
#Knight 防禦姿態
static func _knight_guard() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "knight_guard"
	buff.target_class_id = "knight"
	buff.name = "Guard Stance"
	buff.description = "防禦大幅提升"
	buff.duration = 3
	buff.stats_flat.str = 5
	buff.stats_flat.def = 20
	return buff
	
#Mage 魔力集中
static func _mage_focus() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "mage_focus"
	buff.target_class_id = "mage"
	buff.name = "Arcane Focus"
	buff.description = "魔法攻擊大幅提升"
	buff.duration = 3
	buff.stats_flat.int = 20
	buff.stats_flat.dex = 5
	return buff
	
#Martial Artist 戰鬥姿態
static func _martial_artist_stance() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "martial_artist_stance"
	buff.target_class_id = "martial_artist"
	buff.name = "Combat Stance"
	buff.description = "速度與攻擊小幅提升"
	buff.duration = 3
	buff.stats_flat.mp = 10
	buff.stats_flat.str = 10
	buff.stats_flat.dex = 5
	return buff
	
#Priest 神聖祝福
static func _priest_bless() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "priest_bless"
	buff.target_class_id = "priest"
	buff.name = "Divine Blessing"
	buff.description = "最大生命值與防禦提升"
	buff.duration = 3
	buff.stats_flat.hp = 10
	buff.stats_flat.int = 10
	buff.stats_flat.luk = 5
	return buff
	
#Ranger 專注狙擊
static func _ranger_focus() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "ranger_focus"
	buff.target_class_id = "ranger"
	buff.name = "Hunter's Focus"
	buff.description = "攻擊與速度提升"
	buff.duration = 3
	buff.stats_flat.str = 10
	buff.stats_flat.dex = 10
	buff.stats_flat.luk = 5
	return buff
	
#Summoner 召喚詠唱
static func _summoner_preparation() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "summoner_preparation"
	buff.target_class_id = "summoner"
	buff.name = "Summoner Preparation"
	buff.description = "最大生命值與魔力攻擊提升"
	buff.duration = 3
	buff.stats_flat.hp = 15
	buff.stats_flat.def = 5
	buff.stats_flat.int = 5
	return buff
	
#Thief 伏擊準備
static func _thief_ambush() -> BuffData:
	var buff = BuffData.new()
	buff.buff_id = "thief_ambush"
	buff.target_class_id = "thief"
	buff.name = "Ambush"
	buff.description = "速度與幸運大幅提升"
	buff.duration = 3
	buff.stats_flat.dex = 5
	buff.stats_flat.luk = 20
	return buff
