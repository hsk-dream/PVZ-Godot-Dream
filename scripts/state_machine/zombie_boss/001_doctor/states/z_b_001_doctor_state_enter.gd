extends ZB001DoctorState
class_name ZB001DoctorStateEnter
## 入场：在 enter() 中播放入场动画，匹配动画完成后请求 Idle。
## 完成时间取决于实际动画播放进度，因此减速或暂停不会提前结束入场。


## 只在进入时播放一次；动画速度沿用角色速度组件，不在此覆盖。
func enter() -> void:
	boss.is_idle = false
	boss.hurt_box_component.disable_component(ComponentNormBase.E_IsEnableFactor.Character)
	# 每次入场重新允许两次落脚事件，声音和震动由动画方法关键帧同步触发。
	boss.reset_enter_footsteps()
	doctor_state_machine.animation_controller.play_mech_action(ZB001DoctorAnimations.ENTER_ANIMATION, ZB001DoctorAnimationController.DriverReaction.DRIVE)


## 匹配入场动画后请求 Idle；其他动画的完成通知不能结束入场。
## [param anim_name] 本次结束的动画名称，供状态过滤无关动作的完成通知。
func on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ZB001DoctorAnimations.ENTER_ANIMATION:
		# 只提交请求，由下一次状态机更新执行，避免在动画信号回调里嵌套切换。
		state_machine.change_state(doctor_state_machine.idle_state)
