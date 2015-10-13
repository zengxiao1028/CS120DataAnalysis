% This function plots data which has been separated across days.
% It only works with the data format which is generated by separate_days()
% function.
% Only accepts float and categorical data types.
% data: data structure
% options: ploting options (marker, color, etc.)

function plot_crossdays(data)

if isfloat(vertcat(data.value{:})),
    
    value_max = max(vertcat(data.value{:}));
    value_min = min(vertcat(data.value{:}));
    
    hold on;
    set(gca, 'position', [.1 .1 .7 .8]);
    for i=1:length(data.day),
        if ~isempty(data.value{i}),
            if value_max~=value_min,
                plot(data.timeofday{i}, data.day(i) - data.value{i} / (value_max-value_min) / 3, ['.', 'k']);
            else
                plot(data.timeofday{i}, data.day(i)*ones(size(data.timeofday{i})), ['.', 'k']);
            end
        end
        text(86400, data.day(i), sprintf('ST=%.1f MG=%.1f', data.samplingduration(i), data.maxgap(i)));
    end
    
elseif iscategorical(vertcat(data.value{:})),
    
    colors = containers.Map({'INVEHICLE','ONFOOT','STILL','TILTING','ONBICYCLE','UNKNOWN','PHONE','SMS', ...
        'INCOMING', 'OUTGOING', 'MISSED'}, ...
        {'r', 'b', 'k', 'm', 'g', 'y', 'b', 'g', 'b', 'g', 'r'});
        
    cats = categories(vertcat(data.value{:}));
    
    hold on;
    set(gca, 'position', [.1 .1 .7 .8]);

%     for i=1:length(cats),
%         plot(data.timeofday{1}(1), data.day(1), ['.', colors(cats{i})]);
%     end
%     legend(cats, 'location', 'northwestoutside');
    
    for i=1:length(data.day),
        if ~isempty(data.value{i}),
            for j=1:length(cats),
                if ~isempty(data.timeofday{i}(data.value{i}==cats(j))),
                    plot(ones(2,1)*data.timeofday{i}(data.value{i}==cats(j))', ...
                        [(data.day(i)*ones(length(data.timeofday{i}(data.value{i}==cats(j))),1))';...
                        (data.day(i)*ones(length(data.timeofday{i}(data.value{i}==cats(j))),1))'-.5], ...
                        colors(cats{j}));
                end
            end
        end
        text(86400, data.day(i), sprintf('ST=%.1f MG=%.1f', data.samplingduration(i), data.maxgap(i)));
    end
    
else
    error('Data value format unknown.');
end

set(gca, 'ytick', data.day(1):data.day(end), 'yticklabel', datestr((data.day(1):data.day(end)) + datenum(1970,1,1), 6));
ylim([data.day(1)-1 data.day(end)+1]);
set(gca, 'ygrid', 'on');

set(gca, 'xtick', 0:3600:23*3600, 'xticklabel', num2str((0:23)'));
xlim([0 86400]);

xlabel('Time of the day');
ylabel('Days');

set(gca, 'ydir', 'reverse');

end