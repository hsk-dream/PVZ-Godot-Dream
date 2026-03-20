extends Plant000Base
class_name Plant047SpikeRock

@onready var detect_component: DetectComponent = $DetectComponent

@export var attack_value:=20
@export_group("动画状态")
@export var is_attack:=false

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
	var all_enemy_can_be_attacked = detect_component.get_all_enemy_can_be_attacked()
	for i in range(all_enemy_can_be_attacked.size() - 1, -1, -1):
		var enemy:Character000Base = all_enemy_can_be_attacked[i]
		if enemy is Zombie000Base:
			var zombie = enemy as Zombie000Base
			zombie.be_attacked_bullet(attack_value, EnumsBullet.AttackMode.Real, true, true)

## 被压扁
## [character:Character000Base] 发动攻击的角色
func be_flattened_from_enemy(character:Character000Base):
	character.be_caltrop()
	hp_component.Hp_loss(int(hp_component.max_hp/9.0), EnumsBullet.AttackMode.Norm, true)
