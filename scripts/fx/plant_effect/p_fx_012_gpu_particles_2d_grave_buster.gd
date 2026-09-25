extends GPUParticles2D
class_name GPUParticles2DGraveBuster

## 2秒后删除自身
func free_self_after_two_sec():
	await get_tree().create_timer(2.0).timeout
	queue_free()
