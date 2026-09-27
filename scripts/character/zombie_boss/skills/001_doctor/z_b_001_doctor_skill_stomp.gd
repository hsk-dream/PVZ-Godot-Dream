extends ZB001DoctorSkillBase
class_name ZB001DoctorSkillStomp
## 脚踩植物效果组件；后续仅替换 execute 内部实现，动画和技能流程无需跟着改写。

## [param parameters] 本次技能动作参数的独立快照，由准备阶段构建，当前仅用于占位输出。
func execute(parameters: Dictionary) -> void:
	print_placeholder("Stomp", parameters)
