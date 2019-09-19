classdef AnnotationPanel < uix.Panel
    %ANNOTATIONPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App
        
        checkbox_hs
    end
    
    methods
        function obj = AnnotationPanel(varargin)
            set(obj, varargin{:});
            obj.init_panel();
        end
        
        function init_panel(obj)
            obj.App = getappdata(ancestor(obj, 'figure'), 'App');
            
            v = obj.Visible;
            obj.Visible = 'off';
            
            obj.Title = 'Annotation';

            g_h = uix.Grid('Parent', obj, 'Spacing', 5);
            name = {'sag plane', 'cor plane', 'axi plane', 'crosshair', 'keypoints'};
            callback = {{@obj.plane_checkbox_callback, 1},...
                {@obj.plane_checkbox_callback, 2}, {@obj.plane_checkbox_callback, 3},...
                @obj.xhair_checkbox_callback, @obj.joint_checkbox_callback};
            for ii = 1:length(name)
                cb(ii) = uicontrol(g_h, 'String', name{ii}, ...
                    'Style', 'Checkbox', 'Value', 1, obj.App.font,...
                    'HorizontalAlignment', 'Center',...
                    'Callback', callback{ii});
            end
            uix.Empty( 'Parent', g_h );
            set(g_h, 'Widths', [-1 -1], 'Heights', [-1 -1 -1]);
            obj.checkbox_hs = cb;
            obj.Visible = v;
        end
        
        function plane_checkbox_callback(obj, o, e, v)
            vis = obj.App.plane_vis;
            if isempty(vis)
                vis = [1,1,1];
            end
            vis(v) = o.Value;
            obj.App.plane_vis = vis;
        end
        
        function xhair_checkbox_callback(obj, o, e)
            obj.App.xhair_vis = o.Value;
        end
        
        function joint_checkbox_callback(obj, o, e)
            obj.App.joint_vis = o.Value;
        end
    end
end

