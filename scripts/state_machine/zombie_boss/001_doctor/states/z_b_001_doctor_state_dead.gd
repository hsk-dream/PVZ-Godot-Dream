extends ZB001DoctorState
class_name ZB001DoctorStateDead
## 终结状态仅清理尸体，保留一秒淡出窗口供死亡动画末尾的延迟方法轨道执行。


## 保留当前状态和死亡锁，停止帧更新；不使用 stop() 清除当前状态。
func enter() -> void:
	state_machine.set_physics_process(false)
	boss._fade_and_remove()
