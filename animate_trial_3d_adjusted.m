function animate_trial_3d_adjusted(data, red, view_angles)
% Animate the point light display data of a full block of trials. The trial
% number can be selected with a popup list and the time frame can be 
% selected by an animated slider.
% INPUT:
%       data: 3D double array [markers, space, time]
%
    if nargin<3, view_angles=[90,0]; end
    if nargin<2, red=1; end
    import matlib.array.flatmat
    
    %Get parameters of input data
    data = squeeze(data(:,:,1:red:end));
    [~,~,tLen] = size(data);

    xlims = [min(flatmat(data(:,1,:))) , max(flatmat(data(:,1,:)))];
    ylims = [min(flatmat(data(:,2,:))) , max(flatmat(data(:,2,:)))];
    zlims = [min(flatmat(data(:,3,:))) , max(flatmat(data(:,3,:)))];
    t = 1;

    %Create figure
    figure('Position', [100, 100, 400, 895])
    scatter3(data(:,1,t), data(:,2,t), data(:,3,t), 20, 'filled');%,colors(1,:),'filled');

    %Set aspect ratio
    %axis tight;
    axis equal tight;
    %axis vis3d;

    %set limits
    set_limits


    %slider function callback. Defined as nested to access global t.
    function SliderCallback(sliderObj, ~)
        t = get(sliderObj, 'Value');
    end

    %just this
    function set_limits()
        xlim(xlims)
        ylim(ylims)
        zlim(zlims)
    end

    %add slider to control the time dimension of the animation
    slider = uicontrol(...
        'parent', gcf,...
        'style', 'slider',...
        'min', 1,...
        'max', tLen,...
        'Value',1,...
        'units', 'normalized',...
        'position', [0.20 0.05 0.75 0.05],...
        'callback', @SliderCallback);

    %animation loop, it increments t sequentially and returns to 1 in the
    %end
    view(view_angles(1), view_angles(2))
    tic
    for j = 1:1:600
        %Check time limits and increment time counter
        %if t == tLen
         %   t = 1;
        %else
            %t = t + 1;
        %end

        %Get viewpoint paramters
        [az, el] = view;

        %update slider value
        %set(slider, 'Value', t)

        %update data
        scatter3(data(:,1,j),data(:,2,j),data(:,3,j),20,'filled');

        %update view
        view(az, el);
        set_limits

        %stop drawing for a while
        pause(0.001);
        drawnow
    end
    toc
end




