extends ZB001DoctorState
class_name ZB001DoctorStateHeadEnter
## 低头开始关闭受击，第 2 秒由动画事件开启；动作完成后进入吐球前待机。

func enter() -> void:
	boss.is_idle = false
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	doctor_state_machine.play_mech_animation(ZB001DoctorStateMachine.HEAD_ENTER_ANIMATION)

## 受击开关跟随动画时间；死亡或技能已退出时不处理迟到事件。[br]
## [param event_name] 低头方法轨道事件，仅 hurt_enable 开启角色受击因素。
func on_animation_event(event_name: StringName) -> void:
	if event_name == &"hurt_enable" and skill_state.is_active_skill():
		boss.hurt_box_component.enable_component(ComponentNormBase.E_IsEnableFactor.Character)
		# 同一状态内开关受击也要通知检测器，不能只依赖状态切换信号。
		doctor_state_machine.notify_skill_status_changed()


## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ZB001DoctorStateMachine.HEAD_ENTER_ANIMATION and skill_state.is_active_skill():
		state_machine.change_state((skill_state as ZB001DoctorStateHeadSkill).before_spit_idle_state)
