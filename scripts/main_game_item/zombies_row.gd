extends CanvasItem
class_name ZombieRow

@onready var zombie_create_position: Marker2D = $ZombieCreatePosition

## 当前行类型
@export var zombie_row_type:EnumsCharacter.ZombieRowType = EnumsCharacter.ZombieRowType.Land
## 是否有钉耙
@export var have_rake := false
