# PointLightDisplays
Code for PLD experiments

Place the source data in the root folder. 
Call mainscript(), which can take 2 optional arguments (see script summary for usage), generates a new 'prelim.mat' file which contains backangles in the sagittal plane together with the original data and the vector pointing from the middle point between the two outer hip markers to the point right between the two shoulder markers. 

The write_video.m function in the helpers module takes motion data as input and writes it to a video format (avi), to be used as stimuli.

