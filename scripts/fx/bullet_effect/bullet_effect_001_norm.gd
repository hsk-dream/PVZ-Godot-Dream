extends BulletEffect000Base
class_name BulletEffect001Norm
## 通用子弹(普通子弹)特效

@onready var all_particles_2d: Node2D = $AllParticles2D
@onready var splats: Sprite2D = get_node_or_null(^"Splats")

## 播放命中溅射贴图和一次性粒子，结束后独立释放。[br]
## [param is_boss_hit] 原样传给基类设置显示层级，不改变粒子播放时长。
func activate_bullet_effect(is_boss_hit: bool = false) -> void:
	super(is_boss_hit)
	visible = true
	# 命中特效中的各粒子发射器，本次激活后同时开始播放。
	for gpu_particles_2d in all_particles_2d.get_children():
		gpu_particles_2d.emitting = true
	await get_tree().create_timer(0.2).timeout
	if splats:
		splats.visible = false
	if all_particles_2d.get_child_count() != 0:
		await get_tree().create_timer(all_particles_2d.get_child(0).lifetime).timeout
	queue_free()
