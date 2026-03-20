extends Node2D
class_name Trophy

@onready var main_game: MainGameManager

@onready var pick_up_glow: Sprite2D = $PickUpGlow

@onready var all_rays: Node2D = $AllRays
@onready var glow: Node2D = $Glow

func _ready():
	main_game = get_tree().current_scene
	var tween = create_tween()
	tween.tween_property(pick_up_glow, "scale", Vector2(1.5, 1.5), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pick_up_glow, "scale", Vector2(1, 1), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()  # 无限循环
	Global.save_service.save_now()

func _on_trophy_button_pressed() -> void:
	SoundManager.play_other_SFX("winmusic")
	$TrophyButton.disabled = true
	var center = get_viewport().get_visible_rect().size / 2 + Global.main_game.camera_2d.global_position
	var tween = create_tween()
	tween.tween_property(self, "position", center, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	all_rays.visible = true
	for ray in all_rays.get_children():
		var tween_rays1 = create_tween()
		# 无限循环旋转
		tween_rays1.tween_property(ray, "rotation", ray.rotation + TAU, 5.0) \
			.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		var tween_rays2 = create_tween()
		# 无限放大
		tween_rays2.tween_property(ray, "scale", Vector2(10, 10), 5.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	glow.visible = true
	var tween_glow = create_tween()
	tween_glow.tween_property(glow, "modulate:a", 1, 5.0)

	await get_tree().create_timer(5.0).timeout
	EventBus.push_event("win_main_game")


func _on_trophy_button_mouse_entered() -> void:
	## 如果有锤子
	if main_game.game_item_manager.all_game_items.has(GameItemManager.E_GameItemType.Hammer):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
