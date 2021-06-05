function create_videostimuli_from_rawdata(filename)
%CREATE_VIDEOS_FROM_STIMULI Generates avi videos from pld stimuli to be
%used in perceptual experiments
%   Detailed explanation goes here

if nargin <1, filename= "prelim"; end

full_filename = strcat(filename, ".mat");
if exists(full_filename, "file") == 2
    load(full_filename, "data_post");
else
    error("Unable to locate '%s'. \nClosing...\n", full_filename);
end

%%
states = {"Neutral", "Happy", "Sad", "Angry"};

import helpers.write_video
for i = 1:size(data_post, 1)
    for j = 1:size(data_post, 2)
        filename = "pp" + i + "_" + states{j};
        write_video(squeeze(data_post(i, j, :, :, :)), filename);
    end
end

end

