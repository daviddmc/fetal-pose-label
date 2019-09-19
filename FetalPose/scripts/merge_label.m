label_path = 'D:\fetal\label\';
record_path = 'D:\fetal\record\';
new_label_path = 'C:\Users\Ðì¿¡Ÿö\Desktop\predict_b8s64bn_rot_scale0.1_adamwr1_flip_unet_all';

load(fullfile(record_path, 'record.mat'), 'record');

files = dir(fullfile(label_path, '*.mat'));

for ii = 1:length(files)
    rec = record(ii);
    label_old = load(fullfile(label_path, files(ii).name));
    label_new = load(fullfile(new_label_path, files(ii).name));
    assert(strcmp(rec.name, files(ii).name(1:end-4)));
    n = rec.n;
    for jj = 1:length(n)
        if n(jj) > 0
            % do nothing
        else
            label_old.joint_coord(jj, :, :) = label_new.joint_coord(jj, :, :);
        end
    end
    save(fullfile(label_path, files(ii).name), '-struct', 'label_old');
end