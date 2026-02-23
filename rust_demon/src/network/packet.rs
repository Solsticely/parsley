use crate::{joystick::{AXIS_COUNT, Axis, BUTTON_COUNT, Button, Joystick}};

// const BLOCK_SIZE: usize = 16;  // AES works in 16 byte block sizes
// const COUNTER_SIZE: usize = 2;  // 4 hours @ 64 pkt/s can be counted in a 2-byte counter
// const UID_SIZE: usize = 1;  // 256 separate users is alot
// const MIN_MAGIC_SIZE: usize = 3;  // 24 bit security against noise attacks (1 in 16777216 random messages have a chance of passing validation)
// 1 byte per button, 2 bytes per axis, plus other junk
// const FULL_STATE_SIZE: usize = (AXIS_COUNT as usize * 2 + BUTTON_COUNT as usize + COUNTER_SIZE + UID_SIZE + ) >> 3;
// const MAGIC_SIZE: usize = ;

// pub enum Packet {
// 	AxisUpdate(Axis, f32),
// 	ButtonPress(Button),
// 	ButtonRelease(Button),
// 	FullState([u8;FULL_STATE_SIZE]),
// 	Reset,
// }

// impl Packet {
// 	pub fn apply_packet(&self, joystick: &Joystick) -> Result<(), crate::Error> {
// 		use Packet::*;
// 		match self {
// 			AxisUpdate(axis, value) => joystick.move_axis_float(*axis, *value)?,
// 			ButtonPress(button) => joystick.button_press(*button, true)?,
// 			ButtonRelease(button) => joystick.button_press(*button, false)?,
// 			Reset => joystick.reset()?,
// 		};

// 		Ok(())
// 	}
// 	pub fn deserialise(packet: u16) -> Self {
// 		let pktdata = packet / 4;
// 		use Packet::*;
// 		match packet % 4 {
// 			0 => AxisUpdate(Axis::from_number((pktdata % AXIS_COUNT as u16) as u8).unwrap(), Self::deserialize_range(pktdata/AXIS_COUNT as u16)),
// 			1 => ButtonPress(Button::from_number((pktdata % BUTTON_COUNT as u16) as u8).unwrap()),
// 			2 => ButtonRelease(Button::from_number((pktdata % BUTTON_COUNT as u16) as u8).unwrap()),
// 			3 => Reset,
// 			_ => unreachable!()
// 		}
// 	}
// 	fn deserialize_range(range: u16) -> f32 {
// 		((range + 512) as f32 / 512.0).clamp(-1.0,1.0)
// 	}
// }

pub const PACKET_SIZE: usize = AXIS_COUNT as usize * 2 + BUTTON_COUNT as usize;
pub struct Packet(pub [u8; PACKET_SIZE]);

impl Packet {
	pub fn apply_packet(&self, joystick: &Joystick) -> Result<(), crate::Error> {
		let mut pointer = 0;
		for axis in Axis::all_variants() {
			let value = u16::from_le_bytes(*self.0[pointer..pointer+2].first_chunk::<2>().unwrap()) as f32 - (u16::MAX >> 1) as f32;
			let value = value / (u16::MAX >> 1) as f32 - 1.0;
			joystick.move_axis_float(*axis, value)?;
			pointer += 2
		}

		for button in Button::all_variants() {
			let value = self.0[pointer];
			if value & 254 != 0 { return Err(crate::Error::BadPacket("Corrupted button info".to_owned())) }
			joystick.button_press(*button, value == 1)?;
			pointer += 1;
		}
		joystick.synchronise().map_err(|x|x.into())
	}
}


