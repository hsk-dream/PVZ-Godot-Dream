extends DoctorState
class_name DoctorStateHeadAttack
## 吐球：维护本次行号与球类型，在吐球关键帧只释放一次。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 锁定本次目标行与球类型，重置本次释放标记并播放对应吐球动画；不重置整轮暴露时间。
func enter() -> void:
	pass


## 清理本次未释放任务；已生成的球独立运行，共享低头数据保留给下一状态。
func exit() -> void:
	pass


## 暴露时间到期时记录退出意图，正常情况下先完成已开始的吐球动作，再抬头。
func update(_delta: float) -> void:
	pass


## 匹配本次吐球动画后，根据剩余暴露时间请求 HeadIdle 或 HeadLeave。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 核对吐球释放事件和本次动作有效性，仅调用博士本体释放一次；不在此实现球的移动碰撞。
func on_animation_event(_event_name: StringName) -> void:
	pass
