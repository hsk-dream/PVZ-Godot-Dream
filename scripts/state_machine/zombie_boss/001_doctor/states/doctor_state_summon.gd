extends DoctorState
class_name DoctorStateSummon
## 召唤：进入时锁定目标，在召唤关键帧调用博士本体的生成方法。
## 仅提供状态模板；当前不播放动画、不切换状态、不执行技能。
## 下列方法注释说明后续接入业务的约定，不表示这些行为已经实现。


## 锁定本次召唤行、种类和数量，选择对应动画；动画播放后不随意重选目标。
func enter() -> void:
	pass


## 清理召唤预警及尚未生效的回调；已经生成的普通僵尸由其自身和关卡管理器管理。
func exit() -> void:
	pass


## 仅维护当前召唤动作的局部步骤；生成时刻使用关键帧事件，避免计时与动画速度脱节。
func update(_delta: float) -> void:
	pass


## 匹配当前召唤动画并完成所有计划步骤后请求 Recover，不在无关动画结束时切换。
func on_animation_finished(_anim_name: StringName) -> void:
	pass


## 在有效的召唤释放事件中调用博士本体；一次生成事件只执行一次，多次生成需分别标记。
func on_animation_event(_event_name: StringName) -> void:
	pass
