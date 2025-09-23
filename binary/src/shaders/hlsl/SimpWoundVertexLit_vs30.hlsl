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

	float4 vNormal					: NORMAL;
	float3 vSpecular				: COLOR1;

	float3 vTangentS		: TANGENT;
	float3 vTangentT		: BINORMAL;
	float4 vUserData		: TANGENT;

	float4 vTexCoord0		: TEXCOORD0;
	float4 vTexCoord1		: TEXCOORD1;
	float4 vTexCoord2		: TEXCOORD2;
	float4 vTexCoord3		: TEXCOORD3;

};

struct VS_OUTPUT
{
    float4 projPos												: POSITION;	
	float4 baseTexCoord2_tangentSpaceVertToEyeVectorXY			: TEXCOORD0;
	float3 vWoundData 											: TEXCOORD1; 

	float3 vWorldNormal											: TEXCOORD3;	// World-space normal
	float4 vWorldTangent										: TEXCOORD4;
	float3 vWorldBinormal										: TEXCOORD5;
	float4 worldPos_projPosZ									: TEXCOORD6;

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
	float4 vTangent;
	DecompressVertex_NormalTangent( v.vNormal, v.vUserData, vNormal, vTangent );


	// Perform skinning
	float3 worldNormal, worldPos, worldTangentS, worldTangentT;
	SkinPositionNormalAndTangentSpace( g_bSkinning, vPosition, vNormal, vTangent,
		v.vBoneWeights, v.vBoneIndices, worldPos,
		worldNormal, worldTangentS, worldTangentT );

	worldNormal   = normalize( worldNormal );
	worldTangentS = normalize( worldTangentS );
	worldTangentT = normalize( worldTangentT );

	o.vWorldNormal.xyz = worldNormal.xyz;
	o.vWorldTangent = float4( worldTangentS.xyz, vTangent.w );	 // Propagate binormal sign in world tangent.w
	o.vWorldBinormal.xyz = worldTangentT.xyz;

	// Transform into projection space
	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.projPos = vProjPos;
	vProjPos.z = dot( float4( worldPos, 1 ), cViewProjZ );


	o.fogFactorW = CalcFog( worldPos, vProjPos, g_FogType );
#if !defined( _X360 )
	o.fog = o.fogFactorW;
#endif

	o.worldPos_projPosZ = float4( worldPos, vProjPos.z );


	o.baseTexCoord2_tangentSpaceVertToEyeVectorXY.xy = v.vTexCoord0.xy;

	return o;
}