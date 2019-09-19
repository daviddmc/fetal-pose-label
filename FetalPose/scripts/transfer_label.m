old_path = 'D:\fetal\old_data';
new_path = 'D:\fetal\data';
label_path = 'D:\fetal\label';
old_files = dir(old_path);

old_files = old_files(3:end);

for ii = 1:length(old_files)
    dir_old = fullfile(old_path, old_files(ii).name);
    dir_new = fullfile(new_path, old_files(ii).name);
    if ii == 2
        [old2new, new2old] = match_order(dir_old, dir_new, 1);
    else
        [old2new, new2old] = match_order(dir_old, dir_new, 0);
    end
    
    label_new_pred = load(fullfile(label_path, old_files(ii).name));
    label_new_pred = label_new_pred.joint_coord;
    
    label_old = load(fullfile(old_path, old_files(ii).name, old_files(ii).name));
    label_old = reshape(label_old.joint_coord, [], 3, 15);
    if ii == 7
        label_old(:, 3, :) = label_old(:, 3, :) - 20;
    end
    %label_new = zeros(size(label_new_pred));
    rec = zeros(size(label_new_pred,1),1);
    if ii == 4
        label_new_pred(old2new(81:(80+size(label_old, 1))),:,:) = label_old;
        rec(old2new(81:(80+size(label_old, 1)))) = 1;
        %squeeze(label_new(old2new(81),:,:) - label_new_pred(old2new(81),:,:)) 
    else
        label_new_pred(old2new(1:size(label_old, 1)),:,:) = label_old;
        rec(old2new(1:size(label_old, 1))) = 1;
        %squeeze(label_new(old2new(1),:,:) - label_new_pred(old2new(1),:,:)) 
    end
    s.joint_coord = label_new_pred;
    save(old_files(ii).name, '-struct', 's');
    
    load('D:\fetal\record\record.mat', 'record');
    idx = find(strcmp(old_files(ii).name, {record.name}));
    assert(length(idx)==1);
    record(idx).n = rec;
    save('D:\fetal\record\record.mat', 'record');
end

