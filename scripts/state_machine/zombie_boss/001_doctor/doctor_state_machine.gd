extends CharacterStateMachine
class_name DoctorStateMachine
## 博士专用状态机模板。具体技能调度、冻结及低头上下文在此扩展。
## 当前只沿用通用状态管理，不自动驱动博士技能或修改动画速度。
## 后续增加阶段、冷却等博士规则时写在此层，保持 CharacterStateMachine 可被其他角色复用。
## 场景中绑定 character、animation_player、initial_state，角色就绪后再显式初始化和启动。

## 提供博士类型引用，避免各状态重复转换；原始引用仍由通用状态机统一维护。
var boss: ZB001Doctor:
	get:
		return character as ZB001Doctor


## 在状态注册前拒绝其他角色，避免专用状态读取博士接口时才发生错误。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor) and actor is ZB001Doctor
