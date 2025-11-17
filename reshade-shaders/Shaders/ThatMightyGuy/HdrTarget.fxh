texture2D HdrTarget < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	MipLevels = 1;

	Format = RGBA32F;
};

storage2D HdrStorageTarget
{
	Texture = HdrTarget;
	MipLevel = 0;
};

sampler2D HdrSampler
{
    Texture = HdrTarget;
};
