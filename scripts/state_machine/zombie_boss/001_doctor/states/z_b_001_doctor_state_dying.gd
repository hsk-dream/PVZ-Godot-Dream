## 低头死亡先抬头，随后播放机甲死亡；由方法关键帧启动本体死亡、举旗，举旗完成即进入循环保留阶段。
## 同时管理死亡局部爆炸；正常进入 Dead 后继续由计时器驱动，直到机甲死亡动画结束。
extends ZB001DoctorState
class_name ZB001DoctorStateDying

@export_group("死亡爆炸")
## 单次爆炸场景，负责播放自身动画和释放；次数为 0 时允许不配置此场景。
@export var explosion_scene: PackedScene
## 手动绑定当前博士机甲部件下的爆炸位置；初始隐藏的位置也可绑定，每次触发重新筛选可见性。
@export var explosion_points: Array[Marker2D] = []
## 存放单次特效的无脚本 Node2D，必须直属博士根节点，以继承角色整体淡出。
@export var explosion_root: Node2D
## 一次死亡演出最多生成的爆炸次数；0 关闭，机甲动画结束后不再补足次数。
@export_range(0, 64, 1) var explosion_count: int = 30
## 相邻爆炸的随机间隔下限、上限，单位为动作秒，随博士死亡动画倍率变化。
@export var explosion_interval_range: Vector2 = Vector2(0.18, 0.35)
## 单次特效整体缩放的下限、上限，不继承作为定位参考的机甲部件缩放。
@export var explosion_scale_range: Vector2 = Vector2(0.65, 1.1)
@export_group("")

## 独立生成间隔计时器；正常进入 Dead 后仍运行，不依赖状态机的逐帧更新。
@onready var explosion_interval_timer: SpeedTimer = $DeathExplosionIntervalTimer

## 死亡请求时是否处于低头、低头待机、吐球或抬头阶段；在旧技能停止前记录，进入时消费。
var _needs_head_return := false
## 当前是否正在执行死亡前的抬头过渡；只接受相应动画的结束通知。
var _returning_head := false
## 本体死亡序列是否已由机甲关键帧启动，防止重复事件重播动作。
var _driver_death_started := false
## 本体死亡和举旗是否已经完成，防止重复的结束通知再次提交 Dead 状态。
var _driver_finished := false
## 技能取消前取得的视觉复位数据，进入死亡后交给动画控制器。
var _visual_returns: Array[ZB001DoctorVisualReturn] = []

## 初始化时收集的全部位置实例 ID，不按初始可见性裁剪；每次爆炸重新筛选可见候选。
var _explosion_point_ids: Array[int] = []
## 爆炸配置是否有效；检查失败只关闭这项表现，不阻塞博士死亡和奖杯流程。
var _explosion_configuration_valid: bool = false
## 当前独立动画倍率；计时器和已生成特效共同使用，不重复乘全局 Engine.time_scale。
var _explosion_speed_scale: float = 1.0
## 本轮机甲死亡是否已经启动过爆炸，防止重复动画请求重置次数。
var _explosions_started: bool = false
## 是否仍允许生成新爆炸；进入 Dead 不清除此标记，机甲动画结束时清除。
var _is_generating_explosions: bool = false
## 尚未生成的次数；暂时没有可见位置时保留，等待下一个间隔重新检查。
var _remaining_explosions: int = 0
## 已生成特效的实例 ID 与引用；结束通知只绑定 ID，避免回调携带已释放节点。
var _active_explosions: Dictionary[int, ZB001DoctorDeathExplosionEffect] = {}


## 注入死亡状态依赖并提前检查爆炸配置；失败只取消表现，保留原有死亡流程。[br]
## [param actor] 当前博士实例；[param machine] 管理本状态的主状态机。
func setup(actor: Character000Base, machine: CharacterStateMachine) -> void:
	super.setup(actor, machine)
	stop_death_explosions()
	_explosions_started = false
	_explosion_point_ids.clear()
	# 导出数组决定候选范围；隐藏标记也登记，之后显示时仍有机会被选中。
	# 以 Variant 读取配置项，先过滤空值及已释放引用，避免强类型赋值报错。
	for point: Variant in explosion_points:
		if not is_instance_valid(point) or point.is_queued_for_deletion():
			continue
		# 按实例 ID 去重，重复绑定同一位置不会意外提高其随机权重。
		var point_id: int = point.get_instance_id()
		if not _explosion_point_ids.has(point_id):
			_explosion_point_ids.append(point_id)
	_explosion_configuration_valid = _validate_explosion_configuration()


## [param previous_state] 为尚未清理的旧主状态；只读取技能统一接口，不识别具体技能类型。
func prepare_interruption(previous_state: CharacterState) -> void:
	_needs_head_return = false
	_visual_returns.clear()
	if previous_state is ZB001DoctorSkillState:
		# 通用技能状态提供头部要求，组件提供其代码控制的部件复位信息。
		var skill: ZB001DoctorSkillState = previous_state as ZB001DoctorSkillState
		_needs_head_return = skill.needs_head_return()
		_visual_returns = skill.effect_component.capture_visual_returns()
		# 死亡请求与主层切换可能相隔一帧；先留存实际位置，再取消 Tween，期间不跳回待机位置。
		skill.effect_component.interrupt_position_motion()


## 致死伤害的调用尾部可能重新生成控制效果，切换状态时再次整理。
func enter() -> void:
	boss.is_idle = false
	boss.prepare_death_animation()
	_driver_death_started = false
	_driver_finished = false
	# 低头中死亡时，保留该行的部件定位直到抬头结束；其他技能立即开始平滑复位。
	if _needs_head_return:
		_restore_head_visual_positions(true)
	else:
		doctor_state_machine.animation_controller.begin_visual_returns(_visual_returns)
		_visual_returns.clear()
	# 本体死亡启动关键帧到达前保持待机，不延续被死亡中断的操纵或吐球动作。
	doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_IDLE_ANIMATION)
	_returning_head = _needs_head_return
	_needs_head_return = false
	if _returning_head:
		# 若已经开始抬头，则从当前动画秒数继续，避免再次回到低头姿态。
		var resume_position := 0.0
		if state_machine.animation_player.assigned_animation == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
			resume_position = state_machine.animation_player.current_animation_position
		# 抬头可能在死亡请求与状态切换之间结束；此时直接进入死亡动画，不能等待已错过的通知。
		if resume_position < state_machine.animation_player.get_animation(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION).length:
			if state_machine.animation_player.assigned_animation == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
				# 原抬头动作继续播放，不重新捕获、不重播零秒音效，也不跳过已有关键帧。
				state_machine.animation_player.play(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION)
			else:
				doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION, ZB001DoctorAnimationController.DriverReaction.KEEP, doctor_state_machine.animation_controller.death_transition_duration)
			return
	_start_death_animation()


## 抬头完成后启动机甲死亡和局部爆炸；本体仍等待轨道中配置的死亡启动关键帧。
func _start_death_animation() -> void:
	# 抬头期间保持的场地偏移现在才恢复，防止新场地配置让头部在抬头中途跳位。
	if _returning_head:
		_restore_head_visual_positions(false)
		_visual_returns.clear()
	# 完整抬头后的姿势已经对齐；其余动作中途死亡从当前姿势过渡。
	var transition_duration: float = 0.0 if _returning_head else doctor_state_machine.animation_controller.death_transition_duration
	_returning_head = false
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.DEATH_ANIMATION, ZB001DoctorAnimationController.DriverReaction.KEEP, transition_duration)
	# 先应用死亡动画首帧的显隐和姿势，第一次爆炸也从当前真正可见的部件位置选择。
	state_machine.animation_player.advance(0.0)
	_start_death_explosions()


## [param use_start_position] 为 true 时恢复取消前姿态，为 false 时应用待机位置。[br]
## 同步切换期间取消技能已复位节点，用快照重建抬头定位；失效节点直接跳过。
func _restore_head_visual_positions(use_start_position: bool) -> void:
	# 只恢复技能实际移动的头部父节点；受击框保持场景原位，不查询或修改技能资源。
	for snapshot: ZB001DoctorVisualReturn in _visual_returns:
		# 从实例 ID 重新取得有效对象，节点已释放时不会对强类型变量赋无效引用。
		var node: Node2D = instance_from_id(snapshot.node_id) as Node2D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.position = snapshot.start_position if use_start_position else snapshot.target_position


## 结束剩余视觉复位；正常转入 Dead 时爆炸继续，其余提前退出停止后续生成。
func exit() -> void:
	doctor_state_machine.animation_controller.finish_visual_returns()
	_restore_head_visual_positions(false)
	_visual_returns.clear()
	if not _driver_finished:
		stop_death_explosions()


## 接收机甲轨道中的本体死亡事件；使用动画时间触发，使死亡加速后仍与机甲姿态对齐。[br]
## [param event_name] 方法轨道的事件名；仅接受本阶段的本体死亡启动事件，重复或迟到事件忽略。
func on_animation_event(event_name: StringName) -> void:
	if event_name != ZB001DoctorAnimationEvents.DRIVER_DEATH or _returning_head or _driver_death_started \
		or state_machine.animation_player.assigned_animation != ZB001DoctorAnimations.DEATH_ANIMATION:
		return
	_driver_death_started = true
	# 在关键帧当下同步倍率，后续动作由本体结束信号推进。
	doctor_state_machine.animation_controller.sync_driver_speed()
	doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_DEATH_ANIMATION)


## 本体单次动作依次播放死亡、举旗；举旗完成即交给 Dead 播放循环并计时，不等待机甲结束。[br]
## [param anim_name] 本体已结束的动画名；死亡序列尚未启动时不接收普通动作的结束事件。
func on_driver_animation_finished(anim_name: StringName) -> void:
	if not _driver_death_started or _driver_finished:
		return
	if anim_name == ZB001DoctorAnimations.DRIVER_DEATH_ANIMATION:
		doctor_state_machine.animation_controller.play_driver_animation(ZB001DoctorAnimations.DRIVER_FLAG_ANIMATION)
	elif anim_name == ZB001DoctorAnimations.DRIVER_FLAG_ANIMATION:
		_driver_finished = true
		# Dead 只切换本体播放器，尚未播完的机甲动画及其奖杯方法轨道继续运行。
		state_machine.change_state(doctor_state_machine.dead_state)


## 只在抬头结束时推进机甲死亡；机甲死亡动画的结束不参与本体循环切换。[br]
## [param anim_name] 本次结束的机甲动画名称，只有死亡前抬头的结束通知需要处理。
func on_animation_finished(anim_name: StringName) -> void:
	if _returning_head:
		if anim_name == ZB001DoctorAnimations.HEAD_LEAVE_ANIMATION:
			_start_death_animation()
		return


## 机甲死亡动画开始时只启动一轮；次数为 0 或配置无效时不影响其余死亡表现。
func _start_death_explosions() -> void:
	if _explosions_started or explosion_count == 0 or not _explosion_configuration_valid:
		return
	_explosions_started = true
	_is_generating_explosions = true
	_remaining_explosions = explosion_count
	set_death_explosion_speed(state_machine.animation_player.speed_scale)
	_spawn_next_death_explosion()


## 只停止后续生成，已经出现的特效继续消散；不影响本体举旗和奖杯动画轨道。
func stop_death_explosions() -> void:
	_is_generating_explosions = false
	_remaining_explosions = 0
	if is_instance_valid(explosion_interval_timer):
		explosion_interval_timer.stop()


## 博士根节点直接连接速度信号，因此进入 Dead、停止状态逐帧更新后仍能同步。[br]
## [param value] 为有限非负的独立动作倍率；0 同时冻结计时器和单次特效动画。
func set_death_explosion_speed(value: float) -> void:
	if not is_finite(value) or value < 0.0:
		push_error("%s：死亡爆炸的播放倍率必须为有限非负数。" % get_path())
		return
	_explosion_speed_scale = value
	if is_instance_valid(explosion_interval_timer):
		explosion_interval_timer.set_speed_scale(value)
	# 当前播放中的特效实例 ID，节点可能在同一帧被提前释放。
	for explosion_id: int in _active_explosions:
		# 先以 Variant 检查有效性，避免读取已释放的强类型节点引用。
		var explosion: Variant = _active_explosions[explosion_id]
		if is_instance_valid(explosion) and not explosion.is_queued_for_deletion():
			explosion.set_speed_scale(value)


## 博士根节点直接连接机甲结束信号，不经过只通知当前状态的分发入口。[br]
## [param animation_name] 为结束的机甲动画；Dying 和 Dead 都只在机甲死亡结束后停止生成。
func on_mech_death_animation_finished(animation_name: StringName) -> void:
	if animation_name == ZB001DoctorAnimations.DEATH_ANIMATION:
		stop_death_explosions()


## 每次触发都从所有有效、可见的位置等权随机选一个，不排除上一处爆炸的位置。
func _spawn_next_death_explosion() -> void:
	if not _is_generating_explosions or _remaining_explosions <= 0:
		return
	if not _can_generate_death_explosions():
		stop_death_explosions()
		return
	# 本次触发时的完整可见候选集合；仅保存 ID，不缓存上一次的可见性或世界坐标。
	var candidates: Array[Dictionary] = []
	# 初始化收集的全部位置 ID，包含初始隐藏、死亡过程中可能重新显示的位置。
	for point_id: int in _explosion_point_ids:
		# 按 ID 重新解析标记，释放或隐藏的标记不会进入本次随机池。
		var candidate: Marker2D = instance_from_id(point_id) as Marker2D
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and candidate.is_visible_in_tree():
			candidates.append({"data": point_id, "weight": 1.0})
	if candidates.is_empty():
		# 暂时没有可见部件时不扣次数；下次间隔再检查，机甲动画结束仍会停止生成。
		_schedule_next_death_explosion()
		return
	# 项目的等权随机选择器，每次使用当前全部可见位置重新构造候选池。
	var picker: RandomPicker = RandomPicker.new(candidates, false)
	# 本次抽中的标记，只使用其触发当下的位置，不让特效继续跟随机甲部件移动。
	var point: Marker2D = instance_from_id(picker.get_random_item()) as Marker2D
	if not is_instance_valid(point) or point.is_queued_for_deletion():
		_schedule_next_death_explosion()
		return
	# 添加特效前保存世界位置，避免入树回调影响作为定位参考的部件。
	var spawn_position: Vector2 = point.global_position
	# 尚未入树的特效根节点；类型错误时释放本次实例，只取消后续爆炸。
	var instance: Node = explosion_scene.instantiate()
	if not instance is ZB001DoctorDeathExplosionEffect:
		instance.queue_free()
		push_error("%s：单次爆炸场景必须使用 ZB001DoctorDeathExplosionEffect。" % get_path())
		stop_death_explosions()
		return
	# 单次特效挂在博士根节点的独立容器下，避免继承部件隐藏和局部缩放。
	var explosion: ZB001DoctorDeathExplosionEffect = instance as ZB001DoctorDeathExplosionEffect
	explosion_root.add_child(explosion)
	explosion.global_position = spawn_position
	explosion.scale = Vector2.ONE * randf_range(explosion_scale_range.x, explosion_scale_range.y)
	explosion.rotation = randf_range(-PI, PI)
	explosion.set_speed_scale(_explosion_speed_scale)
	_active_explosions[explosion.get_instance_id()] = explosion
	explosion.finished.connect(_on_death_explosion_finished.bind(explosion.get_instance_id()), CONNECT_ONE_SHOT)
	explosion.play()
	_remaining_explosions -= 1
	if _remaining_explosions > 0:
		_schedule_next_death_explosion()
	else:
		_is_generating_explosions = false


## 按动作秒安排下一次爆炸；原生场景暂停和全局时间倍率由 SpeedTimer 自行处理。
func _schedule_next_death_explosion() -> void:
	explosion_interval_timer.start_scaled(randf_range(explosion_interval_range.x, explosion_interval_range.y))


## 生成间隔结束后重新检查全部标记，Dying 已进入 Dead 时也会执行此回调。
func _on_death_explosion_interval_timer_timeout() -> void:
	_spawn_next_death_explosion()


## [param explosion_id] 为已播放完成的实例 ID；只清理同步引用，节点由单次特效释放。
func _on_death_explosion_finished(explosion_id: int) -> void:
	_active_explosions.erase(explosion_id)


## 返回是否仍处于本实例的机甲死亡演出；与当前活动状态是否为 Dying 无关。
func _can_generate_death_explosions() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(boss) \
		and not boss.is_queued_for_deletion() and boss.is_death \
		and boss.character_init_type == Character000Base.E_CharacterInitType.IsNorm \
		and is_instance_valid(explosion_root) and not explosion_root.is_queued_for_deletion() \
		and is_instance_valid(state_machine) and is_instance_valid(state_machine.animation_player) \
		and state_machine.animation_player.is_playing() \
		and state_machine.animation_player.assigned_animation == ZB001DoctorAnimations.DEATH_ANIMATION


## 在实际检查处分支报告配置错误；返回 false 只关闭死亡爆炸，不中断状态机初始化。
func _validate_explosion_configuration() -> bool:
	if explosion_count < 0:
		push_error("%s：死亡爆炸次数不能为负数。" % get_path())
		return false
	if explosion_count == 0:
		return true
	if not is_instance_valid(explosion_scene) or not explosion_scene.can_instantiate():
		push_error("%s：缺少可实例化的单次死亡爆炸场景。" % get_path())
		return false
	if not is_instance_valid(explosion_root) or explosion_root.get_parent() != boss:
		push_error("%s：死亡爆炸容器必须是博士根节点下的 Node2D。" % get_path())
		return false
	if not is_instance_valid(explosion_interval_timer):
		push_error("%s：缺少有效的 DeathExplosionIntervalTimer。" % get_path())
		return false
	if _explosion_point_ids.is_empty():
		push_error("%s：explosion_points 必须绑定有效的机甲爆炸位置标记。" % get_path())
		return false
	if not explosion_interval_range.is_finite() or explosion_interval_range.x <= 0.0 \
		or explosion_interval_range.y < explosion_interval_range.x:
		push_error("%s：死亡爆炸间隔必须为有限正数，且上限不小于下限。" % get_path())
		return false
	if not explosion_scale_range.is_finite() or explosion_scale_range.x <= 0.0 \
		or explosion_scale_range.y < explosion_scale_range.x:
		push_error("%s：死亡爆炸大小必须为有限正数，且上限不小于下限。" % get_path())
		return false
	return true


## 博士离树时停止生成并清理同步引用；单次特效随根节点的容器一起卸载。
func _exit_tree() -> void:
	stop_death_explosions()
	_explosion_point_ids.clear()
	_active_explosions.clear()


## 检查机甲死亡轨道能启动本体死亡；允许起止关键帧，具体时机完全由轨道决定。
func get_configuration_error() -> String:
	# 基础动画已由控制器校验，此处只负责死亡序列所需的方法事件。
	var animation: Animation = state_machine.animation_player.get_animation(ZB001DoctorAnimations.DEATH_ANIMATION)
	if ZB001DoctorAnimationEvents.get_state_event_times(animation, ZB001DoctorAnimationEvents.DRIVER_DEATH).is_empty():
		push_error("%s：机甲死亡动画必须具有有效的 driver_death 方法事件。" % get_path())
		return "缺少本体死亡启动事件。"
	return ""
