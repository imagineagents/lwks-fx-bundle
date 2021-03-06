// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/Toon.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Toon.fx
//
// The image is posterized, then outlines are developed from image edges.  These are
// applied on top of the already posterized image to give the final effect.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Cross platform compatibility check 27 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float3 variable to address behavioural differences between the D3D
// and Cg compilers.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Toon";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
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

float RedStrength
<
   string Description = "RedStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float GreenStrength
<
   string Description = "GreenStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float BlueStrength
<
   string Description = "BlueStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float Threshold
<
   string Description = "Threshold";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 0.00;
   float MaxVal       = 10.00;
> = 0.1; // Default value

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define NUM 9

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 dirtyToonPS( float2 xy : TEXCOORD1 ) : COLOR
{
   // Read a pixel from the source image at position 'xy'
   // and place it in the variable 'color'
   float4 color = tex2D( FgSampler, xy );

	color.r = round(color.r*RedStrength)/RedStrength;
	color.g = round(color.g*GreenStrength)/GreenStrength;
	color.b = round(color.b*BlueStrength)/BlueStrength;
	
	const float threshold = Threshold;

	float2 c[NUM] =
	{
		float2(-0.0078125, 0.0078125), 
		float2( 0.00 ,     0.0078125),
		float2( 0.0078125, 0.0078125),
		float2(-0.0078125, 0.00 ),
		float2( 0.0,       0.0),
		float2( 0.0078125, 0.007 ),
		float2(-0.0078125,-0.0078125),
		float2( 0.00 ,    -0.0078125),
		float2( 0.0078125,-0.0078125),
	};	

	int i;
	float3 col[NUM];
	for (i=0; i < NUM; i++)
	{
		col[i] = tex2D(FgSampler, xy + 0.2*c[i]).rgb;
	}
	
	float3 rgb2lum = float3(0.30, 0.59, 0.11);
	float lum[NUM];
	for (i = 0; i < NUM; i++)
	{
		lum[i] = dot(col[i].xyz, rgb2lum);
	}
	float x = lum[2]+  lum[8]+2*lum[5]-lum[0]-2*lum[3]-lum[6];
	float y = lum[6]+2*lum[7]+  lum[8]-lum[0]-2*lum[1]-lum[2];
	float edge =(x*x + y*y < threshold)? 1.0:0.0;
	
	color.rgb *= edge;
	return color;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Toon
{
   pass SinglePass
   {
      PixelShader = compile PROFILE dirtyToonPS();
   }
}
