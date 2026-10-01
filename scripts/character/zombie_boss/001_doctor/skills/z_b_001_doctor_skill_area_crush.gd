## 砸车与脚踩共用的区域碾压：锁定格子，关键帧读取植物并安全处理各种植层。
extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillAreaCrush


## 本轮锁定的完整格子区域；只保存格子，落地时读取最新植物。
var target_cells: Array[PlantCell] = []
## 本轮零偏移基准之外的实际左上角，使用从 1 开始的行列。
var target_top_left: Vector2i


## 清理当前区域；已被碾压的植物不恢复，不影响其他技能实例。
func cancel_skill() -> void:
	super.cancel_skill()
	target_cells.clear()
	target_top_left = Vector2i.ZERO


## 在落地关键帧读取锁定格子，一次碾压所有种植层。
func _release_action() -> void:
	# 当前关卡用于确认目标仍属于本次战斗，防止离树后的延迟事件执行。
	var manager: PlantCellManager = _get_active_manager()
	if manager == null or target_cells.is_empty():
		return
	# 先收集所有目标植物，再执行可能同步释放其他植物的死亡逻辑。
	var plants: Array = []
	# 用实例 ID 去重，防止跨格植物或共享引用被同一次区域攻击重复处理。
	var seen_ids: Dictionary[int, bool] = {}
	# 格子也可能已经释放，先保留 Variant，检查后才转换类型。
	for cell_reference: Variant in target_cells:
		if not is_instance_valid(cell_reference):
			continue
		# 本次目标格子；只读取仍属于当前关卡的有效节点。
		var cell := cell_reference as PlantCell
		if cell == null or cell.is_queued_for_deletion() or not manager.main_game.is_ancestor_of(cell):
			continue
		# 字典中可能含有已释放引用，禁止在有效性检查前赋给植物类型变量。
		for plant_reference: Variant in cell.plant_in_cell.values():
			if not is_instance_valid(plant_reference):
				continue
			# 同一次区域攻击中的植物唯一标识。
			var instance_id: int = plant_reference.get_instance_id()
			if not seen_ids.has(instance_id):
				seen_ids[instance_id] = true
				plants.append(plant_reference)
	# 死亡回调可能释放后续目标，执行前必须再次验证 Variant 引用。
	for plant_reference: Variant in plants:
		if _get_active_manager() != manager:
			return
		if not is_instance_valid(plant_reference):
			continue
		# 有效引用才转换为植物；已死亡、待释放或展示实例不重复碾压。
		var plant := plant_reference as Plant000Base
		if plant != null and plant.is_inside_tree() and not plant.is_queued_for_deletion() \
			and not plant.is_death and plant.character_init_type == Character000Base.E_CharacterInitType.IsNorm:
			plant.be_flattened()


## 仅返回本博士所属的有效战斗管理器；展示、死亡、退出及战斗结束后取消技能效果。
func _get_active_manager() -> PlantCellManager:
	# 公共入口先检查博士与关卡的生命周期，本技能只确认自己的管理器。
	var game: MainGameManager = _get_active_game()
	if game == null:
		return null
	# 管理器正在释放或已离树时不再读取场地及生成对象。
	var manager: PlantCellManager = game.plant_cell_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null
