@tool
class_name ClassTree
extends VBoxContainer

# Variable Declarations
var root: TreeItem
var editor_interface: EditorInterface  # Reference to the EditorInterface
var search_bar: LineEdit              # The search bar
var tree: Tree                        # The tree displaying nodes
var full_node_list: Array = []        # Full list of node classes
var root_items_collapsed_state = {
	"Popular": true,
	"2D Nodes": true,
	"3D Nodes": true,
	"Misc": true,
	"All Nodes": true,
}
var is_search_active = false
var descriptions={
	"Node": "The base class for all scene objects. Handles hierarchies and the basic scene lifecycle.",
	"AcceptDialog": "A dialog with a confirmation button, often used for simple alerts or confirmations.",
	"AnimatableBody2D": "A 2D physics body whose transform can be directly animated.",
	"AnimatableBody3D": "A 3D physics body whose transform can be directly animated.",
	"AnimatedSprite2D": "Displays a sequence of textures as a 2D animation.",
	"AnimatedSprite3D": "Displays animated textures in 3D space, useful for billboard-like animations.",
	"AnimationPlayer": "Plays back animations stored in Animation resources, controlling timelines of properties.",
	"AnimationTree": "Allows blending and transitioning between multiple animations using a graph interface.",
	"Area2D": "A 2D detection and influence area, can detect bodies and influence physics properties.",
	"Area3D": "A 3D volume that can detect bodies and apply effects such as gravity or audio reverb.",
	"AspectRatioContainer": "A UI container that maintains a constant aspect ratio for its children.",
	"AudioListener2D": "Defines how 2D audio is perceived from a given point, affecting panning and volume.",
	"AudioListener3D": "Defines the listener’s position in 3D space, affecting spatial audio perception.",
	"AudioStreamPlayer": "Plays audio streams (like WAV or OGG) in a non-positional context.",
	"AudioStreamPlayer2D": "Plays audio streams in 2D space, allowing positional audio effects.",
	"AudioStreamPlayer3D": "Plays audio streams in 3D space for spatialized audio experiences.",
	"BackBufferCopy": "Copies the back buffer content, useful for post-processing effects.",
	"BaseButton": "A base class for button nodes, handling common button states and behaviors.",
	"Bone2D": "Represents a single bone in a 2D skeleton, used for skeletal animations.",
	"BoneAttachment3D": "Attaches a node to a skeleton bone in 3D, making it move with that bone.",
	"BoxContainer": "A UI container arranging its children in a single horizontal or vertical line.",
	"Button": "A clickable UI element that can trigger actions when pressed.",
	"CPUParticles2D": "A CPU-based 2D particle system for effects like smoke, sparks, or fire.",
	"CPUParticles3D": "A CPU-based 3D particle system for volumetric effects in three dimensions.",
	"CSGBox3D": "A CSG node that creates a simple 3D box shape.",
	"CSGCombiner3D": "Combines multiple CSG shapes using union, intersect, or subtract operations.",
	"CSGCylinder3D": "A CSG node that creates a 3D cylindrical shape.",
	"CSGMesh3D": "Imports a Mesh as a CSG shape for boolean operations.",
	"CSGPolygon3D": "Defines a polygon to extrude or revolve for CSG operations.",
	"CSGSphere3D": "A CSG node that creates a spherical shape.",
	"CSGTorus3D": "A CSG node that creates a torus (doughnut-shaped) mesh.",
	"Camera2D": "Renders a certain area of the 2D scene, supporting zoom and panning.",
	"Camera3D": "Renders the 3D scene from a given viewpoint.",
	"CanvasGroup": "Allows grouping UI elements and controlling their opacity together.",
	"CanvasLayer": "Renders its children on a separate layer, useful for HUDs or overlays.",
	"CanvasModulate": "Applies a color modulation to an entire canvas layer.",
	"CenterContainer": "Centers its child control both horizontally and vertically.",
	"CharacterBody2D": "A specialized 2D physics body for characters, simplifying movement and collision handling.",
	"CharacterBody3D": "A specialized 3D physics body for characters, easing movement and collision handling in 3D.",
	"CheckBox": "A toggleable check box UI element, can be on or off.",
	"CheckButton": "A toggleable button that functions like a check box but has a button-like appearance.",
	"CodeEdit": "A text editor control optimized for editing code, with features like syntax highlighting.",
	"CollisionPolygon2D": "Defines a custom polygonal collision shape in 2D.",
	"CollisionPolygon3D": "Defines a custom polygonal collision shape in 3D.",
	"CollisionShape2D": "Defines a simple 2D collision shape (e.g., rectangle, circle).",
	"CollisionShape3D": "Defines a simple 3D collision shape (e.g., box, sphere).",
	"ColorPicker": "A UI element for selecting colors interactively.",
	"ColorPickerButton": "A button that opens a ColorPicker dialog when pressed.",
	"ColorRect": "Displays a solid color rectangle, often used for backgrounds or indicators.",
	"ConeTwistJoint3D": "A 3D joint allowing constrained rotations, often used for limbs in ragdolls.",
	"ConfirmationDialog": "A dialog with OK/Cancel buttons, commonly used to confirm actions.",
	"Container": "A base UI class that controls the arrangement of its child elements.",
	"Control": "The base class for all GUI elements, handling sizing and anchoring.",
	"DampedSpringJoint2D": "A 2D joint that behaves like a spring with damping, connecting two physics bodies.",
	"Decal": "A 3D node projecting textures onto surfaces, useful for details like bullet holes.",
	"DirectionalLight2D": "A 2D light affecting the entire scene from a given direction.",
	"DirectionalLight3D": "A 3D light simulating sunlight or distant light sources.",
	"FileDialog": "A dialog for selecting files or directories.",
	"FlowContainer": "A container that arranges children in a flow, wrapping to the next line as needed.",
	"FogVolume": "Defines a 3D volumetric fog region for atmospheric effects.",
	"GPUParticles2D": "A GPU-accelerated 2D particle system, more efficient than CPU-based particles.",
	"GPUParticles3D": "A GPU-accelerated 3D particle system for large, complex effects.",
	"GPUParticlesAttractorBox3D": "A box-shaped field attracting 3D GPU particles.",
	"GPUParticlesAttractorSphere3D": "A spherical field attracting 3D GPU particles inward.",
	"GPUParticlesAttractorVectorField3D": "Influences 3D GPU particles using a vector field.",
	"GPUParticlesCollisionBox3D": "A box-shaped collision area for GPU 3D particles.",
	"GPUParticlesCollisionHeightField3D": "Uses a height map for GPU 3D particle collisions.",
	"GPUParticlesCollisionSDF3D": "Uses a Signed Distance Field for GPU 3D particle collisions.",
	"GPUParticlesCollisionSphere3D": "A spherical collision area for GPU 3D particles.",
	"Generic6DOFJoint3D": "A 3D joint offering six degrees of freedom, allowing complex movement constraints.",
	"GeometryInstance3D": "A base for 3D visual instances, often used to display meshes or geometry.",
	"GraphEdit": "A control for creating and editing graphs of nodes and connections.",
	"GraphElement": "A base class for elements placed inside a GraphEdit.",
	"GraphFrame": "A frame that visually groups or separates graph elements in a GraphEdit.",
	"GraphNode": "A draggable, connectable node used within GraphEdit.",
	"GridContainer": "Arranges its children in a grid layout, specifying columns.",
	"GridMap": "A 3D grid-based layout tool for placing meshes to form environments.",
	"GrooveJoint2D": "A 2D joint allowing a body to move along a predefined groove or path.",
	"HBoxContainer": "A container arranging its children in a horizontal line.",
	"HFlowContainer": "A container that arranges children horizontally and wraps them to a new line when out of space.",
	"HScrollBar": "A horizontal scrollbar for navigating wide content.",
	"HSeparator": "A horizontal line used to separate UI elements visually.",
	"HSlider": "A horizontal slider for selecting a value within a range.",
	"HSplitContainer": "Splits the available space into two panes horizontally.",
	"HTTPRequest": "Performs HTTP requests to fetch or send data over the internet.",
	"HingeJoint3D": "A 3D joint allowing rotation around one axis, like a door hinge.",
	"ImporterMeshInstance3D": "Instantiates a mesh imported from a 3D asset file.",
	"ItemList": "A UI element listing items that can be selected, scrolled, and managed.",
	"Label": "Displays text in the UI, supporting alignment, themes, and wrapping.",
	"Label3D": "A label that places text in 3D space, visible from the camera’s perspective.",
	"LightOccluder2D": "Used with 2D lights to define areas that block light, creating shadows.",
	"LightmapGI": "Manages precomputed lightmaps for global illumination in 3D scenes.",
	"LightmapProbe": "Used in 3D scenes for advanced lighting, storing and applying lightmap data.",
	"Line2D": "Draws a line in 2D with customizable thickness, color, and pattern.",
	"LineEdit": "A single-line text input field, often used for entering short strings.",
	"LinkButton": "A clickable button styled like a hyperlink, often leading to URLs or actions.",
	"MarginContainer": "A container that adds margin around its children.",
	"Marker2D": "A 2D marker node used as a reference point or placeholder in the scene.",
	"Marker3D": "A 3D marker node for placing reference points or markers in 3D space.",
	"MenuBar": "A horizontal bar containing multiple menus and options.",
	"MenuButton": "A button that, when pressed, displays a popup menu of selectable items.",
	"MeshInstance2D": "Displays a 2D mesh resource, useful for custom shapes or polygons.",
	"MeshInstance3D": "Displays a 3D mesh resource in the scene, can be a model or shape.",
	"MultiMeshInstance2D": "Displays multiple instances of a mesh in 2D, improving rendering performance.",
	"MultiMeshInstance3D": "Displays many instances of a 3D mesh efficiently, useful for large scenes.",
	"MultiplayerSpawner": "Used in multiplayer contexts to spawn nodes for different players or peers.",
	"MultiplayerSynchronizer": "Synchronizes node properties or states across multiple clients in a multiplayer game.",
	"NavigationAgent2D": "A 2D navigation agent that finds paths and moves along them, avoiding obstacles.",
	"NavigationAgent3D": "A 3D navigation agent for pathfinding and obstacle avoidance in 3D environments.",
	"NavigationLink2D": "Connects two navigation regions in 2D, allowing agents to move between them.",
	"NavigationLink3D": "Connects two navigation regions in 3D for agents to traverse seamlessly.",
	"NavigationObstacle2D": "Defines a 2D obstacle that affects navigation paths, making agents avoid it.",
	"NavigationObstacle3D": "Defines a 3D obstacle for navigation, altering pathfinding routes.",
	"NavigationRegion2D": "A region that defines navigable areas for pathfinding in 2D.",
	"NavigationRegion3D": "A region in 3D space that agents can navigate through.",
	"NinePatchRect": "A UI control that stretches a texture using a 9-slice technique.",
	"Node2D": "A 2D node with position, rotation, and scale, forms the basis of 2D scenes.",
	"Node3D": "A 3D node that can be positioned, rotated, and scaled in 3D space.",
	"OccluderInstance3D": "Used to define geometry that can occlude (block) objects behind it, optimizing rendering.",
	"OmniLight3D": "A point light that shines equally in all directions in a 3D scene.",
	"OpenXRCompositionLayerCylinder": "A specialized XR layer rendering on a curved cylinder surface.",
	"OpenXRCompositionLayerEquirect": "An XR layer that displays images in an equirectangular format for VR/AR.",
	"OpenXRCompositionLayerQuad": "A flat, rectangular layer displayed in VR/AR contexts.",
	"OpenXRHand": "Represents a tracked hand in an XR environment, providing hand pose and finger positions.",
	"OptionButton": "A drop-down button that lets users pick from multiple options.",
	"OrchestratorAboutDialog": "A dialog showing about information for the Orchestrator tool/plugin.",
	"OrchestratorBuildOutputPanel": "A panel displaying build or compilation output logs.",
	"OrchestratorFileDialog": "A file dialog integrated into the Orchestrator tool for selecting files.",
	"OrchestratorGettingStarted": "A panel or dialog providing getting-started information and instructions.",
	"OrchestratorGotoNodeDialog": "A dialog that helps quickly navigate to a specific node in a project.",
	"OrchestratorGraphActionMenu": "A context menu providing actions related to graph editing in Orchestrator.",
	"OrchestratorGraphEdit": "A specialized GraphEdit control for Orchestrator workflows.",
	"OrchestratorGraphKnot": "A utility node in Orchestrator’s graph system, for rerouting connections.",
	"OrchestratorGraphNode": "A node representing functions, variables, or logic in Orchestrator graphs.",
	"OrchestratorGraphNodeComment": "A comment box for annotating Orchestrator graphs.",
	"OrchestratorGraphNodeDefault": "A default type of graph node used as a basic building block in Orchestrator.",
	"OrchestratorGraphNodePin": "Represents a connection point on a graph node for linking data or signals.",
	"OrchestratorGraphNodePinBitField": "A pin type handling bitfields, allowing complex flag-based data input/output.",
	"OrchestratorGraphNodePinBool": "A pin handling boolean values (true/false).",
	"OrchestratorGraphNodePinColor": "A pin handling color data, useful for passing color values in a graph.",
	"OrchestratorGraphNodePinEnum": "A pin handling enumerations, restricting data to predefined options.",
	"OrchestratorGraphNodePinExec": "A pin handling execution flow in Orchestrator’s visual logic.",
	"OrchestratorGraphNodePinFile": "A pin handling file paths or resources in the graph.",
	"OrchestratorGraphNodePinInputAction": "A pin handling input action references, used in input event graphs.",
	"OrchestratorGraphNodePinNodePath": "A pin handling NodePath references to nodes in the scene.",
	"OrchestratorGraphNodePinNumeric": "A pin handling numeric values (integers, floats).",
	"OrchestratorGraphNodePinObject": "A pin referencing objects or instances.",
	"OrchestratorGraphNodePinString": "A pin handling string data.",
	"OrchestratorGraphNodePinStruct": "A pin handling structured data types or dictionaries.",
	"OrchestratorPlugin": "Represents the Orchestrator editor plugin, providing various tools and panels.",
	"OrchestratorPropertySelector": "A UI element for selecting properties of nodes or objects.",
	"OrchestratorSceneNodeSelector": "A UI element for choosing nodes from the current scene.",
	"OrchestratorScreenSelect": "A tool for screen-based selections or navigation in Orchestrator.",
	"OrchestratorScriptAutowireSelections": "Handles automatic wiring of script-related pins or connections.",
	"OrchestratorScriptComponentPanel": "A panel displaying script components, variables, or functions.",
	"OrchestratorScriptConnectionsDialog": "A dialog listing and managing script connections or signals.",
	"OrchestratorScriptFunctionsComponentPanel": "A panel dedicated to script functions and their logic.",
	"OrchestratorScriptGraphsComponentPanel": "A panel for viewing and editing script-based graphs.",
	"OrchestratorScriptMacrosComponentPanel": "A panel handling script macros, reusable code snippets, or directives.",
	"OrchestratorScriptSignalsComponentPanel": "Displays and manages signals defined in scripts.",
	"OrchestratorScriptVariablesComponentPanel": "Displays and allows editing of script variables and their values.",
	"OrchestratorSelectTypeSearchDialog": "A dialog for searching and selecting types or classes in Orchestrator.",
	"OrchestratorUpdaterButton": "A button triggering Orchestrator updates, checks for new versions.",
	"OrchestratorUpdaterReleaseNotesDialog": "Displays release notes when updating Orchestrator.",
	"OrchestratorUpdaterVersionPicker": "A UI for selecting specific versions of Orchestrator to install.",
	"OrchestratorWindowWrapper": "A wrapper node integrating Orchestrator panels into a window-like container.",
	"Panel": "A basic UI panel with a background, useful as a container or base for other controls.",
	"PanelContainer": "A container that automatically draws a panel behind its children.",
	"Parallax2D": "A node that creates a 2D parallax scrolling effect with multiple layers.",
	"ParallaxBackground": "A background node that creates a parallax effect by scrolling different layers at varying speeds.",
	"ParallaxLayer": "A single layer of a parallax background, offsetting and scaling its movement.",
	"Path2D": "Defines a 2D curve that other nodes (like PathFollow2D) can follow.",
	"Path3D": "Defines a 3D curve for nodes to follow, useful for paths and animations.",
	"PathFollow2D": "Makes a node follow a 2D path, controlling its position along a curve.",
	"PathFollow3D": "Allows a node to follow a 3D path defined by a curve.",
	"PhysicalBone2D": "A 2D bone integrated with the physics system, useful for ragdoll effects.",
	"PhysicalBone3D": "A 3D bone that interacts with physics, enabling skeletal physics simulations.",
	"PhysicalBoneSimulator3D": "Manages multiple PhysicalBone3D nodes for complex ragdoll or skeletal physics.",
	"PinJoint2D": "A 2D joint connecting two bodies at a point, restricting their relative movement.",
	"PinJoint3D": "A 3D joint fixing two bodies together at a point, limiting their relative motion.",
	"PointLight2D": "A 2D light that shines outward from a single point, illuminating areas around it.",
	"Polygon2D": "Draws a polygon in 2D space, can be filled and textured for various shapes.",
	"Popup": "A base class for popups, UI windows that appear above other controls.",
	"PopupMenu": "A popup that displays a list of options or actions for selection.",
	"PopupPanel": "A simple popup with a panel background, useful for dialogs or tooltips.",
	"ProgressBar": "A UI element that displays progress, often from 0% to 100%.",
	"Range": "A base class for controls that represent a floating-point value in a range, like sliders.",
	"RayCast2D": "Casts an invisible ray in 2D and detects what it hits, used for line-of-sight or collision checks.",
	"RayCast3D": "Casts a ray in 3D space to detect intersections with objects.",
	"ReferenceRect": "A rectangle used as a reference or guide in UI layouts.",
	"ReflectionProbe": "Captures a static reflection of the surroundings for use in PBR materials.",
	"RemoteTransform2D": "Applies this node’s transform to a target Node2D, syncing their transforms.",
	"RemoteTransform3D": "Applies this node’s transform to a target Node3D, syncing their transforms.",
	"ResourcePreloader": "Stores and preloads resources for quick access at runtime.",
	"RichTextLabel": "Displays rich-formatted text with BBCode features like bold, italics, and embedded images.",
	"RigidBody2D": "A 2D physics body influenced by forces, gravity, and collisions.",
	"RigidBody3D": "A 3D physics body that can move, rotate, and interact under physics simulation.",
	"RootMotionView": "Displays a preview of root motion in animations, useful for animation blending.",
	"ScrollContainer": "A container allowing its child to be scrolled if it’s larger than the viewport.",
	"ShaderGlobalsOverride": "Allows overriding global shader parameters in a scene.",
	"ShapeCast2D": "Casts a 2D shape along a direction to see where it would collide.",
	"ShapeCast3D": "Casts a 3D shape to detect potential collisions before it moves.",
	"Skeleton2D": "A 2D skeleton for skeletal animations, managing multiple Bone2D nodes.",
	"Skeleton3D": "A 3D skeleton for skeletal animations, controlling bone transforms.",
	"SkeletonIK3D": "Adds inverse kinematics to a 3D skeleton for procedural posing.",
	"SkeletonModifier3D": "Allows applying modifiers to a Skeleton3D for procedural animation effects.",
	"SliderJoint3D": "A 3D joint that restricts a body to slide along a single axis.",
	"SoftBody3D": "A 3D physics body that can deform, simulating soft or elastic materials.",
	"SpinBox": "A numeric input control with increment/decrement arrows for changing values.",
	"SplitContainer": "Splits the area into two sections, either horizontally or vertically, with a movable divider.",
	"SpotLight3D": "A 3D light that shines in a cone shape, like a flashlight or spotlight.",
	"SpringArm3D": "A helper node that keeps a child node at a set distance, adjusting for collisions.",
	"Sprite2D": "Displays a 2D texture, supporting region selection, flip, and animation frames.",
	"Sprite3D": "Displays a 2D texture in 3D space, often used as a billboarded sprite.",
	"StaticBody2D": "A 2D physics body that doesn’t move and can’t be pushed, used for walls or floors.",
	"StaticBody3D": "A 3D physics body that remains fixed in space, like terrain or immovable objects.",
	"StatusIndicator": "A UI element indicating a status, such as active/inactive or progress.",
	"SubViewport": "A secondary viewport that can render a scene or be used for custom textures.",
	"SubViewportContainer": "Displays a SubViewport’s content as a UI element.",
	"TabBar": "A bar of tabs for switching between different content panels.",
	"TabContainer": "Holds multiple tabs each with its own panel of content.",
	"TextEdit": "A multiline text editor control for editing longer text blocks.",
	"TextureButton": "A button that uses images (textures) for its normal, pressed, and hover states.",
	"TextureProgressBar": "A progress bar using textures to represent progress.",
	"TextureRect": "Displays a texture (image) that can scale or stretch.",
	"TileMap": "A 2D node that places tiles from a tileset to create maps or levels efficiently.",
	"TileMapLayer": "A layer of a TileMap, allowing multiple overlapping layers of tiles.",
	"Timer": "A node that triggers a signal after a specified time period.",
	"TouchScreenButton": "A button designed for touchscreens, displaying a texture and detecting touch input.",
	"Tree": "A UI control displaying items in a hierarchical structure with expand/collapse functionality.",
	"VBoxContainer": "A container that arranges its children in a vertical column.",
	"VFlowContainer": "A flow container that arranges children vertically and wraps them as needed.",
	"VScrollBar": "A vertical scrollbar control.",
	"VSeparator": "A vertical line to separate UI elements visually.",
	"VSlider": "A vertical slider for selecting a value within a range.",
	"VSplitContainer": "Splits the area vertically into two resizable panels.",
	"VehicleBody3D": "A specialized rigid body simulating a vehicle’s physics.",
	"VehicleWheel3D": "Represents a wheel of a VehicleBody3D, affecting its movement and suspension.",
	"VideoStreamPlayer": "Plays video streams (webm, ogv) inside the engine’s UI or 3D space.",
	"VisibleOnScreenEnabler2D": "Disables or enables its children based on whether they are visible on screen in 2D.",
	"VisibleOnScreenEnabler3D": "Disables or enables its children based on whether they are visible on screen in 3D.",
	"VisibleOnScreenNotifier2D": "Notifies when its bounding box is visible on the screen in 2D.",
	"VisibleOnScreenNotifier3D": "Notifies when its bounding box is visible on the screen in 3D.",
	"VisualInstance3D": "A base class for 3D nodes that create visual geometry, like MeshInstance3D.",
	"VoxelGI": "A 3D node providing real-time global illumination via voxel-based calculations.",
	"Window": "A draggable, resizable window that can hold UI elements, often a toplevel UI container.",
	"WorldEnvironment": "Controls scene-wide environment effects like sky, fog, and lighting.",
	"XRAnchor3D": "An XR anchor that tracks a real-world position/orientation in AR/VR.",
	"XRBodyModifier3D": "Modifies XR body setups for tracked XR devices.",
	"XRCamera3D": "A camera tailored for XR rendering, representing a VR or AR headset’s view.",
	"XRController3D": "Represents a tracked XR controller in 3D space.",
	"XRFaceModifier3D": "Handles XR face tracking data, allowing facial expressions or head position.",
	"XRHandModifier3D": "Handles XR hand tracking data, including finger positions and gestures.",
	"XRNode3D": "A base node that can represent any XR-tracked object.",
	"XROrigin3D": "Represents the origin of an XR space, often the player’s physical floor level or starting point."
}

# Define the list of popular nodes in the order you want them displayed.
var popular_nodes = [
	"Node", "Node2D", "RigidBody2D", "CharacterBody2D", "Sprite2D",
	"CollisionShape2D", "Area2D", "AnimationPlayer", "AnimatedSprite2D",
	"StaticBody2D", "Camera2D", "CanvasLayer", "Label", "Panel",
	"ParallaxBackground", "ParallaxLayer", "Parallax2D", "RayCast2D",
	"Marker2D", "Button", "TextEdit", "ColorRect",
	# Newly added nodes
	"TileMap", "TileMapLayer", "Timer", "AudioStreamPlayer", "AudioStreamPlayer2D"
]

func _init(_editor_interface: EditorInterface) -> void:
	editor_interface = _editor_interface
	name = "Nodes"

	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search Nodes..."
	search_bar.clear_button_enabled = true
	add_child(search_bar)
	search_bar.text_changed.connect(self._on_search_text_changed)

	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.set_drag_forwarding(_get_drag_data_fw, Callable(), Callable())
	add_child(tree)

	tree.item_activated.connect(self._on_item_activated)
	tree.item_collapsed.connect(self._on_item_collapsed)

	generate_full_node_list()
	generate_class_tree()

func generate_full_node_list() -> void:
	full_node_list.clear()
	var node_classes = ClassDB.get_inheriters_from_class("Node")
	node_classes.append("Node")

	for _class_name in node_classes:
		if _class_name == "MissingNode" or "Editor" in _class_name:
			continue
		if not ClassDB.can_instantiate(_class_name) or not ClassDB.is_class_enabled(_class_name):
			continue
		full_node_list.append(_class_name)

	full_node_list.sort()
	if "Node" in full_node_list:
		full_node_list.erase("Node")
		full_node_list.insert(0, "Node")


func generate_class_tree() -> void:
	tree.clear()
	var editor_theme: Theme = editor_interface.get_editor_theme()
	var search_text = search_bar.text.strip_edges().to_lower()
	is_search_active = search_text != ""

	root = tree.create_item()
	root.set_text(0, "Nodes")
	root.set_icon(0, editor_theme.get_icon("Sprite2D", "EditorIcons"))
	root.set_disable_folding(true)

	var categories = {
		"Popular": { "nodes": popular_nodes, "icon": "RigidBody2D" },
		"2D Nodes": { "nodes": [], "icon": "Node2D" },
		"3D Nodes": { "nodes": [], "icon": "Node3D" },
		"Misc": { "nodes": [], "icon": "Control" },
		"All Nodes": { "nodes": full_node_list, "icon": "Node" }
	}

	for node_name in full_node_list:
		if "2D" in node_name:
			categories["2D Nodes"].nodes.append(node_name)
		elif "3D" in node_name:
			categories["3D Nodes"].nodes.append(node_name)
		elif node_name not in popular_nodes:
			categories["Misc"].nodes.append(node_name)

	for category in categories:
		var parent = tree.create_item(root)
		parent.set_text(0, category)
		parent.set_icon(0, editor_theme.get_icon(categories[category].icon, "EditorIcons"))
		
		# Ensure categories are expanded during a search
		if is_search_active:
			parent.set_collapsed(false)  # Expand the category
		else:
			parent.set_collapsed(root_items_collapsed_state.get(category, true))

		for node_name in categories[category].nodes:
			if is_search_active and node_name.to_lower().find(search_text) == -1:
				continue
			var description = descriptions.get(node_name, "No description available.")
			create_tree_item(parent, node_name, editor_theme, description)



func create_tree_item(parent: TreeItem, node_name: String, theme: Theme, tooltip: String) -> void:
	var class_item = tree.create_item(parent)
	var class_icon = theme.get_icon("Node", "EditorIcons")
	if theme.has_icon(node_name, "EditorIcons"):
		class_icon = theme.get_icon(node_name, "EditorIcons")
	class_item.set_text(0, node_name)
	class_item.set_icon(0, class_icon)
	class_item.set_selectable(0, ClassDB.can_instantiate(node_name))
	class_item.set_tooltip_text(0, tooltip)

func _on_search_text_changed(new_text: String) -> void:
	generate_class_tree()

func _on_item_activated() -> void:
	var item = tree.get_selected()
	if item == null:
		return
	_create_node(item)

func _create_node(item: TreeItem) -> void:
	var node_type = item.get_text(0)
	var node: Node = ClassDB.instantiate(node_type)
	if node == null:
		return
	var scene_root = editor_interface.get_edited_scene_root()
	
	if not is_instance_valid(scene_root):  # No root exists, set this node as root
		var tree_editor = Engine.get_meta("SceneTreeEditor", null)
		var editor_node = Engine.get_meta("EditorNode", null)
		if not is_instance_valid(tree_editor) or not is_instance_valid(editor_node):
			node.free()  # Avoid memory leak
			return
		editor_node.call("set_edited_scene", node)
		tree_editor.call("update_tree")
		return
	
	# Add the node to the existing scene
	scene_root.add_child(node, true)
	node.owner = scene_root


func _on_item_collapsed(item: TreeItem) -> void:
	var item_text = item.get_text(0)
	if item_text in root_items_collapsed_state:
		root_items_collapsed_state[item_text] = item.is_collapsed()
func _get_drag_data_fw(position: Vector2) -> Variant:
	var current_scene = editor_interface.get_edited_scene_root()
	if not is_instance_valid(current_scene):
		return null
	
	var item := tree.get_item_at_position(position)
	if not item:
		return null
	
	var _class_name = item.get_text(0)
	if _class_name.is_empty() or not ClassDB.can_instantiate(_class_name):
		return null
	
	var instance: Node = ClassDB.instantiate(_class_name) as Node
	current_scene.add_child(instance, true)
	instance.owner = current_scene
	editor_interface.get_selection().clear()
	editor_interface.get_selection().add_node(instance)
	
	var editor_theme = editor_interface.get_editor_theme()
	var class_icon = editor_theme.get_icon("Node", "EditorIcons")
	if editor_theme.has_icon(_class_name, "EditorIcons"):
		class_icon = editor_theme.get_icon(_class_name, "EditorIcons")
	
	var hb := HBoxContainer.new()
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2i(16, 16)
	tr.texture = class_icon
	hb.add_child(tr)
	var label := Label.new()
	label.text = _class_name
	hb.add_child(label)
	set_drag_preview(hb)
	return {"type": "nodes", "nodes": [instance.get_path()]}
