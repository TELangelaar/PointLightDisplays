function pipeline()

% %make data without changing C7 and headmarkers
% [data_pre, data_post, backangle_pre, backangle_post, hip, shoulder] = mainscript(false);
% create_comparison_images('WithoutChange',data_pre, data_post, backangle_pre, backangle_post, hip, shoulder);

%% Final Analysis
% make data with changing C7 and headmarkers
[data_pre, data_post, backangle_pre, backangle_post, hip, shoulder] = mainscript(true);
% create_comparison_images('WithChange',data_pre, data_post, backangle_pre, backangle_post, hip, shoulder);
create_videostimuli_from_rawdata();


end