extends MainGameItemBase
class_name ScaryPot

const SCARY_POT_WATER = preload("uid://bcaaxvox84hq5")
## 罐子类型
enum E_PotType{
	Random,	## 随机罐子
	Plant,	## 植物罐子
	Zombie,	## 僵尸罐子
}

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
@export var pot_type:E_PotType = E_PotType.Random
## 是否为结果随机罐子,若结果随机，最后会从白名单中等权重随机
@export var is_fixed_res:=true
## 当前植物类型
@export var curr_plant_type:CharacterRegistry.PlantType
## 当前僵尸类型
@export var curr_zombie_type:CharacterRegistry.ZombieType

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
var all_plant_character_statics:Dictionary[CharacterRegistry.PlantType,Node2D]
## 所有角色的角色虚影,结果随机罐子使用
var all_zombie_character_statics:Dictionary[CharacterRegistry.ZombieType,Node2D]
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
	pot_type = pot_init_para.get(E_PotInitParaAttr.PotType, E_PotType.Random)
	is_fixed_res = pot_init_para.get(E_PotInitParaAttr.IsFixedRes, false)
	if is_fixed_res:
		curr_plant_type = pot_init_para.get(E_PotInitParaAttr.PlantType, CharacterRegistry.PlantType.Null)
		curr_zombie_type = pot_init_para.get(E_PotInitParaAttr.ZombieType, CharacterRegistry.ZombieType.Null)
		assert(curr_plant_type!= CharacterRegistry.PlantType.Null or curr_zombie_type !=  CharacterRegistry.ZombieType.Null, "error: 植物类型和僵尸类型都为空")
	plant_cell = pot_init_para[E_PotInitParaAttr.PlantCell]
	lane = plant_cell.row_col.x
	is_can_look_random = pot_init_para.get(E_PotInitParaAttr.IsCanLookRandom, false)



## 根据罐子类型更新罐子外表
func update_pot_appearance(curr_pot_type:E_PotType):
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
	if curr_plant_type!= CharacterRegistry.PlantType.Null:
		open_plant(curr_plant_type)
	elif curr_zombie_type != CharacterRegistry.ZombieType.Null:
		open_zombie(curr_zombie_type)
		is_zombie = true
	else:
		print("error: 空罐子")
	signal_open_pot.emit(is_zombie, marker_2d_create_card_or_trophy.global_position)
	## 等待一帧后删除
	queue_free()


func random_res():
	match pot_type:
		E_PotType.Random:
			var p_plant_zombie:=randf()
			if p_plant_zombie <=0.5:
				curr_plant_type = Global.global_read_data.whitelist_plant_types_with_pot.pick_random()
			else:
				var curr_zomebi_row_type:CharacterRegistry.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
				curr_zombie_type = Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type].pick_random()
		E_PotType.Plant:
			curr_plant_type = Global.global_read_data.whitelist_plant_types_with_pot.pick_random()
		E_PotType.Zombie:
			var curr_zomebi_row_type:CharacterRegistry.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
			curr_zombie_type = Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type].pick_random()

## 打开 [param plant_type] 对应植物的临时卡，保留原有位置、限时和弹出动画。
func open_plant(plant_type:CharacterRegistry.PlantType):
	# 罐子内容显式转换为植物卡引用，不再使用二选一参数字典。
	var reference: ResourceCardReference = ResourceCardReference.create(ResourceCardReference.CardType.Plant, plant_type)
	# 临时卡的释放与存在计时仍由卡片管理器负责。
	var card: Card = Global.main_game.card_manager.create_temp_card(reference, marker_2d_create_card_or_trophy.global_position, card_exist_time)
	if card == null:
		return

	## 控制卡片移动
	# 植物卡弹出的水平随机偏移，单位像素。
	var move_x = randf_range(-20, 20)
	# 植物卡弹出的垂直随机偏移，单位像素。
	var move_y = randf_range(10, 30)

	# 先上升再落下的垂直弹出动画。
	var tween_y = card.create_tween()
	tween_y.tween_property(card, "position:y", -move_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(card, "position:y", move_y, 0.3).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 同时推进垂直弹出与水平位移的动画。
	var tween_x = card.create_tween()
	tween_x.set_parallel()
	tween_x.tween_subtween(tween_y)
	tween_x.tween_property(card, "position:x", move_x, 0.6).as_relative()


func open_zombie(zombie_type:CharacterRegistry.ZombieType):
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

## 通过统一卡牌目录初始化固定或轮换内容的静态预览，不生成出战角色。
func character_static_init():
	## 固定随机结果
	if is_fixed_res:
		if curr_plant_type != CharacterRegistry.PlantType.Null:
			character_static = AllCards.create_static_preview(ResourceCardReference.create(ResourceCardReference.CardType.Plant, curr_plant_type))
		elif curr_zombie_type != CharacterRegistry.ZombieType.Null:
			character_static = AllCards.create_static_preview(ResourceCardReference.create(ResourceCardReference.CardType.Zombie, curr_zombie_type))
		if character_static == null:
			return
		character_container.add_child(character_static)
		character_static.position = Vector2(0,0)
	else:
		match pot_type:
			E_PotType.Random:
				character_static_init_res_random_plant()
				character_static_init_res_random_zombie()
			E_PotType.Plant:
				character_static_init_res_random_plant()
			E_PotType.Zombie:
				character_static_init_res_random_zombie()
		update_res_random_character_static()
		create_res_random_character_static_update_timer()

## 更新随机结果罐子角色虚影
func update_res_random_character_static():
	match pot_type:
		E_PotType.Random:
			var p_plant_zombie:=randf()
			if p_plant_zombie <=0.5:
				curr_plant_type = all_plant_character_statics.keys().pick_random()
				curr_zombie_type = CharacterRegistry.ZombieType.Null
				character_static = all_plant_character_statics[curr_plant_type]
			else:
				curr_plant_type = CharacterRegistry.PlantType.Null
				curr_zombie_type = all_zombie_character_statics.keys().pick_random()
				character_static = all_zombie_character_statics[curr_zombie_type]
		E_PotType.Plant:
			curr_plant_type = all_plant_character_statics.keys().pick_random()
			character_static = all_plant_character_statics[curr_plant_type]
		E_PotType.Zombie:
			curr_zombie_type = all_zombie_character_statics.keys().pick_random()
			character_static = all_zombie_character_statics[curr_zombie_type]

## 为植物白名单预先复制静态预览，身份只用于查询统一目录。
func character_static_init_res_random_plant():
	# 罐子允许出现的植物内容编号。
	for plant_type:CharacterRegistry.PlantType in Global.global_read_data.whitelist_plant_types_with_pot:
		# 独立的植物缩略图节点，不共享卡牌模板节点。
		var preview: Node2D = AllCards.create_static_preview(ResourceCardReference.create(ResourceCardReference.CardType.Plant, plant_type))
		if preview == null:
			continue
		all_plant_character_statics[plant_type] = preview
		character_container.add_child(all_plant_character_statics[plant_type])
		all_plant_character_statics[plant_type].position = Vector2(0,0)
		all_plant_character_statics[plant_type].visible = false

## 为本行地形允许的普通僵尸预先复制静态预览，僵王不进入罐子内容。
func character_static_init_res_random_zombie():
	# 当前罐子所在僵尸行的地形类型。
	var curr_zomebi_row_type:CharacterRegistry.ZombieRowType = Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type
	## 从白名单生成所有的僵尸虚影
	# 本行地形对应的普通僵尸内容编号。
	for zombie_type:CharacterRegistry.ZombieType in Global.global_read_data.whitelist_refresh_zombie_types_with_zombie_row_type[curr_zomebi_row_type]:
		# 独立的普通僵尸缩略图节点。
		var preview: Node2D = AllCards.create_static_preview(ResourceCardReference.create(ResourceCardReference.CardType.Zombie, zombie_type))
		if preview == null:
			continue
		all_zombie_character_statics[zombie_type] = preview
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
