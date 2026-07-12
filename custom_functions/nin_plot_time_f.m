function [h] = nin_plot_time_f(x, varargin)

%% This function plot results
%
% - inputs:
% x: data structure
%
% - optional:
% eegsys: eegsystem used for data recording (default: 'BrainVision')
% cxrange/cyrange/czrange: x/y/z range (default: [])
% sp: number of subplots (default: [10 11])
% fonts: figure font size (default: 10)
% fposition: figure position (default: full screen)
%
% - example:
% [h] = nin_topoplot(R, R.stats.anova);

% -- read input parameters
nin_import_params(varargin);

%% -- set default values

if ~exist('eegsys', 'var')
    eegsys = 'BrainVision';
end

% -- font size of figure
if ~exist('fonts', 'var')
    fonts = 10;
end

% -- figure position
if ~exist('fposition', 'var')
    fposition = get(0, 'ScreenSize');
end

% -- range of x axes
if ~exist('cxrange', 'var')
    cxrange = [];
else
    xrange1 = cxrange(1);
    xrange2 = cxrange(2);
end

% -- range of y axes
if ~exist('cyrange', 'var')
    cyrange = [];
else
    yrange1 = cyrange(1);
    yrange2 = cyrange(2);
end

% -- range of y axes
if ~exist('czrange', 'var')
    czrange = [];
else
    zrange1 = czrange(1);
    zrange2 = czrange(2);
end

% -- number of subplots
if ~exist('sp', 'var')
    sp = [10, 11];
end

% -- define eeg system
eegsystem = nin_eeg_system(eegsys);

% -- make sure that values in columns are numeric
if ischar(x(1).data_columns{1, 1})
    ccolumns = cellfun(@str2num, x(1).data_columns, 'un', 0);
else
    ccolumns = cell2mat(x(1).data_columns);
end


%% -- plot data

if eegsystem.nochannels > sp(1)*sp(2)
    error('Not enough subplots.')
end

h = figure('color', [1 1 1], 'name', 'All', 'position', fposition);

k = 1;
while k <= length(eegsystem.ix_plot)
    
    subplot(sp(1), sp(2), k);
    
    if eegsystem.ix_plot(k) ~= 0
        
        cdata = squeeze(x.data(eegsystem.ix_plot(k), :, :)); % channels x freq x time stamps
        
        if ~isempty(czrange)
            imagesc(cdata, [zrange1 zrange2]);
        else
            imagesc(cdata);
        end
        
        % -- set y labels properly
        set (gca, 'ydir', 'normal');
        
        if ~isempty(cyrange)
            ylim([yrange1 yrange2]);
        end
        
        if ~isempty(cxrange)
            xlim([xrange1 xrange2]);
        end
        
        colormap(jet);
        
        if k == 105
            b = colorbar;
            set(b, 'position', [0.93, 0.25, 0.02, 0.5], 'units', 'normalized');
        end
        
        set(gca, 'fontweight', 'bold');
        
        title(x.data_rows{eegsystem.ix_plot(k)}, 'fontsize', fonts, 'fontweight', 'bold');
        
    else
        
        set(gca, 'visible', 'off');
        
    end
    
    k = k + 1;
    
end

end
