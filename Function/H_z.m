function   x    =   H_z(z, fft_B, sf, sz,s0)
[ch, n]         =    size(z);%取reshape后的图像大小



if ch==1
    Hz          =    real( ifft2(fft2( reshape(z, sz) ).*fft_B) );
    x           =    Hz(s0:sf:end, s0:sf:end);
    x           =    (x(:))';
else
    x           =    zeros(ch, floor(n/(sf^2)));    
    for  i  = 1 : ch
        Hz         =    real( ifft2(fft2( reshape(z(i,:), sz) ).*fft_B) );%将每一个光谱维的空间像素，塑形成512*512，大小然后转换到傅里叶域中，进行点乘，因为卷积操作等于频率域点乘，再进行反傅里叶变换，最后取实部
        t          =    Hz(s0:sf:end, s0:sf:end);%从第一个开始，行列每隔8个取一个数字，相当于进行下采样
        x(i,:)     =    (t(:))';%在将其全部放在第一列
    end
end


