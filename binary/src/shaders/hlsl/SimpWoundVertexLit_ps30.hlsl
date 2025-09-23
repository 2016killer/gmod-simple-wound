#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjTextureSampler	: register( s2 );

const float3 woundSize_blendMode	: register(c0);

struct PS_INPUT
{
	float4 baseTexCoord2_tangentSpaceVertToEyeVectorXY			: TEXCOORD0;
	float3 vWoundData 											: TEXCOORD1; 
};

void SimpWound_TextureCombine(
	const float4 deformedColor, 
	const float4 projColor, 
	const float deformedSize, const float projSize, const float blendMode,
	const float dist, 
	inout float4 baseColor)
{
	float4 undeformedColor = float4(
		lerp(
			baseColor.rgb,
			projColor.rgb,
			(1 - smoothstep(deformedSize, deformedSize + projSize, dist)) * lerp(1, projColor.a, step(0.5, blendMode))
		), 
		1
	);

	baseColor = lerp(
		undeformedColor,
		deformedColor,                            
		step(dist, blendMode)
	);
} 


float4 main( PS_INPUT i ) : COLOR
{
	float4 baseColor = tex2D( BaseTextureSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );
	float4 deformedColor = tex2D( DeformedTextureSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );
	float4 projColor = tex2D( ProjTextureSampler, i.vWoundData.xy );


	SimpWound_TextureCombine( 
		deformedColor, 
		projColor, 
		woundSize_blendMode.x, woundSize_blendMode.y, woundSize_blendMode.z,
		i.vWoundData.z,
		baseColor
	);
	

	
	return baseColor;
}