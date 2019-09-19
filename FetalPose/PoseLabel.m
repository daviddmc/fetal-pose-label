classdef PoseLabel < matlab.mixin.SetGet
    %POSELABEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        fig
        wb
        wb_min=0
        wb_max=0
        
        label_path
        data_path
        record_path
        
        p_list
        f_list
        p_id = []
        f_id = []
        s_name
        
        font
        
        joints
        edge
        joint_changed
        joint_color
        joint_name
        edge_color
        joint_R
        joint_active
        
        volume
        vol_size = [1, 1, 1]
        
        saved=true
        record
        score_p;
        score_f;
    end
    
    properties (SetObservable)
        data_name = ''
        probe = [0,0,0,0]
        joint = []
        dims = []
        axi_slice = []
        sag_slice = []
        cor_slice = []
        vlim = []
        clim = []
        
        xhair_vis
        joint_vis
        plane_vis
    end
    
    methods
        function obj = PoseLabel(label_path, data_path, record_path, varargin)
            obj.wb = waitbar(0, 'please wait');
            
            obj.fig = figure('Visible', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
            
            setappdata(obj.fig, 'App', obj);
            set(obj.fig, varargin{:});
            obj.label_path = label_path;
            obj.data_path = data_path;
            obj.record_path = record_path;
            obj.init_param();
            obj.init_layout();       
            obj.add_waitbar(0.10);
            obj.init_record();
            obj.add_waitbar(0.15);
            obj.init_data();
            
            close(obj.wb);
            set(obj.fig, 'CloseRequestFcn', @obj.onCloseRequest);
            obj.fig.Visible = 'on';
              
        end
        
        function init_param(obj)
            obj.font = struct('FontUnits', 'point', 'FontSize', 12, 'FontName', 'FixedWidth');
            
            % joint
            obj.joint_name = {'ankle_l', 'ankle_r', 'knee_l', 'knee_r', 'bladder', 'elbow_l', ...
                    'elbow_r', 'eye_l', 'eye_r', 'hip_l', 'hip_r', 'shoulder_l', 'shoulder_r',...
                    'wrist_l', 'wrist_r'};
            colors = [1, 0, 0;0, 0, 1;0, 1, 0;1, 0, 1];
            obj.edge_color = colors([1,2,1,2,3,3,3,3,3,1,2,1,2,4,4,4], :);
            obj.joint_color = colors([1,2,1,2,3,1,2,4,4,1,2,1,2,1,2], :);
            obj.define_edge();
            obj.joint_R = 2;
        end
        
        function init_layout(obj)
            hb_h = uix.HBox('Parent', obj.fig, 'Units', 'Normalized', ...
                'Position', [0, 0, 1, 1], 'Padding', 10, 'Spacing', 10);
            obj.add_waitbar(0.25);
            kp = KeypointPanel('Parent', hb_h, 'Padding', 5, obj.font);
            obj.add_waitbar(0.25);
            cp = ControlPanel('Parent', hb_h, 'Padding', 5, obj.font);
            obj.add_waitbar(0.25);
            vp = ViewPanel('Parent', hb_h, obj.font);
            
            set(hb_h, 'Widths', [-5,-5,-10])
        end
        
        function init_record(obj)
            obj.set_waitbar(0, 'initializing record');
            p_list = dir(obj.data_path);
            p_list = {p_list(3:end).name};
            obj.p_list = p_list;
            if ~exist(fullfile(obj.record_path, 'record.mat'), 'file')
                [record(1:length(p_list)).n] = deal([]);
                [record.name] = deal(p_list{:});
                for ii = 1:length(p_list)
                    f_list = dir(fullfile(obj.data_path, p_list{ii}));
                    record(ii).n = zeros(length(f_list) - 2, 1); % remove . and ..
                end
                save(fullfile(obj.record_path, 'record.mat'), 'record');
            else
                load(fullfile(obj.record_path, 'record.mat'), 'record');
            end
            
            if length(p_list) > length(record)
                names = {record.name};
                new_p_list = p_list(~ismember(p_list, names));
                for ii = 1:length(new_p_list)
                    f_list = dir(fullfile(obj.data_path, new_p_list{ii}));
                    record(end+1) = struct('n', zeros(length(f_list) - 2, 1), 'name', new_p_list{ii});
                    if ~exist(fullfile(obj.label_path, [new_p_list{ii} '.mat']), 'file')
                        joint_coord = zeros(length(f_list) - 2, 3, 15);
                        save(fullfile(obj.label_path, new_p_list{ii}), 'joint_coord');
                    end
                end
                [~, idx] = sort({record.name});
                record = record(idx);
            elseif length(p_list) < length(record)
                names = {record.name};
                mask = ismember(names, p_list);
                remove_record = record(~mask);
                for ii = 1:length(remove_record)
                    if exist(fullfile(obj.label_path, [remove_record(ii).name '.mat']), 'file')
                        delete(fullfile(obj.label_path, [remove_record(ii).name '.mat']));
                    end
                end
                record = record(mask);
            end
            
            obj.record = record;
            obj.compute_score();
        end
        
        function compute_score(obj)
            p_list = obj.p_list;
            record = obj.record;
            score_p = zeros(1, length(p_list));
            score_f = cell(1, length(p_list));
            for ii = 1:length(p_list)
                load(fullfile(obj.label_path, p_list{ii}), 'joint_coord');
                bone = joint_coord(:, :, [12,6,13,7,10,3,11,4, 8]) - joint_coord(:, :, [6,14,7,15,3,1,4,2,9]);
                bone = squeeze(sqrt(sum(bone.^2, 2)));
                %bone_diff = bone - [bone(2,:); bone(1:end-1,:)];
                m = mean(bone, 1);
                bone_diff = (bone - m) ./ m;
                score_f{ii} = mean(abs(bone_diff), 2); %./ (5.^obj.record(ii).n);
                score_p(ii) = max(score_f{ii});
            end
            obj.score_p = score_p;
            obj.score_f = score_f;
        end
        
        function init_data(obj)
            obj.set_waitbar(0, 'initializing keypoint panel');
            obj.load_data(1, 1);
            obj.set_waitbar(1, 'finished');
        end
        
        function save_data(obj)
            obj.joints(obj.f_id, :, :) = obj.joint([2, 1, 3], :);
            s.joint_coord = obj.joints;
            save(fullfile(obj.label_path, obj.s_name), '-struct', 's');
            obj.record(obj.p_id).n(obj.f_id) = obj.record(obj.p_id).n(obj.f_id) + 1;
            obj.data_name = obj.data_name;
            obj.saved = true;
            disp('data saved');
        end
        
        function reset_data(obj)
            obj.joint = squeeze(obj.joints(obj.f_id, [2, 1, 3], :));
            obj.saved = true;
        end
        
        function auto_label(obj)
            rec_n = obj.record(obj.p_id).n;
            rec_n(obj.f_id) = 0;
            labelled = find(rec_n);
            if isempty(labelled)
                return
            else
                [~, m_idx] = min(abs(labelled - obj.f_id));
                new_f_id = labelled(m_idx);
                obj.joint = squeeze(obj.joints(new_f_id, [2, 1, 3], :));
            end
        end
        
        function choice = check_saved(obj)
            choice = [];
            if ~obj.saved
                
                choice = obj.unsaved_dialog();
                if choice(1) == 'S'
                    obj.save_data();
                elseif choice(2) == 'D'
                    % do nothing
                else % cancel
                    % return
                end
            end
        end
        
        function selection = unsaved_dialog(obj)
            font = obj.font;
            [w, h] = obj.fontsize_pixel;
            s = 'You have unsaved data. Would you like to save it?';
            text_width = 30;
            n_line = ceil(length(s)/30);

            d = dialog('Position',[300, 300, w*text_width, h*(n_line+4)],...
                'Name','unsaved label','Visible', 'off');
            vb_h = uix.VBox('Parent', d);
            txt = uicontrol('Parent',vb_h, 'Style','text', 'String',s, font,...
                'horizontalalignment', 'left');
            hbb_h = uix.HButtonBox('Parent', vb_h);
            btn = uicontrol('Parent', hbb_h, 'String', 'Save', 'Callback', @button_callback, font);
            btn = uicontrol('Parent', hbb_h, 'String', 'Discard','Callback', @button_callback, font);
            btn = uicontrol('Parent', hbb_h, 'String', 'Cancel','Callback', @button_callback, font);
            set(hbb_h, 'ButtonSize', [w*9 h*2], 'Spacing', 5, 'Padding', 10);
            set(vb_h, 'Heights', [h*n_line, -1],'Spacing', 5, 'Padding', 10);
            movegui(d,'center');
            d.Visible = 1;
            selection = 'Cancel';
            uiwait(d);

            function button_callback(src, event)
               selection = src.String;
               close(d);
            end
        end
        
        function [p_id, f_id] = find_best_series(obj)
            [~, sorted_idx] = sort(obj.score_p);
            for p_id = sorted_idx
                if ~all(obj.record(p_id).n)
                    f_id = find(obj.record(p_id).n == 0, 1);
                    return
                end
            end
            p_id = obj.p_id;
            f_id = obj.f_id;
        end
        
        function [p_id, f_id] = find_worst_case(obj)
            [~, p_id] = max(obj.score_p);
            [~, f_id] = max(obj.score_f{p_id});
            obj.score_f{p_id}(f_id) = 0;
            obj.score_p(p_id) = max(obj.score_f{p_id});
            
            if isempty(p_id) || isempty(f_id)
                p_id = 1;
                f_id = 1;
            end
            
        end
        
        function load_data(obj, p_id, f_id)
            
            choice = obj.check_saved();
            if ~isempty(choice) && choice(1) == 'C'
                return
            end
            
            old_p_id = obj.p_id;
            obj.f_id = f_id;
            
            if isempty(old_p_id) || old_p_id ~= p_id % new series
                obj.p_id = p_id;
                obj.s_name = obj.p_list{obj.p_id};
                f_list = dir(fullfile(obj.data_path, obj.s_name));
                f_list = {f_list(3:end).name};
                obj.f_list = f_list;
                joints = load(fullfile(obj.label_path, obj.s_name));
                obj.joints = joints.joint_coord;
            end
            
            obj.data_name = obj.f_list{obj.f_id};
            info = niftiinfo(fullfile(obj.data_path, obj.s_name, obj.f_list{obj.f_id}));
            obj.vol_size = info.ImageSize .* info.PixelDimensions;
            obj.volume = niftiread(info);
            obj.dims = info.ImageSize;
            obj.vlim = [min(obj.volume(:)), max(obj.volume(:))];
            obj.joint = squeeze(obj.joints(obj.f_id, [2, 1, 3], :));
            obj.saved = true;
        end
        
        function onCloseRequest(obj, o, e)
            choice = obj.check_saved();
            if ~isempty(choice) && choice(1) == 'C'
                return
            else
                record = obj.record;
                save(fullfile(obj.record_path, 'record.mat'), 'record');
                nf_finished = 0;
                nf_progress = 0;
                nf_todo = 0;
                n_progress = 0;
                n_finished = 0;
                for ii = 1:length(record)
                    n_nz = nnz(record(ii).n);
                    n_d = length(dir(fullfile(obj.data_path, record(ii).name, '*.nii*')));
                    if n_nz < n_d
                        n_progress = n_progress + 1;
                        nf_progress = nf_progress + n_nz;
                        nf_todo = nf_todo + n_d;
                    else
                        n_finished = n_finished + 1;
                        nf_finished = nf_finished + n_nz;
                    end
                end
                fprintf('in progress: %d / %d (%d)\n', nf_progress, nf_todo, n_progress);
                fprintf('finished: %d (%d)\n', nf_finished, n_finished);
                delete(obj.fig);
                delete(obj);
            end
        end
        
        function set.probe(obj, value)
            obj.probe = value;
        end
        
        function value = get.probe(obj)
            if isempty(obj.probe)
                value = [];
                return
            end
            probe = round(obj.probe);
            value = [probe(1), probe(2), probe(3), ...
                obj.volume(probe(1), probe(2), probe(3))];
        end
        
        function set.joint( obj, value )
            obj.saved = false;
            if iscell(value)
                obj.joint_changed = value{2};
                obj.joint(:, value{2}) = value{1};
            else
                obj.joint_changed = 1:size(value,2);
                obj.joint = value;
            end
        end
        
        function value = get.joint( obj )
            value = obj.joint;
        end
        
        function [joint, edge, color] = pose_graph(obj)
            shoulder_l = 12;
            shoulder_r = 13;
            neck = 16;
            joint = obj.joint;
            if ~isempty(joint)
                joint(:, neck) = (joint(:, shoulder_l) + joint(:, shoulder_r)) / 2;
            end
            edge = obj.edge;
            color = obj.edge_color;
        end
        
        function ns = get_slice(obj, view)
            if view == 1
                ns = obj.sag_slice;
            elseif view == 2
                ns = obj.cor_slice;
            else
                ns = obj.axi_slice;
            end
        end
        
        function set_slice(obj, ns, view)
            if view == 1
                obj.sag_slice = ns;
            elseif view == 2
                obj.cor_slice = ns;
            else
                obj.axi_slice = ns;
            end
        end
        
        function [w,h] = fontsize_pixel(obj)
            
            ht = getappdata(obj.fig, 'text_handle');
            N = 13+2+2+3*3;

            if isempty(ht)
                ax = axes(obj.fig, 'Visible', 'off', 'HandleVisibility', 'off');
                ht = text(ax, 0,0, pad('test', N, 'o'),'Visible', 'off', ...
                    'HandleVisibility', 'off', 'Unit', 'Pixel', obj.font);
                setappdata(obj.fig, 'test_handle', ht);
            end

            ext = get(ht, 'Extent');
            w = ext(3)/N;
            h = ext(4);
        end
        
        function set_waitbar(obj, x, msg)
            waitbar(obj.wb_min + (obj.wb_max - obj.wb_min)*x, obj.wb, msg)
        end
        
        function add_waitbar(obj, x)
            obj.wb_min = obj.wb_max;
            obj.wb_max = obj.wb_max + x;
        end
        
        function define_edge(obj)
            
            ankle_l = 1;
            ankle_r = 2;
            knee_l = 3;
            knee_r = 4;
            bladder = 5;
            elbow_l = 6;
            elbow_r = 7;
            eye_l = 8;
            eye_r = 9;
            hip_l = 10;
            hip_r = 11;
            shoulder_l = 12;
            shoulder_r = 13;
            wrist_l = 14;
            wrist_r = 15;
            neck = 16;

            obj.edge = [ankle_l, knee_l;
            ankle_r, knee_r;
            hip_l, knee_l;
            hip_r, knee_r;
            hip_r, bladder;
            hip_l, bladder;
            neck, bladder;
            neck, shoulder_l;
            neck, shoulder_r;
            elbow_l, shoulder_l;
            elbow_r, shoulder_r;
            elbow_l, wrist_l;
            elbow_r, wrist_r;
            neck, eye_l;
            neck, eye_r;
            eye_r, eye_l];
        end
    end
end

