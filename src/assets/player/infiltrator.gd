extends Node2D

onready var animator: AnimationPlayer = $Animator
# UI Controller for the player
onready var ui_controller: CanvasLayer = get_tree().get_root().find_node("uicontroller", true, false)
# Area within which a player may be killed
onready var kill_area: Area2D = $KillArea
# Cooldown before next kill may be made
onready var kill_cooldown_timer: Timer = $KillCooldownTimer
# Parent player
onready var player: KinematicBody2D = get_parent()

# Emitted when the infiltrator kills a player
signal kill(emitter, player)
# Emitted when the infiltrator stops reloading their weapon
signal stopped_reloading

# Whether reloading may be cancelled or not
export (bool) var can_cancel_reload := true
# Whether the infiltrator may kill or not
var _killing_enabled: bool = true setget enable_killing, is_killing_enabled
# If the infiltrator has executed a kill and has not reloaded yet; separate from
# _killing_enabled as an infiltrator may be reloaded but an event may prevent
# them from killing
var _reloaded: bool = true setget set_reloaded, is_reloaded
# Whether the infiltrator is reloading their weapon
var _reloading: bool = false setget set_reloading, is_reloading
# The highlighted target if the infiltrator decides to kill
var _target_player: KinematicBody2D

func _ready() -> void:
	if player.main_player:
		_instantiate_kill_gui()
	# Get Main parent node and connect kill player signal to it
	var main: YSort = get_tree().get_root().find_node("Main", true, false)
	connect("kill", main, "_on_infiltrator_kill")

func _process(delta: float) -> void:
	if player.main_player:
		if is_reloaded() and is_killing_enabled() and Input.is_action_just_pressed("kill") and \
		   _target_player != null:
			_kill_player()
		elif Input.is_action_just_pressed("reload"):
			if animator.current_animation == "Reload":
				if can_cancel_reload:
					_cancel_reload()
			elif not is_reloaded():
				_reload()

	if is_killing_enabled() and player.main_player:
		_get_target()

func is_killing_enabled() -> bool:
	"""Returns whether killing is enabled for the infiltrator."""
	return _killing_enabled

func enable_killing(enable: bool = true) -> void:
	"""Enable or disable killing; may be used from outside of script."""
	_killing_enabled = enable

func is_reloaded() -> bool:
	"""Check whether the infiltrator has reloaded."""
	return _reloaded

func set_reloaded(reloaded: bool) -> void:
	"""Set whether the infiltrator has reloaded."""
	_reloaded = reloaded

func is_reloading() -> bool:
	"""Returns whether the infiltrator is reloading their weapon."""
	return _reloading

func set_reloading(reloading: bool) -> void:
	"""Set whether the infiltrator is reloading their weapon."""
	_reloading = reloading

func _kill_player() -> void:
	"""Kill the player who is currently the target."""
	for player in kill_area.get_overlapping_bodies():
		var target_sprite: Sprite = player.get_node("ViewportTextureTarget")
		target_sprite.material.set_shader_param("line_color", Color.transparent)
	emit_signal("kill", player, _target_player)
	set_reloaded(false)
	enable_killing(false)
#	kill_cooldown_timer.start()

func _get_target() -> void:
	"""
	Each frame, highlight the nearest target within the kill area in red as the
	player who will be killed if the infiltrator decides to do so.
	"""
	var distance: float = INF
	_target_player = null
	for player in kill_area.get_overlapping_bodies():
		var sprite: Sprite = player.get_node("ViewportTextureTarget")
		sprite.material.set_shader_param("line_color", Color.transparent)
		if not player.get_node("DeathHandler").is_dead:
			var temp_distance: float = (player.global_position - global_position).length()
			if temp_distance < distance:
				distance = temp_distance
				_target_player = player
	if _target_player != null:
		var target_sprite: Sprite = _target_player.get_node("ViewportTextureTarget")
		target_sprite.material.set_shader_param("line_color", Color.red)

func _instantiate_kill_gui() -> void:
	"""Add kill UI to the infiltrator's HUD."""
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	ui_controller.open_menu("killui", {"linked_node": self}, true)

func _reload() -> void:
	"""Reload the infiltrator's weapon and freeze the parent player node."""
	animator.play("Reload")
	set_reloading(true)
	player.set_movement_disabled(true)

func _cancel_reload() -> void:
	"""Stop reload animation, returning control to the player."""
	animator.stop()
	set_reloading(false)
	emit_signal("stopped_reloading")
	player.set_movement_disabled(false)

func _on_KillArea_body_exited(body: Node) -> void:
	"""Remove the outline from the body that exited the kill area."""
	if player.main_player:
		var target_sprite: Sprite = body.get_node("ViewportTextureTarget")
		target_sprite.material.set_shader_param("line_color", Color.transparent)

func _on_KillCooldownTimer_timeout() -> void:
	"""Re-enable killing mechanic after cooldown ends."""
	enable_killing()

func _on_Animator_animation_finished(anim_name: String) -> void:
	"""
	Re-enable killing mechanic and player movement after reload animation is 
	finished.
	"""
	match anim_name:
		"Reload":
			set_reloaded(true)
			set_reloading(false)
			enable_killing()
			player.set_movement_disabled(false)
