extends Control
class_name User

const ONE_USER_BUTTON = preload("uid://5yk8fhfwgwo0")

@onready var v_box_container: VBoxContainer = $Panel/PanelContainer/ScrollContainer/VBoxContainer
@onready var button_create: Button = $Panel/PanelContainer/ScrollContainer/VBoxContainer/ButtonCreate
@onready var panel_create_new_user: PanelCreateNewUser = $PanelCreateNewUser
@onready var dialog_create_user: Dialog = $Panel/DialogCreateUser
@onready var dialog_choose_null: Dialog = $Panel/DialogChooseNull
@onready var dialog_error: DialogError = $DialogError
@onready var panel_rename_user: PanleRenameUser = $PanelRenameUser
@onready var dialog_confirm_del: DialogConfirm = $DialogConfirmDel

@onready var texture_button_rename: PVZButtonBase = $Panel/HBoxContainer/TextureButtonRename
@onready var texture_button_ok: PVZButtonBase = $Panel/HBoxContainer/TextureButtonOk
@onready var texture_button_del: PVZButtonBase = $Panel/HBoxContainer/TextureButtonDel
@onready var texture_button_cancel: PVZButtonBase = $Panel/HBoxContainer/TextureButtonCancel

## 所有用户名的button
var all_user_button:Array[OneUserButton] = []
## 当前选择的用户button
var curr_user_button:OneUserButton

func _ready() -> void:
	create_curr_all_user_button()
	Global.user_manager.signal_users_update.connect(update_curr_user_button)
	button_create.pressed.connect(_on_button_create_pressed)

	texture_button_rename.pressed.connect(_on_button_rename_pressed)
	texture_button_ok.pressed.connect(_on_button_ok_pressed)
	texture_button_del.pressed.connect(_on_button_del_pressed)
	texture_button_cancel.pressed.connect(_on_button_cancel_pressed)

	dialog_confirm_del.confirmed.connect(_on_delete_confirmed)

## 新增、删除、改名 更新当前用户按钮
func update_curr_user_button():
	del_curr_all_user_button()
	create_curr_all_user_button()

## 删除所有的用户按钮
func del_curr_all_user_button():
	## 删除当前用户button
	for i in range(all_user_button.size()-1, -1, -1):
		var one_user_button:OneUserButton = all_user_button[i]
		all_user_button.erase(one_user_button)
		one_user_button.queue_free()
	curr_user_button = null

## 创建所有的用户按钮
func create_curr_all_user_button():
	if Global.user_manager.all_user_name.is_empty():
		visible = true
		panel_create_new_user.visible = true
		return

	for i in range(Global.user_manager.all_user_name.size()):
		var one_user_button:OneUserButton = ONE_USER_BUTTON.instantiate()
		v_box_container.add_child(one_user_button)
		all_user_button.append(one_user_button)
		one_user_button.set_button_user_name(Global.user_manager.all_user_name[i])
		one_user_button.pressed.connect(_on_choosed_new_user_button.bind(one_user_button))
		if Global.user_manager.curr_user_name == Global.user_manager.all_user_name[i]:
			curr_user_button = one_user_button
			curr_user_button.on_user_be_choosed()
	v_box_container.move_child(button_create, -1)

## 当点击选择新用户时
func _on_choosed_new_user_button(new_user_button:OneUserButton):
	if curr_user_button != null:
		curr_user_button.on_user_cancel_choosed()
	new_user_button.on_user_be_choosed()
	curr_user_button = new_user_button

## 点击创建新用户时
func _on_button_create_pressed():
	panel_create_new_user.visible = true

## 点击重命名按钮
func _on_button_rename_pressed():
	if curr_user_button == null:
		dialog_choose_null.visible = true
		return
	panel_rename_user.visible = true


## 点击 好 按钮
func _on_button_ok_pressed():
	if curr_user_button == null:
		dialog_choose_null.visible = true
		return

	# 切换用户由 Global 编排存档，用户本身由 user_manager 管理
	Global.save_service.save_now()
	Global.user_manager.set_current_user(curr_user_button.user_name_on_curr_button)
	Global.save_service.load_global_game_data()
	Global.config_service.load_and_apply_config()
	visible = false

## 点击 删除 按钮
func _on_button_del_pressed():
	if curr_user_button == null:
		dialog_choose_null.visible = true
		return

	# 显示确认对话框
	dialog_confirm_del.show_confirm("确定要删除用户 \"" + curr_user_button.user_name_on_curr_button + "\" 吗？\n该操作无法撤销！")

## 确认删除用户
func _on_delete_confirmed():
	if curr_user_button == null:
		return

	var del_user_res = Global.user_manager.delete_user(curr_user_button.user_name_on_curr_button)

	if del_user_res.is_empty():
		pass
	else:
		dialog_error.update_text(del_user_res)
		dialog_error.visible = true

## 点击取消按钮
func _on_button_cancel_pressed():
	if curr_user_button == null:
		dialog_choose_null.visible = true
		return
	if Global.user_manager.curr_user_name.is_empty():
		dialog_create_user.visible = true
		return
	visible = false
