clear;
close all;

save_results = true;
remove_duplicates = true;

load('settings');
addpath('features');
addpath('functions');
clear date_start date_end timestamp_start

weather_dir = 'C:\Users\Sohrob\Dropbox\Data\CS120Weather\';
% weather_dir = '~/Dropbox/Data/CS120Weather/';

probes = {'act', 'app', 'aud', 'bat', 'cal', 'coe', 'fus', 'lgt', 'scr', 'wif', 'wtr', 'emc', 'eml', 'emm', 'ems'};
win_shift_size = 7;

% start time will be determined by the start time of mood data
cnt = 1;
for i = 1:length(subjects),
    filename = [data_dir, subjects{i}, '/', 'emm.csv'];
    if ~exist(filename, 'file'),
        disp(['No mood data for ', subjects{i}]);
        continue;
    end
    tab = readtable(filename, 'delimiter', '\t', 'readvariablenames', false);
    day_start(cnt) = floor(tab.Var1(1)/86400);
    day_end(cnt) = floor(tab.Var1(end)/86400);
    subjects_new{cnt} = subjects{i};
    cnt=cnt+1;
end

if length(subjects_new)~=length(subjects),
    fprintf('%d subject(s) removed because they did not have mood data\n', length(subjects)-length(subjects_new));
    subjects = subjects_new;
    clear subjects_new;
end

% reading data and extracting features
fprintf('reading data...\n');
feature = cell(length(subjects),1);
feature_label = cell(length(subjects),1);

parfor i = 1:length(subjects),
    
    fprintf('%d/%d\n',i,length(subjects));

    % loading data
    data = [];
    for j = 1:length(probes),
        if strcmp(probes{j},'wtr'),
            filename = [weather_dir, subjects{i}, '/',probes{j},'.csv'];
        else
            filename = [data_dir, subjects{i}, '/',probes{j},'.csv'];
        end
        if ~exist(filename, 'file'),
            disp(['No ',probes{j},' data for ', subjects{i}]);
            data.(probes{j}) = [];
        else
            tab = readtable(filename, 'delimiter', '\t', 'readvariablenames', false);
            if isempty(tab),
                data.(probes{j}) = [];
            else
                for k=1:size(tab,2),
                    data.(probes{j}){k} = tab.(sprintf('Var%d',k));
                end
                data.(probes{j}){1} = data.(probes{j}){1} + time_zone*3600;
                
                if remove_duplicates,
                    ind = find(diff(data.(probes{j}){1})==0)+1;
                    for k=1:length(data.(probes{j})),
                        data.(probes{j}){k}(ind) = [];
                    end
                end
                
            end
        end
    end
    
    % bi-weekly windows
    day_range = day_start(i):win_shift_size:day_end(i);
    %fprintf('extracting features...\n');
    for d=day_range,
        
        % clipping data
        datac = [];
        for j = 1:length(probes),
            if isempty(data.(probes{j})),
                datac.(probes{j}) = [];
            else
                datac.(probes{j}) = clip_data(data.(probes{j}), d*86400, (d+14)*86400);
            end
        end
        
        % extracting features
        %TODO
        [ft, ft_lab] = extract_features_location(datac.fus);
        feature_win = ft;
        feature_win_lab = ft_lab;
        
        [ft, ft_lab] = extract_features_usage(datac.scr, 30, Inf);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];
        
        [ft, ft_lab] = extract_features_weather(datac.wtr);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];

        [ft, ft_lab] = extract_features_activity(datac.act);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];
        
        [ft, ft_lab] = extract_features_communication(datac.coe);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];
        
        [ft, ft_lab] = extract_features_audio(datac.aud);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];

        [ft, ft_lab] = extract_features_light(datac.lgt);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];

        [ft, ft_lab] = extract_features_affect(datac.emm);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];
        
        [ft, ft_lab] = extract_features_sleep(datac.ems);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];

        [ft, ft_lab] = extract_features_locationreport(datac.eml);
        feature_win = [feature_win, ft];
        feature_win_lab = [feature_win_lab, ft_lab];

        % big feature vector
        feature{i} = [feature{i}; feature_win];
        feature_label{i} = feature_win_lab;
        
    end
    
end

if save_results,
    feature_label = feature_label{1};
    save('features_biweekly.mat', 'feature', 'feature_label', 'subjects');
end