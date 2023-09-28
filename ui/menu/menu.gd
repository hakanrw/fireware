extends Control

var menus = {
	"Multiplayer": preload("res://ui/menu/multiplayer.tscn"),
	"Settings": preload("res://ui/menu/settings.tscn"),	
	"Error": preload("res://ui/menu/error.tscn"),
}

onready var pane = get_tree().get_nodes_in_group("pane")[0]
onready var screen = pane.get_node("MarginContainer/VBoxContainer/Screen")
onready var website_button = $MarginContainer/HBoxContainer/Control/BWebsite

func _ready():
	var bottom_container = get_tree().get_nodes_in_group("bottom_container")[0]
	bottom_container.get_node("BMultiplayer").connect("mouse_clicked", self, "_change_pane_page", ["Multiplayer"])
	bottom_container.get_node("BSettings").connect("mouse_clicked", self, "_change_pane_page", ["Settings"])
	bottom_container.get_node("BExit").connect("mouse_clicked", self, "_exit_pressed")
	bottom_container.get_node("BCreateServer").connect("mouse_clicked", self, "_create_server")
	website_button.connect("mouse_clicked", self, "_launch_website")
	
	pane.get_node("Button").connect("mouse_clicked", self, "_close_pane")

func _exit_pressed():
	get_tree().quit()

func _change_pane_page(page):
	website_button.visible = false
	pane.visible = true
	pane.get_node("MarginContainer/VBoxContainer/Title").text = page
	var screen = pane.get_node("MarginContainer/VBoxContainer/Screen")
	for n in screen.get_children():
		n.queue_free()
	screen.add_child(menus[page].instance())
	print(page)

func _close_pane():
	website_button.visible = true
	pane.visible = false
	
func _create_server():
	print(OS.get_cmdline_args())
	OS.execute(OS.get_executable_path(), ["--server"], false)

func _launch_website():
	OS.shell_open("https://hakan.candar.dev")
