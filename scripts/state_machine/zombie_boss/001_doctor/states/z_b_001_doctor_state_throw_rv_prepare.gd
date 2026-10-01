## 砸车专用准备状态：没有完整可用区域时结束技能，避免进入空动画。
extends ZB001DoctorStateSkillPrepare
class_name ZB001DoctorStateThrowRVPrepare


## 限定所属技能和下一状态类型，防止错误连线跳过落地事件处理。
func get_configuration_error() -> String:
	if not skill_state is ZB001DoctorStateThrowRV:
		push_error("ThrowRVPrepare：必须位于砸车技能内。")
		return "砸车准备状态所属技能错误。"
	if not next_state is ZB001DoctorStateSkillAction:
		push_error("ThrowRVPrepare：必须连接技能动作状态。")
		return "砸车准备状态后续连线错误。"
	return super.get_configuration_error()
