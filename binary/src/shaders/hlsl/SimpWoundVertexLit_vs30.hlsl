//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"
//	DYNAMIC: "DOWATERFOG"				"0..1"

#include "common_vs_fxc.h"

static const bool g_bSkinning		= SKINNING ? true : false;
static const int g_FogType			= DOWATERFOG;

const float4x4 mWoundTransform			:  register( SHADER_SPECIFIC_CONST_0 );
const float4x4 mWoundTransformInvert	:  register( SHADER_SPECIFIC_CONST_4 );
const float3 vWoundSize_blendMode		:  register( SHADER_SPECIFIC_CONST_8 );

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
	float3 vWoundData 											: TEXCOORD1; 
	float4 color												: TEXCOORD2;	
	float4 worldPos_projPosZ									: TEXCOORD3;
	float4 fogFactorW											: COLOR1;

#if !defined( _X360 )
	float  fog													: FOG;
#endif
};


void SimpWound_Deform(const float4x4 mTransform, const float4x4 mTransformInvert, const float size, 
	const float4 vPos, out float4 vPosOut, out float3 vWoundData)
{
	// 球面变形

	float4 vLocalPos = mul(vPos, mTransformInvert);
	float fDist = length(vLocalPos.xyz);
	vWoundData = float3(vLocalPos.yz, fDist);

	float4 vPosProj = mul( 
		float4(vLocalPos.xyz / max(fDist, 1e-6), 1), 
		mTransform 
	);
	vPosProj.w = 1;

	vPosOut = lerp(vPos, vPosProj, step(fDist, size));
}

VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float4 vPosition;
	SimpWound_Deform(mWoundTransform, mWoundTransformInvert, vWoundSize_blendMode.x, 
		v.vPos, vPosition, o.vWoundData
	);

	float3 vNormal;
	DecompressVertex_Normal( v.vNormal, vNormal );


	ApplyMorph( v.vPosFlex, v.vNormalFlex, vPosition.xyz, vNormal );

	// Perform skinning
	float3 worldNormal, worldPos;
	SkinPositionAndNormal( 
		g_bSkinning, 
		vPosition, vNormal,
		v.vBoneWeights, v.vBoneIndices,
		worldPos, worldNormal );

	worldNormal = normalize( worldNormal );


	// Transform into projection space
	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.projPos = vProjPos;
	vProjPos.z = dot( float4( worldPos, 1 ), cViewProjZ );


	o.fogFactorW = CalcFog( worldPos, vProjPos, g_FogType );
#if !defined( _X360 )
	o.fog = o.fogFactorW;
#endif

	o.worldPos_projPosZ = float4( worldPos, vProjPos.z );


	o.color.xyz = DoLighting( worldPos, worldNormal, v.vSpecular, true, true, true );

	
	o.baseTexCoord.xy = v.vTexCoord0.xy;

	return o;
}