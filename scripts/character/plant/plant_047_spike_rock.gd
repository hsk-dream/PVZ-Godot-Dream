extends Plant000Base
class_name Plant047SpikeRock

## 攻击关键帧查询可受击目标的范围检测组件。
@onready var detect_component: DetectComponent = $DetectComponent

## 每次攻击造成的真实伤害。
@export var attack_value:=20
@export_group("动画状态")
## 范围内存在可攻击目标时播放攻击动画。
@export var is_attack:=false

## 按剩余耐久切换地刺王外观的组件。
@onready var hp_stage_change_component: HpStageChangeComponent = $HpStageChangeComponent


## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	detect_component.signal_can_attack.connect(func():is_attack = true)
	detect_component.signal_not_can_attack.connect(func():is_attack = false)

	hp_component.signal_hp_loss.connect(hp_stage_change_component.judge_body_change)

## 攻击一次
func _attack_once():
	SoundManager.play_character_SFX("Throw")
	# 检测组件已按角色去重，并过滤僵王的关闭受击状态。
	var targets: Array[Character000Base] = detect_component.get_all_enemy_can_be_attacked()
	# 前一个目标死亡可能影响后续引用，检查有效性后才执行伤害。
	for target_reference: Variant in targets:
		if not is_instance_valid(target_reference):
			continue
		# 主动攻击兼容僵王；地刺王被碾压时的耐久处理保持独立。
		var enemy := target_reference as Character000Base
		if (enemy is Zombie000Base or enemy is ZB000Base) and not enemy.is_death and not enemy.is_queued_for_deletion():
			enemy.be_attacked_bullet(attack_value, BulletRegistry.AttackMode.Real, true, true)

## 被压扁
## [character:Character000Base] 发动攻击的角色
func be_flattened_from_enemy(character:Character000Base):
	character.be_caltrop()
	hp_component.Hp_loss(int(hp_component.max_hp/9.0),BulletRegistry.AttackMode.Norm, true)
