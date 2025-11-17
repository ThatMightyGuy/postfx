uniform float amount <
    ui_category = "General";
    ui_label = "Amount";
    ui_max = 2;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "How much is the effect allowed to boost exposure";
    ui_type = "slider";
> = 1;

uniform float target <
    ui_category = "General";
    ui_label = "Exposure target";
    ui_max = 1;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "Desired frame exposure level";
    ui_type = "slider";
> = 0.5;

uniform float knee <
    ui_category = "General";
    ui_label = "Knee";
    ui_max = 8;
    ui_min = 0.0;
    ui_step = 0.001;
    ui_tooltip = "How aggressively will the effect change exposure";
    ui_type = "slider";
> = 2;

uniform float interval <
    ui_category = "General";
    ui_label = "Metering interval";
    ui_max = 1000;
    ui_min = 0;
    ui_step = 1;
    ui_tooltip = "How often will the camera evaluate the lightness of the frame [in ms]";
    ui_type = "slider";
    ui_units = "ms";
> = 0;

uniform int samplingPointsX <
    ui_category = "Sampling";
    ui_label = "Horizontal sample point count";
    ui_max = 30;
    ui_min = 1;
    ui_step = 0.001;
    ui_tooltip = "How many points (columns of points) will be evaluated horizontally";
    ui_type = "slider";
> = 3;

uniform int samplingPointsY <
    ui_category = "Sampling";
    ui_label = "Vertical sample point count";
    ui_max = 30;
    ui_min = 1;
    ui_step = 0.001;
    ui_tooltip = "How many points (rows of points) will be evaluated vertically";
    ui_type = "slider";
> = 3;

uniform float timer < source = "timer"; > = 0;

uniform float frametime < source = "frametime"; > = 0;

static const float FRAMETIME_MUL = 1.2;
static const float RENDER_DIV = 4;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

// Texture buffer for the light metering compute shader
texture2D texTarget < pooled = false; >
{
	Width = BUFFER_WIDTH / RENDER_DIV;
	Height = BUFFER_HEIGHT / RENDER_DIV;
	MipLevels = 1;

	Format = RGBA16F;
};

storage2D storageTarget
{
	Texture = texTarget;
	MipLevel = 0;
};

sampler2D texSampler
{
    Texture = texTarget;
};

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float evaluateLightness(sampler2D tex)
{
    float avg = 0;

    float2 stepping = float2(1.0 / samplingPointsX, 1.0 / samplingPointsY);
    for(int y = 0; y < samplingPointsY; y++)
    {
        float2 uv = float2(
            stepping.x / 2.0,
            stepping.y / 2.0 + y * stepping.y
        );

        for(int x = 0; x < samplingPointsX; x++)
        {
            uv.x = stepping.x / 2.0 + x * stepping.x;
            avg += getLuma(tex2D(tex, uv).rgb);
        }
    }

    return avg / (samplingPointsX * samplingPointsY);
}

// TODO: Replace with a pixel shader
void CS_Update(uint3 id : SV_DispatchThreadID)
{
    float4 col = tex2Dfetch(HdrSampler, id.xy * RENDER_DIV, 0);
    if(abs(timer % interval) <= frametime * FRAMETIME_MUL)
        tex2Dstore(storageTarget, id.xy, col);
}

float3 PS_AutoexposureFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;
    float lightness = evaluateLightness(texSampler);

    float bias = target - lightness;

    return lerp(input, exposure(input, bias * knee), amount);
}

technique Autoexposure
{
    pass store
    {
        DispatchSizeX = BUFFER_WIDTH / RENDER_DIV;
		DispatchSizeY = BUFFER_HEIGHT / RENDER_DIV;
        ComputeShader = CS_Update<64, 8>;
        RenderTarget = texTarget;
    }
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AutoexposureFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


