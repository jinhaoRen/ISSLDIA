function [imgs, midres] = scaleup_ANR(conf, imgs)

% Super-Resolution Iteration
    fprintf('Scale-Up ANR');
    midres = resize(imgs, conf.scale, conf.interpolate_kernel);    
    for i = 1:numel(midres)
        sz       = size(midres{i});
        if length(sz)<3
            sz(3) = 1;
        end
        features = collect(conf, {midres{i}}, conf.upsample_factor, conf.filters);
        features = double(features);

        % Reconstruct using patches' dictionary and their anchored
        % projections
        for b = 1:sz(3)
             features_PCA(:,:,b) = conf.V_pca'*features(:,:,b);
        end         
        features = features_PCA;
        clear features_PCA;
        
        patches = zeros(size(conf.PPs{1},1),size(features,2), sz(3));
        blocksize = 70000; %if not sufficient memory then you can reduce the blocksize
        if size(conf.dict_lores,2) > 10000
            blocksize = 500;
        end
        for band = 1:sz(3)
            if size(features,2) < blocksize
                D = abs(conf.dict_lores'*features(:,:,band)); 
                [val idx] = max(D);            
                for l = 1:size(features,2)            
                    patches(:,l,band) = conf.PPs{idx(l)} * features(:,l,band);
                end
            else            
                for b = 1:blocksize:size(features,2)
                    if b+blocksize-1 > size(features,2)
                        D = abs(conf.pointslo'*features(:,b:end,band));
                    else
                        D = abs(conf.pointslo'*features(:,b:b+blocksize-1,band));                 
                    end
                    [val idx] = max(D);            

                    for l = 1:size(idx,2)
                        patches(:,b-1+l,band) = conf.PPs{idx(l)} * features(:,b-1+l,band);
                    end
                end
            end
        end   
        
        % Combine all patches into one image
        img_size = sz;
        grid = sampling_grid(img_size, ...
            conf.window, conf.overlap, conf.border, conf.upsample_factor);
        result = overlap_add(patches, img_size, grid);
        result = result + midres{i};
        imgs{i} = result; % for the next iteration
        fprintf('.');
    end
fprintf('\n');
