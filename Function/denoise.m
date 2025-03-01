function [Xl,W] = denoise(Xl,low,sf,eta,maxiter)
mineta =1e-5;
tol = 1e-4;
[n1,n2,n3] = size(low);
%%
Xl = reshape(Xl,n1*n2,n3);
iter = maxiter;
[ind1] = find(Xl==255);
[ind2] = find(Xl==0);
error = +Inf;
YW = Xl;
for i = 1:iter
    last_E = error;
    W = LSR1(Xl,eta);
    % if eta == 1e-5
    %     pause
    % end
    YW = Xl*W;
    error = norm(Xl-YW);
    grand = error/norm(W);
    eta = eta - 0.3*grand;
    eta = max(mineta,eta);
    Xl(ind1) =YW(ind1);
    Xl(ind2) =YW(ind2);
    if abs(last_E - error) < tol 
        break;
    end
end

YW = reshape(YW,n1,n2,n3);
Xl = reshape(Xl,n1,n2,n3);


[psnr_ge,rmse_ge, ergas_ge, sam_ge, uiqi_ge,ssim_ge,DD_ge,CC_ge] = quality_assessment(double(low), double(YW), 0, 1/sf);
fprintf('PSNR for ISSNIA Denoise: %f dB\n', psnr_ge);
fprintf('SAM for ISSNIA Denoise: %f \n', sam_ge);
fprintf('ERGAS for ISSNIA Denoise: %f \n', ergas_ge);
fprintf('UIQI for ISSNIA Denoise: %f \n', uiqi_ge);
end

