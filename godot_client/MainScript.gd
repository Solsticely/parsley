extends Node

class_name MainScript

@export var debuglabel: Label
@export var address: TextEdit
@export var joypadpicker: OptionButton
@export var transportpicker: OptionButton
@export var control_remapping_container: Container
@export_range(0, 10, 0) var slow_tick_rate: float = 1.0;
@export_range(1, 100, 0) var update_tick_rate: float = 32;

@onready var remapping_control: PackedScene = preload("res://RemappingControl.tscn")
@onready var transport: Transport = UDPTransport.new()
var debuglines: Array[String]

enum DebugLine {
	JOYPAD_INFO,
	PACKET_DBG,
	TRANSPORT_DBG,
	DEBUGLINE_MAX,
}

const ALL_JOY_BUTTONS: Array[JoyButton] = [
	JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y,
	
	JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT,
	
	JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_GUIDE,
	
	JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK,
]
const ALL_JOY_BUTTON_NAMES: PackedStringArray = [
	"A", "B", "X", "Y",
	"D-pad up", "D-pad down", "D-pad left", "D-pad right",
	"Start", "Select", "Home",
	"Left shoulder", "Right shoulder", "Left stick press", "Right stick press"
]
var button_remaps: Array[RemappingControl] = []

const ALL_JOY_AXES: Array[JoyAxis] = [
	JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y,

	JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,

	JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT,
]
const ALL_JOY_AXIS_NAMES: PackedStringArray = [
	"Left analog X", "Left analog Y",
	"Right analog X", "Right analog Y",
	"Left trigger", "Right trigger",
]
var axis_remaps: Array[RemappingControl] = []

@onready var REGISTERED_TRANSPORTS: Dictionary[Variant, String] = {
	UDPTransport.new: "UDP transport (not supported on web)", Transport.new: "Dummy transport"
}

var saver: SettingSaver = SettingSaver.new()

func _ready() -> void:
	# Set up debuglines
	for i in range(DebugLine.DEBUGLINE_MAX):
		debuglines.append("")

	# Set up transports
	var curr_inx = 0;
	for i in REGISTERED_TRANSPORTS.keys():
		transportpicker.add_item(REGISTERED_TRANSPORTS[i], curr_inx)
		transportpicker.set_item_metadata(curr_inx, i)
		curr_inx += 1
	transportpicker.select(0)
	
	transportpicker.item_selected.connect(func(_a):update_transport())
	address.text_changed.connect(update_transport)
	update_transport()
	
	# Set up joycon changes
	Input.joy_connection_changed.connect(func(_a,_b):update_joypads())
	update_joypads()
	joypadpicker.item_selected.connect(func(_a):update_selected_joypad())
	
	# Set up axis remaps
	for axis in range(len(ALL_JOY_AXES)):
		var remap = remapping_control.instantiate()
		remap.control_name = ALL_JOY_AXIS_NAMES[axis]
		remap.remap_type = RemappingControl.RemapType.AXIS
		remap.control_inx = axis
		axis_remaps.append(remap)
		control_remapping_container.add_child(remap)

	# Set up button remaps
	for button in range(len(ALL_JOY_BUTTONS)):
		var remap = remapping_control.instantiate()
		remap.control_name = ALL_JOY_BUTTON_NAMES[button]
		remap.remap_type = RemappingControl.RemapType.BUTTON
		remap.control_inx = button
		button_remaps.append(remap)
		control_remapping_container.add_child(remap)
	
	# Set up saving and load save
	saver.load_save(self)
	saver.enable_saving = true

	# Set up autosaving
	address.text_changed.connect(_on_savestate_update)
	for i in button_remaps + axis_remaps:
		i.mapping_changed.connect(_on_savestate_update)

var fasttick = 0;
func _process(delta: float) -> void:
	if fasttick < 0:
		fasttick = 1/update_tick_rate
		send_packet()
	fasttick -= delta
	debuglabel.text = "".join(debuglines)

func can_send_packet() -> bool:
	if selected_joypad_inx == -1:
		debuglines[DebugLine.PACKET_DBG] = "\nNo selected joypad!"
		return false
	if not is_transport_healthy:
		debuglines[DebugLine.PACKET_DBG] = "\nInternet transport broken"
		return false
	return true

# Returns true if there was an error
func is_error(error: Error, line: DebugLine, format_text: String = "Error: %s") -> bool:
	if error != OK:
		debuglines[line] += "\n"+format_text%error_string(error)
	return error != OK

var is_transport_healthy: bool = false
func update_transport():
	debuglines[DebugLine.TRANSPORT_DBG] = ""
	transport = transportpicker.get_selected_metadata().call()
	is_transport_healthy = not is_error(transport.connect_to_address(address.text), DebugLine.TRANSPORT_DBG)

func send_packet() -> void:
	if not can_send_packet():
		return
	
	var packet = PackedByteArray([])
	for axis in axis_remaps:
		var valu = axis.output_as_float()
		valu = int(round((valu + 1)*2**15))
		valu = max(0,valu)
		valu = min(2**16-1, valu)
		packet.append(valu & 0xff)
		valu = valu >> 8
		packet.append(valu & 0xff)
	
	for button in button_remaps:
		var valu = button.output_as_bool()
		packet.append(1 if valu else 0)
	
	debuglines[DebugLine.PACKET_DBG] = "\nPacket: "+packet.hex_encode()
	
	var error = transport.send_packet(packet)
	if error != OK:
		debuglines[DebugLine.PACKET_DBG] += "\nError: "+error_string(error)

var selected_joypad_inx: int = -1
var selected_joypad_hash: String = ""

func update_selected_joypad() -> void:
	selected_joypad_inx = joypadpicker.get_selected_id()
	selected_joypad_hash = get_joy_hash(selected_joypad_inx)

	for i in axis_remaps + button_remaps:
		i.joypad_id = selected_joypad_inx

func get_joy_hash(inx: int) -> String:
	var joyinfo: Dictionary = Input.get_joy_info(inx)
	var joy_hash: String = ":".join([
		Input.get_joy_name(inx),
		Input.get_joy_guid(inx),
		str(joyinfo.get("xinput_index","")),
		str(joyinfo.get("steam_input_index","")),
		str(joyinfo.get("raw_name","")),
		str(joyinfo.get("vendor_id","")),
		str(joyinfo.get("product_id","")),
		("K" if Input.is_joy_known(inx) else ""),
	])
	return joy_hash

func _on_savestate_update() -> void:
	saver.write_save(self)

func update_joypads() -> void:
	var joypads = Input.get_connected_joypads()
	var infotext = []
	var previous_joy_hash = selected_joypad_hash
	selected_joypad_hash = ""
	selected_joypad_inx = -1
	joypadpicker.clear()
	for joypad in joypads:
		var joypad_name = Input.get_joy_name(joypad)
		var joypad_hash = get_joy_hash(joypad)
		infotext.append("%s (%sknown joypad)\n    Joypad ID: %s" % [
			joypad_name,
			"" if Input.is_joy_known(joypad) else "not a ",
			joypad_hash
		])
		# Add to dropdown
		joypadpicker.add_item(joypad_name, joypad)
		# Do fuzzy match :D
		if joypad_hash == previous_joy_hash:
			selected_joypad_hash = joypad_hash
			selected_joypad_inx = joypad
	
	update_selected_joypad()
	debuglines[DebugLine.JOYPAD_INFO] = "No attached joypads!" if len(infotext) == 0 else "\n".join(infotext)
