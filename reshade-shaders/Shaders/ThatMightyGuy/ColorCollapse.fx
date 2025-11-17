#include "ReShade.fxh"

#include "HdrTarget.fxh"

float4 PS_ColorCollapseFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(HdrSampler, texcoord);
}

technique ColorCollapse
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCollapseFXmain;
    }
}


