extends CharacterCompositeState
class_name ZB001DoctorSkillState
## 博士复合技能只组织阶段和动画；运行数据与效果均由独立技能组件持有。

## 本技能的独立效果组件，负责执行效果，不负责状态切换。
@export var effect_component: ZB001DoctorSkillBase
## 本技能认可的释放事件名；使用方法关键帧的技能必须配置，不使用关键帧的技能留空。
@export var release_event: StringName
## 本轮组件是否成功开始；失败时准备阶段返回空动作并正常收尾。
var _skill_begun: bool = false
## 本次准备阶段选定的动画名称，供动作子状态播放；退出时清空。
var selected_animation: StringName
## 是否已提交正常完成请求，避免重复收尾以及完成后再次执行技能效果。
var _completed := false

## 由注入角色转换得到的博士引用；初始化完成后供技能访问角色组件。
var boss: ZB001Doctor:
	get:
		return character as ZB001Doctor
## 博士根层状态机引用；内部子状态机不承担主层技能选择与死亡管理。
var doctor_state_machine: ZB001DoctorStateMachine:
	get:
		return boss.state_machine if is_instance_valid(boss) else null

## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
func accepts_character(actor: Character000Base) -> bool:
	return actor is ZB001Doctor

## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
## [param machine] 管理当前状态的直属状态机，提供播放器与同层状态切换入口。
func setup(actor: Character000Base, machine: CharacterStateMachine) -> void:
	super.setup(actor, machine)
	if child_initialized and not child_state_machine.state_changed.is_connected(_on_child_state_changed):
		child_state_machine.state_changed.connect(_on_child_state_changed)

## 开始组件生命周期后启动子状态机，目标准备仍由 Prepare 阶段驱动。
func enter() -> void:
	_completed = false
	selected_animation = &""
	boss.is_idle = false
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	_skill_begun = effect_component.begin_skill()
	super.enter()

## 主状态机选择前的只读条件；默认允许，具有目标要求的技能自行覆盖，不提前准备动作。
func can_be_selected() -> bool:
	return is_instance_valid(effect_component) and effect_component.can_start()


## 读取组件提供的动作清单，状态只校验释放事件，不保存另一份动作配置。
func get_action_animations() -> Array[StringName]:
	# 保持返回容器的元素类型；assign 按 StringName 接收组件列表，不依赖三元表达式推导。
	var animations: Array[StringName] = []
	if is_instance_valid(effect_component):
		animations.assign(effect_component.get_action_animations())
	return animations


## 动作准备时锁定一次，动画播放期间不重新选择目标或变体。
func prepare_action() -> void:
	selected_animation = effect_component.prepare_action() if _skill_begun else &""


## 关键帧只提交释放请求；组件持有准备结果并负责每个动作的幂等释放。
func release_action() -> void:
	if is_active_skill():
		effect_component.release_action()


## 是否需要死亡前抬头；只有低头技能根据自己的内部阶段覆盖此查询。
func needs_head_return() -> bool:
	return false


## 当前技能仍由运行中的主状态机持有且角色存活时才接受释放和完成请求。
func is_active_skill() -> bool:
	return is_instance_valid(doctor_state_machine) and doctor_state_machine.is_running \
		and doctor_state_machine.current_state == self and not boss.is_death and not _completed

## 只有正常收尾会调用此方法；死亡等中断只走 exit()，绝不请求返回 Idle。
func finish_skill() -> void:
	if not is_active_skill():
		return
	_completed = true
	stop_skill_timers()
	doctor_state_machine.change_state(doctor_state_machine.idle_state)

## 先退出子阶段，再按正常完成或中断调用组件清理，避免遗留监听与视觉偏移。
func exit() -> void:
	super.exit()
	stop_skill_timers()
	if is_instance_valid(effect_component):
		if _completed:
			effect_component.end_skill()
		else:
			effect_component.cancel_skill()
	_skill_begun = false
	selected_animation = &""

func stop_skill_timers() -> void:
	# 技能子树中当前遍历到的 Timer 节点；只停止其中的 SpeedTimer。
	for timer: Node in find_children("*", "Timer", true, false):
		if timer is SpeedTimer:
			timer.stop()

## 子状态 enter 完成后通知检测器；父层切换期间由父层的统一通知覆盖，避免重复广播。
## [param _previous] 切换前的子状态；此回调仅通知检测器并同步计时倍率。
## [param _next] 切换后的子状态；其进入逻辑已完成，此回调不再修改该状态。
func _on_child_state_changed(_previous: CharacterState, _next: CharacterState) -> void:
	if is_active_skill():
		doctor_state_machine.notify_skill_status_changed()
		doctor_state_machine.sync_action_timer_speed()

## 默认由动画关键帧释放技能；流程自行等待的技能可覆盖为 false，免于配置占位事件。
func requires_release_keyframe() -> bool:
	return true


## 根状态机启动前校验整个内部流程，不允许缺失动画或效果组件后进入死路。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not child_initialized or child_state_machine.initial_state == null:
		detected_error = "%s 缺少有效子状态机或入口。" % name
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not is_instance_valid(effect_component) or not boss.is_ancestor_of(effect_component):
		detected_error = "%s 必须绑定博士自身的技能组件。" % name
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 效果依赖与静态参数由组件自行校验，状态不重复读取其内部配置。
	var effect_error: String = effect_component.get_configuration_error()
	if not effect_error.is_empty():
		return effect_error
	# 通过统一只读入口取得动作清单，兼容行映射与普通变体数组。
	var animations: Array[StringName] = get_action_animations()
	if animations.is_empty() or (requires_release_keyframe() and release_event.is_empty()):
		detected_error = "%s 未配置动作动画或释放事件。" % name
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 当前待检查的技能动画名称；按技能约定决定是否额外校验释放帧。
	for animation_name in animations:
		# 播放器和循环规则交给动画控制器，当前技能只决定其释放事件要求。
		var animation_error: String = doctor_state_machine.animation_controller.get_animation_error(state_machine.animation_player, animation_name, Animation.LOOP_NONE)
		if not animation_error.is_empty():
			return animation_error
		# 当前动作的事件时间；释放必须唯一且严格位于动画内部。
		var times: Array[float] = AnimationMethodQuery.get_times(state_machine.animation_player.get_animation(animation_name), NodePath("StateMachine"), &"notify_skill_event", [animation_name, release_event], false)
		if requires_release_keyframe() and times.size() != 1:
			detected_error = "%s 必须具有唯一的有效技能释放关键帧。" % animation_name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
	# 子状态机的当前直属节点；具有配置检查方法时继续验证其内部连线。
	for child in child_state_machine.get_children():
		if child.has_method("get_configuration_error"):
			# 当前子状态返回的配置错误，非空时中止整个技能的初始化检查。
			var error: String = child.get_configuration_error()
			if not error.is_empty():
				return error
	return ""
