extends Zombie000Base
class_name Zombie017Balloon

## 我是僵尸模式气球破裂的位置
@export var balloon_pop_glo_pos_x_in_zombie_mode:float = 50
@export_group("动画状态")
@export var is_pop:=false

func ready_norm():
	super()
	hurt_box_component.position.y -= 20

func _process(_delta: float) -> void:
	## 如果是我是僵尸模式
	if is_zombie_mode:
		if not is_pop and global_position.x < balloon_pop_glo_pos_x_in_zombie_mode:
			hp_component = hp_component as HpComponentZombie
			hp_component.Hp_loss(hp_component.curr_hp_armor1)

## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	hp_component.signal_armor1_death.connect(balloon_pop)
	attack_component.disable_component(ComponentNormBase.E_IsEnableFactor.Balloon)

## 气球破裂
func balloon_pop():
	if not is_death:
		is_pop = true
		#hurt_box_component.position.y += 20
		move_component.update_move_factor(true, MoveComponent.E_MoveFactor.IsAnimGap)
		move_component.update_move_mode(MoveComponent.E_MoveMode.Ground)
		curr_be_attack_status = E_BeAttackStatusZombie.IsNorm
		SoundManager.play_character_SFX(&"balloon_pop")
		if curr_zombie_row_type == EnumsCharacter.ZombieRowType.Pool:
			character_death_disappear()

## 动画调用 气球破裂结束落地,可以移动
func balloon_pop_end():
	move_component.update_move_factor(false, MoveComponent.E_MoveFactor.IsAnimGap)
	attack_component.enable_component(ComponentNormBase.E_IsEnableFactor.Balloon)

## 被三叶草吹走
func be_blow_away():
	move_component.update_move_factor(true, MoveComponent.E_MoveFactor.IsBlover)

	var tween:Tween = create_tween()
	tween.tween_property(self, ^"position:x", position.x+1000, 1)
	tween.tween_callback(character_death_disappear)


## 被冰冻控制
func be_ice_freeze(time:float, new_time_ice_end_decelerate:float):
	be_ice_decelerate(time + new_time_ice_end_decelerate)
