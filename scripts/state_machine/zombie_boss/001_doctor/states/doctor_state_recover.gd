extends DoctorState
class_name DoctorStateRecover
## 动作间歇：按配置计时，结束后请求 Idle。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 初始化本次动作间歇并播放待机表现；各技能可在父层提供不同的恢复时长。
func enter() -> void:
	pass


## 清理本次恢复计时，不重置整场技能冷却或下次低头期限。
func exit() -> void:
	pass


## 恢复时间结束后请求 Idle；只提交一次有效转换，不在这里直接选择并释放技能。
func update(_delta: float) -> void:
	pass


## 恢复阶段可能播放循环待机动画，动画完成不应替代恢复计时。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 通常只处理表现事件；恢复期不接受上一技能迟到的伤害或生成事件。
func on_animation_event(_event_name: StringName) -> void:
	pass
