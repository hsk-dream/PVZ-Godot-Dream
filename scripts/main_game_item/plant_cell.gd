extends Control
class_name PlantCell

## 植物的父节点为对应位置的容器节点 plant_container_node
## 底部植物会上下移动
## 如果使用tween控制移动，每帧计算差值控制中间植物上下移动会卡#
## 因此放置底部植物时：
## 将中间植物（norm和shell）的容器节点放到底部植物的容器（底部植物自带的子节点，与植物格子的底部植物容器无关）中
## 底部植物容器会上下移动，从而带动中间植物上下移动
## 中间植物的位置与底部植物的容器位置无关

signal click_cell
signal cell_mouse_enter
signal cell_mouse_exit
## 删除墓碑信号
signal signal_cell_delete_tombstone(plant_cell:PlantCell, tombstone:TombStone)

@onready var button: Button = $Button
## 植物碰撞器位置节点
@onready var plant_area_2d_position: Control = $PlantArea2dPosition

## 植物格子类型
enum PlantCellType{
	Grass,		## 草地
	Pool,		## 水池
	Roof,		## 屋顶/裸地
}
## 当前格子类型
@export var plant_cell_type :PlantCellType = PlantCellType.Grass

## 行和列 PlantCellManager赋值
@export var row_col:Vector2i

@export_group("当前格子的条件")
@export_subgroup("植物种植")
#@export_flags("1 无", "2 草地", "4 花盆", "8 水", "16 睡莲", "32 屋顶/裸地")
var ori_condition:int = 3
## 植物种植地形条件（满足一个即可），默认（无1 + 草地2 = 3）
var curr_condition:int = 3

## 在当前格子中对应位置的植物
@export var plant_in_cell:Dictionary[CharacterRegistry.PlacePlantInCell, Plant000Base] =  {
	CharacterRegistry.PlacePlantInCell.Norm: null,
	CharacterRegistry.PlacePlantInCell.Float: null,
	CharacterRegistry.PlacePlantInCell.Down: null,
	CharacterRegistry.PlacePlantInCell.Shell: null,
	#CharacterRegistry.PlacePlantInCell.Imitater: null,
}

## 在当前格子中对应位置的容器节点
@onready var plant_container_node:Dictionary =  {
	CharacterRegistry.PlacePlantInCell.Norm: $PlantNormContainer,
	CharacterRegistry.PlacePlantInCell.Shell: $PlantShellContainer,
	CharacterRegistry.PlacePlantInCell.Float: $PlantFloatContainer,
	CharacterRegistry.PlacePlantInCell.Down: $PlantDownContainer,
	CharacterRegistry.PlacePlantInCell.Imitater: $PlantImitaterContainer,
}

## 在当前格子中对应容器位置的节点初始全局位置,
var plant_postion_node_ori_global_position:Dictionary =  {}

@export_subgroup("特殊状态，特殊状态下无法种植")
## 是否可以种植普通植物
@export var can_common_plant := true
#var is_can_common_plant
enum E_SpecialStatePlant {
	IsTombstone,	# 墓碑
	IsCrater,		# 坑洞
	IsIceRoad,		# 冰道
	IsPot,			# 罐子
	IsNoPlantBowling,		# 不能种植（保龄球红线模式不能种植）
}

## 当前特殊状态
@export var curr_special_state_plant:Dictionary[E_SpecialStatePlant, bool]

## 当前格子冰道
var curr_ice_roads:Array[IceRoad] = []
## 当前cell的墓碑
var tombstone:TombStone
## 当前cell的坑洞
var crater:DoomShroomCrater
## 标准九列屋顶从左到右的斜面列数；零起点列号 0～4 使用斜面坑洞，其余列使用平面坑洞。
const ROOF_SLOPE_COLUMN_COUNT := 5

@export_subgroup("特殊状态，特殊状态下无法种植僵尸")
## 是否可以种植僵尸
@export var can_common_zombie := true
enum E_SpecialStateZombie {
	IsNoPlantBowling,		## 不能种植（保龄球红线模式不能种植）
}
## 当前特殊状态
@export var curr_special_state_zombie:Dictionary[E_SpecialStateZombie, bool]

## 梯子
var ladder:Ladder

## 植物种植和死亡信号
signal signal_plant_create(plant_cell:PlantCell, plant_type:CharacterRegistry.PlantType)
signal signal_plant_free(plant_cell:PlantCell, plant_type:CharacterRegistry.PlantType)

#region 植物格子初始化
func _ready() -> void:
	## 隐藏按钮样式
	var new_stylebox_normal = $Button.get_theme_stylebox("pressed").duplicate()
	$Button.add_theme_stylebox_override("normal", new_stylebox_normal)

	## 根据格子类型初始化植物种植地形条件
	init_condition()

## 根据当前格子类型初始化当前格子状态
func init_condition():
	match plant_cell_type:
		PlantCellType.Grass:
			ori_condition = 3
			curr_condition = 3

		PlantCellType.Pool:
			ori_condition = 9
			curr_condition = 9

		PlantCellType.Roof:
			ori_condition = 33
			curr_condition = 33

	### 在当前格子中对应位置的节点初始全局位置,植物放在该节点下
	for place_plant_in_cell in plant_container_node.keys():
		plant_postion_node_ori_global_position[place_plant_in_cell] = plant_container_node[place_plant_in_cell].global_position
#endregion


#region 伽刚特尔攻击当前植物格子
func be_gargantuar_attack(zombie_gargantuar:Zombie000Base):
	for place_plant_in_cell in plant_in_cell:
		if is_instance_valid(plant_in_cell[place_plant_in_cell]) and plant_in_cell[place_plant_in_cell].hurt_box_component.is_enabling:
			## 被压扁
			plant_in_cell[place_plant_in_cell].be_flattened_from_enemy(zombie_gargantuar)
	if is_instance_valid(pot):
		pot.open_pot_be_gargantuar()


func plant_be_flattened():
	for place_plant_in_cell in plant_in_cell:
		if is_instance_valid(plant_in_cell[place_plant_in_cell]):
			## 被压扁
			plant_in_cell[place_plant_in_cell].be_flattened()
			print(plant_in_cell[place_plant_in_cell].name, "被压扁")

#endregion

#region 植物(僵尸)种植(死亡)
## 模仿者创建植物
func imitater_create_plant(plant_type:CharacterRegistry.PlantType, is_plant_start_effect:=true):
	await get_tree().process_frame
	var plant = create_plant(plant_type, false, is_plant_start_effect, true)
	return plant
## 新植物种植
##[is_imitater:bool] 植物是否为模仿者
##[is_plant_start_effect:bool] 是否有种植特效
##[is_imitater_material:bool] 是否为模仿者材质
##[is_zombie_mode:bool] 是否为我是僵尸模式
func create_plant(plant_type:CharacterRegistry.PlantType, is_imitater:=false, is_plant_start_effect:=true, is_imitater_material:=false, is_zombie_mode:=false) -> Plant000Base:
	var plant_condition:ResourcePlantCondition
	var plant :Plant000Base
	plant_condition = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)

	## 如果该植物为紫卡
	if plant_condition.is_purple_card:
		## 删除紫卡前置植物,创建新植物
		var condition_pre_plant :ResourcePlantCondition = Global.character_registry.get_plant_info(Global.character_registry.AllPrePlantPurple[plant_type], CharacterRegistry.PlantInfoAttribute.PlantConditionResource)
		if is_instance_valid(plant_in_cell[condition_pre_plant.place_plant_in_cell]):
			plant_in_cell[condition_pre_plant.place_plant_in_cell].character_death_disappear()
			#await get_tree().process_frame
	else:
		## 非紫卡 如果该位置已经存在植物,返回
		if is_instance_valid(plant_in_cell[plant_condition.place_plant_in_cell]):
			print("当前位置", row_col, "已经有植物：", plant_in_cell[plant_condition.place_plant_in_cell].name)
			return

	## 创建植物
	if is_imitater:
		## 创建植物
		#plant_condition = Global.character_registry.get_plant_info(CharacterRegistry.PlantType.P999Imitater, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)
		plant = Global.character_registry.get_plant_info(CharacterRegistry.PlantType.P999Imitater, CharacterRegistry.PlantInfoAttribute.PlantScenes).instantiate()
		plant = plant as Plant999Imitater
		plant.imitater_plant_type = plant_type
	else:
		plant = Global.character_registry.get_plant_info(plant_type, CharacterRegistry.PlantInfoAttribute.PlantScenes).instantiate()

	var plant_init_para = {
		Plant000Base.E_PInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
		Plant000Base.E_PInitAttr.PlantCell:self,
		Plant000Base.E_PInitAttr.IsImitaterMaterial:is_imitater_material,
		Plant000Base.E_PInitAttr.IsZombieMode:is_zombie_mode
	}
	plant.init_plant(plant_init_para)
	if is_imitater:
		plant_container_node[CharacterRegistry.PlacePlantInCell.Imitater].add_child(plant)
	else:
		plant_container_node[plant_condition.place_plant_in_cell].add_child(plant)

	plant_in_cell[plant_condition.place_plant_in_cell] = plant
	plant.signal_character_death.connect(one_plant_free.bind(plant))

	if is_plant_start_effect:
		## 种植特效
		var plant_start_effect_scene:Node2D
		## 当前地形为水或者睡莲
		if curr_condition & 8 or curr_condition & 16:
			plant_start_effect_scene = SceneRegistry.PLANT_START_EFFECT_WATER.instantiate()
		else:
			plant_start_effect_scene = SceneRegistry.PLANT_START_EFFECT.instantiate()
		plant.body.add_child(plant_start_effect_scene)

	if not is_imitater:

		## 如果是down位置植物，修改中间植物节点顺序， 提高中间植物和壳的位置,
		if plant_condition.place_plant_in_cell == CharacterRegistry.PlacePlantInCell.Down:
			#plant = plant as PlantDownBase
			## 修改PlantNorm和PlantShell为底部植物节点上下移动节点的子节点
			remove_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Norm])
			plant.down_plant_container.add_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Norm])
			plant_container_node[CharacterRegistry.PlacePlantInCell.Norm].global_position = plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm] - plant.plant_up_position

			remove_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Shell])
			plant.down_plant_container.add_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Shell])
			plant_container_node[CharacterRegistry.PlacePlantInCell.Shell].global_position = plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Shell] - plant.plant_up_position

	signal_plant_create.emit(self, plant.plant_type)

	return plant

## 咖啡豆唤醒在睡眠中的植物
func coffee_bean_awake_up():
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]):
		plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm].coffee_bean_awake_up()
	else:
		print("没有睡眠植物")

## 获取种植新植物时植物虚影的位置
func get_new_plant_static_shadow_global_position(place_plant_in_cell:CharacterRegistry.PlacePlantInCell):
	return plant_container_node[place_plant_in_cell].global_position

## 植物死亡
func one_plant_free(plant:Plant000Base):
	var curr_plant_condition :ResourcePlantCondition = Global.character_registry.get_plant_info(plant.plant_type, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)

	if is_instance_valid(ladder):
		if curr_plant_condition.place_plant_in_cell in [CharacterRegistry.PlacePlantInCell.Down, CharacterRegistry.PlacePlantInCell.Norm, CharacterRegistry.PlacePlantInCell.Shell]:
			ladder.ladder_death()

	#plant_in_cell[curr_plant_condition.place_plant_in_cell] = null
	## 如果是down位置植物，下降中间植物和壳的位置，修改节点结构
	if curr_plant_condition.place_plant_in_cell == CharacterRegistry.PlacePlantInCell.Down:
		## 中间植物的节点修改回来
		plant.down_plant_container.remove_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Norm])
		add_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Norm])
		plant_container_node[CharacterRegistry.PlacePlantInCell.Norm].global_position = plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Norm]

		plant.down_plant_container.remove_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Shell])
		add_child(plant_container_node[CharacterRegistry.PlacePlantInCell.Shell])
		plant_container_node[CharacterRegistry.PlacePlantInCell.Shell].global_position = plant_postion_node_ori_global_position[CharacterRegistry.PlacePlantInCell.Shell]
	## 玉米加农炮只有后轮plantcell发射信号更新植物数据
	if plant.plant_type == CharacterRegistry.PlantType.P048CobCannon:
		if plant.plant_cell == self:
			signal_plant_free.emit(self, plant.plant_type)
	else:
		signal_plant_free.emit(self, plant.plant_type)

	##如果植物死亡时鼠标在当前植物格子中，等待一帧后重新发射鼠标进入格子信号检测种植
	if is_mouse_in_ui(button):
		await get_tree().process_frame
		_on_button_mouse_entered()

## 改变特殊状态(植物)
func update_special_state_plant(value:bool, change_specila_state:E_SpecialStatePlant):
	curr_special_state_plant[change_specila_state] = value
	_update_state_plant()

## 改变特殊状态(僵尸)
func update_special_state_zombie(value:bool, change_specila_state:E_SpecialStateZombie):
	curr_special_state_zombie[change_specila_state] = value
	_update_state_zombie()

## 更新状态
func _update_state_plant():
	##是否全为false(无特殊状态，可以种植)
	can_common_plant = curr_special_state_plant.values().all(func(v): return not v)
	##如果更新状态时鼠标在当前植物格子中，重新发射鼠标进入格子信号检测种植
	if is_mouse_in_ui(button):
		_on_button_mouse_entered()

## 更新状态
func _update_state_zombie():
	##是否全为false(无特殊状态，可以种植)
	can_common_zombie = curr_special_state_zombie.values().all(func(v): return not v)
	##如果更新状态时鼠标在当前植物格子中，重新发射鼠标进入格子信号检测种植
	if is_mouse_in_ui(button):
		_on_button_mouse_entered()

## 荷叶种植/死亡时调用
func _lily_pad_change_condition():
	## 切换荷叶地形
	curr_condition = curr_condition ^ 16
	## 切换水池地形
	curr_condition = curr_condition ^ 8

## 花盆种植/死亡时调用
func _flower_pot_change_condition():
	## 如果当前是花盆地形，设置地形为原始地形
	if curr_condition & 4:
		curr_condition = ori_condition
	## 如果当前不是花盆地形，设置当前地形为花盆地形
	else:
		curr_condition = 4

## 底部植物种植或死亡时改变地形
func down_plant_change_condition(is_water:bool):
	if is_water:
		_lily_pad_change_condition()
	else:
		_flower_pot_change_condition()
#endregion

#region 蹦极僵尸偷植物
## 返回当前可偷取的第一层植物；选择目标与实际偷取共用此顺序，失效或死亡实例不参与。
func get_bungi_target() -> Plant000Base:
	# 各种植层的偷取优先级；一次只取一株，不连带移除整格植物。
	for place in [
		CharacterRegistry.PlacePlantInCell.Norm,
		CharacterRegistry.PlacePlantInCell.Shell,
		CharacterRegistry.PlacePlantInCell.Down,
		CharacterRegistry.PlacePlantInCell.Float
	]:
		# 先以 Variant 检查可能已释放的引用，再转换植物类型。
		var plant_reference: Variant = plant_in_cell[place]
		if not is_instance_valid(plant_reference):
			continue
		# 只有仍在场景中的存活植物才能成为偷取目标。
		var plant := plant_reference as Plant000Base
		if plant != null and plant.is_inside_tree() and not plant.is_queued_for_deletion() and not plant.is_death:
			return plant
	return null


## 偷取当前有效植物并返回其表现复制体；目标消失时返回 null。
func be_bungi() -> Node2D:
	# 执行时重新读取格内植物，避免使用准备阶段已死亡的植物引用。
	var plant: Plant000Base = get_bungi_target()
	return plant.be_bungi() if plant != null else null
#endregion

#region 特殊状态
#region 墓碑相关
## 创建墓碑
func create_tombstone():
	if is_instance_valid(tombstone):
		print("当前植物格子", row_col, "已经有墓碑， 创建墓碑失败")
		return
	## 被墓碑顶掉的植物
	var all_place_plant_in_cell_be_tombstone = [
		CharacterRegistry.PlacePlantInCell.Norm,
		CharacterRegistry.PlacePlantInCell.Down,
		CharacterRegistry.PlacePlantInCell.Shell
	]
	## 删除对应位置植物
	for place_plant_in_cell in all_place_plant_in_cell_be_tombstone:
		## 如果存在植物
		if is_instance_valid(plant_in_cell[place_plant_in_cell]):
			plant_in_cell[place_plant_in_cell].character_death()

	tombstone = SceneRegistry.TOMBSTONE.instantiate()
	tombstone.init_tombstone(self)
	add_child(tombstone)
	tombstone.position = Vector2(size.x / 2, size.y)
	update_special_state_plant(true, E_SpecialStatePlant.IsTombstone)

	Global.main_game.plant_cell_manager.tombstone_list.append(tombstone)


## 刪除墓碑，墓碑死亡时调用该函数
func tombstone_death_update_plant_cell_data():
	signal_cell_delete_tombstone.emit(self, tombstone)
	Global.main_game.plant_cell_manager.tombstone_list.erase(tombstone)
	## 等到墓碑被删除后，下一帧更新（如果鼠标拿着新植物在当前格子中，可以更新）
	await get_tree().process_frame
	update_special_state_plant(false, E_SpecialStatePlant.IsTombstone)

#endregion

#region 坑洞相关
## 按背景和格子地形创建毁灭菇坑洞并清空同格植物。
## 先禁种，避免死亡回调刷新种植虚影时短暂允许种植。
func create_crater():
	update_special_state_plant(true, E_SpecialStatePlant.IsCrater)
	_clear_plants_for_crater()

	self.crater = SceneRegistry.DOOM_SHROOM_CRATER.instantiate()
	add_child(crater)
	crater.init_crater(_get_crater_type(), self)


## 根据实际背景与原始格子地形返回坑洞图片组索引，不受睡莲或花盆改变种植条件的影响。[br]
## 0/1 为陆地白天/黑夜，2/3 为水池白天/黑夜，4/5 为屋顶平面/斜面。[br]
## 屋顶按开局初始化完成后的左起零起点列号判断；未知背景回退到陆地白天。
func _get_crater_type() -> int:
	match Global.main_game.game_para.game_BG:
		ConstLevelData.GameBg.FrontDay:
			return 0
		ConstLevelData.GameBg.FrontNight:
			return 1
		ConstLevelData.GameBg.Pool:
			return 2 if plant_cell_type == PlantCellType.Pool else 0
		ConstLevelData.GameBg.Fog:
			return 3 if plant_cell_type == PlantCellType.Pool else 1
		ConstLevelData.GameBg.Roof, ConstLevelData.GameBg.RoofNight:
			return 5 if row_col.y >= 0 and row_col.y < ROOF_SLOPE_COLUMN_COUNT else 4
	return 0


## 清空坑洞所在格子的各层植物，不触发连带亡语；底层植物最后死亡以恢复地形和容器结构。
## 已死亡或等待释放的实例不重复结算，毁灭菇自身由原来的死亡流程释放。
func _clear_plants_for_crater() -> void:
	# 保存各层植物引用，避免死亡回调修改格子数据后影响本次清理目标。
	var plants_to_clear: Dictionary = plant_in_cell.duplicate()
	# 当前清理的种植层；底层植物最后处理，模仿者层不存在时会被跳过。
	for place: CharacterRegistry.PlacePlantInCell in [
		CharacterRegistry.PlacePlantInCell.Norm,
		CharacterRegistry.PlacePlantInCell.Shell,
		CharacterRegistry.PlacePlantInCell.Float,
		CharacterRegistry.PlacePlantInCell.Imitater,
		CharacterRegistry.PlacePlantInCell.Down
	]:
		# 先检查原始引用，前一个植物的死亡回调可能已经释放后续目标。
		var plant_reference: Variant = plants_to_clear.get(place)
		if not is_instance_valid(plant_reference):
			continue
		# 有效的待清理植物；正在执行亡语的毁灭菇尚未排队释放，但已经标记死亡。
		var plant := plant_reference as Plant000Base
		if plant == null or plant.is_death or plant.is_queued_for_deletion():
			continue

		plant.is_can_death_language = false
		# 沿用死亡通知、数量更新和底层植物地形恢复，不直接释放节点。
		plant.character_death_disappear()
		# 只清空仍指向原目标的种植层，避免覆盖死亡回调新写入的植物引用。
		if plant_in_cell.get(place) == plant_reference:
			plant_in_cell[place] = null

## 坑洞调用该函数，坑洞是自己消失后调用该函数
func delete_crater_update_plant_cell_data():
	update_special_state_plant(false, E_SpecialStatePlant.IsCrater)

#endregion

#region 冰道相关
func add_new_ice_road(new_ice_road:IceRoad):
	curr_ice_roads.append(new_ice_road)
	update_special_state_plant(true, E_SpecialStatePlant.IsIceRoad)
	new_ice_road.signal_ice_road_disappear.connect(del_new_ice_road_update_plant_cell_data.bind(new_ice_road))

## 删除冰道
func del_new_ice_road_update_plant_cell_data(new_ice_road):
	curr_ice_roads.erase(new_ice_road)
	if curr_ice_roads.is_empty():
		update_special_state_plant(false, E_SpecialStatePlant.IsIceRoad)

#endregion

#region 保龄球种植限制
## 设置保龄球不能种植
func set_bowling_no_plant():
	update_special_state_plant(true, E_SpecialStatePlant.IsNoPlantBowling)

## 设置保龄球不能僵尸
func set_bowling_no_zombie():
	update_special_state_zombie(true, E_SpecialStateZombie.IsNoPlantBowling)
#endregion

#region 罐子
var pot:ScaryPot
const SCARY_POT = preload("uid://bfhjvru3xr23t")

## 生成一个罐子
func create_pot(pot_para:Dictionary) -> ScaryPot:
	if is_instance_valid(pot):
		return
	pot = SCARY_POT.instantiate()
	pot.init_pot(pot_para)
	add_child(pot)
	pot.position = Vector2(size.x / 2, size.y)

	update_special_state_plant(true, E_SpecialStatePlant.IsPot)

	return pot

## 打开罐子后更新数据
func open_pot_update_plant_cell_data():
	update_special_state_plant(false, E_SpecialStatePlant.IsPot)
#endregion

#endregion

#region 鼠标交互相关
func _on_button_pressed() -> void:
	click_cell.emit(self)

func _on_button_mouse_entered() -> void:
	cell_mouse_enter.emit(self)

func _on_button_mouse_exited() -> void:
	cell_mouse_exit.emit(self)


func is_mouse_in_ui(control_node: Control) -> bool:
	return control_node.get_rect().has_point(control_node.get_local_mouse_position())

## 返回当前被铲子威胁的植物
func return_plant_be_shovel_look():
	## 如果当前格子有植物,根据位置选择植物，若位置没有植物，选择别的植物
	if get_curr_plant_num() > 0:
		var plant_place_be_shovel = get_plant_place_from_mouse_pos()
		return return_plant_null_res(plant_place_be_shovel)
	else:
		return null

## 如果当前位置没有植物时，返回顺位植物,递归调用，直到返回植物
## is_loop 表示上次是否判断过是否为norm，shell循环
## 写代码的时候没有float植物，不确定是否有问题
func return_plant_null_res(plant_place_be_shovel:CharacterRegistry.PlacePlantInCell, is_loop:=false):
	match plant_place_be_shovel:
		CharacterRegistry.PlacePlantInCell.Norm:
			if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]):
				return plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]
			else:
				if is_loop:
					return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Down, true)
				else:
					return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Shell, true)

		CharacterRegistry.PlacePlantInCell.Shell:
			if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Shell]):
				return plant_in_cell[CharacterRegistry.PlacePlantInCell.Shell]
			else:
				if is_loop:
					return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Down, true)
				else:
					return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Norm, true)

		CharacterRegistry.PlacePlantInCell.Float:
			if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Float]):
				return plant_in_cell[CharacterRegistry.PlacePlantInCell.Float]
			else:
				return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Norm)

		CharacterRegistry.PlacePlantInCell.Down:
			if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Down]):
				return plant_in_cell[CharacterRegistry.PlacePlantInCell.Down]
			else:
				return return_plant_null_res(CharacterRegistry.PlacePlantInCell.Float)

## 铲子进入该shell时，判断当前格子是否有多个植物,蹦极僵尸判断是否有植物
## 有多个植物时，会随鼠标移动更新当前被铲子看的植物
func get_curr_plant_num()->int:
	var curr_plant_num = 0
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]):
		curr_plant_num += 1
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Shell]):
		curr_plant_num += 1
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Float]):
		curr_plant_num += 1
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Down]):
		curr_plant_num += 1
	return curr_plant_num

## 鼠标移动检测
#func _input(event):
	#if event is InputEventMouseMotion:
		#_check_mouse_panel_region(event.position)
#
## 根据鼠标在当前格子中的位置，返回应该被铲除的植物
func get_plant_place_from_mouse_pos():
	var local_pos = button.get_local_mouse_position()
	var height = button.size.y
	if local_pos.y < height / 3:
		return CharacterRegistry.PlacePlantInCell.Float
	elif local_pos.y < height * 2 / 3:
		return CharacterRegistry.PlacePlantInCell.Norm
	else:
		return CharacterRegistry.PlacePlantInCell.Shell

#endregion

#region 梯子
## 被挂载梯子
## global_pos:挂载梯子精灵节点的全局位置
func be_ladder():
	ladder = SceneRegistry.LADDER.instantiate()
	ladder.init_ladder(self)
	add_child(ladder)
	for p in plant_in_cell:
		if is_instance_valid(plant_in_cell[p]):
			plant_in_cell[p].signal_ladder_update.emit()

## 梯子消失
func ladder_loss():
	for p in plant_in_cell:
		if is_instance_valid(plant_in_cell[p]):
			plant_in_cell[p].signal_ladder_update.emit()


## 获取当前植物格子可以挂载梯子的植物
func get_plant_ladder() -> Plant000Base:
	## 如果有壳类植物
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Shell]):
		return plant_in_cell[CharacterRegistry.PlacePlantInCell.Shell]
	## 如果Norm植物
	if is_instance_valid(plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]) and plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm].is_can_ladder:
		return plant_in_cell[CharacterRegistry.PlacePlantInCell.Norm]

	return null


#endregion


## 获取周围一圈(包括本身格子)的某个植物
func get_plant_surrounding(p_t:CharacterRegistry.PlantType) -> Array[Plant000Base]:
	var all_plant:Array[Plant000Base] = []
	## 植物种植条件
	var plant_condition:ResourcePlantCondition = Global.character_registry.get_plant_info(p_t, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)
	for i in range(max(0, row_col.x-1), min(Global.main_game.plant_cell_manager.row_col.x, row_col.x+2)):
		for j in range(max(0, row_col.y-1), min(Global.main_game.plant_cell_manager.row_col.y, row_col.y+2)):
			var p_c:PlantCell = Global.main_game.plant_cell_manager.all_plant_cells[i][j]
			if is_instance_valid(p_c.plant_in_cell[plant_condition.place_plant_in_cell]) and p_c.plant_in_cell[plant_condition.place_plant_in_cell].plant_type == p_t:
				all_plant.append(p_c.plant_in_cell[plant_condition.place_plant_in_cell])
	return all_plant

## 获取周围一圈的植物格子，包括本身
func get_plant_cell_surrounding()->Array[PlantCell]:
	var all_plant_cells_surrounding:Array[PlantCell]
	for i in range(max(0, row_col.x-1), min(Global.main_game.plant_cell_manager.row_col.x, row_col.x+2)):
		for j in range(max(0, row_col.y-1), min(Global.main_game.plant_cell_manager.row_col.y, row_col.y+2)):
			all_plant_cells_surrounding.append(Global.main_game.plant_cell_manager.all_plant_cells[i][j])
	return all_plant_cells_surrounding

#region 存档
## 植物格子存档
func get_save_game_data_plant_cell() -> ResourceSaveGamePlantCell:
	var save_game_data_plant_cell:ResourceSaveGamePlantCell = ResourceSaveGamePlantCell.new()
	save_game_data_plant_cell.row_col = row_col
	for place_plant_in_cell in plant_in_cell:
		if is_instance_valid(plant_in_cell[place_plant_in_cell]):
			## 如果不是加农炮
			if not plant_in_cell[place_plant_in_cell] is Plant048CobCannon:
				save_game_data_plant_cell.plant_type_in_cell[place_plant_in_cell] = plant_in_cell[place_plant_in_cell].gat_save_game_data_plant()
			else:
				var plant_48_cob_cannon:Plant048CobCannon = plant_in_cell[place_plant_in_cell] as Plant048CobCannon
				if plant_48_cob_cannon.plant_cell_next != self:
					save_game_data_plant_cell.plant_type_in_cell[place_plant_in_cell] = plant_in_cell[place_plant_in_cell].gat_save_game_data_plant()

	if is_instance_valid(ladder):
		save_game_data_plant_cell.is_ladder = true

	return save_game_data_plant_cell

## 读档植物格子数据
func load_game_data_plant_cell(save_game_data_plant_cell:ResourceSaveGamePlantCell):
	for place_plant_in_cell in save_game_data_plant_cell.plant_type_in_cell:
		var game_data_plant:Dictionary = save_game_data_plant_cell.plant_type_in_cell[place_plant_in_cell]
		_load_game_data_create_plant(game_data_plant)

	if save_game_data_plant_cell.is_ladder:
		be_ladder()

## 清除当前植物格子数据
func clear_data_plant_cell():
	for place_plant_in_cell in plant_in_cell:
		if is_instance_valid(plant_in_cell[place_plant_in_cell]):
			plant_in_cell[place_plant_in_cell].character_death_disappear()


## 读档时创建植物
func _load_game_data_create_plant(game_data_plant):
	var plant:Plant000Base
	plant = create_plant(game_data_plant["plant_type"], false, false, game_data_plant["is_imitater_material"])
	if plant != null:
		plant.load_game_data_plant(game_data_plant)
#endregion
