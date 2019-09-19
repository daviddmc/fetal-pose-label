xls = 'D:\fetal\list.xlsx';
[~, ~, xls] = xlsread(xls);
data_path = 'D:\fetal\data';
label_path = 'D:\fetal\label';

joint70 = load('D:\fetal\70joints');
joint70 = reshape(joint70.joint', [], 3, 15);

load('D:\fetal\record\record.mat', 'record');
for ii = 1:70
   

    sname = split(xls{ii}, '_');
    load(fullfile(label_path,sname{1}), 'joint_coord');
    joint_coord(1, :, :) = joint70(ii,:,:);
    save(fullfile(label_path,sname{1}), 'joint_coord');
    
    record(ii).n(1) = 1;
end
save('D:\fetal\record\record.mat', 'record');
