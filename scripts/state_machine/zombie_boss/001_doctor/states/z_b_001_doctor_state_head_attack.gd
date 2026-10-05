extends ZB001DoctorStateSkillAction
class_name ZB001DoctorStateHeadAttack
## 沿用低头关键帧开启的受击状态，播放 Prepare 选定的吐球动画。
## 本次只释放一个球，关键帧去重由通用动作状态处理，完成后进入吐球后待机。

## 播放吐球动画前设置本轮的冰火颜色，动画继续负责嘴部和眼部的出现时机。
func enter() -> void:
	boss.is_idle = false
	# 初始化阶段已经校验的吐球效果组件，统一处理嘴部和眼部表现。
	var ball_skill: ZB001DoctorSkillIceFireBall = skill_state.effect_component as ZB001DoctorSkillIceFireBall
	ball_skill.apply_charge_visuals()
	super.enter()


## 正常进入吐球后待机或死亡中断均清理光效，不影响已生成的球和已喷出的粒子。
func exit() -> void:
	# 所属技能的效果组件；停止状态机时也通过同一入口恢复光效默认状态。
	var ball_skill: ZB001DoctorSkillIceFireBall = skill_state.effect_component as ZB001DoctorSkillIceFireBall
	if is_instance_valid(ball_skill):
		ball_skill.reset_charge_visuals()
	super.exit()


## 吐球动作明确要求本体 damage，其余头部阶段仍使用普通操纵动作。
func get_driver_reaction() -> ZB001DoctorAnimationController.DriverReaction:
	return ZB001DoctorAnimationController.DriverReaction.DAMAGE
