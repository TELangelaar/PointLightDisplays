function mainscript(do_plot)
clc;
close all;

if nargin<1, do_plot=false; end

%% Load files into workspace
% the file 'gaitdata.mat' contains transformed motion data as per the
% method section in the master thesis.
%
% It contains the following structures:
% - data; 7D matrix containing the marker positions per participant, state
%         speed and trial. Described in detail below
%
% - Freqs; frequencies - unused, unsure what its purpose is.
%
% - invalid; a matrix which size corresponds to the first 4 dimensions of
%         'data'. It indicates which trials are invalid either due to
%         issues with the data, technical issues during the experiment, or
%         participants that didnt perform that particular trial
%
% - kintbl; table describing the raw source data corresponding to the
%         'data' matrix.
%         Columns: ParticipantNumber, FileName, ev1, ev2, ..., ev6
%         ev1, ev3, ev5 columns contain the start frame for respectively
%         the first, second and third trial. The even-numbered ev columns
%         contain the end frame. (The difference between a start and end
%         frame is always 600 frames)
%
% - L; matrix containing the length for each trial in 'data'. Either 600 or
%         NaN.
%
% - pptbl; table desciribing the participants:
%           - 'Sense': D = first gender experiment, then emotion experiment
%                      I = first emotion experiment, then gender experiment
%           - 'Genre': mispelling of 'gender'. 
%                      'H'=Hombre (male), 'M'=Mujer (female)
%           - 'WC', 'Wm', 'RC', 'Rm': respectively comfortable walking
%           speed, maximal walking speed, comfortable running speed,
%           maximal running speed, in m/s.
%
% - Wfourier & Wfourier_fixed; fourier transformations of the original
% motion data - unused

if exist('gaitdata.mat','file') == 2
    load gaitdata.mat data invalid %we only need the original data and the invalid matrix
else
    fprintf("something went wrong with importing gaitdata.mat.\nClosing...\n")
    return
end

%% Description
% Data: 53 (pp) x 5 (states) x 3 (speed) x 3 (trials) x 3 (dimension;
% (x,y,z) x 600 (time in 0.01s)
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

n_participants = size(data,1);
n_states = size(data,2);
n_markers = size(data,3);
n_dimensions = size(data,4);
n_time = size(data,5);

%% Backangle calculation
% find the vector that points from the middle of the two outer hip markers
% to the middle of the two shoulder markers (Y & Z)
hip_R_marker = 3;    %marker locations come from the Gait.dbbuild.get_conf function
hip_L_marker = 6;

shoulder_R_marker = 11;
shoulder_L_marker = 14;

%step 1: find average (x,y,z) of 2 outer hip markers
hip_R = squeeze(data(:,:,hip_R_marker,:,:));
hip_L = squeeze(data(:,:,hip_L_marker,:,:));

hip_middle_calculated = (hip_R + hip_L) / 2;

%step 2: do the same for the shoulders
shoulder_R = squeeze(data(:,:,shoulder_R_marker,:,:));
shoulder_L = squeeze(data(:,:,shoulder_L_marker,:,:));

shoulder_middle_calculated = (shoulder_R + shoulder_L) / 2;

%step 3: calculate the backangle (using dotproduct)
% -> angle = cos-1 (a dot b)/(|a||b|)
backangle = NaN(n_participants, n_states, n_time); % in degrees!
unitvector_z = [0 0 1];

for i = 1:n_participants
    for j = 1:n_states
        for k = 1:n_time
            backvector = squeeze(shoulder_middle_calculated(i, j, :, k)) - squeeze(hip_middle_calculated(i, j, :, k));
            backangle(i, j, k) = acos(dot(backvector, unitvector_z) / norm(backvector)) * 180 / pi;
        end
    end
end

if do_plot
%For inspection purposes; plot a random participant and state in blue, with
%the calculated markers and resulting vector in red. Also display the back
%angle
    pp = randi(n_participants);
    state = randi(n_states);

    plot_inspection(squeeze(data(pp, state, :, :, :)), ...
        squeeze(hip_middle_calculated(pp, state, :, :)), ...
        squeeze(shoulder_middle_calculated(pp, state, :, :)), ...
        squeeze(backangle(pp, state, :)));

end

save('prelim.mat', 'backangle', 'data');
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

t = 1;

figure;
scatter3(data(:,1,t), data(:,2,t), data(:,3,t), 20, 'filled' , 'b');
hold on 
scatter3(hipMiddle(1,1), hipMiddle(2,1), hipMiddle(3,1), 'filled', 'r');
scatter3(shoulderMiddle(1,1), shoulderMiddle(2,1), shoulderMiddle(3,1), 'filled', 'r');

dim = [0.1 0.5 0 0];
annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(1), char(176)));

axis equal tight
xlim(xlims)
ylim(ylims)
zlim(zlims)
view(viewparams(1), viewparams(2))

function SliderCallback(sliderObj, ~)
    t = get(sliderObj, 'value');
end

slider = uicontrol(...
    'parent', gcf,...
    'style', 'slider',...
    'min', 1,...
    'max', 600,...
    'Value',1,...
    'units', 'normalized',...
    'position', [0.20 0.05 0.75 0.05],...
    'callback', @SliderCallback);

while true
    if t == 600
        t = 1;
    else
        t = t + 1;
    end
    
    set(slider, 'Value', t);

    hold off
    scatter3(data(:,1,t), data(:,2,t), data(:,3,t), 20, 'filled' , 'b');
    hold on
    plot3([hipMiddle(1,t) shoulderMiddle(1,t)], ...
        [hipMiddle(2,t) shoulderMiddle(2,t)], ...
        [hipMiddle(3,t) shoulderMiddle(3,t)], '-or')
%     scatter3(hipMiddle(1,i), hipMiddle(2,i), hipMiddle(3,i), 'filled', 'r');
%     scatter3(shoulderMiddle(1,i), shoulderMiddle(2,i), shoulderMiddle(3,i), 'filled', 'r');

    delete(findall(gcf,'type','annotation'))
    annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(t), char(176)));
    
    view(viewparams(1), viewparams(2))
    xlim(xlims)
    ylim(ylims)
    zlim(zlims)
    axis equal tight
    pause(0.001)
end
    

end
