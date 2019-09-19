classdef DataPanel < uix.Panel
    %DATAPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App
        text_h
        data_name_listener
    end
    
    methods
        function obj = DataPanel(varargin)
            set(obj, varargin{:});
            obj.init_panel();
        end
        
        function init_panel(obj)
            obj.App = getappdata(ancestor(obj, 'figure'), 'App');
            
            v = obj.Visible;
            obj.Visible = 'off';
            
            obj.Title = 'Data';

            params = {
                {{'String','prev series', 'Callback',{@obj.control_button_callback, -1, 's'}}, {'String','next series', 'Callback',{@obj.control_button_callback, 1, 's'}}},...
                {{'String','prev frame', 'Callback',{@obj.control_button_callback, -1, 'f'}}, {'String','next frame', 'Callback',{@obj.control_button_callback, 1, 'f'}}},...
                {{'String','random', 'Callback',{@obj.control_button_callback, [], 'r'}}, {'String','worst', 'Callback', {@obj.control_button_callback, [], 'w'}}, {'String','best', 'Callback', {@obj.control_button_callback, [], 'b'}}},...
                {{'String','auto', 'Callback', @obj.auto_button_callback},{'String','reset', 'Callback', @obj.reset_button_callback}, {'String','save', 'Callback', @obj.save_button_callback}},...
                };

            N = length(params);

            vb_h = uix.VBox('Parent', obj);
            obj.text_h = uicontrol(vb_h,'Style', 'Text', obj.App.font, ...
                    'HorizontalAlignment', 'Center');

            for ii = 1:N
                hbb_h = uix.HButtonBox('Parent', vb_h);
                line_param = params{ii};
                M = length(line_param);
                for jj = 1:M
                    param = line_param{jj};
                    uicontrol(hbb_h,'Style', 'pushbutton', obj.App.font, param{:});
                end 
                set(hbb_h, 'ButtonSize', [130 35], 'Spacing', 5 );
            end
            [~, h] = obj.App.fontsize_pixel;
            set(vb_h, 'Heights', [h, -ones(1, N)],'Spacing', 5);
            
            obj.data_name_listener = addlistener(obj.App, 'data_name', 'PostSet', @obj.onDataNameChanged);

            obj.Visible = v;
        end
        
        function control_button_callback(obj,o, e, d, t)
            
            f_id = obj.App.f_id;
            p_id = obj.App.p_id;

            if t == 'r'
                data_path = obj.App.data_path;
                p_list = obj.App.p_list;
                p_id = randi(length(p_list));
                s_name = p_list{p_id};
                f_id = randi(length(dir(fullfile(data_path, s_name)))-2);
            elseif t == 'b'
                [p_id, f_id] = obj.App.find_best_series();
            elseif t == 'w'
                [p_id, f_id] = obj.App.find_worst_case();
            elseif t == 'f'
                N = length(obj.App.f_list);
                f_id = mod(f_id + d - 1, N) + 1;
            else
                N = length(obj.App.p_list);
                p_id = mod(p_id + d - 1, N) + 1;
                f_id = 1;
            end
            
            obj.App.load_data(p_id, f_id);
              
        end
        
        function reset_button_callback(obj, o, e)
            obj.App.reset_data();
        end
        
        function save_button_callback(obj, o, e)
            obj.App.save_data();
        end
        
        function auto_button_callback(obj, o, e)
            obj.App.auto_label();
        end
        
        function onDataNameChanged(obj, src, event)
            data_name = split(event.AffectedObject.data_name, {'_', '.'});
            s_name = data_name{1};
            f_name = data_name{2};
            set(obj.text_h, 'String', sprintf('Series:%7s, Frame:%4s', s_name, f_name));
            
            p_id = event.AffectedObject.p_id;
            f_id = event.AffectedObject.f_id;
            if event.AffectedObject.record(p_id).n(f_id) > 0
                set(obj.text_h, 'foregroundcolor','red');
            else
                set(obj.text_h, 'foregroundcolor','black');
            end  
        end
        
    end
end

