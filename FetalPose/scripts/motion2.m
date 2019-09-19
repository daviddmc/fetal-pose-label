label_path = 'D:\fetal\label\';
data_path = 'D:\fetal\data';


files = dir(fullfile(label_path, '*.mat'));
m_all = [];
v_all = [];
for ii = 1:length(files)
    load(fullfile(files(ii).folder, files(ii).name), 'joint_coord');
    bone = joint_coord(:, :, [12,6,13,7,10,3,11,4, 8]) - joint_coord(:, :, [6,14,7,15,3,1,4,2,9]);
    bone = squeeze(sqrt(sum(bone.^2, 2)));
    b = mean(std(bone, 1) ./ mean(bone, 1));
    m = joint_coord(2:end,:,:) - joint_coord(1:end-1, :, :);
    m = squeeze(sqrt(sum(m.^2, 2)));
    m_all = [m_all; mean(m, 2)];
    
    v = joint_coord(:, :, 8) + joint_coord(:, :, 9) - (joint_coord(:, :, 12) + joint_coord(:, :, 13));
    v = v ./ sqrt(sum(v.*v, 2));
    v_all = [v_all; v];
end

histogram(m_all*0.3);
xlabel('motion (cm)')

theta = acos(v_all(:,3));
phi = atan(v_all(:,2) ./ v_all(:,1));

scatter(theta/pi*180, phi/pi*180);
xlim([0,180]);
ylim([-90,90]);
xlabel('theta (degree)')
ylabel('phi (degree)')