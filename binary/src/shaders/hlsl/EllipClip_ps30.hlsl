#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler DepthTextureSampler	: register( s1 );
sampler ProjectedTextureSampler	: register( s2 );

struct PS_INPUT
{
	HALF2 vBaseTexCoord	: TEXCOORD0;
	
	float3 vLocalPos1 				: TEXCOORD1; 
	float3 vLocalPos2 				: TEXCOORD2; 
	float fDist1 					: TEXCOORD3; 
	float fDist2 					: TEXCOORD4; 
};


HALF4 main( PS_INPUT i ) : COLOR
{
	clip( min(i.fDist1, i.fDist2) - 1.0 );

	HALF4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	return baseColor;
}