extends Node
class_name GlobalGameState

const DEFAULT_COIN_VALUE: int = 0
const DEFAULT_CURR_NUM_NEW_GARDEN_PLANT: int = 3
const DEFAULT_GARDEN_DATA: Dictionary = {
	"num_bg_page_0": 1,
	"num_bg_page_1": 1,
	"num_bg_page_2": 1,
}
const DEFAULT_CURR_ALL_LEVEL_STATE_DATA: Dictionary = {}
"""
## 一个关卡的游戏状态的例子
var curr_one_level_state_data:Dictionary = {
	"IsSuccess":false,
	"IsHaveMultiRoundSaveGameData":false,
	"CurrGameRound":1
}
"""
signal coin_value_changed(new_value: int)

var coin_value: int = DEFAULT_COIN_VALUE:
	set(value):
		coin_value = value
		coin_value_changed.emit(coin_value)

var curr_num_new_garden_plant: int = DEFAULT_CURR_NUM_NEW_GARDEN_PLANT
var garden_data: Dictionary = DEFAULT_GARDEN_DATA.duplicate(true)
var curr_all_level_state_data: Dictionary = DEFAULT_CURR_ALL_LEVEL_STATE_DATA.duplicate(true)
var selected_cards: Array = []

var curr_plant :Array[CharacterRegistry.PlantType]= [
	CharacterRegistry.PlantType.P001PeaShooterSingle,
	CharacterRegistry.PlantType.P002SunFlower,
	CharacterRegistry.PlantType.P003CherryBomb,
	CharacterRegistry.PlantType.P004WallNut,
	CharacterRegistry.PlantType.P005PotatoMine,
	CharacterRegistry.PlantType.P006SnowPea,
	CharacterRegistry.PlantType.P007Chomper,
	CharacterRegistry.PlantType.P008PeaShooterDouble,
	CharacterRegistry.PlantType.P009PuffShroom,
	CharacterRegistry.PlantType.P010SunShroom,
	CharacterRegistry.PlantType.P011FumeShroom,
	CharacterRegistry.PlantType.P012GraveBuster,
	CharacterRegistry.PlantType.P013HypnoShroom,
	CharacterRegistry.PlantType.P014ScaredyShroom,
	CharacterRegistry.PlantType.P015IceShroom,
	CharacterRegistry.PlantType.P016DoomShroom,
	CharacterRegistry.PlantType.P017LilyPad,
	CharacterRegistry.PlantType.P018Squash,
	CharacterRegistry.PlantType.P019ThreePeater,
	CharacterRegistry.PlantType.P020TangleKelp,
	CharacterRegistry.PlantType.P021Jalapeno,
	CharacterRegistry.PlantType.P022Caltrop,
	CharacterRegistry.PlantType.P023TorchWood,
	CharacterRegistry.PlantType.P024TallNut,
	CharacterRegistry.PlantType.P025SeaShroom,
	CharacterRegistry.PlantType.P026Plantern,
	CharacterRegistry.PlantType.P027Cactus,
	CharacterRegistry.PlantType.P028Blover,
	CharacterRegistry.PlantType.P029SplitPea,
	CharacterRegistry.PlantType.P030StarFruit,
	CharacterRegistry.PlantType.P031Pumpkin,
	CharacterRegistry.PlantType.P032MagnetShroom,
	CharacterRegistry.PlantType.P033CabbagePult,
	CharacterRegistry.PlantType.P034FlowerPot,
	CharacterRegistry.PlantType.P035CornPult,
	CharacterRegistry.PlantType.P036CoffeeBean,
	CharacterRegistry.PlantType.P037Garlic,
	CharacterRegistry.PlantType.P038UmbrellaLeaf,
	CharacterRegistry.PlantType.P039MariGold,
	CharacterRegistry.PlantType.P040MelonPult,
	CharacterRegistry.PlantType.P041GatlingPea,
	CharacterRegistry.PlantType.P042TwinSunFlower,
	CharacterRegistry.PlantType.P043GloomShroom,
	CharacterRegistry.PlantType.P044Cattail,
	CharacterRegistry.PlantType.P045WinterMelon,
	CharacterRegistry.PlantType.P046GoldMagnet,
	CharacterRegistry.PlantType.P047SpikeRock,
	CharacterRegistry.PlantType.P048CobCannon,
	CharacterRegistry.PlantType.P049PeaShooterDoubleReverse,
]

var curr_zombie :Array[CharacterRegistry.ZombieType]= [
	CharacterRegistry.ZombieType.Z001Norm,
	CharacterRegistry.ZombieType.Z002Flag,
	CharacterRegistry.ZombieType.Z003Cone,
	CharacterRegistry.ZombieType.Z004PoleVaulter,
	CharacterRegistry.ZombieType.Z005Bucket,
	CharacterRegistry.ZombieType.Z006Paper,
	CharacterRegistry.ZombieType.Z007ScreenDoor,
	CharacterRegistry.ZombieType.Z008Football,
	CharacterRegistry.ZombieType.Z009Jackson,
	CharacterRegistry.ZombieType.Z010Dancer,
	CharacterRegistry.ZombieType.Z011Duckytube,
	CharacterRegistry.ZombieType.Z012Snorkle,
	CharacterRegistry.ZombieType.Z013Zamboni,
	CharacterRegistry.ZombieType.Z014Bobsled,
	CharacterRegistry.ZombieType.Z015Dolphinrider,
	CharacterRegistry.ZombieType.Z016Jackbox,
	CharacterRegistry.ZombieType.Z017Balloon,
	CharacterRegistry.ZombieType.Z018Digger,
	CharacterRegistry.ZombieType.Z019Pogo,
	CharacterRegistry.ZombieType.Z020Yeti,
	CharacterRegistry.ZombieType.Z021Bungi,
	CharacterRegistry.ZombieType.Z022Ladder,
	CharacterRegistry.ZombieType.Z023Catapult,
	CharacterRegistry.ZombieType.Z024Gargantuar,
	CharacterRegistry.ZombieType.Z025Imp,
	CharacterRegistry.ZombieType.Z1001BobsledSingle,
]
