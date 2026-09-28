extends ZB001DoctorState
class_name ZB001DoctorStateDead
## 死亡演出完成后让本体循环举旗；从进入循环时开始计时，保留结束后再淡出。


## 保留当前状态和死亡锁，停止状态更新；根节点计时器继续运行，不依赖机甲动画是否结束。
func enter() -> void:
	doctor_state_machine.driver_animation_player.play(ZB001DoctorStateMachine.DRIVER_FLAG_LOOP_ANIMATION)
	boss.start_death_remain()
	state_machine.set_physics_process(false)
