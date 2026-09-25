extends DoctorState
class_name DoctorStateBungee
## 蹦极：维护本次进入、离开动画步骤，在释放关键帧请求召唤。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 锁定本批蹦极目标，初始化进入、离开两个动画步骤；同批目标应避免重复。
func enter() -> void:
	pass


## 清理本次演出的临时数据；已生成的蹦极僵尸独立运行，不因主体退出而重复生成。
func exit() -> void:
	pass


## 仅推进本次主体演出的局部等待；蹦极僵尸的下降、偷盗和离场不在这里逐帧控制。
func update(_delta: float) -> void:
	pass


## 按当前步骤匹配进入或离开动画；进入结束后切到离开步骤，离开结束后请求 Recover。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 处理一次有效的蹦极释放事件；目标在释放前消失时，按既定业务规则跳过或空抓。
func on_animation_event(_event_name: StringName) -> void:
	pass
