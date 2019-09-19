function [old2new, new2old] = match_order(dir_old, dir_new, p1)

files_old = dir(fullfile(dir_old, '*nii*'));
files_new = dir(fullfile(dir_new, '*nii*'));

if length(files_old) ~= length(files_new)
    error('number of frames mismatch')
    disp(dir_old)
    old2new = [];
    new2old = [];
    return
end

v_new = niftiread(fullfile(dir_new, files_new(1).name));
v_old = niftiread(fullfile(dir_old, files_old(1).name));
n = size(v_old, 3);

if ndims(v_new) ~= ndims(v_old) || any(size(v_new) ~= size(v_old))
    error('size mismatch')
    disp(dir_old)
    old2new = [];
    new2old = [];
    return
end

key(length(files_old)) = 0;

for ii = 1:length(files_old)
    v_old = niftiread(fullfile(dir_old, files_old(ii).name));
    v_old = double(v_old(:, :, floor(n/2)+p1));
    key(ii) = mean(v_old(:)) - std(v_old(:));
end

uni_key = unique(key);
if length(key) ~= length(uni_key)
    error('key should be unique');
end

M = containers.Map(key, 1:length(key));

old2new(length(files_new)) = 0;
new2old(length(files_new)) = 0;

for ii = 1:length(files_new)
    v_new = niftiread(fullfile(dir_new, files_new(ii).name));
    v_new = double(v_new(:, :, floor(n/2)+p1));
    k = mean(v_new(:)) - std(v_new(:));
    if ~isKey(M, k)
        error('Key error')
    end
    old_idx = M(k);
    if old2new(old_idx)
        error('repeat')
    end
    old2new(old_idx) = ii;
    new2old(ii) = old_idx;
end

