extends ZB001DoctorState
class_name ZB001DoctorStateHeadLeave
## 吐球后待机结束再抬头，第 0.6667 秒由动画事件关闭受击，动画结束完成整轮技能。

func enter() -> void:
	boss.is_idle = false
	state_machine.animation_player.play(ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION)

## 抬头初段沿用受击窗口，关闭关键帧发生时立即通知检测器更新目标。[br]
## [param event_name] 抬头方法轨道事件，仅 hurt_disable 关闭角色受击因素。
func on_animation_event(event_name: StringName) -> void:
	if event_name == &"hurt_disable" and skill_state.is_active_skill():
		boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
		doctor_state_machine.notify_skill_status_changed()


## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ZB001DoctorStateMachine.HEAD_LEAVE_ANIMATION and skill_state.is_active_skill():
		skill_state.finish_skill()
