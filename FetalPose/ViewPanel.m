classdef ViewPanel < matlab.mixin.SetGet
    %VIEWPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        panel
        
        App
        
        ax_hs
        
        slider_hs
        
        img_hs
        
        xhair_hs
        
        slider_listeners
        
        dims_listener
        
        clim_listener
        
        xhair_vis_listener
        joint_vis_listener
        plane_vis_listener
        
        cor_slice_listener
        sag_slice_listener
        axi_slice_listener
        
        R
        cos_theta
        sin_theta
        joint_hs
        
        joint_listener
        
        edge_hs
        plane_hs
        
        ax_pos = zeros(4,4)
     
        trans_mat
        
        rot_on=false
    end
    
    methods
        function obj = ViewPanel(varargin)
            obj.panel = uipanel(varargin{:});
            obj.init_panel();
        end
        
        % init
        
        function init_panel(obj)
            obj.App = getappdata(ancestor(obj.panel, 'figure'), 'App');
            
            v = obj.panel.Visible;
            obj.panel.Visible = 'off';
            
            obj.panel.Title = 'Views';
            
            obj.trans_mat = [2, 3, 1, 1;
                             1, 3, 1, 2;
                             1, 2, 2, 2;];
            obj.App.set_waitbar(0, 'initializing axes');
            init_axes(obj);
            init_slider(obj)
            init_img(obj)
            init_xhair(obj)
            obj.App.set_waitbar(0.5, 'initializing pose');
            init_joint(obj)
            init_pose(obj)     
            init_plane(obj)
            
            obj.dims_listener = addlistener(obj.App, 'dims', 'PostSet', @obj.onDimsChanged);
            obj.axi_slice_listener = addlistener(obj.App, 'axi_slice', 'PostSet', @(o, e) obj.onSliceChanged(o, e, 3));
            obj.sag_slice_listener = addlistener(obj.App, 'sag_slice', 'PostSet', @(o, e) obj.onSliceChanged(o, e, 1));
            obj.cor_slice_listener = addlistener(obj.App, 'cor_slice', 'PostSet', @(o, e) obj.onSliceChanged(o, e, 2));
            obj.joint_listener = addlistener(obj.App, 'joint', 'PostSet', @obj.onJointChanged);
            obj.clim_listener = addlistener(obj.App, 'clim', 'PostSet', @obj.onCLimChanged);
            
            obj.xhair_vis_listener = addlistener(obj.App, 'xhair_vis', 'PostSet', @obj.onXhairVisChanged);
            obj.joint_vis_listener = addlistener(obj.App, 'joint_vis', 'PostSet', @obj.onJointVisChanged);
            obj.plane_vis_listener = addlistener(obj.App, 'plane_vis', 'PostSet', @obj.onPlaneVisChanged);
            
            obj.panel.SizeChangedFcn = @obj.onSizeChanged;
            
            set(obj.App.fig, 'WindowScrollWheelFcn', @obj.scroll_wheel_callback);
            set(obj.App.fig, 'WindowButtonMotionFcn', @obj.mouse_move_callback);

            obj.panel.Visible = v;
        end
        
        function init_axes(obj)
            for ii = 1:4
                hs(ii) = axes(obj.panel, 'Units', 'pixel');
            end
            obj.ax_hs = hs;
        end
        
        function init_slider(obj)
            slider_param = {'Parent',obj.panel, 'Style','slider',...
                'Units','pixel', obj.App.font,'HorizontalAlignment','center',...
                'BackgroundColor',[0.5 0.5 0.5],'ForegroundColor',[0 0 0],...
                'BusyAction','queue'};
            for ii = 1:3
                hs(ii) = uicontrol(slider_param{:});
                els(ii) = addlistener(hs(ii), 'Value', 'PostSet', @(o, e) obj.ax_slider_callback(o, e, ii));
            end
            obj.slider_hs = hs;
            obj.slider_listeners = els;
        end
        
        function init_img(obj)
            for ii = 1:3
                ax_handle = obj.ax_hs(ii); 
                hs(ii) = imagesc(ax_handle, zeros(10));
                colormap(ax_handle, gray(256));
                set(ax_handle,'YDir','normal','ClimMode','manual',...
                    'xtick',[],'ytick',[],...
                    'buttondown',@(o,e) obj.click_image_callback(o, e, ii));
                if ii == 1
                    set(ax_handle,'Xdir', 'reverse');
                end
                set(hs(ii), 'hittest', 'off', 'HandleVisibility', 'off');
            end
            obj.img_hs = hs;
        end
        
        function init_xhair(obj)
            for ii = 1:3
                ax_handle = obj.ax_hs(ii);
                hs(ii, 1) = line(ax_handle, 'xdata', [0  200], 'ydata', [0, 0], ...
                    'color', [1 0 0], 'hittest', 'off', 'HandleVisibility', 'off');
                hs(ii, 2) = line(ax_handle, 'xdata', [0, 0], 'ydata', [0, 200], ...
                    'color', [1 0 0], 'hittest', 'off','HandleVisibility', 'off');
            end
            obj.xhair_hs = hs;
        end
        
        function init_joint(obj)
            joint_color = obj.App.joint_color;
            obj.R = obj.App.joint_R;
            theta = linspace(0, 2*pi, 6*obj.R+1);
            theta(end) = 0;
            obj.cos_theta = cos(theta);
            obj.sin_theta = sin(theta);
            
            for ii = 1:3
                ax_handle = obj.ax_hs(ii);
                for jj = 1:length(joint_color)
                    hs(ii, jj) = line(ax_handle, 'xdata', 0*obj.cos_theta, 'ydata', 0 * obj.sin_theta, ...
                            'color', joint_color(jj, :), 'hittest', 'off', 'HandleVisibility', 'off', 'Visible', 'off');
                end
            end
            obj.joint_hs = hs;
        end
        
        function init_pose(obj)  
            [~, edges, colors] = obj.App.pose_graph;
            ax_handle = obj.ax_hs(4);
            for ii = 1:size(edges, 1)
                hs(ii) =  line(ax_handle, 'xdata', [0,1],...
                    'ydata', [2,3], ...
                    'zdata', [4,5], ...
                    'color', colors(ii,:), 'hittest', 'off',...
                    'MarkerSize',6, 'MarkerEdgeColor',[1, .6, .6],...
                    'LineWidth',3, 'Marker', 'o', 'HandleVisibility', 'off');
            end
            obj.edge_hs = hs;
            grid(ax_handle, 'on');
            axis(ax_handle, 'equal');
            set(ax_handle, 'xticklabel', [], 'yticklabel', [], 'zticklabel', []);
        end
        
        function init_plane(obj)
            ax_handle = obj.ax_hs(4);
            X = [0, 200;0, 200];
            Y = [200, 200;0,0];
            Z = [50,50;50,50];
            C = zeros([size(Z) 3]); C(:,:,1) = 1;
            hs(1) = surface(ax_handle, Z,X,Y,C, 'EdgeAlpha', 0, 'FaceAlpha', 0.3);
            C = zeros([size(Z) 3]); C(:,:,2) = 1;
            hs(2) = surface(ax_handle,Y,Z,X,C, 'EdgeAlpha', 0, 'FaceAlpha', 0.3);
            C = zeros([size(Z) 3]); C(:,:,3) = 1;
            hs(3) = surface(ax_handle,X,Y,Z,C, 'EdgeAlpha', 0, 'FaceAlpha', 0.3);
            obj.plane_hs = hs;
        end

        % callback
        
        function ax_slider_callback(obj, o, e, v)
            slider_handle = e.AffectedObject;
            n_s = get(slider_handle, 'Value');
            if v == 2
                n_s = obj.App.dims(2) - n_s + 1;
            end
            obj.App.set_slice(n_s, v);
        end
        
        function onSizeChanged(obj, o, e)
            
            P = obj.panel;
            if ~isempty( findprop( P, 'Units' ) ) && ~strcmpi(P.Units, 'pixels')
                u = P.Units;
                set(P, 'Units','pixels');
                fig_pos = get(P,'position');
                set(P, 'Units', u);
            else
                fig_pos = get(P,'position');
            end
            
            vol_size = obj.App.vol_size;
            area = [0, 0, 1, 1];
            area = area .* [fig_pos(3),fig_pos(4),fig_pos(3),fig_pos(4)];
           
            gap_x = 15;
            gap_y = 15;
            a = (area(3) - gap_x * 1.3) / (vol_size(1) + vol_size(2));	
            b = (area(4) - gap_y * 3) / (vol_size(2) + vol_size(3));
            c = min([a b]);		
            top_w = vol_size(1) * c;
            side_w = vol_size(2) * c;
            top_h = vol_size(2) * c;
            side_h = vol_size(3) * c;
            side_x = area(1) + top_w + gap_x * 1.3;
            side_y = area(2) + top_h + gap_y * 3;

            top_w = max(top_w, 0);
            top_h = max(top_h, 0);
            side_w = max(side_w, 0);
            side_h = max(side_h, 0);

            top_pos = [area(1) area(2)+gap_y top_w top_h];
            front_pos = [area(1) side_y top_w side_h];
            side_pos = [side_x side_y side_w side_h];
            pose_pos = [side_x area(2)+gap_y side_w top_h];
            
            set(obj.ax_hs(3), 'position', top_pos);
            set(obj.ax_hs(2),'position', front_pos);
            set(obj.ax_hs(1), 'position', side_pos);
            set(obj.ax_hs(4), 'position', pose_pos);
            
            x = side_pos(1);
            y = top_pos(2) + top_pos(4);
            w = side_pos(3);
            h = (front_pos(2) - y) / 2;
            y = y + h;

            set(obj.slider_hs(1), 'position', [x y w h]);
            
            x = top_pos(1);
            y = top_pos(2) + top_pos(4);
            w = top_pos(3);
            h = (front_pos(2) - y) / 2;
            y = y + h;
            
            set(obj.slider_hs(2), 'position', [x y w h]);
            
            x = top_pos(1);
            y = top_pos(2) - h;
            w = top_pos(3);
            h = top_pos(2) - y;

            set(obj.slider_hs(3), 'position', [x y w h]);
            
            for ii = 1:4
                obj.ax_pos(ii, :) = getpixelposition(obj.ax_hs(ii), true);
            end
        
        end
        
        function onDimsChanged(obj, src, event)
            dims = event.AffectedObject.dims;
            if isempty(event.AffectedObject.axi_slice)
                slices = dims/2;
            else
                slices(3) = min(dims(3), event.AffectedObject.axi_slice);
                slices(1) = min(dims(1), event.AffectedObject.sag_slice);
                slices(2) = min(dims(2), event.AffectedObject.cor_slice);
            end
            for ii = 1:3
                set(obj.slider_hs(ii), 'Min',1,'Max',dims(ii),'SliderStep',[1, 1.00001]/dims(ii))
                obj.setSlicerValue(ii, slices(ii))
            end
            set(obj.ax_hs(4), 'xlim', [0, dims(1)], 'ylim', [0,dims(2)], 'zlim', [0,dims(3)]);
            obj.onSizeChanged([], []); % manually update size
        end
        
        function click_image_callback(obj, o, e, v)       
            [XYZ, x, y] = obj.view2XYZ(v);
            obj.setSlicerValue(x, XYZ(x));
            obj.setSlicerValue(y, XYZ(y));
            j_id = obj.App.joint_active;
            if j_id
                obj.App.joint = {XYZ, j_id};
            end
            % update probe
            obj.App.probe = XYZ;
        end
        
        function onCLimChanged(obj, src, event)
            set(obj.ax_hs, 'clim', event.AffectedObject.clim);
        end
        
        function onSliceChanged(obj, src, event, v)
            % update image
            n_s = event.AffectedObject.get_slice(v);
            img_handle = obj.img_hs(v);
            ax_handle = obj.ax_hs(v);
            img = obj.getImgSlice(v, n_s);
            set(img_handle,'CData', img);
            XData = img_handle.XData;
            YData = img_handle.YData;
            ax_handle.XLim = [XData(1)-0.5, XData(2)+0.5];
            ax_handle.YLim = [YData(1)-0.5, YData(2)+0.5];
            
            % update xhair
            [x, y] = obj.view2xy(v);
            [a, b] = obj.dir2xy(v);
            xyz = 'xyz';
            set(obj.xhair_hs(x, 3-a), [xyz(a) 'data'], [n_s, n_s]);
            set(obj.xhair_hs(y, 3-b), [xyz(b) 'data'], [n_s, n_s]);
            
            % update joints
            obj.updateJoints(v, n_s);
            
            % update planes
            set(obj.plane_hs(v), [xyz(v) 'data'], ones(2,2) * n_s);
        end
        
        function onJointChanged(obj, src, event)
            j_id = obj.App.joint_changed;
            
            % update joints
            obj.updateJoints(1, obj.App.sag_slice, j_id);
            obj.updateJoints(2, obj.App.cor_slice, j_id);
            obj.updateJoints(3, obj.App.axi_slice, j_id);
            
            % update pose
            hs = obj.edge_hs;
            [joint, edge, ~] = obj.App.pose_graph;
            for ii = 1:size(edge, 1)
                joint1 = joint(:, edge(ii,1));
                joint2 = joint(:, edge(ii,2));
                set(hs(ii), 'xdata', [joint1(1), joint2(1)],...
                    'ydata', [joint1(2), joint2(2)], ...
                    'zdata', [joint1(3), joint2(3)]);
            end
        end
        
        function updateJoints(obj, v, n_s, j_id)
            joint = obj.App.joint;
            if ~obj.App.joint_vis
                hs = obj.joint_hs(v, :);
                for ii = 1:size(joint, 2)
                    set(hs(ii), 'Visible', 'off');
                end
                return
            end
            
            if isempty(joint)
                return
            end
            
            if nargin < 4
                j_id = 1:size(joint, 2);
            end
            
            [x, y] = obj.view2xy(v);
            d = joint(v, j_id) - n_s;
            X = joint(x, j_id);
            Y = joint(y, j_id);
            r2 = obj.R.^2 - d.^2;
            hs = obj.joint_hs(v, :);
            for ii = 1:length(j_id)
                if r2(ii) > 0
                    r = sqrt(abs(r2(ii)));
                    set(hs(j_id(ii)), 'xdata', X(ii) + r * obj.cos_theta, ...
                        'ydata', Y(ii) + r * obj.sin_theta, 'Visible', 'on');
                else
                    set(hs(j_id(ii)), 'Visible', 'off');
                end
            end
        end
        
        function scroll_wheel_callback(obj, fig, event)
            v = obj.where_curr(fig);
            if v && v ~= 4
                slider_h = obj.slider_hs(v);
                val = slider_h.Value;
                val_min = slider_h.Min;
                val_max = slider_h.Max;
                step = event.VerticalScrollCount;
                val = min(val_max, max(val_min, val + sign(step).* round(abs(step).^1.4)));
                set(slider_h,'Value', val);
                XYZ = obj.view2XYZ(v);
                obj.App.probe = XYZ;
            end
        end
        
        function mouse_move_callback(obj, fig, event)
            v = obj.where_curr(fig);
            if v
                if v == 4
                    if ~obj.rot_on
                        set(fig, 'WindowScrollWheelFcn', '');
                        rotate3d(obj.ax_hs(4), 'on');
                        obj.rot_on = true;
                    end
                    obj.App.probe = [];
                else
                    if obj.rot_on
                        rotate3d(obj.ax_hs(4), 'off');
                        obj.rot_on = false;
                        set(fig, 'WindowScrollWheelFcn', @obj.scroll_wheel_callback);
                    end
                    XYZ = obj.view2XYZ(v);
                    obj.App.probe = XYZ;
                end
            else
                obj.App.probe = [];
            end
        end
        
        function onXhairVisChanged(obj, src, event)
            vis = event.AffectedObject.xhair_vis;
            set(obj.xhair_hs, 'Visible', vis);
        end
        
        function onJointVisChanged(obj, src, event)
            obj.updateJoints(1, obj.App.sag_slice);
            obj.updateJoints(2, obj.App.cor_slice);
            obj.updateJoints(3, obj.App.axi_slice);
        end
        
        function onPlaneVisChanged(obj, src, event)
            vis = event.AffectedObject.plane_vis;
            hs = obj.plane_hs;
            for ii = 1:3
                hs(ii).Visible = vis(ii);
            end
        end
        
        % helper
        
        function img = getImgSlice(obj, v, ns)
            ns = round(ns);
            volume = obj.App.volume;
            if v == 3
                img = volume(:,:,ns)';
            elseif v == 2
                img = squeeze(volume(:,ns,:))';
            else % s
                img = squeeze(volume(ns,:,:))';
            end
        end
        
        function v = where_curr(obj, fig)
            curr = get(fig, 'currentpoint');
            
            for ii = 1:4
                pos = obj.ax_pos(ii,:);
                if  curr(1) >= pos(1) && curr(1) <= pos(1)+pos(3) && ...
                    curr(2) >= pos(2) && curr(2) <= pos(2)+pos(4)
                    v = ii;
                    return
                end
            end
            
            v = 0;
        end
        
        function [x,y] = view2xy(obj, v) % get x and y axis of a view
            x = obj.trans_mat(v, 1);
            y = obj.trans_mat(v, 2);
        end
            
        function [x,y] = dir2xy(obj, dir) % what axis 
            x = obj.trans_mat(dir, 3);
            y = obj.trans_mat(dir, 4);
        end
        
        function setSlicerValue(obj, v, s)
            if v == 2
                val = obj.App.dims(2) + 1 - s;
            else
                val = s;
            end
            old_val = obj.slider_hs(v).Value;
            if old_val == val % abort set
                obj.App.set_slice(s, v);
            else
                obj.slider_hs(v).Value = val;
            end
        end
            
        function [XYZ, x, y] = view2XYZ(obj, v) % find position of probe
            ax_handle = obj.ax_hs(v);
            curr = get(ax_handle, 'current');
            dims = obj.App.dims;    
            [x, y] = obj.view2xy(v);
            XYZ(v) = obj.App.get_slice(v);
            XYZ(x) = max(1, min(dims(x), curr(1, 1)));
            XYZ(y) = max(1, min(dims(y), curr(1, 2)));
        end
    end
end
            

