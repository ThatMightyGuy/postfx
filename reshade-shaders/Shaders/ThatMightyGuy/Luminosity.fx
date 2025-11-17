#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_LuminosityFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;
    float luma = getLuma(input);
    return float3(max(0, luma - 2), max(0, luma - 1), luma);
}

technique Luminosity
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LuminosityFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


