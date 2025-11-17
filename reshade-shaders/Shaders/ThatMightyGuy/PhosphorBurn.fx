uniform float amount <
    ui_category = "General";
    ui_label = "Amount";
    ui_max = 5;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How prominent the burn will be";
    ui_type = "slider";
> = 1;

uniform float threshold <
    ui_category = "General";
    ui_label = "Threshold";
    ui_max = 5;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "Burn threshold";
    ui_type = "slider";
> = 1;

uniform float knee <
    ui_category = "General";
    ui_label = "Knee";
    ui_max = 5;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How soft the burn will be";
    ui_type = "slider";
> = 1;

uniform float dischargeRate <
    ui_category = "General";
    ui_label = "Discharge rate";
    ui_max = 10;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How quickly will the burnt out spots heal";
    ui_type = "slider";
> = 1;

uniform float dischargeKnee <
    ui_category = "General";
    ui_label = "Discharge knee";
    ui_max = 10;
    ui_min = 1;
    ui_step = 0.001;
    ui_tooltip = "Discharge nonlinearity";
    ui_type = "slider";
> = 1;

uniform float kernelSize <
    ui_category = "General";
    ui_label = "Kernel size";
    ui_max = 0.05;
    ui_min = 0;
    ui_step = 0.00001;
    ui_tooltip = "How blurry will the burn be";
    ui_type = "slider";
> = 1;

uniform float blur <
    ui_category = "General";
    ui_label = "Blur amount";
    ui_max = 5;
    ui_min = 0;
    ui_step = 0.001;
    ui_tooltip = "How noticeable will the blur be";
    ui_type = "slider";
> = 1;

uniform float frametime < source = "frametime"; >;

static const float RENDER_DIV = 8;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

texture2D burnTarget < pooled = false; >
{
	Width = BUFFER_WIDTH / RENDER_DIV;
	Height = BUFFER_HEIGHT / RENDER_DIV;
	MipLevels = 1;

	Format = RGBA16F;
};

storage2D burnStorageTarget
{
	Texture = burnTarget;
	MipLevel = 0;
};

sampler2D burnSampler
{
    Texture = burnTarget;
};

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

void CS_Update(uint3 id : SV_DispatchThreadID)
{
    float4 input = max(0, tex2Dfetch(HdrSampler, id.xy, 0) - threshold);
    float4 fade = tex2Dfetch(burnSampler, id.xy / RENDER_DIV, 0);
    fade *= 1-pow(getLuma(fade.rgb), dischargeKnee) - (dischargeRate * (frametime / 1000));
    tex2Dstore(burnStorageTarget, id.xy / RENDER_DIV, max(fade, input));
}

float3 PS_PhosphorBurnFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(HdrSampler, texcoord).rgb;

    float4 burnPixel = tex2D(burnSampler, texcoord);
    float4 burnBlur = (
        tex2D(burnSampler, texcoord - float2(kernelSize, kernelSize)) +
        tex2D(burnSampler, texcoord - float2(kernelSize, 0)) * 2 +
        tex2D(burnSampler, texcoord - float2(kernelSize, -kernelSize)) +
        tex2D(burnSampler, texcoord - float2(0, kernelSize)) * 2 +
        burnPixel * 4 +
        tex2D(burnSampler, texcoord - float2(0, -kernelSize))  * 2 +
        tex2D(burnSampler, texcoord - float2(-kernelSize, kernelSize)) +
        tex2D(burnSampler, texcoord - float2(-kernelSize, 0)) * 2 +
        tex2D(burnSampler, texcoord - float2(-kernelSize, -kernelSize))
    ) / 16;

    float burn = getLuma(lerp(burnPixel, burnBlur, blur).rgb);

    return exposure(input, pow(burn * amount, knee));
    // return burn;
}

technique PhosphorBurn
{
    pass store
    {
        DispatchSizeX = BUFFER_WIDTH / RENDER_DIV;
		DispatchSizeY = BUFFER_HEIGHT / RENDER_DIV;
        ComputeShader = CS_Update<64, 8>;
        RenderTarget = burnTarget;
    }
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PhosphorBurnFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}
