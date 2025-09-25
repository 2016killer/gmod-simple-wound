#include "common_ps_fxc.h"

// 不太懂hlsl，瞎几把乱写的，仅供参考

sampler BaseTextureSampler	: register( s0 );
sampler ProjTextureSampler	: register( s1 );

const float3 woundSize_blendMode	: register(c0);

struct PS_INPUT
{
	float2 vBaseTexCoord			: TEXCOORD0;
	float3 vWoundData 				: TEXCOORD1; 
};


float4 main( PS_INPUT i ) : COLOR
{
	// 剔除
	float dist = i.vWoundData.z;
	clip( dist - woundSize_blendMode.x );

	// 使用 woundSize_blendMode.xy确定投影范围, woundSize_blendMode.z 决定是否开启alpha混合
	float2 projTexCoord = i.vWoundData.xy;
	

	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 projColor = tex2D( ProjTextureSampler, projTexCoord );

	baseColor.rgb = lerp(
		baseColor.rgb,
		projColor.rgb,
		(1 - smoothstep(woundSize_blendMode.x, woundSize_blendMode.x + woundSize_blendMode.y, dist)) * lerp(1, projColor.a, step(0.5, woundSize_blendMode.z))
	);

	return baseColor;
}