extends Transport
class_name UDPTransport

var socket: PacketPeerUDP = PacketPeerUDP.new()

func change_address(address: String) -> Error:
	if ":" not in address:
		return ERR_INVALID_PARAMETER
	return socket.set_dest_address(address.split(":")[0], address.split(":")[1].to_int())

func send_packet(packet: PackedByteArray) -> Error:
	return socket.put_packet(packet)
