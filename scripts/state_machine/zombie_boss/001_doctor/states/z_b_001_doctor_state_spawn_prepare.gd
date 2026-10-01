extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateSpawnPrepare
## 放置专用准备阶段：读取本批清单的下一项，无有效任务时结束本轮，不进入空动画。


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
