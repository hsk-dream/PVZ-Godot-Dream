extends ZB001DoctorSkillState
class_name ZB001DoctorStateSpawn
## 按技能组件提前准备的清单逐只放置，两次放置之间播放待机动画。
## 两次放置之间的等待时间，单位为正常动作速度下的秒；首轮前与最后一轮后不等待。
@export_range(0.1, 60.0, 0.1) var spawn_interval_duration: float = 1.0


## 错误由检测分支就地输出；返回值供上层中止初始化，转发时不重复报错。
func get_configuration_error() -> String:
	if not effect_component is ZB001DoctorSkillSpawn:
		push_error("%s：必须绑定 ZB001DoctorSkillSpawn 效果组件。" % get_path())
		return "技能效果组件类型错误。"
	# 本函数发现的配置错误；下层返回的错误已经由下层报告。
	var detected_error: String = ""
	# 父类技能配置检查的结果；非空时直接返回，不继续验证放置专属参数。
	var error := super.get_configuration_error()
	if not error.is_empty():
		return error
	if not is_finite(spawn_interval_duration) or spawn_interval_duration <= 0.0:
		detected_error = "放置间隔必须为有限正数。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	# 本技能的通用准备入口；所属技能和首条阶段连线在复合状态内统一检查。
	var prepare_state: ZB001DoctorStateSkillPrepare = child_state_machine.initial_state as ZB001DoctorStateSkillPrepare
	if prepare_state == null or prepare_state.skill_state != self:
		detected_error = "放置技能入口必须使用自身的通用 Prepare，处理无可用目标的情况。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	if not prepare_state.next_state is ZB001DoctorStateSpawnPlace:
		detected_error = "放置准备入口必须连接放置动作 Place。"
		push_error("%s：%s" % [get_path(), detected_error])
		return detected_error
	return ""
