#include "common_ps_fxc.h"

// 不太懂hlsl，瞎几把乱写的，仅供参考

sampler BaseTextureSampler	: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjTextureSampler	: register( s2 );

const float3 woundSize_blendMode	: register(c0);

struct PS_INPUT
{
	float2 vBaseTexCoord			: TEXCOORD0;
	float3 vWoundData 				: TEXCOORD1; 
};


float4 main( PS_INPUT i ) : COLOR
{
	// 混合基础、投影纹理混合, 使用 woundSize_blendMode.xy确定投影范围, woundSize_blendMode.z 决定是否开启alpha混合
	float2 projTexCoord = i.vWoundData.xy;
	float dist = i.vWoundData.z;

	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 projColor = tex2D( ProjTextureSampler, projTexCoord );

	baseColor.rgb = lerp(
		baseColor.rgb,
		projColor.rgb,
		(1 - smoothstep(woundSize_blendMode.x, woundSize_blendMode.x + woundSize_blendMode.y, dist)) * lerp(1, projColor.a, step(0.5, woundSize_blendMode.z))
	);

	// 应用变形纹理
	float4 deformedColor = tex2D( DeformedTextureSampler, i.vBaseTexCoord );
	baseColor = lerp(
		baseColor,
		deformedColor,                            
		step(dist, woundSize_blendMode.x)
	);
	
	return baseColor;
}