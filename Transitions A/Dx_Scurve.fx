// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-03-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Sdissolve_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dissolve_S.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Scurve.fx
//
// This is essentially the same as Editshare's "Mix", with a trigonometric curve
// applied to the "Amount" parameter.  If you need to you can vary the linearity of
// the curve.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from S_mix.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;            // Outgoing
texture Bgd;            // Incoming

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
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
> = 0.5;

float Linearity
<
   string Description = "Linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415927

#define HALF_PI 1.5707963

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   float4 Fg = tex2D (FgdSampler, uv);
   float4 Bg = tex2D (BgdSampler, uv);

   amount = saturate (amount + (curve * Linearity));

   return lerp (Fg, Bg, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
