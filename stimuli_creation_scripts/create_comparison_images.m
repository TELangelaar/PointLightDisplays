function create_comparison_images(condition, data_pre, data_post, backangle_pre, backangle_post, hip, shoulder)

pps = {1, 12, 23};
state = 1;

data_pre_copy = data_pre;
data_post_copy = data_post;
backangle_pre_copy = backangle_pre;
backangle_post_copy = backangle_post;
hip_copy = hip;
shoulder_copy = shoulder;

for i = 1:length(pps)
    for j = 1:2
        close all
        pp = pps{i};
        data_pre = squeeze(data_pre_copy(pp, state, :, :, :));
        data_post = squeeze(data_post_copy(pp, state, :, :, :));
        backangle_pre = squeeze(backangle_pre_copy(pp, state, :));
        backangle_post = squeeze(backangle_post_copy(pp, state, :));
        hip = squeeze(hip_copy(pp, state, :, :, :));
        shoulder = squeeze(shoulder_copy(pp, state, :, :, :));

        t = 10;
        mk_size = 60;
        dim = [0.3 0.98 0 0];

        data(:,:,:,1) = data_pre;
        data(:,:,:,2) = data_post;

        ba(:,1) = backangle_pre;
        ba(:,2) = backangle_post;

        import helpers.flatmat
        viewparams = [90 0];

        xlims = [min(flatmat(data(:,1,:,j))), max(flatmat(data(:,1,:,j)))];
        ylims = [min(flatmat(data(:,2,:,j))) - 200, max(flatmat(data(:,2,:,j))) + 200];
        zlims = [min(flatmat(data(:,3,:,j))) - 200, max(flatmat(data(:,3,:,j))) + 200];

        f1 = figure(1);
        f1.Position = [170 513 560 420];
        scatter3(data(:,1,t,j), data(:,2,t,j), data(:,3,t,j), mk_size, 'b', 'LineWidth', 1);
        hold on 
        plot3([hip(1,1,j) shoulder(1,1,j)], [hip(2,1,j) shoulder(2,1,j)], [hip(3,1,j) shoulder(3,1,j)], 'ro:', 'LineWidth', 1);
        % plot3(shoulder(1,1,1), shoulder(2,1,1), shoulder(3,1,1), 'filled', 'r');

        a1 = annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", ba(t,j), char(176)));
        a1.FontSize = 14;
        a1.FontName = "Arial";
        xlim(xlims)
        ylim(ylims)
        zlim(zlims)
        view(viewparams(1), viewparams(2))

        axis equal
        grid off
        hold off
        box on
        set(gca,'Ytick',[]) 
        set(gca,'Ztick',[]) %to just get rid of the numbers but leave the ticks.
        ax = gca;

        outerpos = ax.OuterPosition;
        ti = ax.TightInset; 
        left = outerpos(1) + ti(1);
        bottom = outerpos(2) + ti(2);
        ax_width = outerpos(3) - ti(1) - ti(3);
        ax_height = outerpos(4) - ti(2) - ti(4);
        ax.Position = [left bottom ax_width ax_height];

        if j == 1
            fig_title = strcat(condition,'_before_',num2str(pp),'.png');
        else
            fig_title = strcat(condition,'_after_',num2str(pp),'.png');
        end

        saveas(gcf, fig_title)
    end

    
%     f2 = figure(2);
%     f2.Position = [940 515 560 420];
%     scatter3(data(:,1,t,2),data(:,2,t,2), data(:,3,t,2), mk_size, 'b', 'LineWidth', 1);
%     hold on 
%     plot3([hip(1,1,2) shoulder(1,1,2)], [hip(2,1,2) shoulder(2,1,2)], [hip(3,1,2) shoulder(3,1,2)], 'ro-', 'LineWidth', 1);
%     % plot3(shoulder(1,t,2), shoulder(2,t,2), shoulder(3,t,2), 'filled', 'r');
% 
%     a2 = annotation('textbox', dim, 'string', sprintf("Backangle: %.2f%c", ba(t,2), char(176)));
%     a2.FontSize = 14;
%     a2.FontName = "Arial";
%     xlim(xlims)
%     ylim(ylims)
%     zlim(zlims)
%     view(viewparams(1), viewparams(2))
% 
%     axis equal
%     grid off
%     hold off
%     box on
%     set(gca,'Ytick',[]) 
%     set(gca,'Ztick',[]) %to just get rid of the numbers but leave the ticks.
%     ax = gca;
%     outerpos = ax.OuterPosition;
%     ti = ax.TightInset; 
%     left = outerpos(1) + ti(1);
%     bottom = outerpos(2) + ti(2);
%     ax_width = outerpos(3) - ti(1) - ti(3);
%     ax_height = outerpos(4) - ti(2) - ti(4);
%     ax.Position = [left bottom ax_width ax_height];
%     
%     saveas(gcf, strcat(condition,'_after_',num2str(pp),'.png'))
end
close all
end