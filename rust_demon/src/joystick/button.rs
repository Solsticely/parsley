crate::enum_mixer!{
    const BUTTON_COUNT: u8;

    #[derive(Debug, PartialEq, Eq, Hash, Clone, Copy)]
    pub enum Button {
        XboxA,
        XboxB,
        XboxX,
        XboxY,

        DpadUp,
        DpadDown,
        DpadLeft,
        DpadRight,

        Start,
        Select,
        Home,

        LeftShoulder,
        RightShoulder,
        LeftThumb,
        RightThumb
    }
}

impl Button {
    pub(super) fn to_evdev_button(&self) -> input_linux::Key {
        use input_linux::Key::*;
        use Button::*;

        match &self {
            XboxA => ButtonSouth,
            XboxB => ButtonEast,
            XboxX => ButtonNorth,
            XboxY => ButtonWest,

            DpadUp => ButtonDpadUp,
            DpadDown => ButtonDpadDown,
            DpadLeft => ButtonDpadLeft,
            DpadRight => ButtonDpadRight,

            Button::Start => ButtonStart,
            Button::Select => ButtonSelect,
            Button::Home => ButtonMode,

            LeftShoulder => ButtonTL,
            RightShoulder => ButtonTR,
            LeftThumb => ButtonThumbl,
            RightThumb => ButtonThumbr,
        }
    }
}
