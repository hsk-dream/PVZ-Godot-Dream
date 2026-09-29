extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateHeadPrepare
## 低头技能专用准备：锁定目标行、对应动画与冰火类型，无有效目标时结束本轮。


## 空结果不能进入低头流程，避免最终播放空动画；正常结果沿既有阶段链执行。
func enter() -> void:
	skill_state.prepare_action()
	if skill_state.selected_animation.is_empty():
		skill_state.finish_skill()
		return
	state_machine.change_state(next_state)


## 准备节点只属于低头技能，后续必须连接低头动作。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not skill_state is ZB001DoctorStateHeadSkill or not next_state is ZB001DoctorStateHeadEnter:
		detected_error = "HeadPrepare 必须属于 HeadSkill 并连接 LowerHead。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return super.get_configuration_error()
