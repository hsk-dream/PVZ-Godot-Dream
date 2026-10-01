extends ZB001DoctorState
class_name ZB001DoctorStateSkillPrepare
## 五个技能共用动作准备和失败收尾；专用子类只校验所属技能及后续连线。
## 本次动作参数准备完成后进入的同层状态，通常为动作播放或低头阶段。
@export var next_state: CharacterState

## 锁定本次动作；空动画表示准备失败，结束整轮技能，成功时进入同层后续状态。
func enter() -> void:
	skill_state.prepare_action()
	if skill_state.selected_animation.is_empty():
		skill_state.finish_skill()
		return
	state_machine.change_state(next_state)

## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not is_instance_valid(next_state) or next_state.get_parent() != state_machine or next_state == self:
		detected_error = "准备状态必须绑定同层后续状态。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""
