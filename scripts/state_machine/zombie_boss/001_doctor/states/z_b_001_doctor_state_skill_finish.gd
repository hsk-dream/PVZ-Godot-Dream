extends ZB001DoctorState
class_name ZB001DoctorStateSkillFinish
## 动画已经完成收尾；通知所属技能结束，由父技能请求回到主层 Idle。
func enter() -> void:
	skill_state.finish_skill()
