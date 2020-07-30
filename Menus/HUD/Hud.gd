extends CanvasLayer

var user
var kill_msg_slots : Kill_Message_slots
var score_board = preload("res://Objects/Misc/ScoreBoard.tscn").instance()
var admin_menu = null
var frames : int = 0

onready var Reload_panel = $reload
onready var Reload_progressBar = get_node("reload/TextureProgress")
onready var Grenade_count_label = get_node("HE/Label")
onready var Tween_node = $Tween
onready var Reloading_text = $reloading_txt
onready var Cash_label = $cash
onready var Pause_menu_panel = $pause_menu
onready var Pick_button = $pick

func _ready():
	if not game_states.is_android:
		$controller.queue_free()
	# Show Fps
	if game_states.game_settings.show_fps:
		$fps_timer.start()
	# Create Slots for hud messages
	kill_msg_slots = Kill_Message_slots.new(self,8)
	# Connect signals
	score_board.connect("scoreboard_closed", self, "_on_scoreboard_closed")
	MenuManager.connect("back_pressed", self,"_on_back_pressed")
	# Enable admin menu if admin
	if get_tree().is_network_server():
		Pause_menu_panel.get_node("container/admin_menu").disabled = false
		admin_menu = load("res://Menus/HUD/AdminPanel.tscn").instance()
		admin_menu.connect("adminPanel_closed", self, "_on_admin_menu_closed")

# Set user of Hud
func setUser(u):
	user = u
	$controller.user = u
	user.connect("gun_picked",self,"_on_gun_picked")
	user.connect("gun_loaded", self, "setWeaponInfo")
	user.connect("gun_switched", self, "setWeaponInfo")

# Show mags remaining in hud
func setClipCount(count):
	var n = $reload
	# Hide icons
	for i in range(4):
		n.get_node("b" + String(i + 1)).hide()
	# Show icons
	for i in range(count):
		n.get_node("b" + String(i + 1)).show()

func _process(_delta):
	frames += 1
	Reload_progressBar.value =  user.selected_gun.rounds_left
	# Update every 8 frames
	if frames % 8 == 0:
		Grenade_count_label.text = "x" + String(game_states.player_data.nade_count)

# Handle quit pressed
func _on_quit_pressed():
	if get_tree().is_network_server():
		network.kick_player(game_states.player_info.net_id,"Disconnected From Server")
	else:
		network.rpc_id(1,"kick_player",game_states.player_info.net_id,"Disconnected From Server")

# handle paused pressed
func _on_pause_pressed():
	Pause_menu_panel.show()
	UiAnim.animZoomIn([Pause_menu_panel])

# Sorter
class MyPlayerSorter:
	static func sort(a, b):
		if a["kills"] < b["kills"]:
			return false
		return true

# Show scoreboard
func _on_score_pressed():
	UiAnim.animZoomOut([Pause_menu_panel])
	updateScoreBoard()
	yield(get_tree().create_timer(UiAnim.getAnimDuration()), "timeout")
	Pause_menu_panel.hide()
	add_child(score_board)
	UiAnim.animZoomIn([score_board])

#remove scoreboard when closed
func _on_scoreboard_closed():
	UiAnim.animZoomOut([score_board])
	yield(get_tree().create_timer(UiAnim.getAnimDuration()), "timeout")
	remove_child(score_board)

func updateScoreBoard():
	score_board.setBoardData(game_server._unit_data_list)

func _on_zoom_pressed():
	user.get_node("Camera2D").zoom = user.selected_gun.getNextZoom()

func _on_HE_pressed():
	if game_states.player_data.nade_count > 0:
		game_states.player_data.nade_count -= 1
		user.rpc_id(1,"server_throwGrenade")


func addCash(val):
	Tween_node.stop_all()
	Cash_label.visible = true
	Cash_label.text = "+ $" + String(val)
	Tween_node.interpolate_property(Cash_label, "rect_scale", Vector2(0.5,0.5), Vector2(1,1),1.5,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT)
	Tween_node.interpolate_property(Cash_label, "rect_scale", Vector2(1,1), Vector2(0.5,0.5),1,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,1.5)
	Tween_node.interpolate_property(Cash_label, "visible", true,false,0.5,Tween.TRANS_LINEAR,Tween.EASE_OUT,3)
	Tween_node.start()

class Message_slot:
	var is_free : bool
	var msg : String
	
	func _init():
		is_free = true
		
	func clear_slot():
		msg = ""
		is_free = true
	
	func addMessage(_msg):
		msg = _msg
		is_free = false

class Kill_Message_slots:
	var msg_slots : Array
	var timer : Timer
	var active_slots : int
	var max_slots
	var hud
	
	func _init(usr,num = 6):
		hud = usr
		active_slots = 0
		max_slots = 6
		num = 6
		for _i in range(0,num):
			msg_slots.append(Message_slot.new())
		timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.connect("timeout",self,"_on_timeout")
		usr.add_child(timer)
	
	func _on_timeout():
		if active_slots:
			active_slots -= 1
			for i in range(active_slots):
				msg_slots[i].addMessage(msg_slots[i + 1].msg)
				msg_slots[i + 1].clear_slot()
			timer.start()
			showKillMsg()
	
	func forceRemove():
		active_slots -= 1
		for i in range(active_slots):
			msg_slots[i].addMessage(msg_slots[i + 1].msg)
			msg_slots[i + 1].clear_slot()
		

	func addKillMessage(msg):
		if not active_slots:
			timer.start()
			
		active_slots += 1
		if active_slots > max_slots:
			active_slots = max_slots
			forceRemove()
			active_slots += 1
		
		msg_slots[active_slots - 1].addMessage(msg)
		showKillMsg()
	
	func showKillMsg():
		var labels = hud.get_node("kill_msg")
		for i in range(active_slots):
			if game_states.game_settings.use_rich_text:
				labels.get_node(String(i + 1)).bbcode_text = msg_slots[i].msg
			else:
				labels.get_node(String(i + 1)).text = msg_slots[i].msg
		
		#Remove messages
		for i in range(active_slots,max_slots):
			if game_states.game_settings.use_rich_text:
				labels.get_node(String(i + 1)).bbcode_text = ""
			else:
				labels.get_node(String(i + 1)).text = ""


func addKillMessage(msg):
	kill_msg_slots.addKillMessage(msg)

#set weapon info in hud
func setWeaponInfo():
	if not user.selected_gun:
		return
	 
	Reload_panel.get_node("gun_s").texture = user.selected_gun.gun_portrait
	Reload_progressBar.max_value = user.selected_gun.clip_size
	Reload_progressBar.value =  user.selected_gun.rounds_left
	setClipCount(user.selected_gun.clip_count)
	user.get_node("Camera2D").zoom = user.selected_gun.getCurrentZoom()

	if not user.selected_gun.is_connected("gun_reloaded",self,"_on_gun_reload"):
		user.selected_gun.connect("gun_reloaded",self,"_on_gun_reload")

	if not user.selected_gun.is_connected("gun_reloading",self,"_on_gun_reloading"):
		user.selected_gun.connect("gun_reloading",self,"_on_gun_reloading")


#switch weapon when "next gun" is pressed
func _on_nextGun_pressed():
	user.rpc("switchGun")

# Called when reloading is complete 
func _on_gun_reload():
	setClipCount(user.selected_gun.clip_count)
	UiAnim.animZoomOut([Reloading_text])
	var tree = get_tree()
	if tree:
		yield(tree.create_timer(UiAnim.getAnimDuration()), "timeout")
	Reloading_text.hide()

# Called when reloading starts
func _on_gun_reloading():
	Reloading_text.show()
	UiAnim.animZoomIn([Reloading_text])

# Called when gun is picked from ground
func _on_gun_picked():
	setWeaponInfo()

# Called when reload button is pressed
func _on_btn_pressed():
	user.selected_gun.reload()

 
func _on_back_pressed():
	UiAnim.animZoomOut([Pause_menu_panel])	
	var tree = get_tree()
	if tree:
		yield(tree.create_timer(UiAnim.getAnimDuration()), "timeout")
	Pause_menu_panel.hide()

# 
func _on_changeTeam_pressed():
	user.P_on_team_menu_selected()
	UiAnim.animZoomOut([Pause_menu_panel])
	yield(get_tree().create_timer(UiAnim.getAnimDuration()), "timeout")
	Pause_menu_panel.hide()


func _on_admin_menu_pressed():
	UiAnim.animZoomOut([Pause_menu_panel])
	yield(get_tree().create_timer(UiAnim.getAnimDuration()), "timeout")
	Pause_menu_panel.hide()
	add_child(admin_menu)


func _on_admin_menu_closed():
	UiAnim.animZoomOut([admin_menu])
	var tree = get_tree()
	if tree:
		yield(tree.create_timer(UiAnim.getAnimDuration()), "timeout")
	remove_child(admin_menu)


func _on_fps_timer_timeout():
	$fps.text = "Fps : " + String(frames)
	frames = 0


func _on_pick_pressed():
	if user.alive:
		user.pickItem()
		Pick_button.hide()

# Called when melee button is pressed
func _on_melee_pressed():
	user.performMeleeAttack()


func _on_pic_touch_pressed():
	if user.alive:
		user.pickItem()
		Pick_button.hide()
