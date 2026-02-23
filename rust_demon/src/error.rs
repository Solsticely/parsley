
#[derive(thiserror::Error, Debug)]
pub enum Error {
	#[error("Websocket error")]
	WebSocketError(#[from] tokio_tungstenite::tungstenite::Error),
	#[error("IO Error")]
	IoError(#[from] std::io::Error),
}

