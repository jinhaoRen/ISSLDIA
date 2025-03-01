function [imgs] = scaleup_Zeyde(conf, imgs)

% Super-Resolution Iteration
for j = 1:conf.level
    fprintf('Scale-Up Zeyde et al. #%d', j);
    midres = resize(imgs, conf.upsample_factor, conf.interpolate_kernel);
    for i = 1:numel(midres)
        sz       = size(midres{i});
        if length(sz)<3
            sz(3) = 1;
        end
        features = collect(conf, {midres{i}}, conf.upsample_factor, conf.filters);
        % features = collect(conf, {midres{i}}, 1, conf.filters);
        features = double(features);
        
        for b = 1:sz(3)
            % Encode features using OMP algorithm
            coeffs = omp(double(conf.dict_lores), conf.V_pca' * features(:,:,b), [], 3);
            patches(:,:,b) = conf.dict_hires * full(coeffs);   
        end                    
        img_size = sz;
        grid = sampling_grid(img_size, ...
            conf.window, conf.overlap, conf.border, conf.scale);
        result = overlap_add(patches, img_size, grid);
        % Add low frequencies to residual result
        result = result + midres{i};
        imgs{i} = result; % for the next iteration
        fprintf('.');
    end
end
fprintf('\n');