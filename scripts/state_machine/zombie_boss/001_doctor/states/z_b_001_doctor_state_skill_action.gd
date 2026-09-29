extends ZB001DoctorState
class_name ZB001DoctorStateSkillAction
## 播放一段完整动作；收手/收脚包含在动画内，释放只发生在方法关键帧。
## 完整动作结束后的同层目标状态；放置动作可根据次数覆盖该选择。
@export var next_state: CharacterState
## 本次进入时锁定的动画名，用于过滤不属于当前动作的完成通知。
var _animation: StringName
## 本次动作是否已处理完成通知；每次进入重置，防止重复计数或提交切换。
var _finished := false

func enter() -> void:
	_finished = false
	_animation = skill_state.selected_animation
	doctor_state_machine.animation_controller.play_mech_action(_animation, get_driver_reaction())
	doctor_state_machine.sync_action_timer_speed()

## [param event_name] 动画方法轨道传入的事件名，由当前活动状态判断是否处理。
func on_animation_event(event_name: StringName) -> void:
	if skill_state.requires_release_keyframe() and event_name == skill_state.release_event and skill_state.is_active_skill():
		skill_state.release_action()

## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name == _animation and not _finished and skill_state.is_active_skill():
		# 结束事件可能重复投递；只允许一次计数和转换，释放帧仍允许在同帧延迟到达。
		_finished = true
		state_machine.change_state(get_next_state())

## 普通技能只执行一次；放置子类在这里根据本轮次数决定进入间隔还是收尾。
func get_next_state() -> CharacterState:
	return next_state

## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not is_instance_valid(next_state) or next_state.get_parent() != state_machine or next_state == self:
		detected_error = "动作状态必须绑定同层后续状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""


## 普通技能动作使用本体操纵，吐球子状态显式覆盖，控制器不识别状态类型。
func get_driver_reaction() -> ZB001DoctorAnimationController.DriverReaction:
	return ZB001DoctorAnimationController.DriverReaction.DRIVE
