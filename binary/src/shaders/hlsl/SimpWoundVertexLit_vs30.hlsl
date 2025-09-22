//======= Copyright (c) 1996-2009, Valve Corporation, All rights reserved. ======
//  STATIC: "HALFLAMBERT"				"0..1"
//  STATIC: "USE_WITH_2B"				"0..1"
//  STATIC: "DECAL"						"0..1" [vs30]
//  STATIC: "FLASHLIGHT"				"0..1" [XBOX]
//  STATIC: "USE_STATIC_CONTROL_FLOW"	"0..1" [vs20]

//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"
//	DYNAMIC: "DOWATERFOG"				"0..1"
//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "MORPHING"					"0..1" [vs30]
//  DYNAMIC: "NUM_LIGHTS"				"0..2" [vs20]

// If using static control flow on Direct3D, we should use the NUM_LIGHTS=0 combo
//  SKIP: $USE_STATIC_CONTROL_FLOW && ( $NUM_LIGHTS > 0 ) [vs20]

// 原文件为vertexlit_and_unlit_generic_bump_vs20.fxc, 使用AIGC 豆包插入自定义逻辑
// 插入部分使用"---------SimpWound"标记
// 为腾出寄存器砍掉了两个纹理变换
// 砍掉TEXCOORD8、TEXCOORD7, 可能会有一些细节问题

#include "common_vs_fxc.h"

static const bool g_bSkinning		= SKINNING ? true : false;
static const int g_FogType			= DOWATERFOG;

// ---------SimpWound
const float4x4 mWoundTransform		:  register( SHADER_SPECIFIC_CONST_0 );	// 0,1,2,3 (4x4矩阵占4个寄存器)
const float4x4 mWoundTransformInvert	:  register( SHADER_SPECIFIC_CONST_4 );	// 4,5,6,7 (4x4矩阵占4个寄存器)
const float3 vWoundSize				:  register( SHADER_SPECIFIC_CONST_8 );	// 8 (float3占1个寄存器)
// ---------SimpWound

const float4x4 g_FlashlightWorldToTexture :  register( SHADER_SPECIFIC_CONST_9 );	// 9,10,11,12 (避开mWound占用的0-8，4x4矩阵占4个寄存器)




//-----------------------------------------------------------------------------
// Input vertex format
//-----------------------------------------------------------------------------
struct VS_INPUT
{
	// This is all of the stuff that we ever use.
	float4 vPos				: POSITION;
	float4 vBoneWeights		: BLENDWEIGHT;
	float4 vBoneIndices		: BLENDINDICES;
	float4 vNormal			: NORMAL;
	float4 vColor			: COLOR0;
	float3 vSpecular		: COLOR1;
	// make these float2's and stick the [n n 0 1] in the dot math.
	float4 vTexCoord0		: TEXCOORD0;
	float4 vTexCoord1		: TEXCOORD1;
	float4 vTexCoord2		: TEXCOORD2;
	float4 vTexCoord3		: TEXCOORD3;
	float3 vTangentS		: TANGENT;
	float3 vTangentT		: BINORMAL;
	float4 vUserData		: TANGENT;

	// Position and normal/tangent deltas
	float3 vPosFlex			: POSITION1;
	float3 vNormalFlex		: NORMAL1;
#ifdef SHADER_MODEL_VS_3_0
	float vVertexID			: POSITION2;
#endif
};


//-----------------------------------------------------------------------------
// Output vertex format
//-----------------------------------------------------------------------------
struct VS_OUTPUT
{
	// Stuff that isn't seen by the pixel shader
	float4 projPos												: POSITION;	
#if !defined( _X360 )
	float  fog													: FOG;
#endif
	// Stuff that is seen by the pixel shader

	float4 baseTexCoord2_tangentSpaceVertToEyeVectorXY			: TEXCOORD0;
	float3 lightAtten											: TEXCOORD1;
	float4 worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ	: TEXCOORD2;
	float3 vWorldNormal											: TEXCOORD3;	// World-space normal
	float4 vWorldTangent										: TEXCOORD4;
#if	USE_WITH_2B
	float4 vProjPos												: TEXCOORD5;
#else
	float3 vWorldBinormal										: TEXCOORD5;
#endif
	float4 worldPos_projPosZ									: TEXCOORD6;

	float4 fogFactorW											: COLOR1;

// ---------SimpWound
	float3 vSimpWoundData 										: TEXCOORD7; 
// ---------SimpWound

};


//-----------------------------------------------------------------------------
// Main shader entry point
//-----------------------------------------------------------------------------
VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float4 vPosition = v.vPos;
	float3 vNormal;
	float4 vTangent;
	DecompressVertex_NormalTangent( v.vNormal, v.vUserData, vNormal, vTangent );

// ---------SimpWound
	float4 vLocalPos = mul( vPosition, mWoundTransformInvert );
	float fDist = length( vLocalPos.xyz / vWoundSize );
	float mask = step(fDist, 1.0); 

	float4 vPosWound = mul( 
		float4(vLocalPos.xyz, 1), 
		mWoundTransform 
	);
	vPosWound.w = 1;

	float3 vNormalWound = normalize( mul( 
		float4(vNormal, 0), 
		mWoundTransform 
	));

	float3 vTangentWound = normalize( mul( 
		float4(vTangent.xyz, 0), 
		mWoundTransform 
	));

	vPosition = lerp(vPosition, vPosWound, mask);
	vNormal = lerp(vNormal, vNormalWound, mask);
	vTangent.xyz = lerp(vTangent.xyz, vTangentWound, mask);
// ---------SimpWound


	ApplyMorph( v.vPosFlex, v.vNormalFlex, vPosition.xyz, vNormal, vTangent.xyz );


	// Perform skinning
	float3 worldNormal, worldPos, worldTangentS, worldTangentT;
	SkinPositionNormalAndTangentSpace( g_bSkinning, vPosition, vNormal, vTangent,
		v.vBoneWeights, v.vBoneIndices, worldPos,
		worldNormal, worldTangentS, worldTangentT );

	// Always normalize since flex path is controlled by runtime
	// constant not a shader combo and will always generate the normalization
	worldNormal   = normalize( worldNormal );
	worldTangentS = normalize( worldTangentS );
	worldTangentT = normalize( worldTangentT );

#if defined( SHADER_MODEL_VS_3_0 ) && MORPHING && DECAL
	// Avoid z precision errors
	worldPos += worldNormal * 0.05f * v.vTexCoord2.z;
#endif

	o.vWorldNormal.xyz = worldNormal.xyz;
	o.vWorldTangent = float4( worldTangentS.xyz, vTangent.w );	 // Propagate binormal sign in world tangent.w

	// Transform into projection space
	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.projPos = vProjPos;
	vProjPos.z = dot( float4( worldPos, 1 ), cViewProjZ );

#if USE_WITH_2B
	o.vProjPos = vProjPos;
#else
	o.vWorldBinormal.xyz = worldTangentT.xyz;
#endif

	o.fogFactorW = CalcFog( worldPos, vProjPos, g_FogType );
#if !defined( _X360 )
	o.fog = o.fogFactorW;
#endif

 	// Needed for water fog alpha and diffuse lighting
	// FIXME: we shouldn't have to compute this all the time.
	o.worldPos_projPosZ = float4( worldPos, vProjPos.z );

	// Needed for cubemapping + parallax mapping
	// FIXME: We shouldn't have to compute this all the time.
	//o.worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ.xyz = VSHADER_VECT_SCALE * (cEyePos - worldPos);
	o.worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ.xyz = normalize( cEyePos.xyz - worldPos.xyz );

#if defined( SHADER_MODEL_VS_2_0 ) && ( !USE_STATIC_CONTROL_FLOW )
	o.lightAtten.xyz = float3(0,0,0);

	#if ( NUM_LIGHTS > 0 )
		o.lightAtten.x = GetVertexAttenForLight( worldPos, 0, false );
	#endif
	#if ( NUM_LIGHTS > 1 )
		o.lightAtten.y = GetVertexAttenForLight( worldPos, 1, false );
	#endif
	#if ( NUM_LIGHTS > 2 )
		o.lightAtten.z = GetVertexAttenForLight( worldPos, 2, false );
	#endif
#else
	// Scalar light attenuation
	o.lightAtten.x = GetVertexAttenForLight( worldPos, 0, true );
	o.lightAtten.y = GetVertexAttenForLight( worldPos, 1, true );
	o.lightAtten.z = GetVertexAttenForLight( worldPos, 2, true );
#endif

	// Base texture coordinate transform
	o.baseTexCoord2_tangentSpaceVertToEyeVectorXY.x = v.vTexCoord0.x;
	o.baseTexCoord2_tangentSpaceVertToEyeVectorXY.y = v.vTexCoord0.y;

	return o;
}