extends DoctorState
class_name DoctorStateHeadEnter
## 低头：初始化整轮低头上下文，低头动画完成后请求 HeadIdle。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 初始化整轮低头上下文并播放低头动画；暴露计时从头部到位后开始。
func enter() -> void:
	pass


## 正常退出时保留低头上下文供 HeadIdle 和 HeadAttack 使用，终止战斗的清理由父层负责。
func exit() -> void:
	pass


## 此阶段不消耗尚未开始的暴露时间，避免较长低头动画缩短玩家的实际输出窗口。
func update(_delta: float) -> void:
	pass


## 匹配低头动画完成后请求 HeadIdle，由统一的受击规则开放头部受击。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 如增加低头到位或表现关键帧，应与动画完成路径协调，避免重复开放窗口或重置计时。
func on_animation_event(_event_name: StringName) -> void:
	pass
