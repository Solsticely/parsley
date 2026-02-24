crate::enum_mixer!{
    const AXIS_COUNT: u8;

    #[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
    pub enum Axis {
        LeftX,
        LeftY,
        RightX,
        RightY,
        LeftT,
        RightT
    }
}

impl Axis {
    pub(super) fn to_evdev_axis(&self) -> input_linux::AbsoluteAxis {
        use Axis::*;

        match &self {
            LeftX => input_linux::AbsoluteAxis::X,
            LeftY => input_linux::AbsoluteAxis::Y,
            RightX => input_linux::AbsoluteAxis::RX,
            RightY => input_linux::AbsoluteAxis::RY,
            LeftT => input_linux::AbsoluteAxis::Z,
            RightT => input_linux::AbsoluteAxis::RZ,
        }
    }
}
