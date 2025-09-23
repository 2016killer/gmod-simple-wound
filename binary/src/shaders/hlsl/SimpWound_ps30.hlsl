#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjTextureSampler	: register( s2 );

const float3 woundSize	: register(c0);

struct PS_INPUT
{
	float2 vBaseTexCoord			: TEXCOORD0;
	float3 vWoundData 				: TEXCOORD1; 
};


float4 main( PS_INPUT i ) : COLOR
{
	// 混合基础、投影纹理混合, 使用woundSize.xy确定投影范围, woundSize.z 决定是否开启alpha混合
	float2 projTexCoord = i.vWoundData.xy;
	float dist = i.vWoundData.z;

	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 projColor = tex2D( ProjTextureSampler, projTexCoord );

	baseColor.rgb = lerp(
		baseColor.rgb,
		projColor.rgb,
		(1 - smoothstep(woundSize.x, woundSize.x + woundSize.y, dist)) * lerp(1, projColor.a, step(0.5, woundSize.z))
	);

	// 应用变形纹理
	float4 deformedColor = tex2D( DeformedTextureSampler, i.vBaseTexCoord );
	baseColor = lerp(
		baseColor,
		deformedColor,                            
		step(dist, woundSize.x)
	);
	
	return baseColor;
}