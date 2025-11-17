uniform float amount <
    ui_category = "General";
    ui_label = "Amount";
    ui_max = 1;
    ui_min = -1;
    ui_step = 0.0001;
    ui_tooltip = "How much will the image be distorted";
    ui_type = "slider";
> = 0;

uniform float scale <
    ui_category = "General";
    ui_label = "Scale";
    ui_max = 1;
    ui_min = 0.5;
    ui_step = 0.0001;
    ui_tooltip = "Scale the resulting image to reduce overscan";
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

float3 PS_BarrelDistortionFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float2 uv = 2 * texcoord - 1;
    float r = sqrt(pow(texcoord.x, 2) + pow(texcoord.y, 2));
    float2 dist3 = uv / (1 - amount * r);
    float2 dist2 = uv / (1 - amount * (pow(dist3.x, 2) + pow(dist3.y, 2)));
    dist2 *= scale;
    dist2 = (dist2 + 1) / 2;
    if(dist2.x < 0 || dist2.x > 1 || dist2.y < 0 || dist2.y > 1)
        return 0;

    float3 input = tex2D(HdrSampler, dist2).rgb;
    
    return input;
}

technique BarrelDistortion
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BarrelDistortionFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}
