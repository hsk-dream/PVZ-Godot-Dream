extends AttackComponentBulletBase
class_name AttackComponentBulletSplitPea


## 攻击间隔后触发执行攻击
func _on_bullet_attack_cd_timer_timeout() -> void:
	# 在这里调用实际攻击逻辑
	animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	animation_tree.set("parameters/OneShot 2/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func set_cancel_attack():
	#animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	#animation_tree.set("parameters/OneShot 2/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	pass

## 发射子弹（动画调用）
func _shoot_bullet():
	var bullet:Bullet000Base = Global.bullet_registry.get_bullet_scenes(attack_bullet_type).instantiate()
	var ray_direction = detect_component.ray_area_direction[0]
	## 子弹初始位置
	var bullet_pos_ori = markers_2d_bullet[0].global_position
	var bullet_paras = {
		Bullet000Base.E_InitParasAttr.BulletLane : owner.lane,
		Bullet000Base.E_InitParasAttr.Position :  bullets.to_local(bullet_pos_ori),
		Bullet000Base.E_InitParasAttr.Direction : ray_direction
	}
	bullet.init_bullet(bullet_paras)
	bullets.add_child(bullet)
	play_throw_sfx()

## 发射子弹2（动画调用）
func _shoot_bullet_2():
	var bullet:Bullet000Base = Global.bullet_registry.get_bullet_scenes(attack_bullet_type).instantiate()
	var ray_direction = detect_component.ray_area_direction[1]
	## 子弹初始位置
	var bullet_pos_ori = markers_2d_bullet[1].global_position
	var bullet_paras = {
		Bullet000Base.E_InitParasAttr.BulletLane : owner.lane,
		Bullet000Base.E_InitParasAttr.Position :  bullets.to_local(bullet_pos_ori),
		Bullet000Base.E_InitParasAttr.Direction : ray_direction
	}
	bullet.init_bullet(bullet_paras)
	bullets.add_child(bullet)
	play_throw_sfx()
