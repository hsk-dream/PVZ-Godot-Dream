extends ZB001DoctorState
class_name ZB001DoctorStateDead
## 本体举旗完成后立即循环并开始保留计时；机甲死亡动画独立继续，保留结束后再淡出。


## 保留死亡锁，只停止状态机的物理更新；两个动画播放器和根节点计时器继续运行。
func enter() -> void:
	doctor_state_machine.play_driver_animation(ZB001DoctorStateMachine.DRIVER_FLAG_LOOP_ANIMATION)
	boss.start_death_remain()
	state_machine.set_physics_process(false)
