//--------------------------------------------------------------//
// Lightworks user effect Cx_xPinch.fx
// Created by LW user jwrl 10 September 2017.
//
// This effect pinches the outgoing video to a user-defined
// point to reveal the incoming shot, while zooming out of the
// pinched image.  It can also reverse the process to bring in
// the incoming video.
//
// The direction swap has been deliberately made asymmetric.
// Subjectively it looked better to have the pinch established
// before the zoom out started, but to run the zoom in through
// the entire un-pinch process.  Trig functions are used on
// the effect progress to make the acceleration smoother.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite X-pinch";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

texture Fg : RenderColorTarget;
texture Bg : RenderColorTarget;

texture Pinch : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler V1sampler = sampler_state
{
   Texture   = <V1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V3sampler = sampler_state
{
   Texture   = <V3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

sampler VidSampler = sampler_state
{
   Texture   = <Pinch>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V2sampler = sampler_state { Texture = <V2>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool Swapped
<
   string Description = "Make V3 and not V1 the outgoing image";
> = false;

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_swap_V1 (float2 uv : TEXCOORD1) : COLOR
{
   if (Swapped) return tex2D (V3sampler, uv);

   float4 retval = tex2D (V1sampler, uv);

   retval.a = max (retval.a, tex2D (V2sampler, uv).a);

   return retval;
}

float4 ps_swap_V3 (float2 uv : TEXCOORD1) : COLOR
{
   if (!Swapped) return tex2D (V3sampler, uv);

   float4 retval = tex2D (V1sampler, uv);

   retval.a = max (retval.a, tex2D (V2sampler, uv).a);

   return retval;
}

float4 ps_pinch_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (FgdSampler, xy);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 outgoing = (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (VidSampler, xy);

   return lerp (tex2D (BgdSampler, uv), outgoing, outgoing.a);
}

float4 ps_pinch_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = cos (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (BgdSampler, xy);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - sin (Amount * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 incoming = (any (xy > (1.0).xx) || any (xy < (0.0).xx)) ? EMPTY : tex2D (VidSampler, xy);

   return lerp (tex2D (FgdSampler, uv), incoming, incoming.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Pinch_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_swap_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_swap_V3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_1 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Pinch_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_swap_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_swap_V3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_2 (); }
}

