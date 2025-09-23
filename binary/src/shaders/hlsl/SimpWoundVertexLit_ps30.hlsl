#include "common_ps_fxc.h"

sampler BaseTextureSampler	: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjTextureSampler	: register( s2 );

const float3 woundSize_blendMode	: register(c0);

const float3 g_EyePos				: register( c1 );

const float4 g_ShaderControls		: register( c2 );
#define g_fPixelFogType					g_ShaderControls.x
#define g_fWriteDepthToAlpha			g_ShaderControls.y
#define g_fWriteWaterFogToDestAlpha		g_ShaderControls.z

const float4 g_FogParams			: register( c3 );

const float4 g_DiffuseModulation	: register( c4 );

struct PS_INPUT
{
	float4 baseTexCoord2_tangentSpaceVertToEyeVectorXY			: TEXCOORD0;
	float3 vWoundData 											: TEXCOORD1; 
	float4 worldPos_projPosZ									: TEXCOORD6;

	float4 fogFactorW											: COLOR1;
};


// Calculate both types of Fog and lerp to get result
float CalcPixelFogFactorConst( float fPixelFogType, const float4 fogParams, const float flEyePosZ, const float flWorldPosZ, const float flProjPosZ )
{
	float fRangeFog = CalcRangeFog( flProjPosZ, fogParams.x, fogParams.z, fogParams.w );
	float fHeightFog = CalcWaterFogAlpha( fogParams.y, flEyePosZ, flWorldPosZ, flProjPosZ, fogParams.w );
	return lerp( fRangeFog, fHeightFog, fPixelFogType );
}

// Blend both types of Fog and lerp to get result
float3 BlendPixelFogConst( const float3 vShaderColor, float pixelFogFactor, const float3 vFogColor, float fPixelFogType )
{
	pixelFogFactor = saturate( pixelFogFactor );
	float3 fRangeResult = lerp( vShaderColor.rgb, vFogColor.rgb, pixelFogFactor * pixelFogFactor ); //squaring the factor will get the middle range mixing closer to hardware fog
	float3 fHeightResult = lerp( vShaderColor.rgb, vFogColor.rgb, saturate( pixelFogFactor ) );
	return lerp( fRangeResult, fHeightResult, fPixelFogType );
}

float4 FinalOutputConst( const float4 vShaderColor, float pixelFogFactor, float fPixelFogType, const int iTONEMAP_SCALE_TYPE, float fWriteDepthToDestAlpha, const float flProjZ )
{
	float4 result = vShaderColor;
	if( iTONEMAP_SCALE_TYPE == TONEMAP_SCALE_LINEAR )
	{
		result.rgb *= LINEAR_LIGHT_SCALE;
	}
	else if( iTONEMAP_SCALE_TYPE == TONEMAP_SCALE_GAMMA )
	{
		result.rgb *= GAMMA_LIGHT_SCALE;
	}

	result.a = lerp( result.a, DepthToDestAlpha( flProjZ ), fWriteDepthToDestAlpha );

	result.rgb = BlendPixelFogConst( result.rgb, pixelFogFactor, g_LinearFogColor.rgb, fPixelFogType );
	result.rgb = SRGBOutput( result.rgb ); //SRGB in pixel shader conversion

	return result;
}

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
	
	float4 result = baseColor;

	// float alpha = g_DiffuseModulation.a * baseColor.a;
	float alpha = baseColor.a;

	float fogFactor = CalcPixelFogFactorConst( g_fPixelFogType, g_FogParams, g_EyePos.z, i.worldPos_projPosZ.z, i.worldPos_projPosZ.w );
	alpha = lerp( alpha, fogFactor, g_fPixelFogType * g_fWriteWaterFogToDestAlpha ); // Use the fog factor if it's height fog
	return FinalOutputConst( float4( result.rgb, alpha ), fogFactor, g_fPixelFogType, TONEMAP_SCALE_LINEAR, g_fWriteDepthToAlpha, i.worldPos_projPosZ.w );
	// return baseColor;
}