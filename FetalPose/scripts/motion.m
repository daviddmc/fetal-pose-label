label_path = 'D:\fetal\label\';
data_path = 'D:\fetal\data';


files = dir(fullfile(label_path, '*.mat'));

for ii = 1:length(files)
    load(fullfile(files(ii).folder, files(ii).name), 'joint_coord');
    bone = joint_coord(:, :, [12,6,13,7,10,3,11,4, 8]) - joint_coord(:, :, [6,14,7,15,3,1,4,2,9]);
    bone = squeeze(sqrt(sum(bone.^2, 2)));
    b = mean(std(bone, 1) ./ mean(bone, 1));
    m = joint_coord(2:end,:,:) - joint_coord(1:end-1, :, :);
    m = squeeze(sqrt(sum(m.^2, 2)));
    m = mean(m(:)) / mean(bone(:));
    
    B(ii) = b;
    M(ii) = m;
end

scatter(B, M);
xlabel('b')
ylabel('m')

R = mean(B)/mean(M) .* M + B;

% 1:train, 2:val, 3:test
c = [1, 1, 1, 1, 1, 2, 3, 1, 2, 3, 1];

[~, I] = sort(R, 'descend');

I(I) = 1:length(files);

I = mod(I-1, length(c)) + 1;
I = c(I);

train_set = {files(I == 1).name};
val_set = {files(I == 2).name};
test_set = {files(I == 3).name};

disp(join(cellfun(@(x) x(1:end-4), train_set, 'UniformOutput', false), ''','''));
disp(join(cellfun(@(x) x(1:end-4), val_set, 'UniformOutput', false), ''','''));
disp(join(cellfun(@(x) x(1:end-4), test_set, 'UniformOutput', false), ''','''));

n = 0;
for ii = 1:length(train_set)
    n = n + length(dir(fullfile(data_path, train_set{ii}(1:end-4), '*.nii*')));
end
disp(n)
