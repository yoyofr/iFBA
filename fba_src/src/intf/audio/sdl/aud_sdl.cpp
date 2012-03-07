// SDL_Sound module

//#include "SDL.h"
#include "burner.h"
#include "aud_dsp.h"
#include <math.h>
#include "fbaconf.h"
#include <AudioToolbox/AudioToolbox.h>

static unsigned int nSoundFps;	

int (*GetNextSound)(int);				// Callback used to request more sound

//static SDL_AudioSpec audiospec;

//#define PLAYBACK_FREQ 22050
extern INT32 nAudSampleRate;
extern INT32 nAudSegCount;
//#define SOUND_BUFFER_NB 6


static int mInterruptShoudlRestart;
static short int **buffer_ana;
static volatile int buffer_ana_gen_ofs,buffer_ana_play_ofs;
static volatile int *buffer_ana_flag;

static AudioQueueRef mAudioQueue;
static AudioQueueBufferRef *mBuffers;
static float mVolume=1.0f;



static int nAudLoopLen;

static int SDLSoundGetNextSoundFiller(int)							// int bDraw
{
	if (nAudNextSound == NULL) {
		return 1;
	}
	memset(nAudNextSound, 0, nAudSegLen << 2);						// Write silence into the buffer
    
	return 0;
}

static int SDLSoundBlankSound()
{
	dprintf (_T("SDLBlankSound\n"));
    if (nAudNextSound) {
		dprintf (_T("blanking nAudNextSound\n"));
		memset(nAudNextSound, 0, nAudSegLen << 2);
	}
    
	return 0;
}

#define WRAP_INC(x) { x++; if (x >= nAudSegCount) x = 0; }

static int SDLSoundCheck() {
    int drawframe=0;
	if (!bAudPlaying) {
		dprintf(_T("SDLSoundCheck (not playing)\n"));
		return 0;
	}
    
    while (buffer_ana_flag[buffer_ana_gen_ofs]) {
		//[NSThread sleepForTimeInterval:DEFAULT_WAIT_TIME_MS];
        usleep(100); //0.1ms
		if (bAudPlaying==0) {
			return 0;
		}
	}
    
    //		dprintf(_T("Filling seg %i at %i\n"), nSDLFillSeg, nSDLFillSeg * (nAudSegLen << 2));
    int diff_buf=buffer_ana_gen_ofs-buffer_ana_play_ofs;
    if (diff_buf<0) diff_buf+=nAudSegCount;
    if (diff_buf>=nAudSegCount/2) drawframe=1;
    GetNextSound(drawframe);    
    //    if (nAudDSPModule) DspDo(nAudNextSound, nAudSegLen);
    memcpy(buffer_ana[buffer_ana_gen_ofs], nAudNextSound, nAudSegLen << 2);
    buffer_ana_flag[buffer_ana_gen_ofs]=1;
    buffer_ana_gen_ofs++;
    if (buffer_ana_gen_ofs==nAudSegCount) buffer_ana_gen_ofs=0;
    
	return 0;
}

static int SDLSoundExit() {
	//dprintf(_T("SDLSoundExit\n"));
    
    free(nAudNextSound);
	nAudNextSound = NULL;
    
    for (int i=0;i<nAudSegCount;i++) {
        free(buffer_ana[i]);
    }    
    free((void*)buffer_ana_flag);
    free(buffer_ana);
    
    
    for (int i=0; i<nAudSegCount; i++) {
		AudioQueueFreeBuffer( mAudioQueue, mBuffers[i] );		
    }
    free(mBuffers);
    
    
	return 0;
}

static int SDLSetCallback(int (*pCallback)(int)) {
    GetNextSound = pCallback;
    //dprintf(_T("SDL callback set\n"));
	return 0;
}

/********************************************************************/
/********************************************************************/


void interruptionListenerCallback (void *inUserData,UInt32 interruptionState ) {
    //	ModizMusicPlayer *mplayer=(ModizMusicPlayer*)inUserData;
	if (interruptionState == kAudioSessionBeginInterruption) {
		mInterruptShoudlRestart=0;
	}
    else if (interruptionState == kAudioSessionEndInterruption) {
		// if the interruption was removed, and the app had been playing, resume playback
		if (mInterruptShoudlRestart) {
            //check if headphone is used?
            CFStringRef newRoute;
            UInt32 size = sizeof(CFStringRef);
            AudioSessionGetProperty(kAudioSessionProperty_AudioRoute,&size,&newRoute);
            /*            if (newRoute) {
             if (CFStringCompare(newRoute,CFSTR("Headphone"),NULL)==kCFCompareEqualTo) {  //
             mInterruptShoudlRestart=0;
             }                
             }*/
            
            //			if (mInterruptShoudlRestart) [mplayer Pause:NO];
			mInterruptShoudlRestart=0;
		}
		
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty (
								 kAudioSessionProperty_AudioCategory,
								 sizeof (sessionCategory),
								 &sessionCategory
								 );
		AudioSessionSetActive (true);
	}
}
/*************************************************/
/* Audio property listener                       */
/*************************************************/
void propertyListenerCallback (void                   *inUserData,                                 // 1
							   AudioSessionPropertyID inPropertyID,                                // 2
							   UInt32                 inPropertyValueSize,                         // 3
							   const void             *inPropertyValue ) {
	if (inPropertyID==kAudioSessionProperty_AudioRouteChange ) {
        //		ModizMusicPlayer *mplayer = (ModizMusicPlayer *) inUserData; // 6
        /*		if ([mplayer isPlaying]) {
         CFDictionaryRef routeChangeDictionary = (CFDictionaryRef)inPropertyValue;        // 8
         //CFStringRef 
         NSString *oldroute = (NSString*)CFDictionaryGetValue (
         routeChangeDictionary,
         CFSTR (kAudioSession_AudioRouteChangeKey_OldRoute)
         );
         //NSLog(@"Audio route changed : %@",oldroute);
         if ([oldroute compare:@"Headphone"]==NSOrderedSame) {  // 9				
         [mplayer Pause:YES];
         }
         }*/
	}
}



void emu_AudioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
	mBuffer->mAudioDataByteSize = nAudLoopLen;
	if (bAudPlaying) {
        //consume another buffer
		if (buffer_ana_flag[buffer_ana_play_ofs]) {
            memcpy((char*)mBuffer->mAudioData,buffer_ana[buffer_ana_play_ofs],nAudLoopLen);
			
			
			buffer_ana_flag[buffer_ana_play_ofs]=0;
			buffer_ana_play_ofs++;
			if (buffer_ana_play_ofs==nAudSegCount) buffer_ana_play_ofs=0;
		} else {
			memset((char*)mBuffer->mAudioData,0,nAudLoopLen);  //WARNING : not fast enough!!
		}                
    } else {
        memset(mBuffer->mAudioData, 0, nAudLoopLen);
	}
    AudioQueueEnqueueBuffer( mQueue, mBuffer, 0, NULL);
}



static int SDLSoundInit()
{
    AudioStreamBasicDescription mDataFormat;
    UInt32 err;
    
    switch (ifba_conf.sound_freq) {
        case 0:
            nAudSampleRate=22050;
            break;
        default:
        case 1:
            nAudSampleRate=44100;
            break;
    }    
    switch (ifba_conf.sound_latency) {  //TODO: maybe should depend how sound_frequency
        case 0:
            nAudSegCount=4;
            break;
        case 1:
            nAudSegCount=6;
            break;
        case 2:
            nAudSegCount=8;
            break;
    }
    
    nSoundFps = nAppVirtualFps;
	nAudSegLen = (nAudSampleRate * 100 + (nSoundFps >> 1)) / nSoundFps;
	nAudLoopLen = (nAudSegLen * 1/*nAudSegCount*/) << 2;	    
    
    AudioSessionInitialize (
                            NULL,
                            NULL,
                            interruptionListenerCallback,
                            NULL
                            );
    UInt32 sessionCategory = kAudioSessionCategory_SoloAmbientSound;
    AudioSessionSetProperty (
                             kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory
                             );
    
    //Check if still required or not 
    Float32 preferredBufferDuration = nAudSegLen*1.0f/nAudSampleRate;                      // 1
    AudioSessionSetProperty (                                     // 2
                             kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                             sizeof (preferredBufferDuration),
                             &preferredBufferDuration
                             );
    AudioSessionPropertyID routeChangeID = kAudioSessionProperty_AudioRouteChange;    // 1
    AudioSessionAddPropertyListener (                                 // 2
                                     routeChangeID,                                                 // 3
                                     propertyListenerCallback,                                      // 4
                                     NULL                                                       // 5
                                     );
    AudioSessionSetActive (true);	
    
    
    buffer_ana_flag=(int*)malloc(nAudSegCount*sizeof(int));
    buffer_ana=(short int**)malloc(nAudSegCount*sizeof(unsigned short int *));
    for (int i=0;i<nAudSegCount;i++) {
        buffer_ana[i]=(short int *)malloc(nAudLoopLen);
        buffer_ana_flag[i]=0;
    }
    
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	
	mDataFormat.mSampleRate = nAudSampleRate;
    
	mDataFormat.mBitsPerChannel = 16;
    
	mDataFormat.mChannelsPerFrame = 2;
    
    mDataFormat.mBytesPerFrame = (mDataFormat.mBitsPerChannel>>3) * mDataFormat.mChannelsPerFrame;
	
    mDataFormat.mFramesPerPacket = 1; 
    mDataFormat.mBytesPerPacket = mDataFormat.mBytesPerFrame;
    
    /* Create an Audio Queue... */
    err = AudioQueueNewOutput( &mDataFormat, 
							  emu_AudioCallback, 
							  NULL, 
							  NULL, //CFRunLoopGetCurrent(),
							  kCFRunLoopCommonModes,
							  0, 
							  &mAudioQueue );
    
    /* ... and its associated buffers */
    mBuffers = (AudioQueueBufferRef*)malloc( sizeof(AudioQueueBufferRef) * nAudSegCount );
    for (int i=0; i<nAudSegCount; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer( mAudioQueue, nAudLoopLen, &mBuffer );		
		mBuffers[i]=mBuffer;
    }
    /* Set initial playback volume */
    err = AudioQueueSetParameter( mAudioQueue, kAudioQueueParam_Volume, mVolume );
    
    nAudNextSound = (short*)malloc(nAudSegLen << 2);
	if (nAudNextSound == NULL) {
		SDLSoundExit();
		return 1;
	}
    memset(nAudNextSound,0,nAudSegLen<<2);
    
    
    return 0;
}

static int SDLSoundPlay()
{
    //	dprintf(_T("SDLSoundPlay\n"));
    
    UInt32 err;
    UInt32 i;
    
    AudioQueueStop( mAudioQueue, TRUE );
    /*
     * Enqueue all the allocated buffers before starting the playback.
     * The audio callback will be called as soon as one buffer becomes
     * available for filling.
     */
    
    buffer_ana_gen_ofs=buffer_ana_play_ofs=0;
    for (i=0; i<nAudSegCount; i++) {
        memset(buffer_ana[i],0,nAudLoopLen);
        memset(mBuffers[i]->mAudioData,0,nAudLoopLen);
        mBuffers[i]->mAudioDataByteSize = nAudLoopLen;
        AudioQueueEnqueueBuffer( mAudioQueue, mBuffers[i], 0, NULL);
        //		[self iPhoneDrv_FillAudioBuffer:mBuffers[i]];
        
    }
    bAudPlaying=1;
    /* Start the Audio Queue! */
    //AudioQueuePrime( mAudioQueue, 0,NULL );
    err = AudioQueueStart( mAudioQueue, NULL );
    
	return 0;
}

static int SDLSoundStop()
{
    //	dprintf(_T("SDLSoundStop\n"));
	bAudPlaying = 0;    
    AudioQueueStop( mAudioQueue, TRUE );
	//AudioQueueReset( mAudioQueue );	
    
	return 0;
}

static int SDLSoundSetVolume()
{
	dprintf(_T("SDLSoundSetVolume\n"));
	return 1;
}

static int SDLGetSettings(InterfaceInfo* /* pInfo */)
{
	return 0;
}

struct AudOut AudOutSDL = { SDLSoundBlankSound, SDLSoundCheck, SDLSoundInit, SDLSetCallback, SDLSoundPlay, SDLSoundStop, SDLSoundExit, SDLSoundSetVolume, SDLGetSettings, _T("SDL audio output") };
