crate::enum_mixer!{
    const BUTTON_COUNT: u8;

    #[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
    pub enum Button {
        LeftNorth,
        LeftSouth,
        LeftEast,
        LeftWest,

        LeftSpecial,

        RightNorth,
        RightSouth,
        RightEast,
        RightWest,

        RightSpecial,

        L1,
        R1,
        L2,
        R2
    }
}

impl Button {
    pub(super) fn to_evdev_button(&self) -> input_linux::Key {
        use input_linux::Key::*;
        use Button::*;

        match &self {
            LeftNorth => ButtonDpadUp,
            LeftSouth => ButtonDpadDown,
            LeftEast => ButtonDpadLeft,
            LeftWest => ButtonDpadRight,

            LeftSpecial => ButtonStart,

            RightNorth => ButtonNorth,
            RightSouth => ButtonSouth,
            RightEast => ButtonEast,
            RightWest => ButtonWest,

            RightSpecial => ButtonSelect,

            L1 => ButtonTL,
            R1 => ButtonTR,
            L2 => ButtonTL2,
            R2 => ButtonTR2,
        }
    }
}
