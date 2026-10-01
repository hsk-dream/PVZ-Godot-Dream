## 单次僵王局部爆炸：依次播放闪光、火团和烟团，淡出后自行释放，不负责选点或伤害。
extends Node2D
class_name ZB001DoctorDeathExplosionEffect

## 单次爆炸消散后发出，随后释放本实例，供死亡状态移除速度同步引用。
signal finished

## 当前独立播放倍率；0 冻结本次动画，全局 Engine.time_scale 不在此重复计算。
var _speed_scale: float = 1.0
## 单次爆炸动画的速度，生成方可同步博士死亡倍率；修改时保留当前进度。
@export_range(0.0, 8.0, 0.05, "or_greater") var speed_scale: float = 1.0:
	get:
		return _speed_scale
	# value 是检查器或调用方写入的新倍率，由统一入口验证并同步到正在播放的节点。
	set(value):
		set_speed_scale(value)

## 是否正在播放，防止重复启动或迟到的动画通知再次触发完成事件。
var _is_playing: bool = false

## 本次爆炸的独立播放器，动画时长与贴图切换均在特效场景中配置。
@onready var animation_player: AnimationPlayer = $AnimationPlayer


## 初始保持隐藏，不自动播放或生成预览；由僵王生成方显式调用 [method play]。
func _ready() -> void:
	visible = false
	animation_player.speed_scale = _speed_scale


## 从首帧开始播放一次；必须在节点 ready 后调用，位置和大小由死亡状态设置，重复调用忽略。
## 同步首帧后才显示，避免初始姿势闪现；播放完成后实例自动释放。
func play() -> void:
	if _is_playing or not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(animation_player):
		return
	_is_playing = true
	animation_player.stop()
	animation_player.speed_scale = _speed_scale
	animation_player.play(&"explode")
	animation_player.advance(0.0)
	visible = true


## [param value] 为有限非负的独立倍率；只调整当前动画速度，不重播动画。
func set_speed_scale(value: float) -> void:
	if not is_finite(value) or value < 0.0:
		push_error("ZB001DoctorDeathExplosionEffect：播放倍率必须为有限非负数。")
		return
	_speed_scale = value
	if is_instance_valid(animation_player):
		animation_player.speed_scale = value


## [param animation_name] 为结束的动画名称；只处理正在播放的单次爆炸。
func _on_animation_finished(animation_name: StringName) -> void:
	if not _is_playing or animation_name != &"explode":
		return
	_is_playing = false
	visible = false
	finished.emit()
	queue_free()
