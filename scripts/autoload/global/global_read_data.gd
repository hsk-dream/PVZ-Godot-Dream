extends Node
class_name GlobalReadData

var data_almanac: Dictionary = {}
const PATH_DATA_ALMANAC := "res://data/almanac_data.json"
@onready var character_registry: CharacterRegistry = %CharacterRegistry

## 僵尸行类型可以自然刷新的僵尸白名单
var whitelist_refresh_zombie_types_with_zombie_row_type: Dictionary[EnumsCharacter.ZombieRowType, Array] = {}

## 自然刷怪出现的僵尸黑名单类型
var blacklist_refresh_zombie_types: Array[EnumsCharacter.ZombieType] = [
	EnumsCharacter.ZombieType.Null,
	EnumsCharacter.ZombieType.Z002Flag,
	EnumsCharacter.ZombieType.Z011Duckytube,
	EnumsCharacter.ZombieType.Z010Dancer,
	EnumsCharacter.ZombieType.Z025Imp,
	EnumsCharacter.ZombieType.Z1001BobsledSingle,
]

## 随机罐子刷新的植物白名单
var whitelist_plant_types_with_pot: Array[EnumsCharacter.PlantType] = []
## 罐子模式无冷却植物卡牌类型
var zero_cd_plnat_card_type_on_pot_mode: Array = [
	EnumsCharacter.PlantType.P017LilyPad,
	EnumsCharacter.PlantType.P034FlowerPot,
	EnumsCharacter.PlantType.P036CoffeeBean,
]

## 随机罐子刷新的植物黑名单类型(null等)
var blacklist_plant_types_with_pot: Array[EnumsCharacter.PlantType] = [
	EnumsCharacter.PlantType.Null,
	EnumsCharacter.PlantType.P036CoffeeBean,
	EnumsCharacter.PlantType.P999Imitater,
	EnumsCharacter.PlantType.P1000Sprout,
]
## 随机罐子刷新的僵尸黑名单,白名单使用自然刷怪白名单
var blacklist_zombie_types_with_pot: Array[EnumsCharacter.ZombieType] = [
	EnumsCharacter.ZombieType.Null,
	EnumsCharacter.ZombieType.Z011Duckytube,
]

func _ready() -> void:
	update_whitelist_refresh_zombie_types_with_zombie_row_type()
	update_whitelist_plant_types_with_pot()

func ensure_almanac_loaded() -> void:
	if not data_almanac.is_empty():
		return
	data_almanac = _load_json(PATH_DATA_ALMANAC)

func update_whitelist_refresh_zombie_types_with_zombie_row_type() -> void:
	whitelist_refresh_zombie_types_with_zombie_row_type.clear()
	for curr_zombie_row_type in EnumsCharacter.ZombieRowType.values():
		whitelist_refresh_zombie_types_with_zombie_row_type[curr_zombie_row_type] = get_whitelist_refresh_zombie_types_on_zombie_row_type(curr_zombie_row_type)

func get_whitelist_refresh_zombie_types_on_zombie_row_type(curr_zombie_row_type: EnumsCharacter.ZombieRowType) -> Array[EnumsCharacter.ZombieType]:
	var curr_whitelist_refresh_zombie_types: Array[EnumsCharacter.ZombieType] = []
	for zombie_type in EnumsCharacter.ZombieType.values():
		if blacklist_refresh_zombie_types.has(zombie_type):
			continue

		if curr_zombie_row_type == EnumsCharacter.ZombieRowType.Both:
			curr_whitelist_refresh_zombie_types.append(zombie_type)
		else:
			var zombie_row_type: EnumsCharacter.ZombieRowType = character_registry.get_zombie_info(zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieRowType)
			if zombie_row_type == EnumsCharacter.ZombieRowType.Both:
				curr_whitelist_refresh_zombie_types.append(zombie_type)
			elif zombie_row_type == curr_zombie_row_type:
				curr_whitelist_refresh_zombie_types.append(zombie_type)

	return curr_whitelist_refresh_zombie_types

func update_whitelist_plant_types_with_pot() -> void:
	whitelist_plant_types_with_pot.clear()
	for plant_type in EnumsCharacter.PlantType.values():
		if blacklist_plant_types_with_pot.has(plant_type):
			continue
		whitelist_plant_types_with_pot.append(plant_type)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text := file.get_as_text()
	file.close()
	var result: Dictionary = JSON.parse_string(json_text) as Dictionary
	if result == null:
		return {}
	return result
