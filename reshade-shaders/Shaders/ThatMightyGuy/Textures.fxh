texture2D TMGDirtTexture < source = "ThatMightyGuy/tmg_dirt.png"; >
{
    Width = 4096;
    Height = 2048;
    MipLevels = 1;
    AddressU = MIRROR;
	AddressV = MIRROR;
};

sampler2D TMGDirtSampler
{
    Texture = TMGDirtTexture;
};
