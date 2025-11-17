static const float3 SPD = float3(0.412656, 0.715158, 0.072186);

// // https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion
// static const float3x3 RGB2YCBCR = float3x3(
//     0.2126, 0.7152, 0.0722,
//     -0.1146, -0.3854, 0.5,
//     0.5, -0.4542, -0.0458
// );

// // https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion
// static const float3x3 YCBCR2RGB = float3x3(
//     1, 0, 1.5748,
//     1, -0.1873, -0.4681,
//     1, 1.8556, 0
// );

// // https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion
// static const float3x3 RGB2YCBCR = float3x3(
//     0.2126, -0.1146, 0.5,
//     0.7152, -0.3854, -0.4542,
//     0.0722, 0.5, -0.0458
// );

// // https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.709_conversion
// static const float3x3 YCBCR2RGB = float3x3(
//     1, 1, 1,
//     0, -0.1873, 1.8556,
//     1.5748, -0.4681, 0
// );

// PD80 Base Effects
float getLuma(in float3 col)
{
    return dot(col, SPD);
}

// PD80 Base Effects
float3 sat(float3 col, float fac)
{
    return saturate(lerp(getLuma(col.rgb), col.rgb, fac));
}

float3 exposure(float3 col, float fac)
{
    // Why? Hell if I know, I'm just not gonna touch that
    fac = fac < 0.0f ? fac * 0.333f : fac;

    float3 preexp = col * exp2(fac);
    float3 blowout = (max(0, preexp - 1));
    float3 adjust = float3(blowout.g + blowout.b, blowout.r + blowout.b, blowout.r + blowout.g);

    return preexp + adjust;
}

// https://www.shadertoy.com/view/4djSRW hash32
float3 rand(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}

float rand2(float2 co)
{
    return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

float3 rand3(float2 co)
{
    return float3(rand2(co), rand2(co + float2(25782.3512, 23684.3256)), rand2(co + float2(15461.26721, 36277.1516)));
}

float map(float value, float min1, float max1, float min2, float max2)
{
    float t = (value - min1) / (max1 - min1);
    return t * (max2 - min2) + min2;
}

float3 aces(float3 x)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float3 toYCbCr(float3 rgb)
{
    rgb = min(rgb, 1);
    float y = (0.257 * rgb.r) + (0.504 * rgb.g) + (0.098 * rgb.b);
    float cb = (0.439 * rgb.r) - (0.368 * rgb.g) - (0.071 * rgb.b);
    float cr = -(0.148 * rgb.r) - (0.291 * rgb.g) + (0.439 * rgb.b);

    return float3(y, cb, cr);
}

float3 toRGB(float3 ycbcr)
{
    float r = 1.164 * ycbcr.x + 2.018 * ycbcr.y;
    float g = 1.164 * ycbcr.x - 0.813 * ycbcr.z - 0.391 * ycbcr.y;
    float b = 1.164 * ycbcr.x + 1.596 * ycbcr.z;

    return float3(r, g, b);
}

