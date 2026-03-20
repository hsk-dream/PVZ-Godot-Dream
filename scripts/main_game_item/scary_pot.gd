extends MainGameItemBase
class_name ScaryPot

const SCARY_POT_WATER = preload("uid://bcaaxvox84hq5")

@onready var area_2d_detect: Area2D = $Area2DDetect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var zombie_whitewater: Sprite2D = $Body/Zombie_whitewater

@onready var shadow: Sprite2D = $Shadow
@onready var scary_pot_back: Sprite2D = $Body/ScaryPotBack
@onready var scary_pot_front: Sprite2D = $Body/ScaryPotFront
## 角色容器节点
@onready var character_container: Node2D = $Body/CharacterContainer

@onready var marker_2d_create_card_or_trophy: Marker2D = $Marker2DCreateCardOrTrophy

@onready var hammer: PotHammer = $Hammer
@onready var pot_all_vase_chunks: PotAllVaseChunks = $PotAllVaseChunks

## 是否已经打开
var is_open:=false
## 罐子类型
@export var pot_type:EnumsItem.E_PotType = EnumsItem.E_PotType.Random
## 是否为结果随机罐子,若结果随机，最后会从白名单中等权重随机
@export var is_fixed_res:=true
## 当前植物类型
@export var curr_plant_type:EnumsCharacter.PlantType
## 当前僵尸类型
@export var curr_zombie_type:EnumsCharacter.ZombieType

## 卡片存在时间，结束后5秒闪烁消失
@export var card_exist_time:=10.0

signal signal_open_pot(is_zombie:bool, create_trophy_glo_pos:Vector2)

enum E_PotInitParaAttr{
	PotType,		## 罐子类型
	IsFixedRes,	## 是否为非随机结果罐子
	PlantType,		## 生成植物类型
	ZombieType,		## 生成僵尸类型
	PlantCell,		## 罐子所在植物格子
	IsCanLookRandom,	## 结果随机罐子永久可以观察
}

## 影响观察当前pot的角色
var all_plant_influence_look_pot:Array[Plant000Base]
## 当前是否可以观察到罐子中的角色
var is_can_loot_pot:=false
## 罐子内角色虚影
var character_static:Node2D
## 所有植物的角色虚影,结果随机罐子使用
var all_plant_character_statics:Dictionary[EnumsCharacter.PlantType,Node2D]
## 所有角色的角色虚影,结果随机罐子使用
var all_zombie_character_statics:Dictionary[EnumsCharacter.ZombieType,Node2D]
## 结果随机罐子的随机时间间隔 (实际使用时上下0.1倍的随机波动)
var random_res_cd:=0.3
## 角色随机虚影计时器
var res_random_character_static_update_timer:Timer

## 结果随机罐子永久可以观察
var is_can_look_random:=false

#region 初始化
func _ready() -> void:
	update_pot_appearance(pot_type)
	## 斜面时更新对应的检测位置
	GlobalUtils.update_plant_cell_slope_y(plant_cell, area_2d_detect)
	plant_cell.plant_be_flattened()
	## 结果随机罐子可以观察结果
	if not is_fixed_res and is_can_look_random:
		start_loot_pot()

## 添加到节点树之前的初始化参数
func init_pot(pot_init_para:Dictionary):
	pot_type = pot_init_para.get(E_PotInitParaAttr.PotType, EnumsItem.E_PotType.Random)
	is_fixed_res = pot_init_para.get(E_PotInitParaAttr.IsFixedRes, false)
	if is_fixed_res:
		curr_plant_type = pot_init_para.get(E_PotInitParaAttr.PlantType, EnumsCharacter.PlantType.Null)
		curr_zombie_type = pot_init_para.get(E_PotInitParaAttr.ZombieType, EnumsCharacter.ZombieType.Null)
		assert(curr_plant_type!= EnumsCharacter.PlantType.Null or curr_zombie_type !=  EnumsCharacter.ZombieType.Null, "error: 植物类型和僵尸类型都为空")
	plant_cell = pot_init_para[E_PotInitParaAttr.PlantCell]
	lane = plant_cell.row_col.x
	is_can_look_random = pot_init_para.get(E_PotInitParaAttr.IsCanLookRandom, false)



## 根据罐子类型更新罐子外表
func update_pot_appearance(curr_pot_type:EnumsItem.E_PotType):
	scary_pot_back.frame_coords.x = int(curr_pot_type)
	scary_pot_front.frame_coords.x = int(curr_pot_type)
	pot_all_vase_chunks.update_pot_vase_chunks_appearance(curr_pot_type)

	## 当前植物格子为水(8)或睡莲（16）地形
	if plant_cell.curr_condition & 24:
		shadow.visible = false
		animation_player.play(&"water_animation", -1, randf_range(0.8, 1.2))
		scary_pot_back.texture = SCARY_POT_WATER
		scary_pot_front.texture = SCARY_POT_WATER
	else:
		zombie_whitewater.visible = false
#endregion


#region 鼠标交互
func mouse_enter_pot():
	scary_pot_back.modulate = Color(2,2,2)
	scary_pot_front.modulate = Color(2,2,2)

func mouse_exit_pot():
	scary_pot_back.modulate = Color(1,1,1)
	scary_pot_front.modulate = Color(1,1,1)

## 打开罐子,被锤子打开
func open_pot_be_hammar():
	hammer.activate_it()
	open_pot()

#endregion

#region 僵尸交互
## 被爆炸打开
func open_pot_be_bomb():
	open_pot()

## 被巨人僵尸打开
func open_pot_be_gargantuar():
	open_pot()
#endregion

#region 打开罐子创建角色相关
## 打开罐子
func open_pot():
	if is_open:
		return
	is_open = true
	plant_cell.open_pot_update_plant_cell_data()
	pot_all_vase_chunks.activate_it()
	SoundManager.play_other_SFX("vase_breaking")
	var is_zombie:= false
	## 结果随机罐子，并且无法观察时，随机结果
	if not is_fixed_res and not is_can_loot_pot:
		random_res()
	if curr_plant_type!= EnumsCharacter.PlantType.Null:
		open_plant(curr_plant_type)
	elif curr_zombie_type != EnumsCharacter.ZombieType.Null:
		open_zombie(curr_zombie_type)
		is_zombie = true
	else:
		print("error: 空罐子")
	signal_open_pot.emit(is_zombie, marker_2d_create_card_or_trophy.global_position)
	## 等待一帧后删除
	queue_free()


func random_res():
	match pot_type:
		EnumsItem.E_PotType.Random:
			var p_plant_zombie:=randf()
			if p_plant_zombie <=0.5:
				curr_plant_type = Global.whitelist_plant_types_with_pot.pick_random()
			else:
				var curr_zomebi_row_type:EnumsCharacter.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
				curr_zombie_type = Global.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type].pick_random()
		EnumsItem.E_PotType.Plant:
			curr_plant_type = Global.whitelist_plant_types_with_pot.pick_random()
		EnumsItem.E_PotType.Zombie:
			var curr_zomebi_row_type:EnumsCharacter.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
			curr_zombie_type = Global.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type].pick_random()

## 打开植物
func open_plant(plant_type:EnumsCharacter.PlantType):
	var temp_card_para:Dictionary = {
		CardManager.E_TempCardParaAttr.PlantType:plant_type,
		CardManager.E_TempCardParaAttr.GlobalPos:marker_2d_create_card_or_trophy.global_position,
		CardManager.E_TempCardParaAttr.ExistTime:card_exist_time
	}
	var card:Card = Global.main_game.card_manager.create_temp_card(temp_card_para)

	## 控制卡片移动
	var move_x = randf_range(-20, 20)
	var move_y = randf_range(10, 30)

	var tween_y = card.create_tween()
	tween_y.tween_property(card, "position:y", -move_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(card, "position:y", move_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var tween_x = card.create_tween()
	tween_x.set_parallel()
	tween_x.tween_subtween(tween_y)
	tween_x.tween_property(card, "position:x", move_x, 0.6).as_relative()


func open_zombie(zombie_type:EnumsCharacter.ZombieType):
	var zombie_init_para:Dictionary = {
		Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
		Zombie000Base.E_ZInitAttr.Lane:plant_cell.row_col.x,
		Zombie000Base.E_ZInitAttr.IsPotZombie:true,
	}

	Global.main_game.zombie_manager.create_norm_zombie(
		zombie_type,
		Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x],
		zombie_init_para,
		Vector2(
			plant_cell.global_position.x + plant_cell.size.x/2,
			Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
		),
		GlobalUtils.get_special_zombie_callable(zombie_type, plant_cell)
	)

#endregion

#region 植物交互
func add_plant_can_look_pot(plant:Plant000Base):
	all_plant_influence_look_pot.append(plant)
	plant.signal_character_death.connect(erase_plant_can_look_pot.bind(plant))
	if not is_can_loot_pot:
		start_loot_pot()

func erase_plant_can_look_pot(plant:Plant000Base):
	all_plant_influence_look_pot.erase(plant)
	if all_plant_influence_look_pot.is_empty():
		end_loot_pot()

## 开始 罐子可以被看到
func start_loot_pot():
	## 如果还没有角色虚影，初始化角色虚影
	if character_static == null:
		character_static_init()
	is_can_loot_pot = true
	scary_pot_front.visible = false
	character_static.visible = true
	if is_instance_valid(res_random_character_static_update_timer):
		res_random_character_static_update_timer.start()

## 结束 罐子可以被看到
func end_loot_pot():
	## 结果随机罐子可以永久观察
	if not is_fixed_res and is_can_look_random:
		return
	is_can_loot_pot = false
	character_static.visible = false
	scary_pot_front.visible = true
	if is_instance_valid(res_random_character_static_update_timer):
		res_random_character_static_update_timer.stop()

## 角色虚影初始化
func character_static_init():
	## 固定随机结果
	if is_fixed_res:
		if curr_plant_type != EnumsCharacter.PlantType.Null:
			character_static = AllCards.all_plant_card_prefabs[curr_plant_type].character_static.duplicate()
		elif curr_zombie_type != EnumsCharacter.ZombieType.Null:
			character_static = AllCards.all_zombie_card_prefabs[curr_zombie_type].character_static.duplicate()
		character_container.add_child(character_static)
		character_static.position = Vector2(0,0)
	else:
		match pot_type:
			EnumsItem.E_PotType.Random:
				character_static_init_res_random_plant()
				character_static_init_res_random_zombie()
			EnumsItem.E_PotType.Plant:
				character_static_init_res_random_plant()
			EnumsItem.E_PotType.Zombie:
				character_static_init_res_random_zombie()
		update_res_random_character_static()
		create_res_random_character_static_update_timer()

## 更新随机结果罐子角色虚影
func update_res_random_character_static():
	match pot_type:
		EnumsItem.E_PotType.Random:
			var p_plant_zombie:=randf()
			if p_plant_zombie <=0.5:
				curr_plant_type = all_plant_character_statics.keys().pick_random()
				curr_zombie_type = EnumsCharacter.ZombieType.Null
				character_static = all_plant_character_statics[curr_plant_type]
			else:
				curr_plant_type = EnumsCharacter.PlantType.Null
				curr_zombie_type = all_zombie_character_statics.keys().pick_random()
				character_static = all_zombie_character_statics[curr_zombie_type]
		EnumsItem.E_PotType.Plant:
			curr_plant_type = all_plant_character_statics.keys().pick_random()
			character_static = all_plant_character_statics[curr_plant_type]
		EnumsItem.E_PotType.Zombie:
			curr_zombie_type = all_zombie_character_statics.keys().pick_random()
			character_static = all_zombie_character_statics[curr_zombie_type]

## 结果随机罐子初始化植物虚影
func character_static_init_res_random_plant():
	for plant_type:EnumsCharacter.PlantType in Global.whitelist_plant_types_with_pot:
		all_plant_character_statics[plant_type] = AllCards.all_plant_card_prefabs[plant_type].character_static.duplicate()
		character_container.add_child(all_plant_character_statics[plant_type])
		all_plant_character_statics[plant_type].position = Vector2(0,0)
		all_plant_character_statics[plant_type].visible = false

## 结果随机罐子初始化僵尸虚影
func character_static_init_res_random_zombie():
	var curr_zomebi_row_type:EnumsCharacter.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
	## 从白名单生成所有的僵尸虚影
	for zombie_type:EnumsCharacter.ZombieType in Global.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type]:
		all_zombie_character_statics[zombie_type] = AllCards.all_zombie_card_prefabs[zombie_type].character_static.duplicate()
		character_container.add_child(all_zombie_character_statics[zombie_type])
		all_zombie_character_statics[zombie_type].position = Vector2(0,0)
		all_zombie_character_statics[zombie_type].visible = false

## 更新一次结果随机罐子虚影
func once_update_character_static_random_res():
	character_static.visible = false
	update_res_random_character_static()
	character_static.visible = true

## 创建角色随机虚影计时器
func create_res_random_character_static_update_timer():
	res_random_character_static_update_timer = Timer.new()
	res_random_character_static_update_timer.one_shot = false
	res_random_character_static_update_timer.wait_time = random_res_cd + randf_range(-random_res_cd*0.1, random_res_cd*0.1)
	res_random_character_static_update_timer.timeout.connect(once_update_character_static_random_res)
	res_random_character_static_update_timer.ignore_time_scale = true
	add_child(res_random_character_static_update_timer)


#endregion
