
#[derive(thiserror::Error, Debug)]
pub enum Error {
	#[error("Websocket error")]
	WebSocketError(#[from] tungstenite::Error),
	#[error("IO Error")]
	IoError(#[from] std::io::Error),
	#[error("Joystick driver error")]
	JoystickError(#[from] crate::joystick::Error),
	#[error("Got badly formed packet: {0}")]
	BadPacket(String),
}

