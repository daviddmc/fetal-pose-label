classdef KeypointPanel < uix.Panel
    %KEYPOINTPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App
        textwidth
        probe_h
        keypoints_h
        probe_listener
        keypoint_listener
    end
    
    methods
        function obj = KeypointPanel(varargin)
            set(obj, varargin{:});
            obj.init_panel();
            
        end
        
        function init_panel(obj)
           
            obj.App = getappdata(ancestor(obj, 'figure'), 'App');
            obj.App.set_waitbar(0, 'initializing keypoint panel');
            obj.textwidth = 13+2+2+3*3;
            
            v = obj.Visible;
            obj.Visible = 'off';
            
            obj.Title = 'Keypoints';
            joint_name = obj.App.joint_name;
            N = length(joint_name);
            for ii = 1:N
                button_name{ii} = pad([joint_name{N+1-ii},':'], obj.textwidth);
            end
            button_name{N+1} = 'None';

            [w, h] = obj.App.fontsize_pixel;
            bg = uix2.VButtonGroup('Parent', obj, 'Spacing',10,... 
                'ButtonSize', [w*obj.textwidth, h]*1.2, 'ButtonStyle','radio',... 
                'HorizontalAlignment','center', 'VerticalAlignment','top'); 
            
            bg.Buttons = button_name;
            bg.SelectionChangeFcn = {@obj.onSelectionChanged};
            bg.Selection = N+1;
            obj.App.joint_active = 0;
    
            set(bg.Children, obj.App.font)
            
            obj.probe_h = bg.Children(1);
            obj.keypoints_h = bg.Children(2:end);
            obj.probe_listener = addlistener(obj.App, 'probe', 'PostSet', @obj.onProbeChanged);
            obj.keypoint_listener = addlistener(obj.App, 'joint', 'PostSet', @obj.onKeypointChanged);
            
            
            obj.Visible = v;
        end
        
        function onSelectionChanged(obj, src, event)
            obj.App.joint_active = 16 - event.NewValue;
        end
        
        function onProbeChanged(obj, src, event)
            probe = event.AffectedObject.probe;
            if isempty(probe)
                ss = 'None';
            else
                ss = sprintf('None%8d (%3d,%3d,%3d)', probe(4), probe(1), probe(2), probe(3));
            end
            set(obj.probe_h, 'String', ss);
        end
        
        function onKeypointChanged(obj, src, event)
            joints = event.AffectedObject.joint;
            j_id = event.AffectedObject.joint_changed;
            for ii = j_id
                joint = joints(:,ii);
                x = round(joint(1)); y = round(joint(2)); z=round(joint(3));
                ss = get(obj.keypoints_h(ii), 'String');
                ss = sprintf('%s(%3d,%3d,%3d)', ss(1:13), x, y, z);
                set(obj.keypoints_h(ii), 'String', ss);
            end
        end
        
    end
end

