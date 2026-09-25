extends DoctorState
class_name DoctorStateEnter
## 入场：在 enter() 中播放入场动画，匹配动画完成后请求 Idle。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 接入入场逻辑时，在此关闭受击并播放入场动画；不要在入场过程中提前调度技能。
func enter() -> void:
	pass


## 清理入场专用的临时效果；若被死亡打断，不应在退出时重新开启受击或启动技能。
func exit() -> void:
	pass


## 仅在入场有额外演出计时时扩展；动作完成优先依据对应动画结束事件。
func update(_delta: float) -> void:
	pass


## 匹配入场动画后请求 Idle；其他动画的完成通知不能结束入场。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 预留入场音效、镜头等关键帧事件，不承担普通技能释放。
func on_animation_event(_event_name: StringName) -> void:
	pass
