extends Node2D
export var damage : float = 100
export var radius : float = 100
export var SCALE : float = 1
var gun_name = "explosive"
var usr = ""
signal exploded

#set explosion size scale
func _ready():
	scale = Vector2(SCALE,SCALE)
	$explode.volume_db = scale.x * 2

#explode 
func explode(cloud = false):
	$explode.play()
	$Timer.start()
	$AnimationPlayer.play("explode")
	$Tween.interpolate_property($Sprite,"scale",Vector2(1,1),Vector2(2,2),1,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	#emit blast particles
	if game_states.game_settings.particle_effects and cloud:
		$explosion_cloud.emitting = true
	
	#Handle Damage
	if get_tree().is_network_server():
		var chars = get_tree().get_nodes_in_group("Damageable")
		for c in chars:
			if (c.position - position).length() < radius * SCALE:
				c.takeDamage(damage,gun_name,usr)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "explode":
		$Sprite.hide()



func _on_Timer_timeout():
	emit_signal("exploded")
	queue_free()
