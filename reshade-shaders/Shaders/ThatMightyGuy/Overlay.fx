uniform float amount <
    ui_category = "General";
    ui_label = "Opacity";
    ui_max = 1;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "Overlay texture opacity";
    ui_type = "slider";
> = 0.5;

uniform float roughness <
    ui_category = "General";
    ui_label = "Roughness";
    ui_max = 8;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "Overlay texture roughness";
    ui_type = "slider";
> = 1;

uniform float x <
    ui_category = "Translation";
    ui_label = "X";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "X position";
    ui_type = "slider";
> = 0;

uniform float y <
    ui_category = "Translation";
    ui_label = "Y";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "Y position";
    ui_type = "slider";
> = 0;

uniform float scale <
    ui_category = "Translation";
    ui_label = "Scale";
    ui_max = 10;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "Texture scale";
    ui_type = "slider";
> = 1;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Textures.fxh"
#include "Utils.fxh"

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_OverlayFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;

    return input + pow(tex2D(TMGDirtSampler, (texcoord + float2(x, y)) * scale), roughness) * amount * getLuma(input);
}

technique Overlay
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OverlayFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


