addpath('./FetalPose');

label_path = 'D:\fetal\label\';%'C:\Users\junsh\Desktop\predict_7_adjusted';
data_path = 'D:\fetal\data\';
record_path = 'D:\fetal\record\';

fig_param = {'position', [100, 100, 800, 400],...
    'NumberTitle', 'off', 'Name', 'Fetal Pose Labelling'};

PoseLabel(label_path, data_path, record_path, fig_param{:});