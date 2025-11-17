uniform float amount <
    ui_category = "General";
    ui_label = "Opacity";
    ui_max = 1;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "MaskBlur texture opacity";
    ui_type = "slider";
> = 0.5;

uniform float roughness <
    ui_category = "General";
    ui_label = "Roughness";
    ui_max = 8;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "MaskBlur texture roughness";
    ui_type = "slider";
> = 1;

uniform float radius <
    ui_category = "General";
    ui_label = "Blur radius";
    ui_max = 8;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "How much will the unmasked areas be blurred";
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

float4 gaussian(sampler2D tex, float2 res, float2 uv)
{
    const float Offsets[11] =
    {
        -5,
        -4,
        -3,
        -2,
        -1,
        0,
        1,
        2,
        3,
        4,
        5,
    };

    const float Weights[11 * 11] =
    {
        0.007959,0.008049,0.00812,0.008171,0.008202,0.008212,0.008202,0.008171,0.00812,0.008049,0.007959,
        0.008049,0.00814,0.008212,0.008263,0.008294,0.008305,0.008294,0.008263,0.008212,0.00814,0.008049,
        0.00812,0.008212,0.008284,0.008336,0.008367,0.008378,0.008367,0.008336,0.008284,0.008212,0.00812,
        0.008171,0.008263,0.008336,0.008388,0.00842,0.00843,0.00842,0.008388,0.008336,0.008263,0.008171,
        0.008202,0.008294,0.008367,0.00842,0.008451,0.008462,0.008451,0.00842,0.008367,0.008294,0.008202,
        0.008212,0.008305,0.008378,0.00843,0.008462,0.008473,0.008462,0.00843,0.008378,0.008305,0.008212,
        0.008202,0.008294,0.008367,0.00842,0.008451,0.008462,0.008451,0.00842,0.008367,0.008294,0.008202,
        0.008171,0.008263,0.008336,0.008388,0.00842,0.00843,0.00842,0.008388,0.008336,0.008263,0.008171,
        0.00812,0.008212,0.008284,0.008336,0.008367,0.008378,0.008367,0.008336,0.008284,0.008212,0.00812,
        0.008049,0.00814,0.008212,0.008263,0.008294,0.008305,0.008294,0.008263,0.008212,0.00814,0.008049,
        0.007959,0.008049,0.00812,0.008171,0.008202,0.008212,0.008202,0.008171,0.00812,0.008049,0.007959,
    };


    float pixelWidth = 1 / res.x;
    float pixelHeight = 1 / res.y;

    float4 color = 0;

    float2 blur;

    for (int x = 0; x < 11; x++) 
    {
        blur.x = uv.x + Offsets[x] * pixelWidth;
        for (int y = 0; y < 11; y++)
        {
            blur.y = uv.y + Offsets[y] * pixelHeight;
            color += tex2D(tex, blur) * Weights[x * 11 + y];
        }
    }

    return color;
}

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_MaskBlurFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;

    float mask = getLuma(pow(tex2D(TMGDirtSampler, (texcoord + float2(x, y)) * scale), roughness) * amount);

    if(mask > 0)
        return lerp(input, gaussian(TMGDirtSampler, float2(4096, 2048), texcoord), mask * radius);
    return input;
}

technique MaskBlur
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MaskBlurFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


