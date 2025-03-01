function [Image2D] = hyperConvert2D(Image3D)
if (ndims(Image3D) == 2)%如果传入图像是一个二维矩阵
    numBands = 1;
    [h, w] = size(Image3D);
else
    [h, w, numBands] = size(Image3D);%取图像的高、宽、以及光谱带
end
Image2D = reshape(Image3D, w*h, numBands).';%将其按照行是一个光谱带，列是所有的空间像素组合成一个新的矩阵，因为加了转置，所以图像大小为29*（512*512）
end
