#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjectedTextureSampler	: register( s2 );

float3 woundSize	: register(c0);

struct PS_INPUT
{
	float2 vBaseTexCoord			: TEXCOORD0;
	float2 vProjectedTexCoord 		: TEXCOORD1; 
	float fDist 					: TEXCOORD2; 
};


float4 main( PS_INPUT i ) : COLOR
{
	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 woundColor = tex2D( DeformedTextureSampler, i.vBaseTexCoord );
	float4 projectedColor = tex2D( ProjectedTextureSampler, i.vProjectedTexCoord );

	float gradient = (1.0 - smoothstep(woundSize.x, woundSize.x + woundSize.y, i.fDist));

	baseColor = lerp(
		baseColor + projectedColor * gradient * woundSize.z,  
		woundColor,                            
		step(i.fDist, woundSize.x)
	);
	
	return baseColor;
}