extends Plant000Base
class_name Plant007Chomper

## 咬合时重新查询范围内目标，避免攻击已抬头的僵王。
@onready var detect_component: DetectComponent = $DetectComponent

## 咀嚼时间计时器
@onready var chew_timer: SpeedTimer = $ChewTimer
## 啃咬伤害
@export var eat_attack:int = 1800
## 吞咽后的咀嚼秒数；咬中僵王时作为同等时长的攻击恢复间隔。
@export var eat_CD :float = 5

@export_group("动画状态")
## 是否啃咬
@export var is_bite := false
## 是否咀嚼
@export var is_chewing = false


func ready_norm() -> void:
	super()
	## 基础咀嚼时间不含倍率，进入角色时同步已有速度因素。
	chew_timer.base_wait_time = eat_CD
	owner_update_speed(GlobalUtils.get_dic_product(influence_speed_factors))

func ready_norm_signal_connect():
	super()
	signal_update_speed.connect(owner_update_speed)
	detect_component.signal_can_attack.connect(change_is_attack.bind(true))

## 速度改变保留剩余咀嚼进度，零速由计时器暂停，避免除零。
func owner_update_speed(speed_product:float):
	chew_timer.set_speed_scale(speed_product)

## 改变是否正在攻击,即攻击范围内是否有敌人
func change_is_attack(is_attack:bool):
	if is_attack:
		## 不在咀嚼状态,并且不在啃咬状态
		if not is_chewing and not is_bite:
			is_bite = true

## 咀嚼完成
func _on_chew_timer_timeout() -> void:
	is_chewing = false
#endregion

#region 动画轨道调用
## 吞咽动画结束
func swallow_end():
	if is_instance_valid(detect_component.update_first_enemy()):
		is_bite = true

## 啃咬动画结束
func bite_end():
	is_bite = false
	## 如果没有啃咬到僵尸
	if not is_chewing:
		if is_instance_valid(detect_component.update_first_enemy()):
			is_bite = true
#endregion

## 咬合关键帧重新选取有效目标；僵王只扣血，不吞掉或直接删除，命中后沿用咀嚼冷却。
func _eat_zombie():
	SoundManager.play_character_SFX(&"BigChomp")
	# 当前关键帧仍处于攻击范围和受击窗口内的目标。
	var enemy: Character000Base = detect_component.update_first_enemy()
	if enemy is ZB000Base:
		enemy.be_attacked_bullet(eat_attack, BulletRegistry.AttackMode.Penetration, false, false)
	elif enemy is Zombie000Base:
		enemy.be_chomper_eat(eat_attack)
	else:
		return
	chew_timer.start_scaled()
	is_chewing = true
