function v = write_video(data, ppno, state)

padding = "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"; %for printing purposes

resolution = [1280 720];
marker_size = 50;

xlims = [-700, 800];
ylims = [-300, 1900];
zlims = [-100, 1900];

scatter3(data(:,1,1), data(:,2,1), data(:,3,1), marker_size, 'filled','w')
set(gca,'Color','k')
axis equal tight;
xlim(xlims)
ylim(ylims)
zlim(zlims)
grid off
%set(gca,'nextplot','replacechildren'); 
set(gca,'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[],'zticklabel',[],'ztick',[])
view(90, 0)

set(gcf,'visible','off');
set(gcf,'Units','pixels');
set(gcf,'OuterPosition',[0 0 resolution(1) resolution(2)]);
set(gcf,'PaperPositionMode','manual');
set(gcf,'PaperUnits', 'inches');
set(gcf,'PaperPosition',[0 0 resolution(1) resolution(2)]/420);

set(gca,'Position',[0 0 1 1])

pp_string = strcat('.\output_videos_FINAL\');
videofile_name = strcat(pp_string, state, 'pp', num2str(ppno));

try
    fprintf("Writing video... pp: %d, state: %s\n", ppno, state);
    
    if exist(strcat(pp_string, videofile_name), 'file') == 0
        v = VideoWriter(strcat(pp_string, state, 'pp', num2str(ppno)), 'MPEG-4');
        v.FrameRate = 100;
        v.Quality = 95;
        open(v)

        for i = 1:600
            [az, el] = view;
            scatter3(data(:,1,i), data(:,2,i), data(:,3,i), marker_size, 'filled','w')
            set(gca,'Color','k','xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[],'zticklabel',[],'ztick',[])
            view(az, el);
            xlim(xlims)
            ylim(ylims)
            zlim(zlims)
            grid off 
            frame = getframe(gcf);
            writeVideo(v,frame);
        end
        close(v)
    end
catch ME
    disp(padding)
    fprintf("!!!!!!!! Could not write video. pp: %d, state, %s\n", ppno, state);
    disp(ME)
    disp(padding)
end