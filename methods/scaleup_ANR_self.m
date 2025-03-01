function [result] = scaleup_ANR_self(conf, imgs)

% Super-Resolution Iteration
    
    midres = imgs;
    
    for i = 1:numel(midres)
        sz       = size(midres{i});
        features = collect(conf, {midres{i}}, conf.upsample_factor, conf.filters);
         % features = collect(conf, {midres{i}}, 1, conf.filters);
        features = double(features);

        % Reconstruct using patches' dictionary and their anchored
        % projections
        for b = 1:sz(3)
             features_PCA(:,:,b) = conf.V_pca'*features(:,:,b);
        end         
        features = features_PCA;
        clear features_PCA;
        
        patches = zeros(size(conf.PPs{1},1),size(features,2), sz(3));
        
        for band = 1:sz(3)
           
                D = abs(conf.dict_lores'*features(:,:,band)); 
            %D = conf.pointslo'*features; 
            %D = conf.pointsloPCA*features; 
                [val idx] = max(D);            

            %if number of patches >> number of atoms in dictionary then you
            %can use the commented code for speed
            
%               uidx = unique(idx);
%               for u = 1: numel(uidx)
%                   fidx = find(idx==uidx(u));                
%                   patches(:,fidx) = conf.PPs{uidx(u)}*features(:,fidx);
%               end
                for l = 1:size(features,2)            
                    patches(:,l,band) = conf.PPs{idx(l)} * features(:,l,band);
                end
                    

%                   uidx = unique(idx);
%                   for u = 1: numel(uidx)
%                       %fidx = find(idx==u);
%                       fidx = find(idx==uidx(u));
%                       patches(:,b-1+fidx) = conf.PPs{uidx(u)}*features(:,b-1+fidx);
%                   end
                    % for l = 1:size(idx,2)
                    %     patches(:,b-1+l,band) = conf.PPs{idx(l)} * features(:,b-1+l,band);
                    % end
                
                end
            end
   
        % Add low frequencies to each reconstructed patch        
%         patches = patches + collect(conf, {midres{i}}, conf.scale, {});
        
        % Combine all patches into one image
        img_size = sz;
        grid = sampling_grid(img_size, ...
            conf.window, conf.overlap, conf.border, conf.upsample_factor);
         % grid = sampling_grid(img_size, ...
         %    conf.window, conf.overlap, conf.border, 1);
        result = overlap_add(patches, img_size, grid);
fprintf('\n');
end