mod joystick;
mod network;
mod error;
pub use error::Error;
use joystick::Axis;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let joystick = joystick::Joystick::new().expect("Can't acquire joystick!");
    println!(
        "Created joystick with device path {}",
        joystick.device_path().expect("Can't acquire joystick!").to_string_lossy()
    );
    
    loop {
        println!("Down!");
        joystick.move_axis(Axis::Y, -512).expect("AAA");
        joystick.synchronise().expect("AAA");
        std::thread::sleep(std::time::Duration::from_secs_f32(1.0));
        println!("Up!");
        joystick.move_axis(Axis::Y, 512).expect("AAA");
        joystick.synchronise().expect("AAA");
        std::thread::sleep(std::time::Duration::from_secs_f32(1.0));
    }

    Ok(())
}
