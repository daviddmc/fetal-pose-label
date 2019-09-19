classdef WindowLevelPanel < uix.Panel
    %WINDOWLEVELPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App
        text_h
        rangeslider_j
        vlim_listener
    end
    
    methods
        function obj = WindowLevelPanel(varargin)
            set(obj, varargin{:});
            obj.init_panel();
        end
        
        function init_panel(obj)
            obj.App = getappdata(ancestor(obj, 'figure'), 'App');
            
            v = obj.Visible;
            obj.Visible = 'off';
            
            obj.Title = 'Window/Level';

            vb_h = uix.VBox('Parent', obj);

            obj.text_h = uicontrol(vb_h, 'Style', 'Text', obj.App.font, 'HorizontalAlignment','Center');
            
            jRS = com.jidesoft.swing.RangeSlider;
            [jRangeSlider, hRangeSlider] = javacomponent(jRS, [], vb_h);
            set(jRangeSlider,'StateChangedCallback', @obj.onRangeSliderChanged);
            obj.rangeslider_j = jRangeSlider;
            
            [~, h] = obj.App.fontsize_pixel;
            set(vb_h, 'Heights', [h, -1],'Spacing', 5)
            
            obj.vlim_listener = addlistener(obj.App, 'vlim', 'PostSet', @obj.onVLimChanged);
           
            obj.Visible = v;
        end
        
        function onRangeSliderChanged(obj, src, event)
            cmin = obj.rangeslider_j.LowValue;
            cmax = obj.rangeslider_j.HighValue;

            set(obj.text_h, 'String', sprintf('cmin:%4d  cmax:%4d', cmin, cmax));
            
            obj.App.clim = [cmin, cmax];
        end
        
        function onVLimChanged(obj, src, event)
            vlim = event.AffectedObject.vlim;
            clim = event.AffectedObject.clim;
            if isempty(clim)
                clim = vlim;
            else
                clim = [min(vlim(2), max(clim(1), vlim(1))), min(clim(2), vlim(2))];
            end
            set(obj.rangeslider_j,'Maximum',vlim(2),'Minimum',vlim(1),...
                'LowValue',clim(1),'HighValue',clim(2));
        end
        
        
    end
end

