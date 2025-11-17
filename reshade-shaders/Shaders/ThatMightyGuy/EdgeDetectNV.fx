#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

// Comment this out if you don't need the HDR postprocessing pipeline
// It will work both ways
#define TMG_USE_HDR_PIPELINE

uniform float amount <
    ui_category = "General";
    ui_label = "Amount";
    ui_max = 4;
    ui_min = 0;
    ui_step = 0.0000001;
    ui_tooltip = "Effect intensity";
    ui_type = "slider";
> = 1;

uniform float depthAmount <
    ui_category = "General";
    ui_label = "Depth amount";
    ui_max = 4;
    ui_min = 0;
    ui_step = 0.0000001;
    ui_tooltip = "Depth edge intensity";
    ui_type = "slider";
> = 1;

uniform float normalAmount <
    ui_category = "General";
    ui_label = "Normal amount";
    ui_max = 4;
    ui_min = 0;
    ui_step = 0.0000001;
    ui_tooltip = "Normal edge intensity";
    ui_type = "slider";
> = 1;

uniform float2 clip <
    ui_category = "General";
    ui_label = "Clipping";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.0001;
    ui_tooltip = "Define near and far depth cutoffs";
    ui_type = "slider";
> = float2(0.07, 1);

uniform float threshold <
    ui_category = "General";
    ui_label = "Threshold";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.0000001;
    ui_tooltip = "Define what counts as an edge";
    ui_type = "slider";
> = 1;

uniform float2 spread <
    ui_category = "Edge Detection";
    ui_label = "Spread";
    ui_max = 0.01;
    ui_min = 0;
    ui_step = 0.0000001;
    ui_tooltip = "How much does the edge detection kernel spread at clip points";
    ui_type = "slider";
> = float2(0.004, 0.004);

uniform float spreadKnee <
    ui_category = "Edge Detection";
    ui_label = "Spread Knee";
    ui_max = 32;
    ui_min = 0;
    ui_step = 0.01;
    ui_tooltip = "Spread nonlinearity";
    ui_type = "slider";
> = 1;

uniform float normalKnee <
    ui_category = "Edge Detection";
    ui_label = "Normal Knee";
    ui_max = 8;
    ui_min = 0;
    ui_step = 0.0001;
    ui_tooltip = "How soft should the normal-derived edges be";
    ui_type = "slider";
> = 1;

uniform float depthKnee <
    ui_category = "Edge Detection";
    ui_label = "Depth Knee";
    ui_max = 8;
    ui_min = 0;
    ui_step = 0.0001;
    ui_tooltip = "How soft should the depth-derived edges be";
    ui_type = "slider";
> = 1;

uniform float3 shadow <
    ui_category = "Color";
    ui_label = "Shadow";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.0001;
    ui_tooltip = "Darker NV color";
    ui_type = "slider";
> = float3(0.05, 0.1, 1);

uniform float3 highlight <
    ui_category = "Color";
    ui_label = "Highlight";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.0001;
    ui_tooltip = "Lighter NV color";
    ui_type = "slider";
> = float3(0.1, 0.6, 1);

// DisplayDepth.fx
float3 GetScreenSpaceNormal(float2 texcoord)
{
    float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
    float2 posCenter = texcoord.xy;
    float2 posNorth  = posCenter - offset.zy;
    float2 posEast   = posCenter + offset.xz;

    float3 vertCenter = float3(posCenter - 0.5, 1) * ReShade::GetLinearizedDepth(posCenter);
    float3 vertNorth  = float3(posNorth - 0.5,  1) * ReShade::GetLinearizedDepth(posNorth);
    float3 vertEast   = float3(posEast - 0.5,   1) * ReShade::GetLinearizedDepth(posEast);

    return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

float GetDepthDifference(float2 texcoord)
{
    float diff = 0;
    float core = ReShade::GetLinearizedDepth(texcoord);
    for(int x = 0; x < 3; ++x)
    {
        float2 offset = float2(x - 1, 0);
        for(int y = 0; y < 3; ++y)
        {
            offset.y = y - 1;
            diff += ReShade::GetLinearizedDepth(texcoord + offset * lerp(spread.x, spread.y, pow(core, spreadKnee)));
        }
    }
    diff /= 9;

    return diff - core;
}

float3 GetNormalDifference(float2 texcoord)
{
    float3 diff = 0;
    float3 core = GetScreenSpaceNormal(texcoord);
    for(int x = 0; x < 3; ++x)
    {
        float2 offset = float2(x - 1, 0);
        for(int y = 0; y < 3; ++y)
        {
            offset.y = y - 1;
            diff += GetScreenSpaceNormal(texcoord + offset * lerp(spread.x, spread.y, pow(core, spreadKnee)));
        }
    }
    diff /= 9;

    return diff - core;
}

float3 PS_NightVision(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    #ifdef TMG_USE_HDR_PIPELINE
    float3 input = tex2D(HdrSampler, texcoord).rgb;
    #else
    float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
    #endif

    float luma = getLuma(input);
    float fragDepth = ReShade::GetLinearizedDepth(texcoord);

    float3 nd = GetNormalDifference(texcoord);
    float dd = abs(GetDepthDifference(texcoord));

    float4 edge = float4(nd, dd);

    float normal = abs(edge.r + edge.g + edge.b);
    normal = pow(normal * normalAmount, normalKnee);

    float depth = abs(edge.a);
    depth = pow(depth * depthAmount, depthKnee);

    float3 edgeColor = clamp(shadow * normal + highlight * depth, 0, 1);
    float visibility = 1 - luma;

    if(fragDepth <= clip.x)
        visibility *= fragDepth / clip.x;
    else if(fragDepth >= clip.y)
        visibility *= edge.a * 100;

    return input + edgeColor * clamp(visibility, 0, 1) * amount;
}

technique EdgeDetectNV
{
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_NightVision;
        #ifdef TMG_USE_HDR_PIPELINE
        RenderTarget = TempHdrTarget;
        #endif
    }

    #ifdef TMG_USE_HDR_PIPELINE
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
    #endif
}


