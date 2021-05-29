function out = flatmat(mat)
%Flattens the input array, from any kind of shape, into [1, numel] shape
    mat = permute(mat,fliplr(1:ndims(mat)));
    out = flipud(mat(:)');
end