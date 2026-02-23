#![feature(macro_metavar_expr)]
mod joystick;
mod network;
mod error;
mod enum_mixer;

pub(crate) use enum_mixer::enum_mixer;
pub use error::Error;
use joystick::Axis;
use tokio;

fn main() -> Result<(), Error> {
    let joystick = joystick::Joystick::new().expect("Can't acquire joystick!");
    println!(
        "Created joystick with device path {}",
        joystick.device_path().expect("Can't acquire joystick!").to_string_lossy()
    );
    let connection = network::Connection::new("192.168.0.17:8800")?;
    
    loop {
        connection.next_message()?.apply_packet(&joystick)?;
    }

    // loop {
    //     println!("Down!");
    //     joystick.move_axis(Axis::Y, -512).expect("AAA");
    //     joystick.synchronise().expect("AAA");
    //     std::thread::sleep(std::time::Duration::from_secs_f32(1.0));
    //     println!("Up!");
    //     joystick.move_axis(Axis::Y, 512).expect("AAA");
    //     joystick.synchronise().expect("AAA");
    //     std::thread::sleep(std::time::Duration::from_secs_f32(1.0));
    // }
}
