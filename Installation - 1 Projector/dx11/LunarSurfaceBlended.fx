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
	//hack for blended version where we encode ours and theirs VP into V and P respectively
	float4x4 tVPOurs : VIEW;
	float4x4 tVPTheirs : PROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWorldInverse <string uiname="Inverse World Transform"; >;
	float thickness = 0.05f;
	float brightness = 0.5f;
	float ambient = 0.2f;
	float3 direction = float3(1.0f, 1.0f, -1.0f);
	float master = 1.0f;
	float fill = 0.0f;
	float gamma = 1.0f;
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
	float Factor : TEXCOORD2;
};

//x is a measurement of 'insideness'
float crossover(float xOurs, float xTheirs) {
	const float lineLength = sqrt(pow(xOurs + xTheirs, 2) * 2);
	const float positionOnLine = sqrt(pow(xOurs,2) * 2);
	return positionOnLine / lineLength;
}

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4 TexCd = input.PosO;
	
	float4 sampledPosition = World.SampleLevel(g_samNearest, input.TexCd.xy, 0);
	sampledPosition.w = 1.0f;
	
	float4 PosO = sampledPosition;
	PosO = mul(PosO, tW);
	Out.PosO = mul(PosO, tWorldInverse);
	
	
	//--
	//Edge blending (and output coord)
	//--
	//
	float4 PosPOurs = mul(PosO, tVPOurs);
	Out.PosWVP = PosPOurs;
	PosPOurs /= PosPOurs.w;
	
	float4 PosPTheirs = mul(PosO, tVPTheirs);
	PosPTheirs /= PosPTheirs.w;
	
	
	bool isLeft = PosPOurs.x > PosPTheirs.x;
	float xOurs = isLeft ? 1.0f - PosPOurs.x : PosPOurs.x + 1.0f;
	float xTheirs = isLeft ? PosPTheirs.x + 1.0f : 1.0f - PosPTheirs.x;
	
	bool insideTheirs = all(abs(PosPTheirs.xyz) < 1.0f);
	//blend if insideTheirs
	float blendFactor = crossover(xOurs, xTheirs);
	Out.Factor = insideTheirs ? blendFactor : 1.0f;
	//
	//--
	
	
	return Out;
}

vs2ps VSCropped(VS_IN input)
{
	vs2ps Out = VS(input);
	
	//--
	//Culling
	//--
	//
	//cull all vertices outside of the bounding sphere
	Out.PosWVP.w *= length(Out.PosO.xyz) < (1.0f + thickness) * 1.1f;
	//
	//--
	
    return Out;
}

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
	
	//lighting
	float3 directionN = normalize(direction);
	float shade = clamp(dot(directionN, In.PosO.xyz), 0.0f, 1.0f);
	
	//apply
	col = rim * (shade * brightness + ambient);
	
	//levels
	col *= master;
	col.rgb *= pow(abs(In.Factor), gamma);
	
    return saturate(col);
}

float4 PSPassThrough(vs2ps In): SV_Target
{
	return In.PosO;
}

float4 PSWhite(vs2ps In): SV_Target
{
	return 1;
}






technique10 LunarSurfaceBlended
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VSCropped() ) );
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




