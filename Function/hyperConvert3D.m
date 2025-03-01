function [Image3D] = hyperConvert3D(Image2D, h, w, numBands)
[numBands, N] = size(Image2D);%取行数作为光谱带，取空间大小
if (1 == N)
    Image3D = reshape(Image2D, h, w);
else
    Image3D = reshape(Image2D.', h, w, numBands); %将其重塑成3维张量
end
end

