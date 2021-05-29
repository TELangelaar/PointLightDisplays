function mainscript(do_plot)
clc;
close all;

if nargin<1, do_plot=false; end

%% Load files into workspace
if exist('gaitdata.mat','file') == 2
    load gaitdata.mat data invalid
else
    fprintf("something went wrong with importing gaitdata.mat.\nClosing...\n")
    return
end

%% Description
% Data: 53 (pp) x 5 (states) x 3 (speed) x 3 (trials)
% Original motion recordings polling rate: 100hz
% First, the following recordings are selected from the dataset:
% From the participants that have emotional walking (speed: 1):
%   Walking (speed: 1)
% - Normal      (states: 1)
% - Happy       (states: 3)
% - Sad         (states: 4)
% - Angry       (states: 5)
tic

valid_participants = invalid(:,3,1,1) == 0; %participants that completed the emotional task
states = [ 1, 3, 4, 5]; %neutral, happy, sad, angry
speeds  = [1]; %walking
trials = [2]; %second "trial" only

data = squeeze(data(valid_participants, states, speeds, trials, :, :, :)); %5 dimensional

%% Backangle calculation
% find the vector that points from the middle of the two outer hip markers
% to the middle of the two shoulder markers (Y & Z)
hipR_marker = 3;    %marker locations come from the Gait.dbbuild.get_conf function
hipL_marker = 6;

shoulderR_marker = 11;
shoulderL_marker = 14;

%step 1: find average (x,y,z) of 2 outer hip markers
hipR = squeeze(data(:,:,hipR_marker,:,:));
hipL = squeeze(data(:,:,hipL_marker,:,:));

hipMiddle_calculated = (hipR + hipL) / 2;

%step 2: do the same for the shoulders
shoulderR = squeeze(data(:,:,shoulderR_marker,:,:));
shoulderL = squeeze(data(:,:,shoulderL_marker,:,:));

shoulderMiddle_calculated = (shoulderR + shoulderL) / 2;

%step 3: calculate the backangle (using dotproduct)
% -> angle = cos-1 (a dot b)/(|a||b|)
backangle = NaN(37, 4, 600); % in degrees!
unitvec_z = [0 0 1];

for i = 1:37
    for j = 1:4
        for k = 1:600
            backvector = squeeze(shoulderMiddle_calculated(i, j, :, k)) - squeeze(hipMiddle_calculated(i, j, :, k));
            backangle(i, j, k) = acos(dot(backvector, unitvec_z) / norm(backvector)) * 180 / pi;
        end
    end
end

if do_plot
%For inspection purposes; plot a random participant and state in blue, with
%the calculated markers and resulting vector in red. Also display the back
%angle
    pp = randi(37);
    state = randi(4);

    plot_inspection(squeeze(data(pp, state, :, :, :)), ...
        squeeze(hipMiddle_calculated(pp, state, :, :)), ...
        squeeze(shoulderMiddle_calculated(pp, state, :, :)), ...
        squeeze(backangle(pp, state, :)));

end

%% Static Translation
% translation of the shoulder and outer hip markers to reduce the trunk
% angle


toc
end

function plot_inspection(data, hipMiddle, shoulderMiddle, backangle)
import matlib.array.flatmat
viewparams = [120 30];

xlims = [min(flatmat(data(:,1,:))), max(flatmat(data(:,1,:)))];
ylims = [min(flatmat(data(:,2,:))), max(flatmat(data(:,2,:)))];
zlims = [min(flatmat(data(:,3,:))), max(flatmat(data(:,3,:)))];

figure;
scatter3(data(:,1,1), data(:,2,1), data(:,3,1), 20, 'filled' , 'b');
hold on 
scatter3(hipMiddle(1,1), hipMiddle(2,1), hipMiddle(3,1), 'filled', 'r');
scatter3(shoulderMiddle(1,1), shoulderMiddle(2,1), shoulderMiddle(3,1), 'filled', 'r');

dim = [0.1 0.5 0 0];
annotation('textbox', dim, 'string', backangle(1));

axis equal tight
xlim(xlims)
ylim(ylims)
zlim(zlims)
view(viewparams(1), viewparams(2))

for i = 2:600
    hold off
    scatter3(data(:,1,i), data(:,2,i), data(:,3,i), 20, 'filled' , 'b');
    hold on
    plot3([hipMiddle(1,i) shoulderMiddle(1,i)], ...
        [hipMiddle(2,i) shoulderMiddle(2,i)], ...
        [hipMiddle(3,i) shoulderMiddle(3,i)], '-or')
%     scatter3(hipMiddle(1,i), hipMiddle(2,i), hipMiddle(3,i), 'filled', 'r');
%     scatter3(shoulderMiddle(1,i), shoulderMiddle(2,i), shoulderMiddle(3,i), 'filled', 'r');

    delete(findall(gcf,'type','annotation'))
    annotation('textbox', dim, 'string', backangle(i));
    
    view(viewparams(1), viewparams(2))
    xlim(xlims)
    ylim(ylims)
    zlim(zlims)
    axis equal tight
    pause(0.001)
end
    

end
