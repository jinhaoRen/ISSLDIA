% Image construction from overlapping patches
function [result] = overlap_add(patches, img_size, grid)

result = zeros(img_size);
weight = zeros(img_size);
if length(img_size)==2
    img_size(3)=1;
end
for i = 1:size(grid, 3)
    patch = reshape(patches(:, i,:), size(grid, 1),size(grid, 2), 1 ,img_size(3));
    result(grid(:,:,i,:))      = result(grid(:,:,i,:)) + patch;
    weight(grid(:,:,i,:))      = weight(grid(:,:,i,:)) + 1;
end
I = logical(weight);
result(I) = result(I) ./ weight(I);

