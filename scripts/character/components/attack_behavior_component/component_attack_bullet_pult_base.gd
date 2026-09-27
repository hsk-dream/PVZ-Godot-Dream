extends AttackComponentBulletBase
class_name AttackComponentBulletPultBase
## 投手类子弹攻击组件

## 最后一个目标敌人位置
var last_target_enemy_global_pos :Vector2
var last_target_enemy:Character000Base
## 每次攻击时,先更新最前面敌人
## 攻击间隔后触发执行攻击
func _on_bullet_attack_cd_timer_timeout() -> void:
	last_target_enemy = detect_component.update_first_enemy()
	#print(last_target_enemy)
	if is_instance_valid(last_target_enemy):
		last_target_enemy_global_pos = last_target_enemy.hurt_box_component.global_position
		# 在这里调用实际攻击逻辑
		animation_tree.set(attack_para, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func get_bullet_paras(marker_2d_bullet_glo_pos:Vector2, ray_direction:Vector2) -> Dictionary[Bullet000NormBase.E_InitParasAttr,Variant]:
	var bullet_paras = super(marker_2d_bullet_glo_pos, ray_direction)
	if is_instance_valid(last_target_enemy):
		bullet_paras[Bullet000NormBase.E_InitParasAttr.Enemy] = last_target_enemy
	bullet_paras[Bullet000NormBase.E_InitParasAttr.EnemyGloPos] = last_target_enemy_global_pos
	return bullet_paras
