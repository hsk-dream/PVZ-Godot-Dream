extends CharacterState
class_name ZB001DoctorState
## 博士状态的公共基类，提供类型明确的角色和专用状态机引用。
## 技能运行数据由效果组件持有，复合状态只组织阶段，主层调度数据属于博士根状态机。
## 不在此处保存低头倒计时等共享数据，避免每个子状态各自持有一份副本。

## 从通用角色引用派生，不重复保存，确保重新 setup() 后仍指向同一个博士。
## 初始化前可能为 null；具体状态应在 enter() 等已完成依赖注入的阶段使用。
var boss: ZB001Doctor:
	get:
		return character as ZB001Doctor


## state_machine 是直接所属层；博士根状态机从角色取得，不能把内部状态机强转为根层。
var doctor_state_machine: ZB001DoctorStateMachine:
	get:
		return boss.state_machine if is_instance_valid(boss) else null

## 内部状态所属的复合技能；顶层 Enter/Idle/死亡状态没有此引用。
var skill_state: ZB001DoctorSkillState:
	get:
		return state_machine.get_parent() as ZB001DoctorSkillState if is_instance_valid(state_machine) else null


## 注册时限制角色类型，让通用状态机也能安全地校验博士专用状态。
## [param actor] 待检查或注入的所属角色；具体允许的角色类型由当前状态或状态机限定。
func accepts_character(actor: Character000Base) -> bool:
	return is_instance_valid(actor) and actor is ZB001Doctor
