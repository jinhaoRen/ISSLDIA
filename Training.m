clear;  
    
p = pwd;
addpath(fullfile(p, '/methods'));  % the upscaling methods

addpath(fullfile(p, '/ksvdbox')) % K-SVD dictionary training algorithm

addpath(fullfile(p, '/ompbox')) % Orthogonal Matching Pursuit algorithm

imgscale = 1; % the scale reference we work with
flag = 1;       % flag = 0 - Training dictionary for CAVE datasets
                % flag = 1 - Training dictionary for remote sensing hyperspectral image datasets
Anchor_folder = 'Anchor/';
Dictionary_folder = 'Dictionary/';
if flag == 0
    dict_name = 'Natural';
    pattern = '*.bmp';
    dataset = 'CVPR08-SR/Data/Training';
elseif flag == 1
    dict_name = 'RS';
    pattern = '*.tif';
    dataset = 'UCMerced_LandUse/Images';
end
upscaling = 2; % the magnification factor x2, x3, x4...
dict_sizes = [2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536];
neighbors = [1:1:12, 16:4:32, 40:8:64, 80:16:128, 256, 512, 1024];
clusterszA = 2048; % neighborhood size for A+
fprintf('\n\n');

for d=10    %1024
    %d = 9; % 512
    %d = 8; %256
    %d = 7; %128
    %d = 6; % 64
    %d = 5; % 32
    %d=4;  %16
    %d=3;  %8
    %d=2; %4
    %d=1; %2
    
    % tag = [input_dir '_x' num2str(upscaling) '_' num2str(dict_sizes(d)) 'atoms'];
    
    disp(['Upscaling x' num2str(upscaling) 'with Zeyde dictionary of size = ' num2str(dict_sizes(d))]);
    mat_file = ['conf_Zeyde_' num2str(dict_sizes(d)) '_finalx' num2str(upscaling) '_' dict_name];    
    if exist([Dictionary_folder mat_file '.mat'],'file')
        disp(['Load trained dictionary...' mat_file]);
        load([Dictionary_folder mat_file], 'conf');
    else                            
        disp(['Training dictionary of size ' num2str(dict_sizes(d)) ' using Zeyde approach...']);
        % Simulation settings
        conf.scale = upscaling; % scale-up factor
        conf.level = 1; % # of scale-ups to perform
        conf.window = [3 3]; % low-res. window size
        conf.border = [1 1]; % border of the image (to ignore)

        % High-pass filters for feature extraction (defined for upsampled low-res.)
        conf.upsample_factor = upscaling; % upsample low-res. into mid-res.
        O = zeros(1, conf.upsample_factor-1);
        G = [1 O -1]; % Gradient
        L = [1 O -2 O 1]/2; % Laplacian
        conf.filters = {G, G.', L, L.'}; % 2D versions
        conf.interpolate_kernel = 'bicubic';

        conf.overlap = [1 1]; % partial overlap (for faster training)
        if upscaling <= 2
            conf.overlap = [1 1]; % partial overlap (for faster training)
        end
        
        startt = tic;
        data = cat(1,load_images(glob(dataset,pattern)));
        conf = learn_dict(conf, data, dict_sizes(d));        
        conf.overlap = conf.window - [1 1]; % full overlap scheme (for better reconstruction)    
        conf.trainingtime = toc(startt);
        toc(startt)
        
        save([Dictionary_folder mat_file], 'conf');                       
        
        % train call        
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
        
    %% A+ computing the regressors
    Aplus_PPs = [];
        
    fname = ['Aplus_x' num2str(upscaling) '_' num2str(dict_sizes(d)) 'atoms' num2str(clusterszA) 'nn_5mil_' dict_name '.mat'];
    
    if exist([Anchor_folder fname],'file')
       load([Anchor_folder fname]);
       fprintf(['\n',fname,' already exists']);
    else
        %%
       disp('Compute A+ regressors');
       ttime = tic;
       tic
       data = cat(1,load_images(glob(dataset,pattern)));
       [plores phires] = collectSamplesScales(conf, data , 12, 0.98);  
        if size(plores,2) > 5000000                
            plores = plores(:,1:5000000);
            phires = phires(:,1:5000000);
        end
        number_samples = size(plores,2);
        
        % l2 normalize LR patches, and scale the corresponding HR patches
        l2 = sum(plores.^2).^0.5+eps;
        l2n = repmat(l2,size(plores,1),1);    
        l2(l2<0.1) = 1;
        plores = plores./l2n;
        phires = phires./repmat(l2,size(phires,1),1);
        clear l2
        clear l2n

        llambda = 0.1;
   
        for i = 1:size(conf.dict_lores,2)
            fprintf('anchor:%d\n',i);
            D = pdist2(single(plores'),single(conf.dict_lores(:,i)'));
            [~, idx] = sort(D);                
            Lo = plores(:, idx(1:clusterszA));                                    
            Hi = phires(:, idx(1:clusterszA));
            Aplus_PPs{i} = Hi*inv(Lo'*Lo+llambda*eye(size(Lo,2)))*Lo';
 
        end        
        clear plores
        clear phires
        
        ttime = toc(ttime);        
        save([Anchor_folder fname],'Aplus_PPs','ttime', 'number_samples');   
        toc
    end    
end
%