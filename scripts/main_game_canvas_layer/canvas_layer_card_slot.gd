extends CanvasLayer
class_name CanvasLayerCardSlot

@onready var card_slot_root: CardSlotRoot = %CardSlotRoot


func _ready() -> void:
	Global.config_service.signal_change_card_slot_top_mouse_focus.connect(card_slot_top_mouse_focus)
	card_slot_root.mouse_entered.connect(_on_bg_mouse_entered)
	card_slot_root.mouse_exited.connect(_on_bg_mouse_exited)
	EventBus.subscribe("main_game_progress_update", _on_main_game_progress_update)

#region 卡槽处于焦点时置顶
func _on_bg_mouse_entered() -> void:
	if Global.config_service.card_slot_top_mouse_focus and Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		# 鼠标进入时，提高z_index，保证在前面显示
		layer = 10

func _on_bg_mouse_exited() -> void:
	if Global.config_service.card_slot_top_mouse_focus and Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		# 鼠标离开时，恢复原始
		layer = -1

## 修改控制台按钮时
## 植物卡槽取消置顶,取消鼠标焦点卡槽置顶时
func card_slot_top_mouse_focus():
	if not Global.config_service.card_slot_top_mouse_focus and Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.MAIN_GAME:
		layer = -1

#endregion

## 当主游戏场景进度更新时
func _on_main_game_progress_update(main_game_progress:MainGameManager.E_MainGameProgress):
	match main_game_progress:
		MainGameManager.E_MainGameProgress.NONE, MainGameManager.E_MainGameProgress.GAME_OVER:
			pass
		MainGameManager.E_MainGameProgress.CHOOSE_CARD,MainGameManager.E_MainGameProgress.PREPARE, MainGameManager.E_MainGameProgress.RE_CHOOSE_CARD:
			layer = 10
		MainGameManager.E_MainGameProgress.MAIN_GAME:
			layer = -1

