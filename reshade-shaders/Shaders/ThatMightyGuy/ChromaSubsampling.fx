
uniform float resolution <
    ui_category = "General";
    ui_label = "Downsampling multiplier";
    ui_max = 64;
    ui_min = 1;
    ui_step = 0.1;
    ui_tooltip = "How large should chunks be";
    ui_type = "slider";
> = 16;

uniform float chromaDiscardProbability <
    ui_category = "Loss";
    ui_label = "Chroma discard probability";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.01;
    ui_tooltip = "How likely is a chunk's color data to be discarded";
    ui_type = "slider";
> = 0.1;

uniform float saturation <
    ui_category = "Loss";
    ui_label = "Saturation";
    ui_max = 1;
    ui_min = 0;
    ui_step = 0.01;
    ui_tooltip = "Desaturate the resulting image";
    ui_type = "slider";
> = 1;

uniform int random_value < source = "random"; min = -100; max = 100; >;

#include "ReShade.fxh"

#include "HdrTarget.fxh"
#include "TempHdrTarget.fxh"

#include "Utils.fxh"

texture2D TMGChromaDownsamplingTarget < pooled = false; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	MipLevels = 1;

	Format = RGBA16F;
};

sampler2D TMGChromaDownsamplingSampler
{
    Texture = TMGChromaDownsamplingTarget;
};

float4 PS_CopyFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(TempHdrSampler, texcoord);
}

float3 PS_ChromaDownsamplingFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float aspect = (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float2 uvp = float2(
        (1 / (BUFFER_WIDTH / resolution)) * floor(texcoord.x / (1 / (BUFFER_WIDTH / resolution))),
        (1 / (BUFFER_HEIGHT / resolution)) * floor(texcoord.y / (1 / (BUFFER_HEIGHT / resolution)))
    );
    uvp += float2((1 / (BUFFER_WIDTH / resolution)) / 2, (1 / (BUFFER_HEIGHT / resolution)) / 2);

    float3 inputFull = tex2D(HdrSampler, texcoord).rgb;
    float3 inputPix = tex2D(HdrSampler, uvp).rgb;
    if(rand2(uvp + (float)random_value / 10000) < chromaDiscardProbability)
        return float3(toYCbCr(inputFull).x, 0, 0);
    return float3(toYCbCr(inputFull).x, toYCbCr(inputPix).yz);
}

float3 PS_ChromaSubsamplingFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 input = tex2D(TMGChromaDownsamplingSampler, texcoord).rgb;
    return sat(toRGB(input), saturation);
}

technique ChromaSubsampling
{
    pass chroma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ChromaDownsamplingFXmain;
        RenderTarget = TMGChromaDownsamplingTarget;
    }
    pass draw
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ChromaSubsamplingFXmain;
        RenderTarget = TempHdrTarget;
    }
    pass copy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyFXmain;
        RenderTarget = HdrTarget;
    }
}


