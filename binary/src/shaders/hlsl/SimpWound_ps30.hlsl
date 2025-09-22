#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler WoundTextureSampler	: register( s1 );
sampler ProjectedTextureSampler	: register( s2 );


struct PS_INPUT
{
	float2 vBaseTexCoord	: TEXCOORD0;
	float2 vProjectedTexCoord 			: TEXCOORD1; 
	float fDist 					: TEXCOORD2; 
};


float4 main( PS_INPUT i ) : COLOR
{
	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 woundColor = tex2D( WoundTextureSampler, i.vBaseTexCoord );
	
	return i.fDist < 1.0 ? woundColor : baseColor;
}