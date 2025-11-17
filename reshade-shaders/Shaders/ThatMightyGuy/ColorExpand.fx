#include "ReShade.fxh"

#include "HdrTarget.fxh"

float4 PS_ColorExpandFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord, 0);
}

technique ColorExpand
{
    pass store
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorExpandFXmain;
        RenderTarget = HdrTarget;
    }
}
