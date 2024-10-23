extends Node

@export var ui: Control
@export var level_container: Node
@export var level_scene: PackedScene
@export var ip_input: LineEdit
@export var status_label: Label
@export var not_connected_hbox : HBoxContainer
@export var host_hbox : HBoxContainer

	
func _ready() -> void:
	Network.start_match.connect(self._start_match)


func _on_host_button_pressed():
	Lobby.create_game()
	not_connected_hbox.hide()
	host_hbox.show()
	status_label.text = "Hosting!"
	
func _start_match():
	print("start match!")
	hide_menu()
	not_connected_hbox.hide()
	host_hbox.hide()
	change_level.call_deferred(level_scene)
	
	
func change_level(scene:PackedScene):
	for c in level_container.get_children():
		level_container.remove_child(c)
		c.queue_free()
	level_container.add_child(scene.instantiate())


func _on_join_button_pressed():
	#Lobby.join_game(ip_input.text)
	#status_label.text = "Connecting..."
	Network._check_webrtc_connection_state()

func _on_connection_failed():
	status_label.text = "Failed to connect"

func _on_connection_succeeded():
	status_label.text = "Connected!"
	not_connected_hbox.hide()
	host_hbox.hide()
	
@rpc("call_local", "authority", "reliable")
func hide_menu():
	ui.hide()

func _on_find_match_button_pressed():
	Network.start(ip_input.text)
