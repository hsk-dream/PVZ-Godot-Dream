## 脚踩触发要求有植物；准备时目标全部消失则随机踩空，关键帧仍按锁定区域处理碾压。
extends ZB001DoctorSkillAreaCrush
class_name ZB001DoctorSkillStomp

## 本技能私有的同步准备候选；绑定只读静态动作与完整区域，实际攻击目标由技能另行锁定。
class StompCandidate extends RefCounted:
	## 对应的只读动作资源，提供动画、部件位置和攻击范围。
	var action: ZB001DoctorAreaAction
	## 本次查询得到的完整区域副本；只在同步准备期间使用，不延长格子节点寿命。
	var cells: Array[PlantCell] = []

	## [param configuration] 为只读动作资源；[param region_cells] 为已通过完整性检查的格子区域。
	## 复制格子容器以隔离后续数组修改；不修改共享动作资源。
	func _init(configuration: ZB001DoctorAreaAction, region_cells: Array[PlantCell]) -> void:
		action = configuration
		cells.assign(region_cells)


## 脚踩动画 1、2 的内侧腿控制器；动画 3、4 使用基类 part_motion 绑定的外侧腿控制器。
@export var inner_leg_motion: ZB001DoctorPartMotion


## 分别保存两条腿的待机位置；控制器目标固定，不在切换脚踩动画时重新绑定或采集位置。
func initialize_skill() -> void:
	super.initialize_skill()
	inner_leg_motion.initialize_motion((owner as ZB001Doctor).state_machine.animation_player)


## [param animation_name] 为准备或校验的动作名；动画 1、2 移动内侧腿，其余动作使用外侧腿。
## 只返回引用，实际开始平移仍等待 0 秒关键帧，校验调用不会改变当前动作。
func get_part_motion_for_animation(animation_name: StringName) -> ZB001DoctorPartMotion:
	if animation_name == &"Zombie_boss_stomp_1" or animation_name == &"Zombie_boss_stomp_2":
		return inner_leg_motion
	return super.get_part_motion_for_animation(animation_name)


## 只查询有无目标，不抽取随机数、不锁定参数，供主状态机过滤脚踩技能。
func can_start() -> bool:
	return not _get_candidates().is_empty()


## 优先选择有植物的完整区域；目标全部消失时从所有完整区域中随机选择，允许踩空。
## 初始化校验通过后调用；战斗结束或没有完整区域时返回空动画名，由准备状态收尾。
func prepare_action() -> StringName:
	_arm_action(&"")
	target_cells.clear()
	# 选择技能与进入准备状态之间植物可能已被移除，不能复用之前的可用性结果。
	var candidates: Array[StompCandidate] = _get_candidates()
	if candidates.is_empty():
		# 技能已经选中，目标消失不取消动作；仍保留区域越界与关卡生命周期检查。
		candidates = _get_candidates(false)
	if candidates.is_empty():
		return &""
	# 项目统一随机选择器；区域内植物数量不影响区域被抽中的概率。
	var picker := RandomPicker.new()
	# 按原候选顺序等权加入，只在全部加入后构建一次选择表，不执行去重。
	for candidate: StompCandidate in candidates:
		picker.add_item(candidate, 1.0, false, false)
	picker.rebuild_alias_table()
	# 只在选择器返回边界转换类型；状态仍只接收动画名，不接收候选对象。
	var selected: StompCandidate = picker.get_random_item() as StompCandidate
	target_cells.assign(selected.cells)
	# 动作配置只读；运行时区域由实例保存。
	var action: ZB001DoctorAreaAction = selected.action
	# 动画同时决定内侧腿或外侧腿；基类缓存本次控制器，准备期间不写入任何腿部位置。
	return _arm_position_action(action.animation_name, action.part_position)


## 当前场地的腿部平移参数；攻击区域已经锁定，平移期间不重新选择格子。
func get_part_motion_config() -> ZB001DoctorPartMotionConfig:
	return scene_config.stomp_part_motion if scene_config != null else null


## 可用性查询和动作准备共用区域检查，仅收集候选，不产生随机选择或攻击副作用。
## 固定配置与腿部绑定已由状态机初始化校验；运行时只重新查询战斗和目标区域。
## [param require_plant] 默认要求区域内有有效植物；仅准备阶段的踩空回退传入 false。
func _get_candidates(require_plant: bool = true) -> Array[StompCandidate]:
	# 无法准备攻击时返回元素类型明确的空候选池。
	var empty_candidates: Array[StompCandidate] = []
	# 当前有效战斗的格子管理器，展示、死亡或退出后的实例不准备攻击。
	var manager: PlantCellManager = _get_active_plant_cell_manager()
	if manager == null:
		return empty_candidates
	# 只在副本内调整列顺序，避免场景的倒序节点编号改变技能的视觉列号。
	var grid: Array[Array] = ZB001DoctorCellQuery.get_visual_grid(manager)
	# 每个候选同时绑定动画和范围，不先选动画再裁剪越界区域。
	var candidates: Array[StompCandidate] = []
	# 每个动作资源同时决定完整矩形与播放动画，过滤时不会失去两者的对应关系。
	for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
		# 当前完整区域；只在技能已经选中后的回退中允许无植物。
		var cells: Array[PlantCell] = ZB001DoctorCellQuery.get_region(grid, action.top_left, action.size)
		if not cells.is_empty() and (not require_plant or _has_living_plant(cells)):
			candidates.append(StompCandidate.new(action, cells))
	return candidates


## [param cells] 待检查的完整攻击区域；任意种植层有正常出战的存活植物即返回 true。
func _has_living_plant(cells: Array[PlantCell]) -> bool:
	# 查询期间不触发死亡回调；格子仍检查生命周期，避免使用待卸载区域。
	for cell: PlantCell in cells:
		if not is_instance_valid(cell) or cell.is_queued_for_deletion() or not cell.is_inside_tree():
			continue
		# 字典可能残留已释放的植物引用，公共谓词先验证 Variant，并与攻击阶段保持相同资格。
		for plant_reference: Variant in cell.plant_in_cell.values():
			if ZB001DoctorCellQuery.is_living_normal_plant(plant_reference):
				return true
	return false


## 状态机初始化时检查固定绑定与场地参数；具体地图上区域越界时由准备阶段过滤。
func get_configuration_error() -> String:
	# 共享场地配置和技能定位节点先校验，再检查每项脚踩区域。
	var placement_error: String = super.get_configuration_error()
	if not placement_error.is_empty():
		return placement_error
	if not is_instance_valid(inner_leg_motion) or inner_leg_motion == part_motion:
		push_error("%s：脚踩动画 1、2 必须绑定独立的内侧腿平移控制器。" % get_path())
		return "内侧腿平移控制器缺失或重复。"
	# 内侧腿节点的归属与位置有效性由控制器自身报告，外侧腿已经由基类校验。
	var inner_leg_error: String = inner_leg_motion.get_configuration_error(owner)
	if not inner_leg_error.is_empty():
		return inner_leg_error
	if inner_leg_motion.target_node == part_motion.target_node:
		push_error("%s：内侧腿与外侧腿平移控制器必须绑定不同的部件节点。" % get_path())
		return "脚踩腿部平移目标重复。"
	if scene_config.stomp_actions.is_empty():
		push_error("StompSkill：必须配置至少一个区域动作。")
		return "脚踩动作配置为空。"
	# 每项必须完整，不允许缺少资源或非正行列；地图越界由准备阶段排除。
	for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
		if action == null or action.animation_name.is_empty() or not action.part_position.is_finite() \
			or action.top_left.x < 1 or action.top_left.y < 1 or action.size.x < 1 or action.size.y < 1:
			push_error("StompSkill：每项动作必须具有有效动画、有限位置、从 1 开始的左上角和正数范围。")
			return "脚踩动作区域无效。"
	return ""


## 从动作配置返回动画列表，供状态检查释放帧。
func get_action_animations() -> Array[StringName]:
	# 只读副本，配置中缺失项交给组件校验报告。
	var animations: Array[StringName] = []
	# 每项动作的动画名称与范围来自同一资源。
	if scene_config != null:
		# 相同行为动画可以用于多个起始行，释放事件仅按唯一动画校验。
		for action: ZB001DoctorAreaAction in scene_config.stomp_actions:
			if action != null and not animations.has(action.animation_name):
				animations.append(action.animation_name)
	return animations
