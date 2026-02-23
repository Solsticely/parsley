
use std::net::{SocketAddr, ToSocketAddrs};

use crate::network;

pub struct Connection {
	listener: std::net::UdpSocket
}

impl Connection {
	pub fn new(listen_addr: impl ToSocketAddrs) -> Result<Self, crate::Error> {
		let listen_addr = listen_addr.to_socket_addrs()?.collect::<Vec<SocketAddr>>();
		let listener = std::net::UdpSocket::bind(&*listen_addr)?;
		eprintln!("Listening on {:?}", &listen_addr);
		Ok(Connection { listener })
	}
	pub fn next_message(&self) -> Result<network::Packet, crate::Error> {
		let mut buffer = [0_u8; network::PACKET_SIZE];
		while self.listener.recv(&mut buffer)? != network::PACKET_SIZE { }

		Ok(network::Packet(buffer))
	}
}


// use std::net::{SocketAddr, ToSocketAddrs};
// use tokio_stream::StreamExt;

// pub struct Connection {
// 	ws: tokio_tungstenite::WebSocketStream<tokio::net::TcpStream>
// }

// impl Connection {
// 	async fn new(listen_addr: impl ToSocketAddrs) -> Result<Self, crate::Error> {
// 		let socket_addrs: Vec<SocketAddr> = listen_addr.to_socket_addrs()?.collect();

// 		let port: tokio::net::TcpListener = tokio::net::TcpListener::bind(&*socket_addrs).await?;

// 		let pin = String::from("282148"); // TODO: randomise pin!

// 		// TODO: hash pin over transit
// 		eprintln!("Listening on {:?}", socket_addrs);
// 		eprintln!("Pin: {}", pin);

// 		loop {
// 			let (stream, addr) = port.accept().await?;
			
// 			eprintln!("Incoming connection from {:?}", addr);
// 			stream.set_nodelay(true);
// 			let Ok(mut stream) = tokio_tungstenite::accept_async(stream).await else {
// 				eprintln!("Broken connection, ignoring..");
// 				continue
// 			};
// 			let Ok(Some(Ok(received_pin))) = tokio::time::timeout(std::time::Duration::from_secs_f32(3.0), stream.next()).await else {
// 				eprintln!("Didn't get a pin from this connection in time, ignoring..");
// 				continue
// 			};
// 			if received_pin != tungstenite::Message::Text((&pin).into()) {
// 				eprintln!("Got a wrong pin! ignoring..");
// 				continue
// 			}
			
// 			eprintln!("Connected to {:?}!", addr);
// 			return Ok(Connection {ws: stream});
// 		}
// 	}
// 	async fn next_message(&mut self) -> Result<Vec<super::Packet>, crate::Error> {
// 		use tungstenite::Message;
// 		let next_token = self.ws.next()
// 			.await.expect("Token stream ended")?;
// 		let Message::Binary(next_token) = next_token else {
// 			return Err(crate::Error::BadPacket(next_token));
// 		};

// 		let (packets, leftover) = next_token.as_chunks::<2>()
// 		if leftover.len != 0 {
// 			return Err(crate::Error::BadPacket(next_token))
// 		}
// 		if next_token.len() & 1 != 0 {
// 			return Err
// 		}
// 		Ok(Vec::new())
// 	}
// }


