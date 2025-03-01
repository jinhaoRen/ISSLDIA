function  y    =    B_x( x, sf, sz,band,lambda1,eta,miu)
z                           =    zeros(sz);
% s0                          =    floor(sf/2);
s0 = 2;
% I                           =  eye(size(W1,1));
% Hx                          =    real( ifft2(fft2( reshape(x, sz) ).*fft_B) );% 模糊
% z(s0:sf:end, s0:sf:end)     =    Hx(s0:sf:end, s0:sf:end);% 下采样
% y                           =    real( ifft2(fft2( z ).*fft_BT) );  

tem                           =    imresize(reshape(x,[sz,band]),1/sf,'bicubic');
y                           =    imresize(tem,sf,'bicubic');
% tem                         =    DS*reshape(x,[sz(1)*sz(2),band]);
% y                           =    DS'*tem;
y                           =    y(:) + (eta+lambda1+miu)*x;


