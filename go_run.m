clear;  
    
p = pwd;
addpath(fullfile(p, '/methods'));  % the upscaling methods

addpath(fullfile(p, '/ksvdbox')) % K-SVD dictionary training algorithm

addpath(fullfile(p, '/ompbox')) % Orthogonal Matching Pursuit algorithm

addpath(fullfile(p, '/Function'));
addpath(fullfile(p, '/quality'));
addpath(fullfile(p,'/proximal_operator'))
imgscale = 1; % the scale reference we work with
flag = 0;       % flag = 0 - only ISSNIA method, the other get the bicubic result by default
                % flag = 1 - all the methods are applied

upscaling = 2; % the magnification factor x2, x3, x4...

dictionary_flag = 1; % dictionary_flag = 0 - using natural image trained dictionary
                    % dictionary_flag = 1 - using low dimension remote sensing image trained dictionary
if dictionary_flag == 0
    dict_name = 'Natural';
elseif dictionary_flag == 1
    dict_name = 'RS';
end
denoise_flag = 0; % TRPCA denoise for other methods, 0 - no denoise, 1 - denoise
ratio = 0; % noise ratio (0 to 1), 0 - noise free, 1 - all impulse noise
datapath = 'Data/';
input_dir = 'Chikusei';
pattern = '*.mat';
dict_sizes = [2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536];
neighbors = [1:1:12, 16:4:32, 40:8:64, 80:16:128, 256, 512, 1024];
clusterszA = 2048; % neighborhood size for A+
load('seed.mat');
rng(s);

disp(['The experiment uses ' input_dir ' dataset and aims at a magnification of factor x' num2str(upscaling) '.']);
if flag==1  
    disp('All methods are employed : Bicubic, Zeyde et al., ISSNIA.');    
else
    disp('We run only for ISSNIA methods, the other get the Bicubic result by default.');
end

fprintf('\n\n');

d=10    %1024
    %d = 9; % 512
    %d = 8; %256
    %d = 7; %128
    %d = 6; % 64
    %d = 5; % 32
    %d=4;  %16
    %d=3;  %8
    %d=2; %4
    %d=1; %2
    tag = [input_dir '_x' num2str(upscaling) '_' num2str(dict_sizes(d)) 'atoms'];
    
    disp(['Upscaling x' num2str(upscaling) ' ' input_dir ' with Zeyde dictionary of size = ' num2str(dict_sizes(d))]);
    
    mat_file = ['Dictionary/conf_Zeyde_' num2str(dict_sizes(d)) '_finalx' num2str(upscaling) '_'  dict_name];

    
    if exist([mat_file '.mat'],'file')
        disp(['Load trained dictionary...' mat_file]);
        load(mat_file, 'conf');
    else
        error(['can not find ', mat_file ,' please comfirm the file name is right or run "Training.m" first.']);
    end
            
    if dict_sizes(d) < 1024
        lambda = 0.01;
    elseif dict_sizes(d) < 2048
        lambda = 0.1;
    elseif dict_sizes(d) < 8192
        lambda = 1;
    else
        lambda = 5;
    end
    conf.filenames = glob([datapath,input_dir], pattern); % Cell array      
    conf.desc = {'Original', 'Bicubic','Zeyde et al.','ISSLDIA'};
    conf.results = {};
    
    %% load the regressors
    Aplus_PPs = [];
        
    fname = ['Anchor/Aplus_x' num2str(upscaling) '_' num2str(dict_sizes(d)) 'atoms' num2str(clusterszA) 'nn_5mil_' dict_name '.mat'];
    
    if exist(fname,'file')
       load(fname);
    else
       error(['can not find "' fname '", please comfirm the file name is right or run "Training.m" first.']);
    end
    

    %%    
    conf.result_dirImages = qmkdir([datapath input_dir '/ratio' num2str(ratio) '/sf' num2str(upscaling) '/results_' tag]);
    conf.result_dir = qmkdir([datapath input_dir '/ratio' num2str(ratio) '/sf' num2str(upscaling) '/Results-' datestr(now, 'YYYY-mm-dd_HH-MM-SS')]);
    
    %%
    t = cputime;    
        
    conf.countedtime = zeros(numel(conf.desc),numel(conf.filenames));
    
    res =[];
    
for i = 1:numel(conf.filenames)
        clear noise
        f = conf.filenames{i};
        [p, name, x] = fileparts(f);
        img = load(f);
        matname = fieldnames(img);
        HR = getfield(img,matname{1});
       
        %% choose 240x240 as the ground truth image
        %% CAVE need downsample x2 to 256x256 , then choose the central part of image HR = HR(8:247,8:247,:); 
        % HR = imresize(HR,1/2,'bicubic');
        % HR = HR(8:247,8:247,:); 
        % HR = HR(206:445,1:240,:); % PaviaU
        % HR = HR(501:740,1:240,:); % WDC
 
        HR = HR(501:740,41:280,:); % Chikusei
        HR = guiyihua(HR,255,0);
        img = cell(1);
        img{1} = HR;
        [M,N,band] = size(img{1});
        MN = [M,N];
        
        if imgscale<1
            img = resize(img, imgscale, conf.interpolate_kernel);
        end
        sz = size(img{1});
        
        fprintf('%d/%d\t"%s" [%d x %d]\n', i, numel(conf.filenames), f, sz(1), sz(2));
        
        LR = resize(img, 1/conf.scale^conf.level, conf.interpolate_kernel);
        LR = LR{1};
        [nrow, ncol,spec] = size(LR);
        if ratio > 0 
            for b = 1:spec
                noise{1}(:,:,b)=imnoise(LR(:,:,b)/255,'salt & pepper',ratio);
                noise{1}(:,:,b)=noise{1}(:,:,b)*255;
            end
        else
            noise{1} = LR;
        end
%% TRPCA denoise for other methods
        if denoise_flag == 1
            [n1,n2,n3]=size(noise{1});
            opts.lambda = 1/sqrt(max(n1,n2)*n3);
            opts.mu = 1e-4;
            opts.tol = 1e-8;
            opts.rho = 1.2;
            opts.max_iter = 800;
            opts.DEBUG = 1;
            [denoise_trpca{1},E,rank,obj,err,iter] = trpca_tnn(noise{1},opts.lambda,opts);
        else
            denoise_trpca{1} = noise{1};
        end
%% bicubic
        interpolated = resize(noise, conf.scale^conf.level, conf.interpolate_kernel);
        res{1} = interpolated;
%% Zeyde        
        if (flag == 1)
            startt = tic;
            res{2} = scaleup_Zeyde(conf, denoise_trpca);
            toc(startt)
            conf.countedtime(2,i) = toc(startt); 
        else
            res{2} = interpolated;
        end

%% ISSLDIA        
        if ~isempty(Aplus_PPs)
            ISSNIA_time = tic;
            % denoise_time = tic;
            if ratio == 0
                start_reg = 1e-5;
                max_denoise_iter = 1;
            else
                start_reg = 3e5;
                max_denoise_iter = 5000;
            end
            [noise{1},W] = denoise(noise{1},LR,upscaling,start_reg,max_denoise_iter); % 3e5 , 5000 for remote sensing HSI
            % toc(denoise_time);
            NAR_path =['NAR/240/ratio' num2str(ratio) '/sf' num2str(upscaling) '/' input_dir '/' name];
            qmkdir(['NAR/240/ratio' num2str(ratio) '/sf' num2str(upscaling) '/' input_dir '/']);
            fprintf('ISSNIA\n');
            conf.PPs = Aplus_PPs;
            LLR = imresize(noise{1},1/2,'bicubic');%%%%%
            LR_b = (imresize(noise{1}, upscaling, 'bicubic'));
            LLR_b = (imresize(LLR, [M,N], 'bicubic'));
            [M,N,band] = size(HR);
            lambda1 = 0.003;                   % similarity regularization
            lambda2 = 0.02;                   % spectral regularization
            eta     = 0.1;                    % A+ regularzation
            % nar(i) = tic;
            for b = 1:band
                if ~exist([NAR_path ,'NAR_',num2str(b),'.mat'],'file')
                     fprintf('compute Nonlocal-similarity band %d\n',b);
                     NAR = Comp_NLAR_Matrix(LR_b(:,:,b),LLR_b(:,:,b),[M,N]);
                     save([NAR_path ,'NAR_',num2str(b),'.mat'],'NAR');
                 end
            end
            DA = scaleup_ANR(conf, noise);
            SR_res{1} = ISSLDIA_SR(noise{1}, upscaling, DA{1}, lambda1, lambda2, eta, HR, NAR_path,conf,W);
            toc(ISSNIA_time)
            res{3} = SR_res;        
            conf.countedtime(3,i) = toc(ISSNIA_time);    
        else
            res{3} = interpolated;
        end
        result = cat(3, img{1}, interpolated{1}, res{2}{1}, res{3}{1});
        conf.results{i} = {};
        for j = 1:numel(conf.desc)            
            conf.results{i}{j} = fullfile(conf.result_dirImages, [name sprintf('[%d-%s]', j, conf.desc{j}) x]);            
            band = size(HR,3);
            img = result(:, :, (j-1)*band+1:j*band);
            save(conf.results{i}{j},'img');
        end        
        conf.filenames{i} = f;
    end   
    conf.duration = cputime - t;

    % Test performance
    [psnr,sam,ergas,uiqi,ssim] = run_comparison(conf,upscaling);
    
    scores = [psnr,sam,ergas,uiqi,ssim];
    m = mean(scores,1);
    scores = [scores;m];
    %%    
    save([datapath input_dir '/ratio' num2str(ratio) '/sf' num2str(upscaling) '/' tag '_' mat_file '_results.mat'],'conf','scores');