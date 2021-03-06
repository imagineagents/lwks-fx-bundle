// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2016-06-01
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaPush_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaPush.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Adx_Push.fx
//
// This mimics the Lightworks push effect but supports alpha channel transitions.  Alpha
// levels can be boosted to support Lightworks titles, which is the default setting.
// The boost technique uses gamma rather than simple amplification to correct alpha
// levels.  This closely matches the way that Lightworks handles titles internally.
//
// LW 14+ version by jwrl 19 May 2017
// Added subcategory "Alpha"
//
// Modified 8 August 2017 by jwrl.
// Renamed from AlphaPushMix.fx for name consistency through the alpha dissolve range.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha push";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;
texture In3;

texture Fg1 : RenderColorTarget;
texture Fg2 : RenderColorTarget;
texture Bgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler In1Sampler = sampler_state {
   Texture = <In1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state {
   Texture = <In2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state {
   Texture   = <In3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg1Sampler = sampler_state {
   Texture   = <Fg1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state {
   Texture   = <Fg2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler  = sampler_state {
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

int Ttype
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Transition";
   string Enum = "Fade in,Fade out,Dissolve FX1 > FX2,Dissolve FX2 > FX1";
> = 0;

int SetTechnique
<
   string Group = "Disconnect video input to any Lightworks title effect used first";
   string Description = "Type";
   string Enum = "Push Right,Push Down,Push Left,Push Up";
> = 0;

bool Boost_On
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Enable alpha boost";
> = false;

float Boost_O
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost outgoing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_I
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost incoming";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define FX_IN   0
#define FX_OUT  1
#define FX1_FX2 2
#define FX2_FX1 3

#define HALF_PI 1.570796

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mode_sw_1 (float2 xy : TEXCOORD1) : COLOR      // Alpha foreground
{
   float4 retval = (Ttype == FX2_FX1) ? tex2D (In2Sampler, xy) : (Ttype == FX_IN) ? EMPTY : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_IN) ? pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0))
                               : pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0));
   return retval;
}

float4 ps_mode_sw_2 (float2 xy : TEXCOORD1) : COLOR      // Alpha background
{
   float4 retval = (Ttype == FX1_FX2) ? tex2D (In2Sampler, xy) : (Ttype == FX_OUT) ? EMPTY : tex2D (In1Sampler, xy);

   if (!Boost_On) return retval;

   retval.a = (Ttype == FX_OUT) ? pow (retval.a, 1.0 / max (1.0, Boost_O + 1.0))
                                : pow (retval.a, 1.0 / max (1.0, Boost_I + 1.0));
   return retval;
}

float4 ps_mode_sw_3 (float2 xy : TEXCOORD1) : COLOR      // Post-process background
{
   return ((Ttype == FX1_FX2) || (Ttype == FX2_FX1)) ? tex2D (In3Sampler, xy) : tex2D (In2Sampler, xy);
}

float4 ps_push_right (float2 uv : TEXCOORD1) : COLOR
{
   float AmtIn, AmtOut;

   sincos (HALF_PI * Amount, AmtIn, AmtOut);

   float2 xy1 = float2 (saturate (uv.x + AmtOut - 1.0), uv.y);
   float2 xy2 = float2 (saturate (uv.x - AmtIn + 1.0), uv.y);

   float4 Fgd1 = (xy1.x != saturate (xy1.x)) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.x != saturate (xy2.x)) ? EMPTY : tex2D (Fg2Sampler, xy2);

   float4 fgdPix = max (Fgd1, Fgd2);
   float4 bgdPix = tex2D (BgdSampler, uv);

   return lerp (bgdPix, fgdPix, fgdPix.a);
}

float4 ps_push_left (float2 uv : TEXCOORD1) : COLOR
{
   float AmtIn, AmtOut;

   sincos (HALF_PI * Amount, AmtIn, AmtOut);

   float2 xy1 = float2 (saturate (uv.x - AmtOut + 1.0), uv.y);
   float2 xy2 = float2 (saturate (uv.x + AmtIn - 1.0), uv.y);

   float4 Fgd1 = (xy1.x != saturate (xy1.x)) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.x != saturate (xy2.x)) ? EMPTY : tex2D (Fg2Sampler, xy2);

   float4 fgdPix = max (Fgd1, Fgd2);
   float4 bgdPix = tex2D (BgdSampler, uv);

   return lerp (bgdPix, fgdPix, fgdPix.a);
}

float4 ps_push_down (float2 uv : TEXCOORD1) : COLOR
{
   float AmtIn, AmtOut;

   sincos (HALF_PI * Amount, AmtIn, AmtOut);

   float2 xy1 = float2 (uv.x, saturate (uv.y + AmtOut - 1.0));
   float2 xy2 = float2 (uv.x, saturate (uv.y - AmtIn + 1.0));

   float4 Fgd1 = (xy1.y != saturate (xy1.y)) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.y != saturate (xy2.y)) ? EMPTY : tex2D (Fg2Sampler, xy2);

   float4 fgdPix = max (Fgd1, Fgd2);
   float4 bgdPix = tex2D (BgdSampler, uv);

   return lerp (bgdPix, fgdPix, fgdPix.a);
}

float4 ps_push_up (float2 uv : TEXCOORD1) : COLOR
{
   float AmtIn, AmtOut;

   sincos (HALF_PI * Amount, AmtIn, AmtOut);

   float2 xy1 = float2 (uv.x, saturate (uv.y - AmtOut + 1.0));
   float2 xy2 = float2 (uv.x, saturate (uv.y + AmtIn - 1.0));

   float4 Fgd1 = (xy1.y != saturate (xy1.y)) ? EMPTY : tex2D (Fg1Sampler, xy1);
   float4 Fgd2 = (xy2.y != saturate (xy2.y)) ? EMPTY : tex2D (Fg2Sampler, xy2);

   float4 fgdPix = max (Fgd1, Fgd2);
   float4 bgdPix = tex2D (BgdSampler, uv);

   return lerp (bgdPix, fgdPix, fgdPix.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique push_right
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_push_right (); }
}

technique push_down
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_push_down (); }
}

technique push_left
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_push_left (); }
}

technique push_up
{
   pass P_1 < string Script = "RenderColorTarget0 = Fg1;"; >
   { PixelShader = compile PROFILE ps_mode_sw_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fg2;"; >
   { PixelShader = compile PROFILE ps_mode_sw_2 (); }

   pass P_3 < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_mode_sw_3 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_push_up (); }
}
