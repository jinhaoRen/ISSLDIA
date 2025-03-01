function [X_last] = ISSLDIA_SR(lIm, up_scale,DA, lambda1,lambda2,eta,im, NAR_path,conf,W)
addpath("quality\");
miu = 0.5;
[M,N,band]    = size(im);
MN       = [M,N];
LRHSI_b = (imresize(lIm, up_scale, 'bicubic'));
L_b2D = hyperConvert2D(LRHSI_b);
%% Compute Nonlocal Matrix
for i = 1:band
    load([NAR_path,'NAR_',num2str(i),'.mat']);
    Non_Lb(i,:) = L_b2D(i,:)*NAR;
end
Non = hyperConvert3D(Non_Lb,M,N,band);
result = scaleup_ANR_self(conf,{Non});
Non_Lb = hyperConvert2D(Non+result);
%% initialize for ADMM
Z  = zeros(size(LRHSI_b));
X_last = Z;
psnr_last = -inf;
Z  = hyperConvert2D(Z);
V = zeros( size(Z) );
L = Z;
X2D   = zeros(size(L_b2D));
for i = 1:150
    %% update X
    x = X2D';
    x= x(:);
    DA(DA>255) = 255;
    DA(DA<0)  = 0;
    DA2D = hyperConvert2D(DA);
    B = (L_b2D' + eta*DA2D' +lambda1*Non_Lb' + miu*(L' + V'/(2*miu)));
    [x,flag] = pcg(  @(x)B_x(x, up_scale, MN,band, lambda1,eta,miu), B(:), 1E-4, 350, [], [], x);
    X2D  = reshape(x,[M*N,band]);
    X2D(X2D>255) = 255;
    X2D(X2D<0)  = 0;
    Z = X2D';
    Z3D    = hyperConvert3D(Z,M,N,band);
    %% update L
    L_last = L;
    IW = eye(band)-W;
    L = (lambda2*(IW*IW')+miu*eye(size(IW*IW')))\(miu*(Z - V/(2*miu)));
    %% update V
    V      =    V + miu*( L - Z);
    %%
    % [psnr_HR,rmse_HR, ergas_HR, sam_HR, uiqi_HR,ssim_HR,DD_HR,CC_HR] = quality_assessment(double(im), double(Z3D), 0, 1/up_scale);
    % if psnr_last>psnr_HR
    %     break;
    % end
    % fprintf('psnr:%f sam:%f ergas:%f uiqi:%f ssim:%f\n',psnr_HR,sam_HR,ergas_HR,uiqi_HR,ssim_HR);
    X_last = Z3D;
    % psnr_last = psnr_HR;
    rk = sum(abs((Z-L)),'all')/band;
    sk = miu*sum(abs((L_last-L)),"all")/band;
    fprintf('Original problem:%f, Dual problem:%f, miu:%f\n',rk,sk,miu);
    if rk<0.002 || sk < 0.002
        return
    end
    if mod(i,3) == 0
        if rk>10*sk
            miu = 1.5*miu; V = V/1.5;
        elseif sk>10*rk
            miu = miu/1.5; V = V*1.5;
        end
    end
end
