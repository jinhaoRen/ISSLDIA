function  W1   =  Comp_NLAR_Matrix(LR, LLR, sz )

ch      =   size(LLR,3);%取光谱数
h       =   sz(1);%取空间行
w       =   sz(2);%取空间列
S          =   30;%在2S*2S大小的窗口内进行比较相似度   36
f          =   3; %patch大小f^2                         5
f2         =   f^2; 
t          =   floor(f/2);
nv         =   10;% 取前nv个相似图像块 15
e_LLR       =   padarray( LLR, [t t], 'symmetric' );%填充图像
e_LR        =   padarray( LR,  [t,t], 'symmetric' );
[h w]      =   size( LLR(:,:,1) );%取图像第一个光谱的行列
nt         =   (nv)*h*w;%做出稀疏矩阵的行数
R          =   zeros(nt,1);
C          =   zeros(nt,1);
V          =   zeros(nt,1);
L          =   h*w;%确立像素数
X          =   zeros(f*f*ch, L, 'single'); 
Y          =   zeros(f*f*ch, L, 'single'); 
k          =   0;
lam_w      =  50000; % 48000
lamada     =  1;
for b = 1:ch
for i  = 1:f
    for j  = 1:f  
        k        =   k+1;
        blk_LLR      =   e_LLR(i:end-f+i,j:end-f+j, b);%取第一个光谱的空间像素
        Y(k+f2*(b-1),:)   =   blk_LLR(:)'; %按列存储
        blk_LR      =   e_LR(i:end-f+i,j:end-f+j, b);%取第一个光谱的空间像素
        X(k+f2*(b-1),:)   =   blk_LR(:)'; %按列存储
    end
end
end
% X           =   X - mean(X);
% Y           =   Y - mean(Y);
% Xnorm       =   sqrt(sum(X).^2);
% Ynorm       =   sqrt(sum(Y).^2);
% X           =   X./Xnorm;
% Y           =   Y./Ynorm;
X           =   X'; %转置
Y           =   Y';

X2          =   sum(X.^2, 2);%每一列的平方和
Y2          =   sum(Y.^2, 2);%每一列的平方和
f2          =   f^2;
I           =   reshape((1:L), h, w);%做一个排序
f3          =   f2*ch;
cnt         =  1;
for  row  =  1 : h
    for  col  =  1 : w
        
        off_cen  =  (col-1)*h + row;        
        
        rmin    =   max( row-S, 1 );
        rmax    =   min( row+S, h );
        cmin    =   max( col-S, 1 );
        cmax    =   min( col+S, w );
         
        idx     =   I(rmin:rmax, cmin:cmax);
        idx     =   idx(:);
        B       =   Y(idx, :);%取LLR局部区域patch        
        B2      =   Y2(idx, :);%取LLR同样区域的平方和
        v       =   X(off_cen, :);%取LR第off_cen个图像块
        v2      =   X2(off_cen, :);%LR第off_cen个patch内像素的平方和
        c2      =   B*v';%计算ab（以内积计算）
        
        dis     =   (B2 + v2 - 2*c2)/f3;%计算距离LR第off_cen个图像块和LLR区域之间的距离，使用a^2+b^2+2ab
        [val,ind]     =   sort(dis);%距离排序        

        b       =   B( ind(2:nv + 1),: )*v';% 因为ind第一位可能是off_cen块本身，所以选从2到第nv+1个相似块，B( ind(2:nv + 1),: )
        wei     =   cgsolve(B( ind(2:nv + 1),: )*B( ind(2:nv + 1),: )' + lam_w*eye(nv), b); %计算类似Ax = b的方程 ,共轭梯度求解，BB'w + lam*w = B*v', 即norm(B'w - v')2 + lam*norm(w)2
        
        R(cnt:cnt+nv)     =   off_cen; %当前为第几个谱线
        C(cnt:cnt+nv)     =   [idx( ind(2:nv+1) );  off_cen];%取前nv个相似谱线
        V(cnt:cnt+nv)     =   [lamada*(wei./(sum(wei)+eps)); (1-lamada)];  %  
       
        cnt                 =   cnt + nv + 1;        
    end
end
R     =   R(1:cnt-1); %与原位置谱线相似的nv个谱线的横坐标
C     =   C(1:cnt-1); %与原位置谱线相似的nv个谱线的纵坐标
V     =   V(1:cnt-1); %与原位置谱线相似的nv个谱线的权值

W1    =   sparse(R, C, V, h*w, h*w); %相似谱线的权值矩阵
W1    =   W1';  
