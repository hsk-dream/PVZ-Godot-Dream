## 手持出战卡的预览、格子判定和创建；显式区分植物与普通僵尸。
extends Node
class_name HM_Character

## 所属手持管理器。
@onready var hand_manager: HandManager = %HandManager
## 鼠标角色预览与格子虚影的临时挂载节点。
@onready var temporary_character: Node2D = %TemporaryCharacter
## 当前手持的卡片实例，退出状态时清除。
var curr_card: Card = null
## 跟随鼠标的静态角色预览。
var characte_static: Node2D
## 当前格子的半透明静态角色虚影。
var characte_static_shadow: Node2D
## 植物格子判定条件，仅植物卡加载。
var plant_condition: ResourcePlantCondition
## 普通僵尸允许出现的行地形，仅僵尸卡读取。
var zombie_row_type: CharacterRegistry.ZombieRowType = CharacterRegistry.ZombieRowType.Land
## 当前格子是否已通过出战卡放置判定。
var is_shadow_in_cell: bool = false
## 是否启用同列多行的柱子模式。
var is_mode_column: bool = false
## 柱子模式按行保存的额外虚影。
var characte_static_shadow_colum: Array[Node2D] = []
## 当前紫卡的预置植物，退出手持时恢复明暗效果。
var curr_all_preplant_purple: Array[Plant000Base] = []

## 从所属关卡读取柱子模式。
func init_hm_character() -> void:
	is_mode_column = hand_manager.game_para.is_mode_column

## 当前预览存在时更新为鼠标的全局位置。
func character_process() -> void:
	if is_instance_valid(characte_static):
		characte_static.global_position = temporary_character.get_global_mouse_position()

## 开始手持 [param card]，建立独立预览并读取本类型条件。
## 返回是否成功初始化；僵王、无效引用和缺少静态预览的卡片不进入手持。
func click_card(card: Card) -> bool:
	if not AllCards.is_battle_card(card.card_reference):
		return false
	if curr_card != null:
		_clear_curr_data()
	# 目录复制静态节点，卡片模板不参与战斗场景生命周期。
	var static_preview: Node2D = AllCards.create_static_preview(card.card_reference)
	if static_preview == null:
		return false
	if static_preview.get_child_count() == 0:
		static_preview.free()
		return false
	curr_card = card
	characte_static = static_preview
	characte_static.get_child(0).scale = Vector2.ONE
	characte_static_shadow = characte_static.get_child(0).duplicate() as Node2D
	characte_static_shadow.modulate.a = 0
	characte_static.z_index = 1
	temporary_character.add_child(characte_static)
	temporary_character.add_child(characte_static_shadow)
	match curr_card.card_reference.card_type:
		ResourceCardReference.CardType.Plant:
			plant_condition = Global.character_registry.get_plant_info(curr_card.card_reference.content_id, CharacterRegistry.PlantInfoAttribute.PlantConditionResource)
			if plant_condition.is_purple_card:
				start_preplant_purple_light(plant_condition, curr_card.card_reference.content_id)
		ResourceCardReference.CardType.Zombie:
			zombie_row_type = Global.character_registry.get_zombie_info(curr_card.card_reference.content_id, CharacterRegistry.ZombieInfoAttribute.ZombieRowType)
	if is_mode_column:
		click_card_column()
	EventBus.push_event("hm_character_hand_card", [curr_card])
	return true

## 让 [param curr_plant_condition] 为 [param plant_type] 找到的预置植物开始明暗提示。
func start_preplant_purple_light(curr_plant_condition: ResourcePlantCondition, plant_type: CharacterRegistry.PlantType) -> void:
	curr_all_preplant_purple = curr_plant_condition.get_all_preplant_purple(Global.main_game.plant_cell_manager.all_plant_cells, plant_type)
	# 本次紫卡可以升级的预置植物。
	for preplant_purple: Plant000Base in curr_all_preplant_purple:
		preplant_purple.preplant_purple_body_light_and_dark()

## 恢复仍然存在的紫卡预置植物明暗状态。
func end_preplant_purple_light() -> void:
	# 预置植物可能在手持期间死亡，需要先检查引用。
	for preplant_purple: Plant000Base in curr_all_preplant_purple:
		if is_instance_valid(preplant_purple):
			preplant_purple.preplant_purple_body_light_and_dark_end()
	curr_all_preplant_purple.clear()

## 释放本次预览、恢复紫卡提示并发出原有手持清除事件。
func _clear_curr_data() -> void:
	if plant_condition != null and plant_condition.is_purple_card:
		end_preplant_purple_light()
	is_shadow_in_cell = false
	if is_instance_valid(curr_card):
		EventBus.push_event("hm_character_clear_card", [curr_card])
	curr_card = null
	if is_instance_valid(characte_static):
		characte_static.queue_free()
	if is_instance_valid(characte_static_shadow):
		characte_static_shadow.queue_free()
	characte_static = null
	characte_static_shadow = null
	plant_condition = null
	zombie_row_type = CharacterRegistry.ZombieRowType.Land
	_clear_curr_data_column()

## 进入 [param plant_cell] 时更新虚影与放置条件，柱子模式同时检查其余行。
func mouse_enter(plant_cell: PlantCell) -> void:
	if curr_card == null:
		return
	is_shadow_in_cell = _update_cell_shadow(plant_cell, characte_static_shadow)
	if is_shadow_in_cell and is_mode_column:
		_mouse_enter_column(plant_cell)

## 更新 [param plant_cell] 上的 [param curr_characte_static_shadow] 并返回能否放置。
## 只支持植物与普通僵尸，其他类别隐藏虚影并返回 false。
func _update_cell_shadow(plant_cell: PlantCell, curr_characte_static_shadow: Node2D) -> bool:
	curr_characte_static_shadow.modulate.a = 0
	if not AllCards.is_battle_card(curr_card.card_reference):
		return false
	match curr_card.card_reference.card_type:
		ResourceCardReference.CardType.Plant:
			if plant_condition.judge_is_can_plant(plant_cell, curr_card.card_reference.content_id):
				curr_characte_static_shadow.global_position = plant_cell.get_new_plant_static_shadow_global_position(plant_condition.place_plant_in_cell)
				curr_characte_static_shadow.modulate.a = 0.5
				return true
		ResourceCardReference.CardType.Zombie:
			if not plant_cell.can_common_zombie and curr_card.card_reference.content_id != CharacterRegistry.ZombieType.Z021Bungi:
				return false
			if plant_cell.row_col.x >= Global.main_game.zombie_manager.all_zombie_rows.size():
				return false
			if zombie_row_type != CharacterRegistry.ZombieRowType.Both and zombie_row_type != Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_row_type:
				return false
			curr_characte_static_shadow.global_position = get_zombie_static_shadow_global_position(plant_cell)
			curr_characte_static_shadow.modulate.a = 0.5
			return true
	return false

## 返回普通僵尸在 [param plant_cell] 对应行的预览全局位置，包含屋顶坡面修正。
func get_zombie_static_shadow_global_position(plant_cell: PlantCell) -> Vector2:
	# 水平位置位于格子中点，垂直位置沿用僵尸行的生成标记。
	var global_pos: Vector2 = Vector2(
		plant_cell.global_position.x + plant_cell.size.x / 2,
		Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
	)
	if is_instance_valid(Global.main_game.main_game_slope):
		global_pos += Vector2(0, Global.main_game.main_game_slope.get_all_slope_y(global_pos.x))
	return global_pos

## 移出 [param _plant_cell] 时隐藏当前及柱子模式虚影。
func mouse_exit(_plant_cell: PlantCell) -> void:
	is_shadow_in_cell = false
	if is_instance_valid(characte_static_shadow):
		characte_static_shadow.modulate.a = 0
	if is_mode_column:
		_mouse_exit_column()

## 在 [param plant_cell] 成功创建后完成同列创建，仅发送一次卡片使用结算。
func click_cell(plant_cell: PlantCell) -> void:
	if not is_shadow_in_cell or not AllCards.is_battle_card(curr_card.card_reference):
		return
	if not _create_character_at_cell(plant_cell):
		return
	if is_mode_column:
		_click_cell_column(plant_cell)
	curr_card.signal_card_use_end.emit(curr_card)

## 在 [param plant_cell] 创建当前植物或普通僵尸并返回是否创建成功，不进行卡槽结算。
func _create_character_at_cell(plant_cell: PlantCell) -> bool:
	match curr_card.card_reference.card_type:
		ResourceCardReference.CardType.Plant:
			return plant_cell.create_plant(curr_card.card_reference.content_id, curr_card.card_reference.is_imitater) != null
		ResourceCardReference.CardType.Zombie:
			# 普通僵尸仍按行初始化，保留关卡模式与特殊僵尸回调。
			var zombie_init_para: Dictionary = {
				Zombie000Base.E_ZInitAttr.CharacterInitType: Character000Base.E_CharacterInitType.IsNorm,
				Zombie000Base.E_ZInitAttr.Lane: plant_cell.row_col.x,
			}
			return Global.main_game.zombie_manager.create_norm_zombie(
				curr_card.card_reference.content_id,
				Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x],
				zombie_init_para,
				Vector2(
					plant_cell.global_position.x + plant_cell.size.x / 2,
					Global.main_game.zombie_manager.all_zombie_rows[plant_cell.row_col.x].zombie_create_position.global_position.y
				),
				GlobalUtils.get_special_zombie_callable(curr_card.card_reference.content_id, plant_cell)
			) != null
	return false

## 退出手持角色状态并清理所有预览。
func exit_status() -> void:
	_clear_curr_data()

## 柱子模式为植物格子行或普通僵尸行生成额外预览，不支持僵王。
func click_card_column() -> void:
	# 本类型用于柱子模式的行数。
	var row_count: int = 0
	match curr_card.card_reference.card_type:
		ResourceCardReference.CardType.Plant:
			row_count = Global.main_game.plant_cell_manager.row_col.x
		ResourceCardReference.CardType.Zombie:
			row_count = Global.main_game.zombie_manager.all_zombie_rows.size()
	# 虚影数组索引与行号一致，当前行由主虚影展示。
	for lane: int in range(row_count):
		# 独立副本只用于该行的预览。
		var column_shadow: Node2D = characte_static_shadow.duplicate() as Node2D
		column_shadow.modulate.a = 0
		temporary_character.add_child(column_shadow)
		characte_static_shadow_colum.append(column_shadow)

## 检查 [param plant_cell] 同列的其余行，仅为可放置格子显示额外虚影。
func _mouse_enter_column(plant_cell: PlantCell) -> void:
	_mouse_exit_column()
	# 虚影行号与对应植物格子行保持一致。
	for lane: int in characte_static_shadow_colum.size():
		if lane == plant_cell.row_col.x or lane >= Global.main_game.plant_cell_manager.all_plant_cells.size():
			continue
		_update_cell_shadow(
			Global.main_game.plant_cell_manager.all_plant_cells[lane][plant_cell.row_col.y],
			characte_static_shadow_colum[lane]
		)

## 隐藏柱子模式所有额外虚影。
func _mouse_exit_column() -> void:
	# 额外预览可能因状态退出释放。
	for shadow: Node2D in characte_static_shadow_colum:
		if is_instance_valid(shadow):
			shadow.modulate.a = 0

## 在 [param plant_cell] 同列的其他可放置行创建角色，不重复发出成功结算信号。
func _click_cell_column(plant_cell: PlantCell) -> void:
	# 透明度记录本次额外行的放置判定。
	for lane: int in characte_static_shadow_colum.size():
		if characte_static_shadow_colum[lane].modulate.a != 0:
			_create_character_at_cell(Global.main_game.plant_cell_manager.all_plant_cells[lane][plant_cell.row_col.y])

## 释放本次手持产生的柱子模式预览，退出后清空引用列表。
func _clear_curr_data_column() -> void:
	# 额外虚影均由本手持状态拥有。
	for shadow: Node2D in characte_static_shadow_colum:
		if is_instance_valid(shadow):
			shadow.queue_free()
	characte_static_shadow_colum.clear()
