// @Maintainer jwrl
// @Released 2018-04-06
// @Author khaver
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Expand16-235.fx
//
// This is one of three tools to manage broadcast colour space.  The names are self-
// explanatory.  They install into the custom category "User", subcategory "Broadcast".
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Expand 16-235 to 0-255";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool superwhite
<
	string Description = "Keep super whites";
> = false;

bool superblack
<
	string Description = "Keep super blacks";
> = false;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 NullPS(float2 xy : TEXCOORD1) : COLOR
{
    float highc = 20.0f / 255.0f;
    float lowc = 16.0f / 255.0f;
    float scale = 255.0f / 219.0f;

    float4 color = tex2D(FgSampler, xy.xy);
    float4 newcolor = (color-lowc) * scale;

    if (superwhite && !superblack) {
    	scale = 255.0f / 239.0f;
    	newcolor = (color - lowc) * scale;
    }

    if (!superwhite && superblack) {
    	scale = scale = 255.0f / 235.0f;
    	newcolor = ((color - highc) * scale) + highc;
    }

    if (superwhite && superblack) newcolor = color;

    if (newcolor.r > 1.0f) newcolor.r = 1.0f;
    if (newcolor.g > 1.0f) newcolor.g = 1.0f;
    if (newcolor.b > 1.0f) newcolor.b = 1.0f;
    if (newcolor.a > 1.0f) newcolor.a = 1.0f;
    if (newcolor.r < 0.0f) newcolor.r = 0.0f;
    if (newcolor.g < 0.0f) newcolor.g = 0.0f;
    if (newcolor.b < 0.0f) newcolor.b = 0.0f;
    if (newcolor.a < 0.0f) newcolor.a = 0.0f;

	return newcolor;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Expand16-235
{
   pass p0
   {
      PixelShader = compile PROFILE NullPS();
   }
}
