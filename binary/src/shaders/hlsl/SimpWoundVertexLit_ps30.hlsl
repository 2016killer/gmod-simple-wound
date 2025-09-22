//======= Copyright � 1996-2008, Valve Corporation, All rights reserved. ======

// STATIC: "CUBEMAP"					"0..1"
// STATIC: "DIFFUSELIGHTING"			"0..1"
// STATIC: "LIGHTWARPTEXTURE"			"0..1"
// STATIC: "NORMALMAPALPHAENVMAPMASK"	"0..1"
// STATIC: "HALFLAMBERT"				"0..1"
// STATIC: "FLASHLIGHT"					"0..1"
// STATIC: "DETAILTEXTURE"				"0..1"
// STATIC: "DETAIL_BLEND_MODE"      	"0..6"
// STATIC: "FLASHLIGHTDEPTHFILTERMODE"	"0..2"						[ps20b] [PC]
// STATIC: "FLASHLIGHTDEPTHFILTERMODE"	"0..2"						[ps30] [PC]
// STATIC: "FLASHLIGHTDEPTHFILTERMODE"	"0..0"						[ps20b] [XBOX]
// STATIC: "BLENDTINTBYBASEALPHA"  "0..1"

// DYNAMIC: "PIXELFOGTYPE"				"0..1"						[ps20]
// DYNAMIC: "WRITEWATERFOGTODESTALPHA"	"0..1"						[ps20]
// DYNAMIC: "NUM_LIGHTS"				"0..2"						[ps20]
// DYNAMIC: "NUM_LIGHTS"				"0..4"						[ps20b]
// DYNAMIC: "NUM_LIGHTS"				"0..4"						[ps30]
// DYNAMIC: "AMBIENT_LIGHT"				"0..1"
// DYNAMIC: "FLASHLIGHTSHADOWS"			"0..1"						[ps20b]
// DYNAMIC: "FLASHLIGHTSHADOWS"			"0..1"						[ps30] [PC]

// We don't use light combos when doing the flashlight
// SKIP: ( $FLASHLIGHT != 0 ) && ( $NUM_LIGHTS > 0 )				[PC]

// We don't care about flashlight depth unless the flashlight is on
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTSHADOWS == 1 )		[ps20b]
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTSHADOWS == 1 )		[ps30]

// Flashlight shadow filter mode is irrelevant if there is no flashlight
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTDEPTHFILTERMODE != 0 ) [ps20b]
// SKIP: ( $FLASHLIGHT == 0 ) && ( $FLASHLIGHTDEPTHFILTERMODE != 0 ) [ps30]

// SKIP: (! $DETAILTEXTURE) && ( $DETAIL_BLEND_MODE != 0 )

// Don't do diffuse warp on flashlight
// SKIP: ( $FLASHLIGHT == 1 ) && ( $LIGHTWARPTEXTURE == 1 )			[PC]

// Only warp diffuse if we have it at all
// SKIP: ( $DIFFUSELIGHTING == 0 ) && ( $LIGHTWARPTEXTURE == 1 )





// Only _XBOX allows flashlight and cubemap in the current implementation
// SKIP: $FLASHLIGHT && $CUBEMAP [PC]

// Meaningless combinations
// SKIP: $NORMALMAPALPHAENVMAPMASK && !$CUBEMAP

// 原文件为vertexlit_and_unlit_generic_bump_ps2x.fxc, 使用AIGC 豆包插入自定义逻辑
// 插入部分使用"---------SimpWound"标记
// 砍掉TEXCOORD8、TEXCOORD7, 可能会有一些细节问题
// 为腾出寄存器砍掉了自发光相关的寄存器c4

#include "common_flashlight_fxc.h"
#include "common_vertexlitgeneric_dx9.h"

const float4 g_EnvmapTint_TintReplaceFactor		: register( c0 );
const float4 g_DiffuseModulation				: register( c1 );
const float4 g_EnvmapContrast_ShadowTweaks		: register( c2 );
const float3 g_EnvmapSaturation					: register( c3 );



const float3 cAmbientCube[6]				: register( c5 );



const float4 g_ShaderControls				: register( c12 );
#define g_fPixelFogType					g_ShaderControls.x
#define g_fWriteDepthToAlpha			g_ShaderControls.y
#define g_fWriteWaterFogToDestAlpha		g_ShaderControls.z


// 2 registers each - 6 registers total
PixelShaderLightInfo cLightInfo[3]			: register( c13 );  // through c18

const float3 g_EyePos						: register( c20 );
const float4 g_FogParams					: register( c21 );

const float4 g_FlashlightAttenuationFactors	: register( c22 );
const float3 g_FlashlightPos				: register( c23 );
const float4x4 g_FlashlightWorldToTexture	: register( c24 ); // through c27

// ---------SimpWound
const float3 vWoundSize					: register( c4 ); // 选用寄存器c4存储伤口尺寸
// ---------SimpWound

sampler BaseTextureSampler					: register( s0 );
sampler EnvmapSampler						: register( s1 );
sampler DetailSampler						: register( s2 );
sampler BumpmapSampler						: register( s3 );
sampler EnvmapMaskSampler					: register( s4 );
sampler NormalizeSampler					: register( s5 );
sampler RandRotSampler						: register( s6 );	// RandomRotation sampler
sampler FlashlightSampler					: register( s7 );
sampler ShadowDepthSampler					: register( s8 );	// Flashlight shadow depth map sampler
sampler DiffuseWarpSampler					: register( s9 );	// Lighting warp sampler (1D texture for diffuse lighting modification)
// ---------SimpWound
sampler WoundTextureSampler				: register( s10 ); // 新增伤口颜色贴图采样器（选用未占用s10）
sampler ProjectedTextureSampler			: register( s11 ); // 新增投射贴图采样器（选用未占用s11）
sampler DeformedNormalTextureSampler		: register( s12 ); // 新增自定义伤口法线贴图采样器（选用未占用s12）
// ---------SimpWound

struct PS_INPUT
{
	float4 baseTexCoord2_tangentSpaceVertToEyeVectorXY			: TEXCOORD0;
	float3 lightAtten											: TEXCOORD1;
	float4 worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ	: TEXCOORD2;
	float3 vWorldNormal											: TEXCOORD3;	// World-space normal
	float4 vWorldTangent										: TEXCOORD4;
#if ((defined(SHADER_MODEL_PS_2_B) || defined(SHADER_MODEL_PS_3_0)))
	float4 vProjPos												: TEXCOORD5;
#else
	float3 vWorldBinormal										: TEXCOORD5;
#endif
	float4 worldPos_projPosZ									: TEXCOORD6;

	float4 fogFactorW											: COLOR1;


	// ---------SimpWound
	float3 vSimpWoundData										: TEXCOORD7; // 新增TEXCOORD7存储伤口数据（dist等）
	// ---------SimpWound
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

float4 main( PS_INPUT i ) : COLOR
{
	bool bCubemap = CUBEMAP ? true : false;
	bool bDiffuseLighting = DIFFUSELIGHTING ? true : false;
	bool bDoDiffuseWarp = LIGHTWARPTEXTURE ? true : false;
	bool bSelfIllum = false;
	bool bSelfIllumFresnel = false;
	bool bNormalMapAlphaEnvmapMask = NORMALMAPALPHAENVMAPMASK ? true : false;
	bool bHalfLambert = HALFLAMBERT ? true : false;
	bool bFlashlight = (FLASHLIGHT!=0) ? true : false;
	bool bAmbientLight = AMBIENT_LIGHT ? true : false;
	bool bDetailTexture = DETAILTEXTURE ? true : false;
	bool bBlendTintByBaseAlpha = BLENDTINTBYBASEALPHA ? true : false;
	int nNumLights = NUM_LIGHTS;

#if ((defined(SHADER_MODEL_PS_2_B) || defined(SHADER_MODEL_PS_3_0)))
	float3 vWorldBinormal = cross( i.vWorldNormal.xyz, i.vWorldTangent.xyz ) * i.vWorldTangent.w;
#else
	float3 vWorldBinormal = i.vWorldBinormal;
#endif

	// Unpack four light attenuations
	float4 vLightAtten = float4( i.lightAtten, 0 );

	float4 baseColor = float4( 1.0f, 1.0f, 1.0f, 1.0f );
	baseColor = tex2D( BaseTextureSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );


	// ---------SimpWound
	
	float4 woundColor = tex2D( WoundTextureSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );
	float4 projectedColor = tex2D( ProjectedTextureSampler, i.vSimpWoundData.xy );
	
	float gradient = (1.0 - smoothstep(vWoundSize.x, vWoundSize.x + vWoundSize.y, i.vSimpWoundData.z)) * vWoundSize.z;
	
	baseColor = lerp(
		baseColor + projectedColor * gradient,  
		woundColor,                            
		step(i.vSimpWoundData.z, vWoundSize.x)
	);
	// ---------SimpWound

	float specularFactor = 1.0f;
	float4 normalTexel = tex2D( BumpmapSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );
	// ---------SimpWound
	float4 deformedNormalTexel = tex2D( DeformedNormalTextureSampler, i.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy );
	float3 tangentSpaceNormal = lerp(
		normalTexel * 2.0f - 1.0f,
		deformedNormalTexel * 2.0f - 1.0f,
		step(i.vSimpWoundData.z, vWoundSize.x)
	);
	// ---------SimpWound

	if ( bNormalMapAlphaEnvmapMask )
		specularFactor = normalTexel.a;

	float3 diffuseLighting = float3( 1.0f, 1.0f, 1.0f );

	float3 worldSpaceNormal = float3( 0.0f, 0.0f, 1.0f );
	if ( bDiffuseLighting || bFlashlight || bCubemap || bSelfIllumFresnel )
	{
		worldSpaceNormal = Vec3TangentToWorld( tangentSpaceNormal, i.vWorldNormal, i.vWorldTangent, vWorldBinormal );
#if ( defined(SHADER_MODEL_PS_2_B) || defined(SHADER_MODEL_PS_3_0) )
		worldSpaceNormal = normalize( worldSpaceNormal );
#else
		worldSpaceNormal = NormalizeWithCubemap( NormalizeSampler, worldSpaceNormal );
#endif
	}

	if ( bDiffuseLighting )
	{
		diffuseLighting = PixelShaderDoLighting( i.worldPos_projPosZ.xyz, worldSpaceNormal,
				float3( 0.0f, 0.0f, 0.0f ), false, bAmbientLight, vLightAtten,
				cAmbientCube, NormalizeSampler, nNumLights, cLightInfo, bHalfLambert,
				false, 1.0f, bDoDiffuseWarp, DiffuseWarpSampler );
	}

	float3 albedo = baseColor;
	if (bBlendTintByBaseAlpha)
	{
		float3 tintedColor = albedo * g_DiffuseModulation.rgb;
		tintedColor = lerp(tintedColor, g_DiffuseModulation.rgb, g_EnvmapTint_TintReplaceFactor.w);
		albedo = lerp(albedo, tintedColor, baseColor.a);
	}
	else
	{
		albedo = albedo * g_DiffuseModulation.rgb;
	}

	float alpha = g_DiffuseModulation.a;
	if ( !bSelfIllum && !bBlendTintByBaseAlpha )
	{
		alpha *= baseColor.a;
	}


#if FLASHLIGHT
	if( bFlashlight )
	{
		int nShadowSampleLevel = 0;
		bool bDoShadows = false;
		float2 vProjPos = float2(0, 0);
// On ps_2_b, we can do shadow mapping
#if ( FLASHLIGHTSHADOWS && (defined(SHADER_MODEL_PS_2_B) || defined(SHADER_MODEL_PS_3_0) ) )
		nShadowSampleLevel = FLASHLIGHTDEPTHFILTERMODE;
		bDoShadows = FLASHLIGHTSHADOWS;
		vProjPos = i.vProjPos.xy / i.vProjPos.w;	// Screen-space position for shadow map noise
#endif

#if defined ( _X360 )
		float4 flashlightSpacePosition = float4( 0, 0, 0, 1.0f );
#else
		float4 flashlightSpacePosition = mul( float4( i.worldPos_projPosZ.xyz, 1.0f ), g_FlashlightWorldToTexture );
#endif

		float3 flashlightColor = DoFlashlight( g_FlashlightPos, i.worldPos_projPosZ.xyz, flashlightSpacePosition,
			worldSpaceNormal, g_FlashlightAttenuationFactors.xyz, 
			g_FlashlightAttenuationFactors.w, FlashlightSampler, ShadowDepthSampler,
			RandRotSampler, nShadowSampleLevel, bDoShadows, false, vProjPos, false, g_EnvmapContrast_ShadowTweaks );

#if defined ( _X360 )
		diffuseLighting += flashlightColor;
#else
		diffuseLighting = flashlightColor;
#endif

	}
#endif


	float3 diffuseComponent = albedo * diffuseLighting;



	float3 specularLighting = float3( 0.0f, 0.0f, 0.0f );
#if !FLASHLIGHT || defined ( _X360 )
	if( bCubemap )
	{
		float3 reflectVect = CalcReflectionVectorUnnormalized( worldSpaceNormal, i.worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ.xyz );

		specularLighting = ENV_MAP_SCALE * texCUBE( EnvmapSampler, reflectVect );
		specularLighting *= specularFactor;
		specularLighting *= g_EnvmapTint_TintReplaceFactor.rgb;
		float3 specularLightingSquared = specularLighting * specularLighting;
		specularLighting = lerp( specularLighting, specularLightingSquared, g_EnvmapContrast_ShadowTweaks );
		float3 greyScale = dot( specularLighting, float3( 0.299f, 0.587f, 0.114f ) );
		specularLighting = lerp( greyScale, specularLighting, g_EnvmapSaturation );
	}
#endif

	float3 result = diffuseComponent + specularLighting;

#if defined(SHADER_MODEL_PS_2_0)
	float fogFactor = CalcPixelFogFactor( PIXELFOGTYPE, g_FogParams, g_EyePos.z, i.worldPos_projPosZ.z, i.worldPos_projPosZ.w );
#else
	float fogFactor = CalcPixelFogFactorConst( g_fPixelFogType, g_FogParams, g_EyePos.z, i.worldPos_projPosZ.z, i.worldPos_projPosZ.w );
#endif

#if defined( SHADER_MODEL_PS_2_0 )
	#if WRITEWATERFOGTODESTALPHA && (PIXELFOGTYPE == PIXEL_FOG_TYPE_HEIGHT)
		alpha = fogFactor;
	#endif
#else // 2b or higher
	alpha = lerp( alpha, fogFactor, g_fPixelFogType * g_fWriteWaterFogToDestAlpha ); // Use the fog factor if it's height fog
#endif

#if defined( SHADER_MODEL_PS_2_0 )
	return FinalOutput( float4( result.rgb, alpha ), fogFactor, PIXELFOGTYPE, TONEMAP_SCALE_LINEAR, false, i.worldPos_projPosZ.w );
#else
	return FinalOutputConst( float4( result.rgb, alpha ), fogFactor, g_fPixelFogType, TONEMAP_SCALE_LINEAR, g_fWriteDepthToAlpha, i.worldPos_projPosZ.w );
#endif

}