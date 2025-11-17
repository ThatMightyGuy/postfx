uniform float3 color <
    ui_category = "General";
    ui_label = "Tint";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "Filter tint";
    ui_type = "color";
> = 1;

uniform float density <
    ui_category = "General";
    ui_label = "Density";
    ui_max = 10;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How opaque the filter is";
    ui_type = "slider";
> = 1;

uniform float saturation <
    ui_category = "General";
    ui_label = "Saturation";
    ui_max = 2;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How saturated the pigment is";
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

float3 PS_ColorFilterFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;
    float3 filter = lerp(1, color, saturation);
    return input * normalize(filter) * 1.732 * (10 - density) / 10;
}

technique ColorFilter
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorFilterFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}
