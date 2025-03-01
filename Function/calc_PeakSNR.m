function [psnr_HR,rmse_HR, ergas_HR, sam_HR, uiqi_HR,ssim_HR,DD_HR,CC_HR] = calc_PeakSNR(f, g, sf)
GT = load(f);
GT = GT.image;
method = load(g);
method = method.image;
[psnr_HR,rmse_HR, ergas_HR, sam_HR, uiqi_HR,ssim_HR,DD_HR,CC_HR] = quality_assessment(GT, method, 0, 1/sf);
% F = im2double(imread(f)); % original
% G = im2double(imread(g)); % distorted
% E = F - G; % error signal
% N = numel(E); % Assume the original signal is at peak (|F|=1)
% res = 10*log10( 255^2 / mean(E(:).^2) );
