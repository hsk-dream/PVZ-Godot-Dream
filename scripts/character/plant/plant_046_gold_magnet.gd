extends Plant000Base
class_name Plant046GoldMagnet

@onready var animation_tree: AnimationTree = $AnimationTree

@onready var marker_2d_coin: Marker2D = $Body/BodyCorrect/Marker2DCoin
var attack_cd_timer:Timer

@export var attack_cd:float = 5

func ready_norm():
	super()
	attack_cd_timer = Timer.new()

	attack_cd_timer.wait_time = attack_cd
	attack_cd_timer.one_shot = false
	attack_cd_timer.autostart = true
	add_child(attack_cd_timer)
	# 连接超时信号
	attack_cd_timer.timeout.connect(_on_attack_cd_timer_timeout)


## 攻击间隔后触发执行攻击
func _on_attack_cd_timer_timeout() -> void:
	# 在这里调用实际攻击逻辑
	animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## 吸收金币一次
func attack_once():
	EventBus.push_event("gold_magnet_attract_once", marker_2d_coin.global_position)

