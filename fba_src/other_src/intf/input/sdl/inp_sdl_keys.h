#ifdef BUILD_SDL

typedef enum {
	GN_NONE=0,
    GN_RIGHT,	
    GN_UPRIGHT,
    GN_UP,
	GN_UPLEFT,
    GN_LEFT,
	GN_DOWNLEFT,    
	GN_DOWN,
	GN_DOWNRIGHT,
    GN_A,
	GN_B,
	GN_C,
	GN_D,
    GN_E,
    GN_F,
	GN_START,
	GN_SELECT_COIN,
	GN_MENU_KEY,
	GN_HOTKEY1,
	GN_HOTKEY2,
	GN_HOTKEY3,
	GN_SERVICE,
    GN_TURBO,
	GN_MAX_KEY,
}GNGEO_BUTTON;

extern unsigned char joy_state[4][GN_MAX_KEY];

#endif
