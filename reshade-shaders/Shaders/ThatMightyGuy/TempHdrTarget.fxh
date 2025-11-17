texture2D TempHdrTarget < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	MipLevels = 1;

	Format = RGBA32F;
};

storage2D TempHdrStorageTarget
{
	Texture = TempHdrTarget;
	MipLevel = 0;
};

sampler2D TempHdrSampler
{
    Texture = TempHdrTarget;
};
