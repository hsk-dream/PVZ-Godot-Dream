## 博士技能效果入口：集中检查战斗归属与角色生命周期，具体效果由各技能实现。
extends Node
class_name ZB001DoctorSkillBase

## 蹦极、砸车直接定位的部件父节点；平滑定位技能只绑定 part_motion，不同时绑定此引用。
@export var position_node: Node2D
## 本技能默认的平移控制器；脚踩默认绑定外侧腿，具体动作可由解析入口选用其他控制器。
@export var part_motion: ZB001DoctorPartMotion
## 准备阶段锁定的本动作控制器；定位、复位和死亡快照始终使用同一实例，取消后清空。
var _active_part_motion: ZB001DoctorPartMotion
## 部件在首次初始化时的待机位置；与资源中第一列、第一格或目标行的技能位置无关。
var _rest_visual_position: Vector2
## 已保存的部件实例 ID；重初始化同一实例不把技能中途的位置误记为待机位置。
var _visual_node_id: int = 0
## 博士根节点持有的场地资源；组件只读共享，不另存一份导出配置。
var scene_config: ZB001DoctorSceneConfig:
	get:
		# 场景 owner 固定指向所属博士，展示实例可以没有活动关卡。
		var doctor: ZB001Doctor = owner as ZB001Doctor
		return doctor.skill_scene_config if is_instance_valid(doctor) else null

## 当前完整技能是否仍有效；结束与取消都会关闭释放入口。
var _skill_active: bool = false
## 当前动作是否已准备完成，防止关键帧先于准备或取消后释放。
var _action_ready: bool = false
## 当前动作是否已释放；重复关键帧不能重复产生效果。
var _action_released: bool = false
## 准备阶段锁定的绝对局部位置；平移开始前不写入实际部件。
var _action_part_position: Vector2
## 当前动作是否已处理定位事件；每次准备重置，重复关键帧不能重启 Tween。
var _position_move_started: bool = false
## 当前动作是否已处理复位事件；一旦复位，迟到的定位事件不能再次把部件移出去。
var _position_return_started: bool = false


## 全部配置校验通过后调用一次；子类可在此修正运行时参数，不在只读校验中修改配置。
func initialize_skill() -> void:
	if is_instance_valid(part_motion):
		part_motion.initialize_motion((owner as ZB001Doctor).state_machine.animation_player)
		return
	if is_instance_valid(position_node) and _visual_node_id != position_node.get_instance_id():
		_visual_node_id = position_node.get_instance_id()
		_rest_visual_position = position_node.position


## [param part_position] 资源定义的绝对局部位置；每次重新赋值，避免连续技能累计偏移。
func apply_visual_position(part_position: Vector2) -> void:
	position_node.position = part_position


## 正常收尾、间隔待机和死亡取消统一恢复首次保存的待机位置；未初始化时不改变场景姿势。
func reset_visual_offset() -> void:
	# 优先复位本动作实际移动的部件；尚未准备动作时使用默认控制器。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if is_instance_valid(motion):
		motion.finish_at_rest()
		return
	if is_instance_valid(position_node) and _visual_node_id == position_node.get_instance_id():
		position_node.position = _rest_visual_position


## 只读查询技能是否可被选择；默认允许，目标要求由具体技能覆盖。
func can_start() -> bool:
	return true


## 开始完整技能并清理上次运行数据；返回是否成功，具体选点仍在动作准备阶段进行。
func begin_skill() -> bool:
	cancel_skill()
	_skill_active = true
	return true


## 准备当前动作并返回动画名；空名称表示没有可执行动作，由状态正常收尾。
func prepare_action() -> StringName:
	return &""


## [param animation_name] 准备结果的动画名；记录本动作释放门闩并返回原名称。
func _arm_action(animation_name: StringName) -> StringName:
	_action_ready = _skill_active and not animation_name.is_empty()
	_action_released = false
	_position_move_started = false
	_position_return_started = false
	_active_part_motion = null
	return animation_name if _action_ready else &""


## [param animation_name] 为选定动画；[param part_position] 为场地配置中的绝对局部位置。
## 只保存本动作数据，实际定位等待攻击动画 0 秒处的方法轨道。
func _arm_position_action(animation_name: StringName, part_position: Vector2) -> StringName:
	_action_part_position = part_position
	# 先重置动作门闩，再缓存解析结果，防止初始化门闩清掉刚选中的腿部控制器。
	var armed_animation: StringName = _arm_action(animation_name)
	if not armed_animation.is_empty():
		_active_part_motion = get_part_motion_for_animation(armed_animation)
		if not is_instance_valid(_active_part_motion):
			_action_ready = false
			return &""
	return armed_animation


## [param _animation_name] 为待播放或校验的动画；默认所有动作使用同一控制器，脚踩覆盖选腿规则。
## 只读解析，不改变当前动作缓存；校验未播放的动画时也能取得正确的目标节点。
func get_part_motion_for_animation(_animation_name: StringName) -> ZB001DoctorPartMotion:
	return part_motion


## 返回本动作锁定的控制器；尚未准备或已取消时使用默认引用，不重新按动画抽取或换绑节点。
func _get_active_part_motion() -> ZB001DoctorPartMotion:
	return _active_part_motion if is_instance_valid(_active_part_motion) else part_motion


## [param event_name] 为动画事件；平移控制器只接受当前有效动作的一次定位、一次复位。
func handle_position_event(event_name: StringName) -> void:
	# 当前动作的平移对象，避免内侧腿的定位和外侧腿的复位混用。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if not _skill_active or not _action_ready or not is_instance_valid(motion):
		return
	if event_name == ZB001DoctorAnimationEvents.POSITION_MOVE and not _position_move_started and not _position_return_started:
		_position_move_started = true
		motion.move_to(_action_part_position, get_part_motion_config())
	elif event_name == ZB001DoctorAnimationEvents.POSITION_RETURN and not _position_return_started:
		_position_return_started = true
		motion.return_to_rest(get_part_motion_config())


## 动作状态退出前清除旧 Tween 并保证复位端点；不再启动第二次复位，不增加等待状态。
func complete_position_action() -> void:
	# 动作退出时只补齐本次选中部件的待机端点。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if is_instance_valid(motion):
		motion.finish_at_rest()


## 死亡快照取得后立即冻结部件当前姿态；主状态正式退出时再执行清理，避免等待一帧期间继续平移。
func interrupt_position_motion() -> void:
	# 快照记录哪个部件，就立即停止哪个部件的 Tween。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if is_instance_valid(motion):
		motion.cancel_motion()


## 返回当前场地中本技能的平移参数；直接定位的蹦极和砸车不使用此资源。
func get_part_motion_config() -> ZB001DoctorPartMotionConfig:
	return null


## 仅允许有效技能的已准备动作释放一次；先关闭门闩，再执行可能同步触发死亡的效果。
func release_action() -> void:
	if not _skill_active or not _action_ready or _action_released:
		return
	_action_released = true
	# 释放前的端点补齐必须应用到本动作的控制器，不能固定写入默认外侧腿。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if is_instance_valid(motion) and not _position_return_started:
		# 定位时长已校验短于释放时间；低帧率同帧跨过两帧时，Tween 尚未执行，先补齐目标端点。
		# 标记已开始使迟到的 0 秒事件不会再重启定位；脚踩落地之后的复位事件仍能正常执行。
		_position_move_started = true
		motion.finish_at_position(_action_part_position)
	_release_action()


## 具体技能消费自身持有的本轮数据，不接收无类型参数字典。
func _release_action() -> void:
	pass


## 正常收尾使用统一清理，保留明确的语义入口，后续正常完成奖励可在子类扩展。
func end_skill() -> void:
	cancel_skill()


## 幂等取消当前技能；子类清理目标和连接，不删除已经独立生成的实体。
func cancel_skill() -> void:
	_skill_active = false
	_action_ready = false
	_action_released = false
	_position_move_started = false
	_position_return_started = false
	reset_visual_offset()
	# 先恢复实际移动部件，再清空缓存；反过来会错误复位默认部件。
	_active_part_motion = null


## 返回该技能的动作动画集合，供状态层校验释放事件，不暴露运行时目标。
func get_action_animations() -> Array[StringName]:
	# 基类没有动作，但空结果仍须携带 StringName 元素类型。
	var animations: Array[StringName] = []
	return animations


## 返回死亡时需要恢复的部件位置；死亡状态决定直接过渡还是先保持定位完成抬头。
func capture_visual_returns() -> Array[ZB001DoctorVisualReturn]:
	# 只记录本动作实际使用的部件，让死亡流程沿用相同的定位与待机端点。
	var motion: ZB001DoctorPartMotion = _get_active_part_motion()
	if is_instance_valid(motion):
		return motion.capture_visual_returns()
	# 各技能返回类型一致的实例快照，静态资源不保存运行时部件引用。
	var snapshots: Array[ZB001DoctorVisualReturn] = []
	if is_instance_valid(position_node) and _visual_node_id == position_node.get_instance_id():
		snapshots.append(ZB001DoctorVisualReturn.new(position_node, _rest_visual_position))
	return snapshots


## 返回所属博士正在参与的关卡；展示、死亡、离树、退出及战斗结束时返回 null。
## 子类仍需检查自己使用的管理器或挂载节点，避免把某个技能的依赖强加给全部技能。
func _get_active_game() -> MainGameManager:
	# 场景 owner 指向博士根节点，不依赖 Skills 的固定层级。
	var doctor: ZB001Doctor = owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or doctor.is_queued_for_deletion() \
		or not doctor.is_inside_tree() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	# 全局关卡必须仍持有当前博士，避免切换场景后旧实例向新关卡释放技能。
	var game: MainGameManager = Global.main_game
	if not is_instance_valid(game) or game.is_queued_for_deletion() or not game.is_ancestor_of(doctor) \
		or game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
		return null
	return game


## 实时返回本博士所在战斗的有效植物格管理器；关卡无效、管理器离树或待删除时返回 null。
## 不缓存查询结果；区域攻击和蹦极在回调之后仍须再次查询，防止旧关卡继续产生效果。
func _get_active_plant_cell_manager() -> PlantCellManager:
	# 先沿用博士与所属关卡的资格检查，不给不使用格子的技能增加初始化依赖。
	var game: MainGameManager = _get_active_game()
	if game == null:
		return null
	# 本次调用的植物格管理器；正在释放或已离树时不再读取场地或执行攻击。
	var manager: PlantCellManager = game.plant_cell_manager
	return manager if is_instance_valid(manager) and manager.is_inside_tree() and not manager.is_queued_for_deletion() else null


## 只读检查具体技能的静态配置，空字符串表示有效；具体分支自行报告错误。
func get_configuration_error() -> String:
	if scene_config == null:
		push_error("%s：博士缺少场景技能配置资源。" % get_path())
		return "场景技能配置为空。"
	# 三个平移技能由场地参数决定定位策略，禁止回退到准备阶段的直接定位。
	var motion_config: ZB001DoctorPartMotionConfig = get_part_motion_config()
	if is_instance_valid(part_motion) or motion_config != null:
		if not is_instance_valid(part_motion) or motion_config == null or is_instance_valid(position_node):
			push_error("%s：平移技能必须绑定独立 PartMotion 和场地平移资源，不能再绑定 position_node。" % get_path())
			return "技能平移配置缺失或重复。"
		# 节点依赖与静态参数分别在各自检测分支报告，不重复输出错误。
		var motion_error: String = part_motion.get_configuration_error(owner)
		return motion_error if not motion_error.is_empty() else motion_config.get_configuration_error(str(get_path()))
	if not is_instance_valid(position_node) or not is_instance_valid(owner) \
		or not owner.is_ancestor_of(position_node) or not position_node.get_parent() is Node2D:
		push_error("%s：必须绑定博士自身的技能定位节点，且父节点为 Node2D。" % get_path())
		return "技能定位节点无效。"
	return ""
