extends CharacterCompositeState
class_name ZB001DoctorSkillState
## 博士复合技能只组织流程、保存本次参数；效果由独立技能组件执行。

## 本技能的独立效果组件，负责执行效果，不负责状态切换。
@export var effect_component: ZB001DoctorSkillBase
## 对应同一技能的动画变体，不假定变体编号等于关卡行号。
@export var action_animations: Array[StringName] = []
## 本技能认可的释放事件名；使用方法关键帧的技能必须配置，不使用关键帧的技能留空。
@export var release_event: StringName
## 当前动作的参数快照，包含动画变体及技能专属数据；准备时重建，退出时清空。
var action_parameters: Dictionary = {}
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

func enter() -> void:
	_completed = false
	action_parameters.clear()
	selected_animation = &""
	boss.is_idle = false
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	super.enter()

## 主状态机选择前的只读条件；默认允许，具有目标要求的技能自行覆盖，不提前准备动作。
func can_be_selected() -> bool:
	return true


## 动作准备时锁定一次，动画播放期间不重新选择目标或变体。
func prepare_action() -> void:
	# 本次随机选择的动画数组下标，从 0 开始；传给效果组件时转换为从 1 开始的编号。
	var variant := randi_range(0, action_animations.size() - 1)
	selected_animation = action_animations[variant]
	action_parameters = {"animation_variant": variant + 1}

## 子状态负责关键帧去重；组件只执行效果，不反向驱动状态转换。
func execute_effect() -> void:
	if is_active_skill():
		effect_component.execute(action_parameters.duplicate(true))

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

func exit() -> void:
	super.exit()
	stop_skill_timers()
	action_parameters.clear()
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
	if action_animations.is_empty() or (requires_release_keyframe() and release_event.is_empty()):
		detected_error = "%s 未配置动作动画或释放事件。" % name
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 当前待检查的技能动画名称；按技能约定决定是否额外校验释放帧。
	for animation_name in action_animations:
		if not state_machine.animation_player.has_animation(animation_name):
			detected_error = "%s 缺少动画 %s。" % [name, animation_name]
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		# 当前技能动画资源，用于检查循环模式和方法轨道配置。
		var animation := state_machine.animation_player.get_animation(animation_name)
		if animation.loop_mode != Animation.LOOP_NONE:
			detected_error = "%s 的技能动作动画必须为非循环。" % name
			push_error("%s：%s" % [get_path(), detected_error])
			return detected_error
		if requires_release_keyframe() and not doctor_state_machine.has_skill_keyframe(animation, animation_name, release_event):
			detected_error = "%s 缺少有效技能释放关键帧。" % animation_name
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
