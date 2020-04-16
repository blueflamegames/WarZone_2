extends Node2D
class_name Gun

export var gun_type : String = "pistol"
export var gun_name : String = "null"
export var damage : float = 18
export var melee_damage : float = 50
export var rounds_in_clip : int = 10
export var clips : int = 4
export var gun_rating : int = 0
export var rate_of_fire : float = 4
export var max_zoom : float = 1.0
export var gun_portrait : Texture = preload("res://Sprites/Weapons/gun_p.png")
export var gun_d_img : Texture
export var wpn_cost : int = 500

var current_zoom : float = 0.75
var projectile = preload("res://Objects/Weapons/Projectile.tscn")
var ready_to_fire : bool = true
var gun_user = null
var rounds_left = 0
var reloading : bool = false

var max_ray_distance : float = 200
var ray_dest : Vector2
var laser_sight : bool = true
var target : bool = false
var muzzle_frames = 0

signal gun_fired
signal reloading_gun

func _ready():
	if rounds_left == 0:
		reload()
	#if it does not have parent/user then force get parent
	if not gun_user:
		gun_user = get_parent()
	laser_sight = game_states.game_settings.laser_targeting


#Try to fire gun
func fireGun():
	#ammo check
	if clips <= 0 and rounds_left <= 0:
		#No ammo
		#play clipout sound
		if ready_to_fire:
			$clipOut.play()
			ready_to_fire = false
			$Timer.start(1 / rate_of_fire)
	elif ready_to_fire and rounds_left > 0:
		_shoot()
	elif rounds_left <= 0:
		#auto reload
		if not reloading:
			reload()
			reloading = true

#create projectile
remotesync func _create_bullet():
	if game_states.game_settings.particle_effects:
		var bullet = projectile.instance()
		bullet.create_bullet($Muzzle.global_position,global_rotation,1500,ray_dest)
		get_tree().root.add_child(bullet)
	
	$Muzzle/muzzle.show()
	muzzle_frames = 3
	$fire.play()
	emit_signal("gun_fired")


remotesync func chkBulletHit():
	if target:
		var body = $RayCast2D.get_collider()
		if body and body.is_in_group("Actor"):
			body.takeDamage(damage,self,gun_user)

#shoot weapon
func _shoot():
	rpc_id(1,"chkBulletHit")
	rpc("_create_bullet")
	
	ready_to_fire = false
	$Timer.start(1 / rate_of_fire)
	rounds_left -= 1


func _on_Timer_timeout():
	ready_to_fire = true

#do reloading
func reload():
	if clips > 0 and not reloading:
		$reload.play()
		$Reload_time.start()
		reloading = true
		emit_signal("reloading_gun")

#reload weapon
func _on_Reload_time_timeout():
	clips -= 1
	rounds_left = rounds_in_clip
	reloading = false

func _process(delta):
	muzzle_frames = max(muzzle_frames - 1,0)
	if muzzle_frames == 1:
		$Muzzle/muzzle.hide()
	target = false
	ray_dest = $RayCast2D.cast_to.rotated(global_rotation) + $RayCast2D.global_position
	if $RayCast2D.is_colliding():
		ray_dest = $RayCast2D.get_collision_point()
		target = true
	#update _draw()
	if laser_sight:
		update()

func _draw():
	if laser_sight:
		draw_line($Muzzle.position, (ray_dest - $RayCast2D.global_position).rotated(-global_rotation)
		+ $RayCast2D.position , Color.red)
		draw_circle((ray_dest - $RayCast2D.global_position).rotated(-global_rotation) + $RayCast2D.position 
		, 3, Color.red)
