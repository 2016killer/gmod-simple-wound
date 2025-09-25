//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"

#include "common_vs_fxc.h"

static const bool g_bSkinning		= SKINNING ? true : false;

float4x4 mMaskTransform1	:  register( SHADER_SPECIFIC_CONST_0 );
float4x4 mMaskTransform2	:  register( SHADER_SPECIFIC_CONST_4 );


struct VS_INPUT
{
	float4 vPos						: POSITION;
	float2 vBaseTexCoord			: TEXCOORD0;
	float4 vBoneWeights				: BLENDWEIGHT;
	float4 vBoneIndices				: BLENDINDICES;
};

struct VS_OUTPUT
{
    float4 vProjPos					: POSITION;	
	float  flFog					: FOG;
	float2 vBaseTexCoord			: TEXCOORD0;
	float4 vLocalPos1 				: TEXCOORD1; 
	float4 vLocalPos2 				: TEXCOORD2; 
	float2 vDist 					: TEXCOORD3; 
};


VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float4 vLocalPos1 = mul( v.vPos, mMaskTransform1 );
	o.vLocalPos1 = vLocalPos1.xyz;
	o.fDist1 = length( vLocalPos1.xyz );

	float4 vLocalPos2 = mul( v.vPos, mMaskTransform2 );
	o.vLocalPos2 = vLocalPos2.xyz;
	o.fDist2 = length( vLocalPos2.xyz );

	float4 vPosition = v.vPos;
	float3 worldPos;
	SkinPosition( 
		g_bSkinning, 
		vPosition,
		v.vBoneWeights, v.vBoneIndices,
		worldPos );

	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	o.vProjPos = vProjPos;

	o.vBaseTexCoord = v.vBaseTexCoord;
	o.flFog = 0;

	return o;
}