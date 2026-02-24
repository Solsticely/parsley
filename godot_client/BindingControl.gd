extends VBoxContainer
class_name BindingControl

@export var control_name: String:
	set(text):
		control_name = text
		_on_control_name_update()

@export var binding_type: BindingType:
	set(value):
		binding_type = value
		_on_control_update()

@export var control_inx: int = 0:
	set(value):
		control_inx = value
		_on_control_update()

@export var joypad_id: int:
	set(value):
		joypad_id = value
		_on_joypad_change()
@onready var binding_button: Button = $Binding/Button
@onready var control_label: Label = $Binding/Name
@onready var indicator: ProgressBar = $Indicator

var joypad_deactivated: bool = true

enum BindingType {
	BUTTON,
	AXIS
}

signal mapping_changed

func _on_control_name_update():
	if control_label != null:
		control_label.text = control_name

func _on_control_update():
	if binding_button != null:
		match binding_type:
			BindingType.BUTTON:
				binding_button.text = "Button %d" % control_inx
			BindingType.AXIS:
				binding_button.text = "Axis %d" % control_inx
	mapping_changed.emit()

func _on_binding_button_clicked():
	binding_button.text = "<Press keybind>"
	var value: Array[Variant] = await get_next_pressed_control()
	if len(value) == 0:
		return
	binding_type = value[0]
	control_inx = value[1]

# Returns [BindingType, BindingIndex]
func get_next_pressed_control() -> Array[Variant]:
	# Get initial state of everything
	var buttons: Array[bool] = []
	for i in range(JOY_BUTTON_MAX):
		buttons.append(Input.is_joy_button_pressed(joypad_id, i))
	var axes: Array[float] = []
	for i in range(JOY_AXIS_MAX):
		axes.append(Input.get_joy_axis(joypad_id, i))
	
	while true:
		# Wait a bit so we're not running a hot loop
		await get_tree().create_timer(0.1).timeout
		
		# Check if any buttons are in a different state
		for i in range(JOY_BUTTON_MAX):
			if buttons[i] != Input.is_joy_button_pressed(joypad_id, i):
				return [BindingType.BUTTON, i]
		
		# Check if any axes are in a different state
		for i in range(JOY_AXIS_MAX):
			if abs(axes[i] - Input.get_joy_axis(joypad_id, i)) > 0.3:
				return [BindingType.AXIS, i]
	
	return []

func _on_joypad_change():
	var max_joypad_id: int = -1
	if len(Input.get_connected_joypads()) != 0:
		max_joypad_id = Input.get_connected_joypads().max()
	var correct_joypad_id: int = clamp(joypad_id, -1, max_joypad_id)
	if joypad_id != correct_joypad_id:
		joypad_id = correct_joypad_id
		return
	joypad_deactivated = joypad_id == -1
	if indicator != null:
		indicator.indeterminate = joypad_deactivated
	if binding_button != null:
		binding_button.disabled = joypad_deactivated

func _ready() -> void:
	_on_joypad_change()
	_on_control_update()
	_on_control_name_update()
	binding_button.pressed.connect(_on_binding_button_clicked)

func output_as_float() -> float:
	if joypad_deactivated:
		return 0

	match binding_type:
		BindingType.BUTTON:
			return 1 if Input.is_joy_button_pressed(joypad_id, control_inx) else -1
		BindingType.AXIS:
			return Input.get_joy_axis(joypad_id, control_inx)

	assert(false, "Unhandled binding type")
	return 0

func output_as_bool() -> bool:
	if joypad_deactivated:
		return false
	
	match binding_type:
		BindingType.BUTTON:
			return Input.is_joy_button_pressed(joypad_id, control_inx)
		BindingType.AXIS:
			return Input.get_joy_axis(joypad_id, control_inx) > 0

	assert(false, "Unhandled binding type")
	return 0

func _process(_delta: float) -> void:
	if not joypad_deactivated:
		indicator.value = output_as_float()
