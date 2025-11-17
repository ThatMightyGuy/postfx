uniform float amount <
    ui_category = "General";
    ui_label = "Exposure";
    ui_max = 10;
    ui_min = -10;
    ui_step = 0.001;
    ui_tooltip = "How much is the effect allowed to boost exposure";
    ui_type = "slider";
> = 1;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_ExposureFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;
    return exposure(input, amount);
}

technique Exposure
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ExposureFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}
