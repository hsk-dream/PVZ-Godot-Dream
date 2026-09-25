extends DoctorState
class_name DoctorStateThrowRV
## 房车：进入时锁定目标，在脱手关键帧调用博士本体生成房车。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 锁定房车落点和预警范围，播放投掷动画；目标参数保留到脱手事件。
func enter() -> void:
	pass


## 清理本状态持有的预警或未发出的任务；已脱手房车的生命周期应交给其实体管理。
func exit() -> void:
	pass


## 可维护投掷局部步骤，不等待独立房车实体完成全部飞行才更新主体动作。
func update(_delta: float) -> void:
	pass


## 匹配投掷动画结束后请求 Recover，房车落地结果不通过无关动画通知驱动。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 在脱手事件中调用博士本体创建房车一次；必须使用进入时已经锁定的目标。
func on_animation_event(_event_name: StringName) -> void:
	pass
