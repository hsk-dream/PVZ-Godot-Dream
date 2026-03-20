extends Zombie000Base
class_name Zombie022Ladder

## 当前可以被搭梯子的植物
var plant_ladder:Plant000Base
@onready var zombie_ladder_1: Sprite2D = $Body/BodyCorrect/Ladder/Zombie_ladder_1

@export_group("动画")
@export var is_place_ladder:bool=false
@export var is_drop_ladder:= false
## 搭梯子失败
@export var is_fail_ladder:=false

## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	hp_component.signal_armor2_death.connect(drop_ladder)
	attack_component = attack_component as AttackComponentZombieLadder
	attack_component.signal_ladder.connect(start_ladder)

## 梯子掉落
func drop_ladder():
	is_drop_ladder = true
	attack_component = attack_component as AttackComponentZombieLadder
	attack_component.is_can_ladder = false
	attack_component.update_is_attack_factors(true, AttackComponentBase.E_IsAttackFactors.Anim)

	move_component.update_move_factor(true, MoveComponent.E_MoveFactor.IsAnimGap)
	await get_tree().create_timer(0.2, false).timeout
	move_component.update_move_factor(false, MoveComponent.E_MoveFactor.IsAnimGap)


## 检测到可以搭梯子的植物,开始搭梯子,
func start_ladder(plant:Plant000Base):
	plant_ladder = plant
	is_place_ladder = true
	attack_component.update_is_attack_factors(false, AttackComponentBase.E_IsAttackFactors.Anim)
	is_fail_ladder = false
	SoundManager.play_character_SFX(&"ladder_zombie")

## 搭梯子,同时搭梯子动画结束
func ladder_once():
	if is_instance_valid(plant_ladder) and not plant_ladder.plant_cell.ladder and not is_drop_ladder:
		plant_ladder.plant_cell.be_ladder()
		hp_component.Hp_loss(hp_component.curr_hp_armor2, EnumsBullet.AttackMode.Norm, false, false, false)
	else:
		is_fail_ladder = true
		is_place_ladder = false
	attack_component.update_is_attack_factors(true, AttackComponentBase.E_IsAttackFactors.Anim)
