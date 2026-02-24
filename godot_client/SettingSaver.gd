extends RefCounted
class_name SettingSaver

var enable_saving: bool = false

func write_save(main_script: MainScript) -> void:
	if not enable_saving: return
	enable_saving = false

	var savestate: Dictionary[String, Variant] = {
		"binds_axes": get_all_bindings(main_script.axis_bindings),
		"binds_buttons": get_all_bindings(main_script.button_bindings),
		"address": main_script.address.text
	}

	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(savestate))
	file.close()
	
	enable_saving = true

func get_all_bindings(list: Array[BindingControl]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for binding in list:
		result.append({
			"inx": binding.control_inx,
			"is_button": binding.binding_type == BindingControl.BindingType.BUTTON
		})
	
	return result

func ensure_type(item: Variant, type: Variant.Type, default: Variant) -> Variant:
	if type == TYPE_INT:
		return int(round(ensure_type(item, TYPE_FLOAT, default)))
	return item if is_instance_of(item, type) else default

func safe_index(base: Variant, index: Variant, type: Variant.Type, default: Variant) -> Variant:
	var op_as_str = "`%s[%s] as %s`, returning `%s`" % [str(base), str(index), str(type), str(default)]
	if typeof(base) == TYPE_ARRAY:
		if typeof(index) != TYPE_INT:
			push_error("Index of array isn't of type int on save operation "+op_as_str)
			return default
		if len(base) <= index:
			push_error("Index of array exceeds array length on save operation "+op_as_str)
			return default
	elif typeof(base) == TYPE_DICTIONARY:
		if index not in base:
			push_error("Dictionary index not present on save operation "+op_as_str)
			return default
	else:
		push_error("Expected subscriptable object on save operation "+op_as_str)
		return default

	return ensure_type(base[index], type, default)

func safe_load_control_mapping(inx: int, json: Variant, bindings: Array[BindingControl], max_control_inx: int) -> Variant:
	var mapping: Dictionary = safe_index(json, inx, TYPE_DICTIONARY, {"skip": true, "mapping_had_wrong_type": 1})
	if "skip" in mapping or "is_button" not in mapping or "inx" not in mapping:
		return mapping
	var is_button: bool = ensure_type(mapping["is_button"], TYPE_BOOL, true)
	var control_inx: int = ensure_type(mapping["inx"], TYPE_INT, -1)
	if typeof(mapping["is_button"]) != TYPE_BOOL or control_inx < 0 or control_inx > max_control_inx:
		return mapping
	bindings[inx].control_inx = control_inx
	bindings[inx].binding_type = BindingControl.BindingType.BUTTON if is_button else BindingControl.BindingType.AXIS
	return null

func load_save(main_script: MainScript) -> void:
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file == null:
		print("No save found!")
		return
	var whole_text = file.get_as_text()
	var as_json = JSON.parse_string(whole_text)
	
	var binds_axes: Array = safe_index(as_json, "binds_axes", TYPE_ARRAY, [])
	var binds_buttons: Array = safe_index(as_json, "binds_buttons", TYPE_ARRAY, [])

	main_script.address.text = safe_index(as_json, "address", TYPE_STRING, "127.0.0.1:8800")

	for inx in range(min(len(binds_buttons), len(main_script.button_bindings))):
		var result = safe_load_control_mapping(inx, binds_buttons, main_script.button_bindings, JOY_BUTTON_MAX)
		if result != null:
			push_error("Encountered bad mapping in save: base[%s]=%s"%[str(inx), str(result)])

	for inx in range(min(len(binds_axes), len(main_script.axis_bindings))):
		var result = safe_load_control_mapping(inx, binds_axes, main_script.axis_bindings, JOY_AXIS_MAX)
		if result != null:
			push_error("Encountered bad mapping in save: base[%s]=%s"%[str(inx), str(result)])
