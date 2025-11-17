uniform float lowerThreshold <
    ui_category = "General";
    ui_label = "Lower threshold";
    ui_max = 5;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "When will the light overload the sensor";
    ui_type = "slider";
> = 1;

uniform float knee <
    ui_category = "General";
    ui_label = "Blowout knee";
    ui_max = 10;
    ui_min = 1;
    ui_step = 0.001;
    ui_tooltip = "How sharply should the light blow out";
    ui_type = "slider";
> = 2;

uniform float blowoutMultiplier <
    ui_category = "General";
    ui_label = "Blowout";
    ui_max = 10;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How much will the blown out parts of the image bloom over";
    ui_type = "slider";
> = 1;

uniform float blowoutBias <
    ui_category = "General";
    ui_label = "Blowout bias";
    ui_max = 5;
    ui_min = -5;
    ui_step = 0.001;
    ui_tooltip = "Exaggerates the blowout";
    ui_type = "slider";
> = 0;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_SensorOverloadFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;

    // float3 testCol = input * float3(1, 1, 1);

    float luma = getLuma(input);

    if(luma > lowerThreshold)
        return lerp(input, luma * blowoutMultiplier, pow(luma - lowerThreshold, knee) * (blowoutBias * 10));
    return input;
}

technique SensorOverload
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SensorOverloadFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


