//====== Copyright � 1996-2007, Valve Corporation, All rights reserved. =======//
//

//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"
//	DYNAMIC: "DOWATERFOG"				"0..1"
//  STATIC: "FLASHLIGHT"				"0..1"

#include "common_vs_fxc.h"

// 不太懂hlsl，瞎几把乱写的，仅供参考
// 自定义逻辑部分用 SimpWound圈起，其他都是Ctrl C+V Value的源码。

static const bool g_bSkinning		= SKINNING ? true : false;
static const int g_FogType			= DOWATERFOG;
static const bool g_bFlashlight		= FLASHLIGHT ? true : false;


struct VS_INPUT
{
	float4 vPos						: POSITION;
	float4 vBoneWeights				: BLENDWEIGHT;
	float4 vBoneIndices				: BLENDINDICES;
	float3 vSpecular				: COLOR1;

	float4 vNormal					: NORMAL;
	float2 vTexCoord0				: TEXCOORD0;

	// Position and normal/tangent deltas
	float3 vPosFlex			: POSITION1;
	float3 vNormalFlex		: NORMAL1;
};

struct VS_OUTPUT
{
    float4 projPos												: POSITION;	
	float2 baseTexCoord											: TEXCOORD0;
	float4 color												: TEXCOORD2;	
	float4 worldPos_projPosZ									: TEXCOORD3;
	float4 vProjPos												: TEXCOORD4;
	float3 worldSpaceNormal										: TEXCOORD5;


	float4 fogFactorW											: COLOR1;

#if !defined( _X360 )
	float  fog													: FOG;
#endif



};



VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float3 vNormal;
	DecompressVertex_Normal( v.vNormal, vNormal );

	float4 vPosition = v.vPos;

	ApplyMorph( v.vPosFlex, v.vNormalFlex, vPosition.xyz, vNormal );

	// Perform skinning
	float3 worldNormal, worldPos;
	SkinPositionAndNormal( 
		g_bSkinning, 
		vPosition, vNormal,
		v.vBoneWeights, v.vBoneIndices,
		worldPos, worldNormal );

	// ------SimpWound
	worldNormal = -normalize( worldNormal );
	// ------SimpWound
	
	o.worldSpaceNormal = worldNormal;

	// Transform into projection space
	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.projPos = vProjPos;
	vProjPos.z = dot( float4( worldPos, 1 ), cViewProjZ );

	o.vProjPos = vProjPos;
	o.fogFactorW.w = CalcFog( worldPos, vProjPos, g_FogType );
#if !defined( _X360 )
	o.fog = o.fogFactorW;
#endif

	o.worldPos_projPosZ = float4( worldPos, vProjPos.z );


	o.color.xyz = DoLighting( worldPos, worldNormal, v.vSpecular, true, true, true );


	o.baseTexCoord.xy = v.vTexCoord0.xy;

	return o;
}