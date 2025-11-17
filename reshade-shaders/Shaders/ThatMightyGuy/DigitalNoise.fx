uniform float amount <
    ui_category = "General";
    ui_label = "Noise amount";
    ui_max = 1;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "How much noise will affect the image";
    ui_type = "slider";
> = 0.25;

uniform float saturation <
    ui_category = "General";
    ui_label = "Noise saturation";
    ui_max = 2;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "How colorful should the noise be";
    ui_type = "slider";
> = 1;

uniform float roughness <
    ui_category = "General";
    ui_label = "Noise roughness";
    ui_max = 10;
    ui_min = 1;
    ui_step = 0.001;
    ui_tooltip = "How uneven should noise values be";
    ui_type = "slider";
> = 1;

uniform float scale <
    ui_category = "General";
    ui_label = "Noise scale";
    ui_max = 10000;
    ui_min = 1;
    ui_step = 1;
    ui_tooltip = "Noise resolution";
    ui_type = "slider";
> = 50;

uniform float lightnessBias <
    ui_category = "General";
    ui_label = "Noise lightness bias";
    ui_max = 1;
    ui_min = -1.0;
    ui_step = 0.001;
    ui_tooltip = "Let the noise affect dark/light areas more";
    ui_type = "slider";
> = 0;

uniform float lightnessBiasKnee <
    ui_category = "General";
    ui_label = "Noise lightness bias knee";
    ui_max = 8;
    ui_min = 0.5;
    ui_step = 0.001;
    ui_tooltip = "How soft is the transition between light and dark";
    ui_type = "slider";
> = 0.5;

uniform float timer < source = "timer"; > = 0;

uniform int random_value < source = "random"; min = -10000; max = 10000; >;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"
#include "Random.fxh"

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_DigitalNoiseFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;

    float luma = getLuma(input);

    float3 result = (pow(rand2dTo3d((texcoord + random_value) + timer / scale), roughness) - 0.5) * 2.0;

    float bias;

    luma += lightnessBias;
    
    if(luma > 0.5)
        bias = map(luma, 0.5, 1, lightnessBias, 1);
    else
        bias = map(luma, 0, 0.5, 0, lightnessBias);
    
    bias = pow(bias, lightnessBiasKnee);

    result *= bias;
    result = sat(result * amount, saturation);

    return input + result;
}

technique DigitalNoise
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DigitalNoiseFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


