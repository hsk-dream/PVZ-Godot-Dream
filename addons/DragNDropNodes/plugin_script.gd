@tool
extends EditorPlugin

var class_tree
const ClassTree = preload("./class_tree.gd") 

func _enter_tree() -> void:
	_setup_editor_nodes()
	
	class_tree = ClassTree.new(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, class_tree)

func _exit_tree() -> void:
	remove_control_from_docks(class_tree)
	class_tree.queue_free()

func _setup_editor_nodes() -> void:
	var base = get_editor_interface().get_base_control()
	var results = base.find_children("*", "SceneTreeEditor", true, false)
	if not results.is_empty():
		Engine.set_meta("SceneTreeEditor", results[0])
	Engine.set_meta("EditorNode", get_window().get_child(0, true))
