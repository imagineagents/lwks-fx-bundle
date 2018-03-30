//--------------------------------------------------------------//
//
// 
// This effect is based on the effect: "Lift, Gamma, Gain"
// Original file name: Sample 1 - Single input, Single pass.fx 
// And came from the Lightworks folder: "Effect Templates"
// Thanks!
// January 2017: LW user "schrauber" has significantly reduced this effect 
//                                   and equipped it with a remote control.
//
// This version modified by jwrl to preserve the alpha channel
// and range limit the returned levels 17 February 2017.
//
// 19 Febuary 2017; modified by user "schrauber": RcSampler settings, Clamp changed to Border
//                  and the setting range of the sliders changed from "MinVal = 1.0" to 0.0.

//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC RGB-Gain";                   // The title
   string Category    = "Remote Control Colour Grade";   // Governs the category that the effect appears in in Lightworks
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;
sampler FgSampler = sampler_state
{
   Texture = <Input>;
};



texture RC;
sampler RcSampler = sampler_state
{
   Texture = <RC>;
   AddressU = Border; 					// If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control.
   AddressV = Border;					// If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control.
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};




////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
/////////////////////////////////////////////////////////////////////////////


 
float ChRed
<
   string Description =  "Channel Red";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 1.0;


float ChGreen
<
   string Description =  "Channel Green";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 2.0;


float ChBlue
<
   string Description =  "ChannelBlue";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> = 3.0;






//////////////////////////////////////////////////////////////////////////////
// Definitions , declarations,  macros	
//////////////////////////////////////////////////////////////////////////////




// ---- Receiving from the remote control input -------



      #define RECEIVING(Ch)    (    (   tex2D(RcSampler, POSCHANNEL(floor(Ch))).r				/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of  "Ch" (receiving channel) is only passed to sub macros  */\
                                 + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255)				/* Green = bit 9 to bit 16   */\
                                ) * 2 - step( 0.001 , STATUS_CH_IN(Ch))  )					// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)   ,  "Step" prevents a change in the received value 0.0 if the channel can not be received.  If Status Channel > 0.001  (then the adjustemnd *2-1)  ,  If the Status = 0.0 then the adjustment *2-0 

      #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)				// Status of the receiving channel ,   blue 0.0  = OFF   ,    0.2 = only Data  ,   0.4   = ON  ,   1.0 = ON and the value of the remote control signal was limited by the sending effect.   ,    The value of ChannelInput is only passed to sub macros 



         // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )		// Sub macro,   Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )					// Sub macro,   y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 
 










///////////////////////////////////////////////////////////////////////////////////////////////////
//               *****  Pixel Shader  *****
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// These functions are used by "Technique"
////////////////////////////////////////////////////////////////////////////////////////////////////


float4 main( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   return  min (float4 (retval.r * (1 + RECEIVING(ChRed)),
                        retval.g * (1 + RECEIVING(ChGreen)),
                        retval.b * (1 + RECEIVING(ChBlue)),
                        retval.a), 1.0);
}






//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main();
   }
}

