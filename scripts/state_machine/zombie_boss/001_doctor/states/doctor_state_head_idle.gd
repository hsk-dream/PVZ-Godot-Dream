extends DoctorState
class_name DoctorStateHeadIdle
## 低头待机：使用共享暴露计时，不在每次进入时重置整轮数据。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 播放低头待机表现，读取父层已有的低头上下文；从吐球返回时不重置整轮计时和次数。
func enter() -> void:
	pass


## 退出到 HeadAttack 时仍属于暴露阶段，不在这里无条件关闭受击或清空低头上下文。
func exit() -> void:
	pass


## 依据共享暴露时间和吐球条件请求 HeadAttack 或 HeadLeave；计时只由一处更新。
func update(_delta: float) -> void:
	pass


## 低头待机通常循环，不能依赖动画结束通知抬头；退出条件由暴露时间和业务规则决定。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 通常不在待机事件中直接吐球，应先进入 HeadAttack，让释放事件归属明确的动作。
func on_animation_event(_event_name: StringName) -> void:
	pass
