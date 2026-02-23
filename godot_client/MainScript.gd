extends Node

@export var debuglabel: Label
@export var address: TextEdit
@export var devicepicker: OptionButton
@export_range(0, 10, 0) var slow_tick_rate: float = 1.0;
@export_range(1, 100, 0) var update_tick_rate: float = 32;

@onready var socket: PacketPeerUDP = PacketPeerUDP.new()
var selected_device: int = -1
var debugtexts: Array[String] = ["InputDebug","ErrorsOccasional","PacketData"]

const ALL_JOY_BUTTONS: Array[int] = [
	JOY_BUTTON_DPAD_UP, 
	JOY_BUTTON_DPAD_DOWN, 
	JOY_BUTTON_DPAD_LEFT, 
	JOY_BUTTON_DPAD_RIGHT,
	
	JOY_BUTTON_START,
	
	JOY_BUTTON_Y,
	JOY_BUTTON_A,
	JOY_BUTTON_B,
	JOY_BUTTON_X,
	
	JOY_BUTTON_BACK,
	
	JOY_BUTTON_LEFT_SHOULDER,
	JOY_BUTTON_RIGHT_SHOULDER,
	JOY_BUTTON_INVALID,
	JOY_BUTTON_INVALID,
	# Missing buttons: guide, left stick, right stick
]

const ALL_JOY_AXES: Array[int] = [
	JOY_AXIS_LEFT_X,
	JOY_AXIS_LEFT_Y,
	JOY_AXIS_RIGHT_X,
	JOY_AXIS_RIGHT_Y,
	# Missing axes:
	#JOY_AXIS_TRIGGER_LEFT,
	#JOY_AXIS_TRIGGER_RIGHT,
]

func _ready() -> void:
	debuglabel.text = "Initialised :D"

var slowtick = 0;
var fasttick = 0;
func _process(delta: float) -> void:
	if slowtick < 0:
		slowtick = slow_tick_rate
		occasional()
	if fasttick < 0:
		fasttick = 1/update_tick_rate
		send_packet()
	slowtick -= delta
	fasttick -= delta
	debuglabel.text = "".join(debugtexts)

func occasional() -> void:
	debugtexts[1] = ""
	var selection = devicepicker.selected
	selected_device = devicepicker.get_item_id(selection)
	devicepicker.clear()
	for i in Input.get_connected_joypads():
		devicepicker.add_item(Input.get_joy_name(i), i)
	devicepicker.selected = selection
	
	var error = socket.set_dest_address(address.text.split(":")[0], address.text.split(":")[1].to_int())
	if error != 0:
		debugtexts[1] = "\nSetting socket address error: "+error_string(error)


func send_packet() -> void:
	if selected_device == -1:
		debugtexts[2] = "\nNo selected device!"
		return
	if selected_device >= len(Input.get_connected_joypads()):
		debugtexts[2] = "\nSelected device doesn't exist!"
		return
	
	var packet = PackedByteArray([])
	for axis in ALL_JOY_AXES:
		var valu = Input.get_joy_axis(selected_device, axis)
		valu = int(round((valu + 1)*2**15))
		valu = max(0,valu)
		valu = min(2**16-1, valu)
		packet.append(valu & 0xff)
		valu = valu >> 8
		packet.append(valu & 0xff)
	
	for button in ALL_JOY_BUTTONS:
		var valu = Input.is_joy_button_pressed(selected_device, button)
		packet.append(1 if valu else 0)
	
	debugtexts[2] = "\nPacket: "+packet.hex_encode()
	socket.put_packet(packet)


func _input(event: InputEvent) -> void:
	var joypads = Input.get_connected_joypads()
	debugtexts[0] = "Joypad count: "+str(len(joypads))+"\n"
	for dev in joypads:
		debugtexts[0] += "\nDevice "+str(dev)+" - "+Input.get_joy_name(dev)+" (%srecognised)"%("" if Input.is_joy_known(dev) else "NOT ")+"\n Buttons:"
		for but in range(JOY_BUTTON_MAX):
			if Input.is_joy_button_pressed(dev, but):
				debugtexts[0] += " "+str(but)
		debugtexts[0] += "\nAxes: "
		for axi in range(JOY_AXIS_MAX):
			debugtexts[0] += "   #"+str(axi)+" "+ "%5s" % ("%.2f" % (Input.get_joy_axis(dev, axi)))
	pass
