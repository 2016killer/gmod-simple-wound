#include "common_ps_fxc.h"
#include "common_vertexlitgeneric_dx9.h"

sampler BaseTextureSampler		: register( s0 );
sampler DeformedTextureSampler	: register( s1 );
sampler ProjTextureSampler		: register( s2 );

const float3 woundSize_blendMode	: register(c0);

const float3 g_EyePos				: register( c1 );

const float4 g_ShaderControls		: register( c2 );
#define g_fPixelFogType					g_ShaderControls.x
#define g_fWriteDepthToAlpha			g_ShaderControls.y
#define g_fWriteWaterFogToDestAlpha		g_ShaderControls.z

const float4 g_FogParams			: register( c3 );

struct PS_INPUT
{
	float4 baseTexCoord				: TEXCOORD0;
	float3 vWoundData 				: TEXCOORD1; 

	float4 color					: TEXCOORD2;	
	float4 worldPos_projPosZ		: TEXCOORD3;

	float4 fogFactorW				: COLOR1;
};


// Calculate unified fog
float CalcPixelFogFactorConst( float fPixelFogType, const float4 fogParams, const float flEyePosZ, const float flWorldPosZ, const float flProjPosZ )
{
	float flDepthBelowWater = fPixelFogType*fogParams.y - flWorldPosZ;  // above water = negative, below water = positive
	float flDepthBelowEye = fPixelFogType*flEyePosZ - flWorldPosZ;		// above eye = negative, below eye = positive
	// if fPixelFogType == 0, then flDepthBelowWater == flDepthBelowEye and frac will be 1
	float frac = (flDepthBelowEye == 0) ? 1 : saturate(flDepthBelowWater/flDepthBelowEye);
	return saturate( min(fogParams.z, flProjPosZ * fogParams.w * frac - fogParams.x) );
}

// Blend both types of Fog and lerp to get result
float3 BlendPixelFogConst( const float3 vShaderColor, float pixelFogFactor, const float3 vFogColor, float fPixelFogType )
{
	//float3 fRangeResult = lerp( vShaderColor.rgb, vFogColor.rgb, pixelFogFactor * pixelFogFactor ); //squaring the factor will get the middle range mixing closer to hardware fog
	//float3 fHeightResult = lerp( vShaderColor.rgb, vFogColor.rgb, saturate( pixelFogFactor ) );
	//return lerp( fRangeResult, fHeightResult, fPixelFogType );
	pixelFogFactor = lerp( pixelFogFactor*pixelFogFactor, pixelFogFactor, fPixelFogType );
	return lerp( vShaderColor.rgb, vFogColor.rgb, pixelFogFactor );
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
	static bool bAmbientLight = true;
	static bool bDoDiffuseWarp = false;
	static bool bHalfLambert = true;


	float4 baseColor = float4( 1.0f, 1.0f, 1.0f, 1.0f );
	baseColor = tex2D( BaseTextureSampler, i.baseTexCoord.xy );

// #if DETAILTEXTURE
// 	float4 detailColor = tex2D( DetailSampler, i.detailTexCoord_atten3.xy );
// 	baseColor = TextureCombine( baseColor, detailColor, DETAIL_BLEND_MODE, g_DetailBlendFactor );
// #endif

	float4 deformedColor = tex2D( DeformedTextureSampler, i.baseTexCoord.xy );
	float4 projColor = tex2D( ProjTextureSampler, i.vWoundData.xy );


	SimpWound_TextureCombine( 
		deformedColor, 
		projColor, 
		woundSize_blendMode.x, woundSize_blendMode.y, woundSize_blendMode.z,
		i.vWoundData.z,
		baseColor
	);
	

	float alpha = baseColor.a;
	float3 result = baseColor.rgb * i.color.rgb;

	float fogFactor = CalcPixelFogFactorConst( g_fPixelFogType, g_FogParams, g_EyePos.z, i.worldPos_projPosZ.z, i.worldPos_projPosZ.w );
	alpha = lerp( alpha, fogFactor, g_fPixelFogType * g_fWriteWaterFogToDestAlpha ); // Use the fog factor if it's height fog
	return FinalOutputConst( float4( result.rgb, alpha ), fogFactor, g_fPixelFogType, TONEMAP_SCALE_LINEAR, g_fWriteDepthToAlpha, i.worldPos_projPosZ.w );
}