extends Node
class_name ZB001DoctorSkillBase
## 博士技能效果入口：集中检查战斗归属与角色生命周期，具体效果由各技能实现。

## 当前完整技能是否仍有效；结束与取消都会关闭释放入口。
var _skill_active: bool = false
## 当前动作是否已准备完成，防止关键帧先于准备或取消后释放。
var _action_ready: bool = false
## 当前动作是否已释放；重复关键帧不能重复产生效果。
var _action_released: bool = false


## 全部配置校验通过后调用一次；子类可在此修正运行时参数，不在只读校验中修改配置。
func initialize_skill() -> void:
	pass


## 只读查询技能是否可被选择；默认允许，目标要求由具体技能覆盖。
func can_start() -> bool:
	return true


## 开始完整技能并清理上次运行数据；返回是否成功，具体选点仍在动作准备阶段进行。
func begin_skill() -> bool:
	cancel_skill()
	_skill_active = true
	return true


## 准备当前动作并返回动画名；空名称表示没有可执行动作，由状态正常收尾。
func prepare_action() -> StringName:
	return &""


## [param animation_name] 准备结果的动画名；记录本动作释放门闩并返回原名称。
func _arm_action(animation_name: StringName) -> StringName:
	_action_ready = _skill_active and not animation_name.is_empty()
	_action_released = false
	return animation_name if _action_ready else &""


## 仅允许有效技能的已准备动作释放一次；先关闭门闩，再执行可能同步触发死亡的效果。
func release_action() -> void:
	if not _skill_active or not _action_ready or _action_released:
		return
	_action_released = true
	_release_action()


## 具体技能消费自身持有的本轮数据，不接收无类型参数字典。
func _release_action() -> void:
	pass


## 正常收尾使用统一清理，保留明确的语义入口，后续正常完成奖励可在子类扩展。
func end_skill() -> void:
	cancel_skill()


## 幂等取消当前技能；子类清理目标和连接，不删除已经独立生成的实体。
func cancel_skill() -> void:
	_skill_active = false
	_action_ready = false
	_action_released = false


## 返回该技能的动作动画集合，供状态层校验释放事件，不暴露运行时目标。
func get_action_animations() -> Array[StringName]:
	# 基类没有动作，但空结果仍须携带 StringName 元素类型。
	var animations: Array[StringName] = []
	return animations


## 返回死亡时需要平滑复位的节点位置；默认没有代码控制的视觉偏移。
func capture_visual_returns() -> Array[ZB001DoctorVisualReturn]:
	# 没有待复位节点时也返回类型化快照数组。
	var snapshots: Array[ZB001DoctorVisualReturn] = []
	return snapshots


## 返回所属博士正在参与的关卡；展示、死亡、离树、退出及战斗结束时返回 null。
## 子类仍需检查自己使用的管理器或挂载节点，避免把某个技能的依赖强加给全部技能。
func _get_active_game() -> MainGameManager:
	# 场景 owner 指向博士根节点，不依赖 Skills 的固定层级。
	var doctor: ZB001Doctor = owner as ZB001Doctor
	if not is_instance_valid(doctor) or doctor.is_death or doctor.is_queued_for_deletion() \
		or not doctor.is_inside_tree() or doctor.character_init_type != Character000Base.E_CharacterInitType.IsNorm:
		return null
	# 全局关卡必须仍持有当前博士，避免切换场景后旧实例向新关卡释放技能。
	var game: MainGameManager = Global.main_game
	if not is_instance_valid(game) or game.is_queued_for_deletion() or not game.is_ancestor_of(doctor) \
		or game.main_game_progress != MainGameManager.E_MainGameProgress.MAIN_GAME:
		return null
	return game


## 只读检查具体技能的静态配置，空字符串表示有效；具体分支自行报告错误。
func get_configuration_error() -> String:
	return ""
