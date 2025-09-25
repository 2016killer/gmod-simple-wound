#include "common_ps_fxc.h"

// 不太懂hlsl，瞎几把乱写的，仅供参考

sampler BaseTextureSampler	: register( s0 );
sampler DepthTextureSampler	: register( s1 );
sampler ProjTextureSampler	: register( s2 );

const float3 woundSize_blendMode	: register(c0);

struct PS_INPUT
{
	float2 vBaseTexCoord			: TEXCOORD0;
	float4 vWoundData 				: TEXCOORD1; 
};


float4 main( PS_INPUT i ) : COLOR
{
	// 统计像素遮挡场景次数, 奇数次剔除
	float2 depthTexCoord = i.vWoundData.yz + float2(0.5, 0.5);
	float4 multiDepth = tex2D( DepthTextureSampler, depthTexCoord );
	float4 depths = i.vWoundData.xxxx + float4(0.5, 0.5, 0.5, 0.5);

	float inside = frac(dot(step(depths, multiDepth), float4(1.0, 1.0, 1.0, 1.0)) * 0.5) * 2.0;

	clip(0.5 - inside);
	// 超出边界的不参与剔除
	// float crossRange = dot(
	// 	step(depthTexCoord, float2(0.0, 0.0)) 
	// 		+ step(float2(1.0, 1.0), depthTexCoord),
	// 	float2(1.0, 1.0)
	// );

	// clip(0.5 - inside * step(crossRange, 0.5));



	// 纹理混合
	float dist = i.vWoundData.w;
	float2 projTexCoord = i.vWoundData.yz;
	
	float4 baseColor = tex2D( BaseTextureSampler, i.vBaseTexCoord );
	float4 projColor = tex2D( ProjTextureSampler, projTexCoord );

	baseColor.rgb = lerp(
		baseColor.rgb,
		projColor.rgb,
		(1 - smoothstep(woundSize_blendMode.x, woundSize_blendMode.x + woundSize_blendMode.y, dist)) * lerp(1, projColor.a, step(0.5, woundSize_blendMode.z))
	);

	return baseColor;
}