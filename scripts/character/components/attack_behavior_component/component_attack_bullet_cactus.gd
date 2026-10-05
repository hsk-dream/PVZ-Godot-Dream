extends AttackComponentBulletBase
class_name AttackComponentBulletCactus

var is_rise:= false

func _ready() -> void:
	super()
	can_attack_zombie_status = 1

## 攻击间隔后触发执行攻击
func _on_bullet_attack_cd_timer_timeout() -> void:
	if is_rise:
		animation_tree.set("parameters/StateMachine/BlendTree 2/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		animation_tree.set("parameters/StateMachine/BlendTree/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func set_cancel_attack():
	animation_tree.set("parameters/StateMachine/BlendTree/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	animation_tree.set("parameters/StateMachine/BlendTree 2/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

## 当仙人掌起落时
func on_cactus_update_is_rise(value:bool):
	is_rise = value

## 升降结束后更新后续发射子弹的可攻击僵尸状态。
## [param value] 为 true 时只攻击空中僵尸，为 false 时恢复只攻击正常状态僵尸。
func update_bullet_can_attack_zombie_status(value:bool):
	if value:
		can_attack_zombie_status = 8
	else:
		# 恢复正常状态，避免对空状态取反后额外允许水下、地下等状态。
		can_attack_zombie_status = 1
	print(can_attack_zombie_status)
