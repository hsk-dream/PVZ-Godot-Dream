extends Node
class_name ZB001DoctorSkillBase
## 技能效果入口，与动画状态机分离；子类可实现实际效果，未实现的技能沿用打印占位。
## 信号用于观察一次实际占位调用，参数使用独立快照，避免后续状态清理改变日志内容。
signal placeholder_executed(parameters: Dictionary)

## [param _parameters] 技能参数字典；基类仅定义执行入口，具体效果由子类实现。
func execute(_parameters: Dictionary) -> void:
	pass

## [param skill_name] 占位日志中的技能名称，便于区分五种技能的关键帧调用。
## [param parameters] 本次技能动作参数的独立快照，由准备阶段构建，当前仅用于占位输出。
func print_placeholder(skill_name: String, parameters: Dictionary) -> void:
	print("[Doctor][%s] 技能占位：%s" % [skill_name, parameters])
	placeholder_executed.emit(parameters.duplicate(true))
