extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateSpawnPrepare
## 放置专用准备阶段：先锁定目标行与类型，无有效目标时结束本轮，不进入空动画。


## 无目标时停止准备链，正常情况下进入 Place；其他技能继续使用原通用准备状态。
func enter() -> void:
	skill_state.prepare_action()
	if skill_state.action_parameters.is_empty() or skill_state.selected_animation.is_empty():
		skill_state.finish_skill()
		return
	state_machine.change_state(next_state)


## 限定所属技能与后续动作，避免在其他技能内误用放置准备规则。
## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	if not skill_state is ZB001DoctorStateSpawn:
		detected_error = "SpawnPrepare 必须属于放置僵尸技能。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not next_state is ZB001DoctorStateSpawnPlace:
		detected_error = "SpawnPrepare 必须连接放置动作 Place。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return super.get_configuration_error()
