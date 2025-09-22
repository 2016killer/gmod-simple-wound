//	DYNAMIC: "SKINNING"					"0..1"
//  DYNAMIC: "COMPRESSED_VERTS"			"0..1"

#include "common_vs_fxc.h"

static const bool g_bSkinning		= SKINNING ? true : false;

float4x4 mWoundTransform		:  register( SHADER_SPECIFIC_CONST_0 );
float4x4 mWoundTransformInvert	:  register( SHADER_SPECIFIC_CONST_4 );
float3 vWoundSize				:  register( SHADER_SPECIFIC_CONST_8 );

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
	float2 vProjectedTexCoord 		: TEXCOORD1; 
	float fDist 					: TEXCOORD2; 
};


VS_OUTPUT main( const VS_INPUT v )
{
	VS_OUTPUT o = ( VS_OUTPUT )0;

	float4 vLocalPos = mul( v.vPos, mWoundTransformInvert );
	float fDist = length( vLocalPos.xyz );

	o.vProjectedTexCoord = vLocalPos.yz;
	o.fDist = fDist;

	float4 vPosWound = mul( 
		float4(vLocalPos.xyz / max(fDist, 1e-6), 1), 
		mWoundTransform 
	);
	vPosWound.w = 1;
	
	float mask = step(fDist, vWoundSize.x); 

	float4 vPosition = lerp(v.vPos, vPosWound, mask);

	
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