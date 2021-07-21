extends Panel

onready var security_button = $MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/Security
onready var insurgent_button = $MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/Insurgent
onready var spectator_button = $MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/Spectator

func _ready():
	security_button.connect( "mouse_clicked", self, "select_team", [Utils.Team.SECURITY ])
	insurgent_button.connect("mouse_clicked", self, "select_team", [Utils.Team.INSURGENT])
	spectator_button.connect("mouse_clicked", self, "select_team", [Utils.Team.SPECTATOR])

func select_team(team: int):
	NetworkController.get_self_player().network_player.rpc_id(1, "set_team", team)
	Utils.get_hud_node().clear_page()
