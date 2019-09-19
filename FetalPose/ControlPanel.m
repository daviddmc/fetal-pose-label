classdef ControlPanel < uix.Panel
    %CONTROLPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App
    end
    
    methods
        function obj = ControlPanel(varargin)
            set(obj, varargin{:});
            obj.init_panel();
        end
        
        function init_panel(obj)
            
            obj.App = getappdata(ancestor(obj, 'figure'), 'App');
            
            v = obj.Visible;
            obj.Visible = 'off';
            
            obj.Title = 'Control';
            
            vb_h = uix.VBox('Parent', obj);
            obj.App.set_waitbar(0, 'initializing window/level panel');
            h = WindowLevelPanel('Parent', vb_h, 'Padding', 5, obj.App.font);
            obj.App.set_waitbar(0.33, 'initializing annotation panel');
            h = AnnotationPanel('Parent', vb_h, 'Padding', 5, obj.App.font);
            obj.App.set_waitbar(0.66, 'initializing data panel');
            h = DataPanel('Parent', vb_h, 'Padding', 5, obj.App.font);
            set(vb_h, 'Heights', [-2, -3, -5],'Spacing', 5)
           
            obj.Visible = v;
        end
    end
end

