extends Node


var default_time_scale = 1.0


const CFG_PATH = "user://config.cfg"

var cfg_data = {}

var default_keys = {
	"ROLL": [KEY_SHIFT, "InputEventKey"],
	"DASH": [KEY_TAB, "InputEventKey"],
	"DOWN DASH": [KEY_C, "InputEventKey"],
	"RMB ATTACK": [MOUSE_BUTTON_RIGHT, "InputEventMouseButton"],
	"RIGHT": [KEY_D, "InputEventKey"],
	"LEFT": [KEY_A, "InputEventKey"],
	"DOWN": [KEY_S, "InputEventKey"], 
	"JUMP": [KEY_SPACE, "InputEventKey"],
	"LMB ATTACK": [MOUSE_BUTTON_LEFT, "InputEventMouseButton"],
	"BLOCK": [KEY_X, "InputEventKey"],
	"FRUIT NINJA": [KEY_Q, "InputEventKey"],
	"SPECIAL ATTACK 1": [KEY_1, "InputEventKey"],
}

var default_cfg_data = {
		#SETTINGS
	"display_mode": 2, #windowed - 0, borderless - 1, fullscreen - 2
	"vsync_on": true,
	"master_vol": -10,
	"music_vol": -10,
	"sfx_vol": - 10,
	"glitchy_transition_on": true,
	"undead": false,
	"skylight_on": true,
#	"glow_on": true,
	"show_fps_on": false,
	"blood_traces_on": true,
	"lens_flare_on": true,
	#KEYS
	"ROLL": [KEY_SHIFT, "InputEventKey"],
	"DASH": [KEY_TAB, "InputEventKey"],
	"DOWN DASH": [KEY_C, "InputEventKey"],
	"RMB ATTACK": [MOUSE_BUTTON_RIGHT, "InputEventMouseButton"],
	"RIGHT": [KEY_D, "InputEventKey"],
	"LEFT": [KEY_A, "InputEventKey"],
	"DOWN": [KEY_S, "InputEventKey"], 
	"JUMP": [KEY_SPACE, "InputEventKey"],
	"LMB ATTACK": [MOUSE_BUTTON_LEFT, "InputEventMouseButton"], 
	"BLOCK": [KEY_X, "InputEventKey"],
	"FRUIT NINJA": [KEY_Q, "InputEventKey"],
	"SPECIAL ATTACK 1": [KEY_1, "InputEventKey"],
}


func _enter_tree():
	load_data()


func load_data():
	if !FileAccess.file_exists(CFG_PATH):
		cfg_data = default_cfg_data
		save_data()
		return
	var file = FileAccess.open(CFG_PATH, FileAccess.READ)
	cfg_data = file.get_var()
	for key in default_cfg_data.keys():
		if key not in cfg_data:
			cfg_data[key] = default_cfg_data[key]
	save_data()
	
	
func save_data():
	var file = FileAccess.open(CFG_PATH, FileAccess.WRITE)
	file.store_var(cfg_data)
	
	
func _ready():
	randomize()
