function imgs = modcrop(imgs, modulo)

for i = 1:numel(imgs)
    sz = size(imgs{i});
    sz(1:2) = sz(1:2) - mod(sz(1:2), modulo);
    % for b = 1:sz(3)
        imgs{i} = imgs{i}(1:sz(1), 1:sz(2),:);
    % end
end
