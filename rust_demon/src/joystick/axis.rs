crate::enum_mixer!{
    const AXIS_COUNT: u8;

    #[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
    pub enum Axis { X, Y, RX, RY }
}

impl Axis {
    pub(super) fn to_evdev_axis(&self) -> input_linux::AbsoluteAxis {
        use Axis::*;

        match &self {
            X => input_linux::AbsoluteAxis::X,
            Y => input_linux::AbsoluteAxis::Y,
            RX => input_linux::AbsoluteAxis::RX,
            RY => input_linux::AbsoluteAxis::RY,
        }
    }
}
