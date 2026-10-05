extends BulletEffect000Base
class_name BulletEffect006PeaFire

## 火豌豆命中后的单次消散动画播放器，完成后释放特效。
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 脱离子弹后播放 fire_done，动画完成时独立释放。[br]
## [param is_boss_hit] 原样传给基类，保证火豌豆命中僵王时同样显示在机甲前方。
func activate_bullet_effect(is_boss_hit: bool = false) -> void:
	super(is_boss_hit)
	visible = true
	animation_player.play("fire_done")
	await animation_player.animation_finished
	queue_free()
