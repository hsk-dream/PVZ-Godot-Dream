extends Node
## 手持管理器，角色（植物僵尸）
class_name HM_Character

## 角色临时挂载节点
@onready var temporary_character: Node2D = %TemporaryCharacter

## 当前卡片
var curr_card:Card = null
## 手持静态角色
var characte_static:Node2D
## 格子静态角色虚影
var characte_static_shadow:Node2D
## 植物种植条件
var plant_condition:ResourcePlantCondition
## 僵尸种植行条件
var zombie_row_type:EnumsCharacter.ZombieRowType
## 虚影在格子中，即可以种植
var is_shadow_in_cell:=false

## 柱子模式
var is_mode_column := false
## 柱子模式虚影
var characte_static_shadow_colum : Array[Node2D]

## 紫卡植物可以的预种植植物,点击卡片时明暗交替
var curr_all_preplant_purple:Array[Plant000Base]

func init_hm_character(game_para:ResourceLevelData):
	self.is_mode_column = game_para.is_mode_column

func character_process() -> void:
	## CanvasItem方法获取位置
	characte_static.global_position = temporary_character.get_global_mouse_position()

## 点击卡片
func click_card(card:Card) -> void:
	## 清除之前数据
	if curr_card != null:
		_clear_curr_data()
	## 新植物数据
	curr_card = card
	EventBus.push_event("hm_character_hand_card", [curr_card])
	## 植物
	if curr_card.card_plant_type != EnumsCharacter.PlantType.Null:
		plant_condition = Global.character_registry.get_plant_info(curr_card.card_plant_type, EnumsCharacter.PlantInfoAttribute.PlantConditionResource)
		## 静态植物以及植物虚影
		characte_static = card.character_static.duplicate()
		characte_static.get_child(0).scale = Vector2.ONE
		characte_static_shadow = characte_static.get_child(0).duplicate()
		characte_static_shadow.modulate.a = 0
		characte_static.z_index = 1

		temporary_character.add_child(characte_static)
		temporary_character.add_child(characte_static_shadow)

		if click_card_column:
			click_card_column()

		# 如果是紫卡植物
		if plant_condition.is_purple_card:
			start_preplant_purple_light(plant_condition, curr_card.card_plant_type)

	## 僵尸
	else:
		zombie_row_type = Global.character_registry.get_zombie_info(curr_card.card_zombie_type, EnumsCharacter.ZombieInfoAttribute.ZombieRowType)
		## 静态僵尸以及僵尸虚影
		characte_static = card.character_static.duplicate()
		characte_static.get_child(0).scale = Vector2.ONE
		characte_static_shadow = characte_static.get_child(0).duplicate()
		characte_static_shadow.modulate.a = 0
		characte_static.z_index = 1

		temporary_character.add_child(characte_static)
		temporary_character.add_child(characte_static_shadow)

		if click_card_column:
			click_card_column()

## 紫卡预种植植物身体明暗发光开始
func start_preplant_purple_light(curr_plant_condition:ResourcePlantCondition, plant_type:EnumsCharacter.PlantType):
	curr_all_preplant_purple = curr_plant_condition.get_all_preplant_purple(Global.main_game.plant_cell_manager.all_plant_cells, plant_type)
	for preplant_purple in curr_all_preplant_purple:
		preplant_purple.preplant_purple_body_light_and_dark()
#
## 紫卡预种植植物身体明暗发光结束
func end_preplant_purple_light():
	for preplant_purple in curr_all_preplant_purple:
		if is_instance_valid(preplant_purple):
			preplant_purple.preplant_purple_body_light_and_dark_end()

## 清除数据
func _clear_curr_data():
	# 如果是紫卡植物
	if plant_condition != null and plant_condition.is_purple_card:
		end_preplant_purple_light()

	is_shadow_in_cell = false
	## 若当前存在卡片,事件总线推清除当前卡片数据,种子雨卡槽接受判断
	if is_instance_valid(curr_card):
		EventBus.push_event("hm_character_clear_card", [curr_card])

	curr_card = null
	characte_static.queue_free()
	characte_static_shadow.queue_free()
	plant_condition = null
	zombie_row_type = EnumsCharacter.ZombieRowType.Land
	if is_mode_column:
		_clear_curr_data_column()

## 鼠标进入cell
func mouse_enter(plant_cell:PlantCell):
	is_shadow_in_cell = _update_cell_shadow(plant_cell, characte_static_shadow)
	if is_shadow_in_cell and is_mode_column:
		_mouse_enter_column(plant_cell)

## 更新植物格子虚影,返回是否能种植
func _update_cell_shadow(plant_cell:PlantCell, characte_static_shadow:Node2D) -> bool:
	## 植物
	if curr_card.card_plant_type != 0:
		## 如果是判定是否可以种植植物
		if plant_condition.judge_is_can_plant(plant_cell, curr_card.card_plant_type):
			characte_static_shadow.global_position = plant_cell.get_new_plant_static_shadow_global_position(plant_condition.place_plant_in_cell)
			characte_static_shadow.modulate.a = 0.5
			return true
		else:
			characte_static_shadow.modulate.a = 0
			return false

	## 僵尸
	else:
		## 如果当前格子不能种植僵尸(蹦极除外)
		if not plant_cell.can_common_zombie and curr_card.card_zombie_type != EnumsCharacter.ZombieType.Z021Bungi:
			return false
		## 如果不是双地形
		if zombie_row_type != EnumsCharacter.ZombieRowType.Both:
			if zombie_row_type == Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type:
				characte_static_shadow.global_position =  get_zombie_static_shadow_global_position(plant_cell)
				characte_static_shadow.modulate.a = 0.5
				return true
			else:
				characte_static_shadow.modulate.a = 0
				return false
		else:
			characte_static_shadow.global_position = get_zombie_static_shadow_global_position(plant_cell)
			characte_static_shadow.modulate.a = 0.5
			return true

## 获取种植僵尸的虚影位置
func get_zombie_static_shadow_global_position(plant_cell)->Vector2:
	var global_pos =  Vector2(
		plant_cell.global_position.x + plant_cell.size.x/2,
		Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
	)

	## 如果有斜面
	if is_instance_valid(Global.main_game.main_game_slope):
		global_pos += Vector2(0, Global.main_game.main_game_slope.get_all_slope_y(global_pos.x))


	return global_pos

## 鼠标移出cell
func mouse_exit(_plant_cell:PlantCell):
	characte_static_shadow.modulate.a = 0
	if is_mode_column:
		_mouse_exit_column()

## 点击种植植物\僵尸
func click_cell(plant_cell:PlantCell):
	if is_shadow_in_cell:
		if curr_card.card_plant_type != 0:
			plant_cell.create_plant(curr_card.card_plant_type, curr_card.is_imitater)
		else:
			var zombie_init_para:Dictionary = {
				Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
				Zombie000Base.E_ZInitAttr.Lane:plant_cell.row_col.x,
			}

			Global.main_game.zombie_manager.create_norm_zombie(
				curr_card.card_zombie_type,
				Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x],
				zombie_init_para,
				Vector2(
					plant_cell.global_position.x + plant_cell.size.x/2,
					Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
				),
				GlobalUtils.get_special_zombie_callable(curr_card.card_zombie_type, plant_cell)
			)

		## 卡片种植完成发射信号
		curr_card.signal_card_use_end.emit()
		if is_mode_column:
			_click_cell_column(plant_cell)

## 退出当前状态
func exit_status():
	_clear_curr_data()


#region 柱子模式额外操作函数
## 柱子模式 点击卡片产生多余植物虚影
func click_card_column() -> void:
	if curr_card.card_plant_type != 0:
		for plant_cell_i in range(Global.main_game.plant_cell_manager.row_col.x):
			var column_characte_static_shadow = characte_static_shadow.duplicate()
			column_characte_static_shadow.modulate.a = 0
			temporary_character.add_child(column_characte_static_shadow)
			characte_static_shadow_colum.append(column_characte_static_shadow)
	else:
		for zombie_rows_i in range(Global.main_game.zombie_manager.all_zombie_rows.size()):
			var column_characte_static_shadow = characte_static_shadow.duplicate()
			column_characte_static_shadow.modulate.a = 0
			temporary_character.add_child(column_characte_static_shadow)
			characte_static_shadow_colum.append(column_characte_static_shadow)

## 柱子模式 鼠标进入判断其他格子是否可以种植，产生虚影
func _mouse_enter_column(plant_cell:PlantCell):
	for plant_cell_i in range(Global.main_game.plant_cell_manager.row_col.x):
		if plant_cell_i == plant_cell.row_col.x:
			continue

		## 判断是否产生虚影
		_update_cell_shadow(
			Global.main_game.plant_cell_manager.all_plant_cells[plant_cell_i][plant_cell.row_col.y],\
			characte_static_shadow_colum[plant_cell_i]
		)

## 柱子模式 鼠标移出cell
func _mouse_exit_column():
	for _characte_static_shadow in characte_static_shadow_colum:
		_characte_static_shadow.modulate.a = 0

## 柱子模式 点击种植或铲掉植物
func _click_cell_column(plant_cell:PlantCell):
	if curr_card.card_plant_type != 0:
		for i in range(characte_static_shadow_colum.size()):
			## 当前格子的图像透明
			var _characte_static_shadow = characte_static_shadow_colum[i]
			if _characte_static_shadow.modulate.a != 0:
				var _plant_cell:PlantCell = Global.main_game.plant_cell_manager.all_plant_cells[i][plant_cell.row_col.y]
				_plant_cell.create_plant(curr_card.card_plant_type, curr_card.is_imitater)
	else:
		for i in range(characte_static_shadow_colum.size()):
			## 当前格子的图像透明
			var _characte_static_shadow = characte_static_shadow_colum[i]
			if _characte_static_shadow.modulate.a != 0:
				var _plant_cell:PlantCell = Global.main_game.plant_cell_manager.all_plant_cells[i][plant_cell.row_col.y]

				var zombie_init_para:Dictionary = {
					Zombie000Base.E_ZInitAttr.CharacterInitType:Character000Base.E_CharacterInitType.IsNorm,
					Zombie000Base.E_ZInitAttr.Lane:_plant_cell.row_col.x,
				}

				Global.main_game.zombie_manager.create_norm_zombie(
					curr_card.card_zombie_type,
					Global.main_game.zombie_manager.all_zombie_rows[_plant_cell.row_col.x],
					zombie_init_para,

					Vector2(_characte_static_shadow.global_position.x,
						Global.main_game.zombie_manager.all_zombie_rows[_plant_cell.row_col.x].zombie_create_position.global_position.y
					),
					GlobalUtils.get_special_zombie_callable(curr_card.card_zombie_type, _plant_cell)
				)

## 柱子模式 清除数据
func _clear_curr_data_column():
	for _characte_static_shadow in characte_static_shadow_colum:
		_characte_static_shadow.queue_free()
	characte_static_shadow_colum.clear()

#endregion
