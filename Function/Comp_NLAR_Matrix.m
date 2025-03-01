function  W1   =  Comp_NLAR_Matrix(LR, LLR, sz )

ch      =   size(LLR,3);%ȡ������
h       =   sz(1);%ȡ�ռ���
w       =   sz(2);%ȡ�ռ���
S          =   30;%��2S*2S��С�Ĵ����ڽ��бȽ����ƶ�   36
f          =   3; %patch��Сf^2                         5
f2         =   f^2; 
t          =   floor(f/2);
nv         =   10;% ȡǰnv������ͼ��� 15
e_LLR       =   padarray( LLR, [t t], 'symmetric' );%���ͼ��
e_LR        =   padarray( LR,  [t,t], 'symmetric' );
[h w]      =   size( LLR(:,:,1) );%ȡͼ���һ�����׵�����
nt         =   (nv)*h*w;%����ϡ����������
R          =   zeros(nt,1);
C          =   zeros(nt,1);
V          =   zeros(nt,1);
L          =   h*w;%ȷ��������
X          =   zeros(f*f*ch, L, 'single'); 
Y          =   zeros(f*f*ch, L, 'single'); 
k          =   0;
lam_w      =  50000; % 48000
lamada     =  1;
for b = 1:ch
for i  = 1:f
    for j  = 1:f  
        k        =   k+1;
        blk_LLR      =   e_LLR(i:end-f+i,j:end-f+j, b);%ȡ��һ�����׵Ŀռ�����
        Y(k+f2*(b-1),:)   =   blk_LLR(:)'; %���д洢
        blk_LR      =   e_LR(i:end-f+i,j:end-f+j, b);%ȡ��һ�����׵Ŀռ�����
        X(k+f2*(b-1),:)   =   blk_LR(:)'; %���д洢
    end
end
end
% X           =   X - mean(X);
% Y           =   Y - mean(Y);
% Xnorm       =   sqrt(sum(X).^2);
% Ynorm       =   sqrt(sum(Y).^2);
% X           =   X./Xnorm;
% Y           =   Y./Ynorm;
X           =   X'; %ת��
Y           =   Y';

X2          =   sum(X.^2, 2);%ÿһ�е�ƽ����
Y2          =   sum(Y.^2, 2);%ÿһ�е�ƽ����
f2          =   f^2;
I           =   reshape((1:L), h, w);%��һ������
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
        B       =   Y(idx, :);%ȡLLR�ֲ�����patch        
        B2      =   Y2(idx, :);%ȡLLRͬ�������ƽ����
        v       =   X(off_cen, :);%ȡLR��off_cen��ͼ���
        v2      =   X2(off_cen, :);%LR��off_cen��patch�����ص�ƽ����
        c2      =   B*v';%����ab�����ڻ����㣩
        
        dis     =   (B2 + v2 - 2*c2)/f3;%�������LR��off_cen��ͼ����LLR����֮��ľ��룬ʹ��a^2+b^2+2ab
        [val,ind]     =   sort(dis);%��������        

        b       =   B( ind(2:nv + 1),: )*v';% ��Ϊind��һλ������off_cen�鱾������ѡ��2����nv+1�����ƿ飬B( ind(2:nv + 1),: )
        wei     =   cgsolve(B( ind(2:nv + 1),: )*B( ind(2:nv + 1),: )' + lam_w*eye(nv), b); %��������Ax = b�ķ��� ,�����ݶ���⣬BB'w + lam*w = B*v', ��norm(B'w - v')2 + lam*norm(w)2
        
        R(cnt:cnt+nv)     =   off_cen; %��ǰΪ�ڼ�������
        C(cnt:cnt+nv)     =   [idx( ind(2:nv+1) );  off_cen];%ȡǰnv����������
        V(cnt:cnt+nv)     =   [lamada*(wei./(sum(wei)+eps)); (1-lamada)];  %  
       
        cnt                 =   cnt + nv + 1;        
    end
end
R     =   R(1:cnt-1); %��ԭλ���������Ƶ�nv�����ߵĺ�����
C     =   C(1:cnt-1); %��ԭλ���������Ƶ�nv�����ߵ�������
V     =   V(1:cnt-1); %��ԭλ���������Ƶ�nv�����ߵ�Ȩֵ

W1    =   sparse(R, C, V, h*w, h*w); %�������ߵ�Ȩֵ����
W1    =   W1';  
