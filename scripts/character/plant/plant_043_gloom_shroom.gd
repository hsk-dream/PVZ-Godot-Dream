extends Plant000Base
class_name Plant043GloomShroom

@onready var attack_component: AttackComponentBulletBase = $AttackComponent
@onready var all_bullet_fx: Array[Node2D] = [%Bullet_FX, %Bullet_FX2, %Bullet_FX3, %Bullet_FX4]
var all_bullet_fx_particles :Array[Array]
var num_attack :int = 0

func ready_norm():
	super()
	for bullet_fx in all_bullet_fx:
		var bullet_fx_particles :Array[GPUParticles2D] = []
		for p in bullet_fx.get_children():
			bullet_fx_particles.append(p)
		all_bullet_fx_particles.append(bullet_fx_particles)

## 初始化正常出战角色信号连接
func ready_norm_signal_connect():
	super()
	signal_update_speed.connect(attack_component.owner_update_speed)


func attack_once():
	var bullet_fx_particles :Array[GPUParticles2D] = all_bullet_fx_particles[num_attack]
	for p:GPUParticles2D in bullet_fx_particles:
		p.amount_ratio = [0.6, 0.8, 1.0].pick_random()
		p.emitting = true
	num_attack = wrapi(num_attack+1, 0, all_bullet_fx_particles.size())

	var all_enemy:Array[Character000Base] = attack_component.detect_component.get_all_enemy_can_be_attacked()
	for enemy in all_enemy:
		enemy.be_attacked_bullet(20, EnumsBullet.AttackMode.Penetration)
