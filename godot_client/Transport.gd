extends RefCounted
class_name Transport

var current_address: String = ""

func connect_to_address(new_address: String) -> Error:
	if new_address == current_address:
		return OK
	var result = change_address(new_address)
	if result == OK:
		current_address = new_address
	return result

func change_address(_new_address: String) -> Error:
	return ERR_UNCONFIGURED

func send_packet(_packet: PackedByteArray) -> Error:
	return ERR_UNCONFIGURED
