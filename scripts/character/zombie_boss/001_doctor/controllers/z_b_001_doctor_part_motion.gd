## 单个机甲部件的局部位置平移；只在 Tween 活动期间同步速度，不移动受击框或其他跟随节点。
extends Node
class_name ZB001DoctorPartMotion

## 由本控制器独占写入 position 的部件父节点；动作动画仍控制其下的精灵姿势。
@export var target_node: Node2D
## 首次初始化保存的待机位置，独立于场地资源中的目标行位置。
var _rest_position: Vector2
## 保存待机位置时的节点实例 ID；同一实例重复初始化不重新采集中途位置。
var _target_id: int = 0
## 提供角色动画倍率的机甲播放器；全局时间倍率由 Tween 自行处理一次。
var _animation_player: AnimationPlayer
## 当前唯一的平移 Tween；重新定位、复位、取消或离树时先终止旧 Tween。
var _tween: Tween


## 默认没有逐帧任务；只有正在平移或等待零速恢复时启用物理更新。
func _ready() -> void:
	set_physics_process(false)


## [param player] 为机甲播放器；配置校验通过后绑定，重复初始化保留同一部件的待机位置。
func initialize_motion(player: AnimationPlayer) -> void:
	cancel_motion()
	_animation_player = player
	if _target_id != target_node.get_instance_id():
		_target_id = target_node.get_instance_id()
		_rest_position = target_node.position


## [param position] 为本轮绝对局部位置；[param configuration] 为只读的定位时长和曲线。
## 从当前实际位置开始，不先跳到待机位置；零时长或相同位置直接完成。
func move_to(position: Vector2, configuration: ZB001DoctorPartMotionConfig) -> void:
	if configuration == null:
		return
	_start_motion(position, configuration.move_duration, configuration)


## [param configuration] 指定复位时长和曲线；由动画关键帧启动，不等待 Tween 再切状态。
func return_to_rest(configuration: ZB001DoctorPartMotionConfig) -> void:
	if configuration == null:
		return
	_start_motion(_rest_position, configuration.return_duration, configuration)


## [param position] 为目标局部位置；[param duration] 为动作秒；[param configuration] 为曲线设置。
## 仅由 [method move_to] 或 [method return_to_rest] 调用，配置非空已由这两个公开入口检查。
## Tween 绑定本节点并继承暂停；角色零速仅冻结推进，恢复速度后继续剩余路程。
func _start_motion(position: Vector2, duration: float, configuration: ZB001DoctorPartMotionConfig) -> void:
	cancel_motion()
	if not _has_target():
		return
	if duration <= 0.0 or target_node.position.is_equal_approx(position):
		target_node.position = position
		return
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_tween.set_trans(configuration.transition_type).set_ease(configuration.ease_type)
	_tween.set_speed_scale(_get_motion_speed())
	_tween.tween_property(target_node, ^"position", position, duration)
	_tween.finished.connect(_on_motion_finished)
	set_physics_process(true)


## [param _delta] 为物理步长；Tween 自行消耗时间，此处仅同步角色倍率，避免重复乘全局倍率。
func _physics_process(_delta: float) -> void:
	if not _has_target() or not is_instance_valid(_animation_player) or _tween == null or not _tween.is_valid():
		cancel_motion()
		return
	_tween.set_speed_scale(_get_motion_speed())


## 使用角色 speed_scale 而非 get_playing_speed，防止动画刚结束就把尚未收尾的平移永久冻结。
func _get_motion_speed() -> float:
	# 角色零速冻结 Tween；非有限或负倍率不应导致反向播放或非法插值。
	var speed: float = _animation_player.speed_scale if is_instance_valid(_animation_player) else 0.0
	return maxf(speed, 0.0) if is_finite(speed) else 0.0


## 单次平移自然完成后关闭逐帧同步；下一次动作会创建新的 Tween。
func _on_motion_finished() -> void:
	_tween = null
	set_physics_process(false)


## 仅终止平移并保留当前局部位置；死亡状态先取得快照，再接管后续视觉复位。
func cancel_motion() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	set_physics_process(false)


## 动作结束时确保待机端点并清除旧 Tween；正常复位早已完成，低帧率跨过末尾时补齐端点。
func finish_at_rest() -> void:
	finish_at_position(_rest_position)


## [param position] 为已经应当到达的动作端点；关闭旧 Tween，仅端点尚未到达时补齐位置。
## 释放关键帧与定位事件在同帧延迟到达时，保证先定位再读取标记；正常帧率下定位早已完成。
func finish_at_position(position: Vector2) -> void:
	cancel_motion()
	if _has_target() and target_node.position != position:
		target_node.position = position


## 返回死亡中断快照，仅记录本控制器移动的部件，不包含根节点受击框。
func capture_visual_returns() -> Array[ZB001DoctorVisualReturn]:
	# 返回类型明确的容器，避免 Array 与类型化 Array 之间的赋值错误。
	var snapshots: Array[ZB001DoctorVisualReturn] = []
	if _has_target():
		snapshots.append(ZB001DoctorVisualReturn.new(target_node, _rest_position))
	return snapshots


## 当前引用必须仍是初始化过的原部件；运行时换绑必须重新初始化后才能写入。
func _has_target() -> bool:
	return is_instance_valid(target_node) and not target_node.is_queued_for_deletion() \
		and _target_id == target_node.get_instance_id()


## [param doctor] 为所属博士；空字符串表示有效，目标和控制器必须都属于此实例。
func get_configuration_error(doctor: Node) -> String:
	if not is_instance_valid(doctor) or not doctor.is_ancestor_of(self) \
		or not is_instance_valid(target_node) or not doctor.is_ancestor_of(target_node) \
		or not target_node.get_parent() is Node2D or not target_node.position.is_finite():
		push_error("%s：必须绑定博士自身的有效部件父节点，且局部位置有限。" % get_path())
		return "部件平移目标无效。"
	if process_mode != Node.PROCESS_MODE_INHERIT:
		push_error("%s：部件平移控制器必须继承场景暂停模式。" % get_path())
		return "部件平移暂停模式无效。"
	return ""


## 退出场景立即撤销 Tween，禁止旧平移继续写入待卸载部件。
func _exit_tree() -> void:
	cancel_motion()
