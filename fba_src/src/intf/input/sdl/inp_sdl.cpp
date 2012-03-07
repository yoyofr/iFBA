// Module for input using SDL
//#include <SDL.h>

#include "burner.h"
#include "inp_sdl_keys.h"

#define MAX_JOYSTICKS 4

static int* JoyPrevAxes = NULL;
static int nJoystickCount = 0;						// Number of joysticks connected to this machine
extern int vpad_button_nb;
extern float joy_analog_x[MAX_JOYSTICKS];
extern float joy_analog_y[MAX_JOYSTICKS];
extern float joy_analog_l[MAX_JOYSTICKS];
extern float joy_analog_r[MAX_JOYSTICKS];
extern void updateWiimotes(void);
int pendingReset=0;

// Sets up one Joystick (for example the range of the joystick's axes)
static int SDLinpJoystickInit(int i)
{
    //	JoyList[i] = SDL_JoystickOpen(i);
	return 0;
}

// Set up the keyboard
static int SDLinpKeyboardInit()
{
	return 0;
}

// Get an interface to the mouse
static int SDLinpMouseInit()
{
	return 0;
}

int SDLinpSetCooperativeLevel(bool bExclusive, bool /*bForeGround*/)
{
    //	SDL_WM_GrabInput((bDrvOkay && (bExclusive || nVidFullscreen)) ? SDL_GRAB_ON : SDL_GRAB_OFF);
    //	SDL_ShowCursor((bDrvOkay && (bExclusive || nVidFullscreen)) ? SDL_DISABLE : SDL_ENABLE);
    
	return 0;
}

int SDLinpExit()
{
	nJoystickCount = 0;
    
	if (JoyPrevAxes) free(JoyPrevAxes);
	JoyPrevAxes = NULL;
    
	return 0;
}

int SDLinpInit()
{
	int nSize;
    
	SDLinpExit();
    
	nSize = MAX_JOYSTICKS * 8 * sizeof(int);
	if ((JoyPrevAxes = (int*)malloc(nSize)) == NULL) {
		SDLinpExit();
		return 1;
	}
	memset(JoyPrevAxes, 0, nSize);
    
	// Set up the joysticks
	nJoystickCount = 4;
    
	return 0;
}

static unsigned char bKeyboardRead = 0;

static unsigned char bJoystickRead = 0;

static unsigned char bMouseRead = 0;

// Call before checking for Input in a frame
int SDLinpStart() {
    
	// Keyboard not read this frame
	bKeyboardRead = 0;
    
	// No joysticks have been read for this frame
	bJoystickRead = 0;
    
	// Mouse not read this frame
	bMouseRead = 0;
    
	return 0;
}

// Read one of the joysticks
static int ReadJoystick()
{
	if (bJoystickRead) {
		return 0;
	}        
    
	// All joysticks have been Read this frame
	bJoystickRead = 1;
    
	return 0;
}

// Read one joystick axis
int SDLinpJoyAxis(int i, int nAxis)
{
	if (i < 0 || i >= nJoystickCount) {				// This joystick number isn't connected
		return 0;
	}
    
	if (ReadJoystick() != 0) {						// There was an error polling the joystick
		return 0;
	}
    
    if (nAxis > 2) return 0;
    
    switch (nAxis) {
        case 0:
            return joy_analog_x[i]*32767;
            break;
        case 1:
            return joy_analog_y[i]*32767;
            break;
        case 2:
            return joy_analog_l[i]*32767;
            break;
        case 3:
            return joy_analog_r[i]*32767;
            break;
    }
    
    return 0;
}

// Read the keyboard
static int ReadKeyboard() {
	if (bKeyboardRead) {							// already read this frame - ready to go
		return 0;
	}
    
    updateWiimotes();
    
	// The keyboard has been successfully Read this frame
	bKeyboardRead = 1;
    
	return 0;
}

static int ReadMouse() {
	if (bMouseRead) {
		return 0;
	}
	bMouseRead = 1;
    
	return 0;
}

// Read one mouse axis
int SDLinpMouseAxis(int i, int nAxis)
{
	if (i < 0 || i >= 1) {									// Only the system mouse is supported by SDL
		return 0;
	}
    
	return 0;
}

// Check a subcode (the 40xx bit in 4001, 4102 etc) for a joystick input code
static int JoystickState(int i, int nSubCode) {
    return 0;
}

// Check a subcode (the 80xx bit in 8001, 8102 etc) for a mouse input code
static int CheckMouseState(unsigned int nSubCode) {
	return 0;
}

// Get the state (pressed = 1, not pressed = 0) of a particular input code
int SDLinpState(int code) {    
    if (code < 0) {
        return 0;
    }
    
    ReadKeyboard();
    
    if (code < 256) {
        switch(code) {
            case 0x02: // 1P start
                return joy_state[0][GN_START];
                break;
            case 0x03: // 2P start
                return joy_state[1][GN_START];
                break;
            case 0x06: // 1P coin 
                return joy_state[0][GN_SELECT_COIN];
                break;
            case 0x07: // 2P coin 
                return joy_state[1][GN_SELECT_COIN];
                break;
            case 0x3c: //f2
                break;
            case 0x3D: //f3
                if (pendingReset) {
                    pendingReset=0;
                    return 1;
                }
                break;
        }
        return 0;
    }
    
    if (code < 0x4000) {
        return 0;
    }
    
    // Codes 4000-8000 = Joysticks
    if (code < 0x8000) {
        int i = (code - 0x4000) >> 8;
        if (i >= nJoystickCount) {					// This gamepad number isn't connected
            return 0;
        }
        switch (code&0xFF) {
            case 0x00: // left
                return joy_state[i][GN_LEFT]|joy_state[i][GN_UPLEFT]|joy_state[i][GN_DOWNLEFT];
                break;
            case 0x01: // right 
                return joy_state[i][GN_RIGHT]|joy_state[i][GN_UPRIGHT]|joy_state[i][GN_DOWNRIGHT];
                break;
            case 0x02: // up 
                return joy_state[i][GN_UP]|joy_state[i][GN_UPLEFT]|joy_state[i][GN_UPRIGHT];
                break;
            case 0x03: // down 
                return joy_state[i][GN_DOWN]|joy_state[i][GN_DOWNLEFT]|joy_state[i][GN_DOWNRIGHT];
                break;            
            case 0x80: //fire1
                if (vpad_button_nb<4+1) vpad_button_nb=4+1;
                return joy_state[i][GN_A];
                break;
            case 0x81: //fire 2 
                if (vpad_button_nb<4+2) vpad_button_nb=4+2;
                return joy_state[i][GN_B];
                break;
            case 0x82: // etc 
                if (vpad_button_nb<4+3) vpad_button_nb=4+3;
                return joy_state[i][GN_C];            
                break;
            case 0x83: 
                if (vpad_button_nb<4+4) vpad_button_nb=4+4;
                return joy_state[i][GN_D];            
                break;
            case 0x84:
                if (vpad_button_nb<4+5) vpad_button_nb=4+5;
                return joy_state[i][GN_E];            
                break;
            case 0x85: 
                if (vpad_button_nb<4+6) vpad_button_nb=4+6;
                return joy_state[i][GN_F];            
                break;
        }
        
        return 0;
    }
    
    // Codes 8000-C000 = mouse
    if (code < 0xC000) {
        return 0;
    }
    
    return 0;
}

// This function finds which key is pressed, and returns its code
int SDLinpFind(bool CreateBaseline)
{
    int nRetVal = -1;										// assume nothing pressed
    
    return nRetVal;
}

int SDLinpGetControlName(int nCode, TCHAR* pszDeviceName, TCHAR* pszControlName)
{
    return 0;
}

struct InputInOut InputInOutSDL = { SDLinpInit, SDLinpExit, SDLinpSetCooperativeLevel, SDLinpStart, SDLinpState, SDLinpJoyAxis, SDLinpMouseAxis, SDLinpFind, SDLinpGetControlName, NULL, _T("SDL input") };
