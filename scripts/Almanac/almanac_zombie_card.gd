extends Control
class_name AlmanacZombieCard

@onready var almanac_zombie_card_bg: TextureRect = $AlmanacZombieCardBg

var zombie_type:EnumsCharacter.ZombieType

signal signal_card_click

func _ready() -> void:
	var zombie_card:Card = AllCards.all_zombie_card_prefabs[zombie_type]
	var character_static:Node2D = zombie_card.character_static.duplicate()
	almanac_zombie_card_bg.add_child(character_static)
	character_static.scale = Vector2(1.6, 1.6)
	character_static.position = Vector2(40, 50)

func init_almanac_zombie_card(curr_zombie_type:EnumsCharacter.ZombieType):
	zombie_type = curr_zombie_type

func _on_button_pressed() -> void:
	signal_card_click.emit()
