//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D World <string uiname="World";>;

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState g_samNearest <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tWVP : WORLDVIEWPROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tWorldInverse <string uiname="Inverse World Transform"; >;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 PosO : TEXCOORD1;
	float4 Debug : COLOR0;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 TexCd = input.PosO;
	
    TexCd = mul(input.TexCd, tTex);
	
	float4 sampledPosition = World.SampleLevel(g_samNearest, TexCd.xy, 0);
	sampledPosition.w = 1.0f;
	
	float4 PosO = sampledPosition;
	PosO = mul(PosO, tW);
	Out.PosO = mul(PosO, tWorldInverse);
	Out.PosWVP = mul(PosO, tVP);
	Out.Debug = sampledPosition;
    return Out;
}


float thickness = 0.05f;
float brightness = 0.5f;
float ambient = 0.2f;
float3 direction = float3(1.0f, 1.0f, -1.0f);
float master = 1.0f;
float fill = 0.0f;

float4 PS(vs2ps In): SV_Target
{
    float4 col = 1;
	//col.a *= Alpha;
	col = In.PosO;
	float r = length(In.PosO.xyz);
	float offSurface = abs(r-1.0f);
	
	//rim
	float rim = 1.0f - smoothstep(offSurface, 0, thickness);
	
	//fill
	rim += float(r < 1.0f) * fill;
	rim = clamp(rim, 0.0f, 1.0f);
	
	float3 directionN = normalize(direction);
	float shade = clamp(dot(directionN, In.PosO.xyz), 0.0f, 1.0f);
	col = rim * (shade * brightness + ambient);
    return col * master;
}

float4 PSPassThrough(vs2ps In): SV_Target
{
	return In.PosO;
}

float4 PSWhite(vs2ps In): SV_Target
{
	return 1;
}






technique10 LunarSurface
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}

technique10 PassThrough
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PSPassThrough() ) );
	}
}


technique10 White
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PSWhite() ) );
	}
}




