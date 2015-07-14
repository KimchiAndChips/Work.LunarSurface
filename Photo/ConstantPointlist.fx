//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float2 TexCd : TEXCOORD0;
	float4 Color : COLOR0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	float4 Color : COLOR0;
	float4 PositionWorld : TEXCOORD1;
};

vs2ps VSInProjector(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 TexCd;
	TexCd.xy = input.TexCd;
	TexCd.zw = float2(0, 1);
	
	float2 projectorPosition = TexCd.xy;
	//projectorPosition *= 2.0f;
	//projectorPosition -= 1.0f;
	//projectorPosition.y *= -1;

	Out.PositionWorld = mul(input.PosO, tW);
    Out.PosWVP  = float4(0,0,0,1);
	Out.PosWVP.xy = projectorPosition;
	Out.TexCd = mul(TexCd, tTex);
	Out.Color = input.Color;
    return Out;
}


vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 TexCd;
	TexCd.xy = input.TexCd;
	TexCd.zw = float2(0, 1);
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
    Out.TexCd = mul(TexCd, tTex);
	Out.Color = input.Color;
    return Out;
}


float zCutOff = 0.4f;


float4 PS(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample(g_samLinear,In.TexCd.xy) * cAmb;
	col *= In.Color;
	col = mul(col, tColor);
	col.a *= Alpha;
    return In.PositionWorld.z < zCutOff;In.TexCd;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

technique10 ConstantInProjector
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VSInProjector() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





