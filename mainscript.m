function mainscript(do_plot, do_plot2)
% MAINSCRIPT This script performs the main computations and transformations
% for the Point-Light-Displays.
% MAINSCRIPT(true) plots a random participant for the unmodified data
% MAINSCRIPT(false, true) plots a random participants for the modified data
% MAINSCRIPT(true, true) plots a random participant for both the modified
% and unmodified data (the same participant will be used)

clc;
close all;

if nargin<2, do_plot2=false; end
if nargin<1, do_plot=false; end

pp = -1;
state = -1;

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
    error("You have no 'gaitdata.mat'.\nClosing...\n")
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

hip_R_marker = 3;    %marker locations come from the Gait.dbbuild.get_conf function
hip_L_marker = 6;

shoulder_R_marker = 11;
shoulder_L_marker = 14;

padding = "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"; %for printing purposes

%% Backangle calculation
% find the vector that points from the middle of the two outer hip markers
% to the middle of the two shoulder markers (Y & Z)
[backangle, backvector, hip_middle_calculated, shoulder_middle_calculated] = calculate_backangle_backvector(data);

if do_plot && ~do_plot2
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

%% Static Translation
% translation of the shoulder and outer hip markers to reduce the trunk
% angle

% Background: 
%   - Aminiaghdam, Soran; Blickhan, Reinhard; Muller, Roy; Rode, Christian (2017): Posture alteration as a measure to accommodate uneven ground in able-bodied gait. figshare. Dataset. https://doi.org/10.6084/m9.figshare.5692006 
%   - Titus, A. W., Hillier, S., Louw, Q. A., & Inglis-Jassiem, G. (2018). An analysis of trunk kinematics and gait parameters in people with stroke. African journal of disability, 7, 310. https://doi.org/10.4102/ajod.v7i0.310
% Average backangle seems to be around 4 - 6 degrees during normal walking

% step 1: calculate the average backangle per participant/state
mean_back_angle = mean(backangle,3);

mean_angle_per_state = mean(mean_back_angle,1);
minimal_angle_per_state = min(mean_back_angle,[],1);
maximal_angle_per_state = max(mean_back_angle,[],1);

states = {'Neutral','Happy','Sad','Angry'};
disp(padding);
txt1 = sprintf("Backangle (degrees):\n\t\t\tMin\t\tMean\tMax\n");
for i = 1:n_states
    if strcmp(states{i},'Sad') %extra whitespace for alignment purposes
        txt1 = txt1+sprintf("-%s: \t\t%.2f\t%.2f\t%.2f\n", states{i}, ...
           minimal_angle_per_state(i),...
           mean_angle_per_state(i),...
           maximal_angle_per_state(i));
    else
       txt1 = txt1+sprintf("-%s: \t%.2f\t%.2f\t%.2f\n", states{i}, ...
           minimal_angle_per_state(i),...
           mean_angle_per_state(i),...
           maximal_angle_per_state(i));
    end
end
disp(txt1); %average backangle is ~11deg for neutral & happy, ~13 for sad and angry

% exploratory step 2: decrease the backangle by 5 degrees and calculate y'
% requirements:
%   - Z (height) should stay the same; the trunk 'height' should be equal
%   compared to pre-transformation
%   - X (width) should stay the same; the width of the shoulders / hips
%   should be equal compared to pre-transformation
%   - Y ('length') should change; the hips should translate slightly
%   forward, the shoulders slightly backward. 
%   IMPORTANT NOTE: this will decrease the length of the vector pointing from
%   the hips to the shoulders (X/Z equal, Y decreases), but that is fine
%   for our current purposes.

% First, we try to shift the shoulders and hips an equal amount
% forward/backward and see what that looks like

%subtract 7 degrees from the back angle
backangle_post = backangle - 7;

%calculate new Y --> new_y = z / tan(90 - new_angle))
z = squeeze(backvector(:,:,3,:));
y = squeeze(backvector(:,:,2,:));
y_diff = y - (z ./ tan(deg2rad(90-backangle_post)));


% step 3: translate the shoulder and hip markers -y_diff/2 and +y_diff/2,
% respectively
half_y_diff = y_diff/2;

data_post = data;

data_post(:, :, hip_R_marker, 2, :) = squeeze(data(:, :, hip_R_marker, 2, :)) + half_y_diff;
data_post(:, :, hip_L_marker, 2, :) = squeeze(data(:, :, hip_L_marker, 2, :)) + half_y_diff;
            
data_post(:, :, shoulder_R_marker, 2, :) = squeeze(data(:, :, shoulder_R_marker, 2, :)) - half_y_diff;
data_post(:, :, shoulder_L_marker, 2, :) = squeeze(data(:, :, shoulder_L_marker, 2, :)) - half_y_diff;

% step 3.1: compute new backvector for verification purposes
[backangle_post, backvector_post, hip_middle_calculated_new, shoulder_middle_calculated_new] = calculate_backangle_backvector(data_post);

save('prelim.mat', 'backangle', 'backangle_post', ...
    'data', 'data_post', 'backvector', 'backvector_post',...
    'y_diff');

if ~do_plot && do_plot2
%For inspection purposes; plot a random participant and state in blue, with
%the calculated markers and resulting vector in red. Also display the back
%angle
    if pp == -1 && state == -1
        pp = randi(n_participants);
        state = randi(n_states);
    elseif xor(pp == -1, state == -1)
        error("Error while trying to plot:\nParticipant:\t%d\nState:\t\t\t%d",pp, state);
    end

    plot_inspection(squeeze(data(pp, state, :, :, :)), ...
        squeeze(hip_middle_calculated_new(pp, state, :, :)), ...
        squeeze(shoulder_middle_calculated_new(pp, state, :, :)), ...
        squeeze(backangle_post(pp, state, :)));

elseif do_plot && do_plot2
    pp = randi(n_participants);
    state = randi(n_states);
    
    a(:,:,:,:,:,1) = data;
    a(:,:,:,:,:,2) = data_post;
    
    hip(:,:,:,:,1) = hip_middle_calculated;
    hip(:,:,:,:,2) = hip_middle_calculated_new;
    
    shoulder(:,:,:,:,1) = shoulder_middle_calculated;
    shoulder(:,:,:,:,2) = shoulder_middle_calculated_new;
    
    ba(:,:,:,1) = backangle;
    ba(:,:,:,2) = backangle_post;
    
    plot_inspection_double(squeeze(a(pp, state, :,:,:,:)), ...
        squeeze(hip(pp, state, :, :, :)), ...
        squeeze(shoulder(pp, state, :, :, :)), ...
        squeeze(ba(pp, state, :, :)));
    
end
%% EOF
disp(padding);
toc
disp(padding);
end

function [backangle, backvector, hip_middle_calculated, shoulder_middle_calculated] = calculate_backangle_backvector(data)
% CALCULATE_BACKANGLE_BACKVECTOR Calculates the vector from the middle of
% the hip to the middle of the shoulders and its corresponding angle
% relative to the Z-axis.
% Does not modify input data.

n_participants = size(data,1);
n_states = size(data,2);

n_dimensions = size(data,4);
n_time = size(data,5);

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
backangle = NaN(n_participants, n_states, n_time); % will be in degrees! 
backvector = NaN(n_participants, n_states, n_dimensions, n_time);
unitvector_z = [0 0 1];

for i = 1:n_participants
    for j = 1:n_states
        for k = 1:n_time
            backvector(i, j, :, k) = squeeze(shoulder_middle_calculated(i, j, :, k)) - squeeze(hip_middle_calculated(i, j, :, k));
            backangle(i, j, k) = acos(dot(squeeze(backvector(i, j, :, k)), unitvector_z) / norm(squeeze(backvector(i, j, :, k)))) * 180 / pi;
        end
    end
end

end

function plot_inspection(data, hipMiddle, shoulderMiddle, backangle)
import helpers.flatmat
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

for j = 2:1:600
    hold off
    scatter3(data(:,1,j), data(:,2,j), data(:,3,j), 20, 'filled' , 'b');
    hold on
    plot3([hipMiddle(1,j) shoulderMiddle(1,j)], ...
        [hipMiddle(2,j) shoulderMiddle(2,j)], ...
        [hipMiddle(3,j) shoulderMiddle(3,j)], '-or')

    delete(findall(gcf,'type','annotation'))
    annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(j), char(176)));
    
    view(viewparams(1), viewparams(2))
    xlim(xlims)
    ylim(ylims)
    zlim(zlims)
    axis equal tight
    pause(0.001)
end
    

end

function plot_inspection_double(data, hipMiddle, shoulderMiddle, backangle)
% PLOT_INSPECTION_DOUBLE This function plots a participant before and after
% the transformation. IMPORTANT: the parameters should have an extra
% dimension; pre- & post- transformation
import helpers.flatmat
viewparams = [120 30];

xlims = [min(flatmat(data(:,1,:,1))), max(flatmat(data(:,1,:,1)))];
ylims = [min(flatmat(data(:,2,:,1))), max(flatmat(data(:,2,:,1)))];
zlims = [min(flatmat(data(:,3,:,1))), max(flatmat(data(:,3,:,1)))];

t = 1;

f1 = figure(1);
f1.Position = [170 513 560 420];
scatter3(data(:,1,t,1), data(:,2,t,1), data(:,3,t,1), 20, 'filled' , 'b');
hold on 
scatter3(hipMiddle(1,1,1), hipMiddle(2,1,1), hipMiddle(3,1,1), 'filled', 'r');
scatter3(shoulderMiddle(1,1,1), shoulderMiddle(2,1,1), shoulderMiddle(3,1,1), 'filled', 'r');

dim = [0.1 0.5 0 0];
annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(1,1), char(176)));
xlim(xlims)
ylim(ylims)
zlim(zlims)
view(viewparams(1), viewparams(2))

axis equal tight
hold off

f2 = figure(2);
f2.Position = [940 515 560 420];
scatter3(data(:,1,t,2),data(:,2,t,2), data(:,3,t,2), 20, 'filled' , 'b');
hold on 
scatter3(hipMiddle(1,1,2), hipMiddle(2,1,2), hipMiddle(3,1,2), 'filled', 'r');
scatter3(shoulderMiddle(1,1,2), shoulderMiddle(2,1,2), shoulderMiddle(3,1,2), 'filled', 'r');

dim = [0.1 0.5 0 0];
annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(1,2), char(176)));
xlim(xlims)
ylim(ylims)
zlim(zlims)
view(viewparams(1), viewparams(2))

axis equal tight
hold off

for j = 2:1:600
    for uu = 1:2
        figure(uu)
        scatter3(data(:,1,j,uu), data(:,2,j,uu), data(:,3,j,uu), 20, 'filled' , 'b');
        hold on
        plot3([hipMiddle(1,j,uu) shoulderMiddle(1,j,uu)], ...
            [hipMiddle(2,j,uu) shoulderMiddle(2,j,uu)], ...
            [hipMiddle(3,j,uu) shoulderMiddle(3,j,uu)], '-or')

        delete(findall(gcf,'type','annotation'))
        annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", backangle(j,uu), char(176)));

        view(viewparams(1), viewparams(2))
        xlim(xlims)
        ylim(ylims)
        zlim(zlims)
        axis equal tight
        hold off
    end
    pause(0.001)
end
end