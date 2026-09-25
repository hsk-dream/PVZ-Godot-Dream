extends CharacterState
class_name DoctorState
## 博士状态的公共模板，仅提供类型明确的角色引用。
## 跨状态共享的数据应放在 DoctorStateMachine 或博士本体中。
## 不在此处保存低头倒计时等共享数据，避免每个子状态各自持有一份副本。

## 从通用角色引用派生，不重复保存，确保重新 setup() 后仍指向同一个博士。
## 初始化前可能为 null；具体状态应在 enter() 等已完成依赖注入的阶段使用。
var boss: ZB001Doctor:
	get:
		return character as ZB001Doctor


## 注册时限制角色类型，让通用状态机也能安全地校验博士专用状态。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor) and actor is ZB001Doctor
