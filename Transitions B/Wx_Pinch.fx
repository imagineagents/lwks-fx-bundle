//--------------------------------------------------------------//
// Lightworks user effect Wx_Pinch.fx
// Created by LW user jwrl 8 September 2017.
//
// This effect pinches the outgoing video to a user-defined
// point to reveal the incoming shot.  It can also reverse the
// process to bring in the incoming video.
//
// I created this when I wanted to take my mind off a serious
// family problem, so it makes no claim to be anything much.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Pinch transition";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float centreX
<
   string Description = "End point";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Description = "End point";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -sin (Amount * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 outgoing = (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (FgdSampler, xy);

   return lerp (tex2D (BgdSampler, uv), outgoing, outgoing.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -cos ((Amount + 0.01) * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 incoming = (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (BgdSampler, xy);

   return lerp (tex2D (FgdSampler, uv), incoming, incoming.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Pinch_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Pinch_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

