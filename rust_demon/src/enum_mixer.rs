macro_rules! enum_mixer {
    {const $count:ident: $reprty:ty; $(#[$meta:meta])* $vis:vis enum $enum:ident { $($symbolnext:ident),* }} => {
    	$(#[$meta])*
    	#[repr($reprty)]
        $vis enum $enum {
        	$($symbolnext = ${index()},)*
        }

	    impl $enum {
	        $vis fn all_variants() -> std::slice::Iter<'static, Self> {
	        	[$($enum::$symbolnext,)*].iter()
	        }
	        $vis fn from_number(num: $reprty) -> Option<Self> {
	        	match num {
	        		$(x if x == $enum::$symbolnext as $reprty => Some($enum::$symbolnext),)*
	        		_ => None
	        	}
	        }
        }
    	// $vis const $count: $reprty = crate::enum_mixer::enum_mixer_count_symbols!($($symbolnext)*);
    	$vis const $count: $reprty = ${count($symbolnext)};
    };
}
pub(crate) use enum_mixer;


