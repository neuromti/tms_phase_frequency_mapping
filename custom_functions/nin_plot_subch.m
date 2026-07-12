function [h] = nin_plot_subch(x, varargin)

%% This function plots results per selected channel
%
% - inputs:
% x: data structure
%
% - optional:
% eegsys: eegsystem used for data recording (default: 'BrainVision')
% cxrange/cyrange: x/y range (default: [])
% ccolor: color of line (default: black)
% cline: line width (defult: 3)
% sp: number of subplots (default: [10 11])
% fonts: figure font size (default: 10)
% fposition: figure position (default: full screen)
% clegend: add legend or not (default: false)
% chlist: list of channelst taht will be plotted
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

% -- number of subplots
if ~exist('sp', 'var')
    sp = [10, 11];
end

% -- line width
if ~exist('cline', 'var')
    cline = 3;
end

% -- line color
if ~exist('ccolor', 'var')
    ccolor = {rgb('Gray');...
        rgb('Black');...
        rgb('DarkRed');...
        rgb('DarkOrange');...
        rgb('Gold');...
        rgb('SaddleBrown');...
        rgb('DarkGreen');...
        rgb('SteelBlue');...
        rgb('DarkViolet')};
end

% -- legend
if ~exist('clegend', 'var')
    clegend = false;
end

% -- legend
if ~exist('chlist', 'var')
    chlist = {'C3', 'Cz', 'C4'};
end

% -- define eeg system
eegsystem = nin_eeg_system(eegsys);

% -- make sure that values in columns are numeric
if ischar(x(1).data_columns{1, 1})
    ccolumns = cell2mat(cellfun(@str2num, x(1).data_columns, 'un', 0));
else
    ccolumns = cell2mat(x(1).data_columns);
end


%% -- plot data

k = 1;
while k <= length(chlist)
    
    ix_plot(k) = find(strcmpi(eegsystem.channels, chlist{k}));
    
    k = k + 1;
    
end

if length(ix_plot) > sp(1)*sp(2)
    error('Not enough subplots.');
end

h = figure('color', [1 1 1], 'name', 'All', 'position', fposition);

fleg = [];
k2 = 1;
while k2 <= size(x, 1)
    
    k = 1;
    while k <= length(ix_plot)
        
        subplot(sp(1), sp(2), k);
                
        try
            plot(ccolumns, x(k2).data(ix_plot(k), :), 'linewidth', cline, 'color', ccolor{k2});
        catch
            plot(ccolumns, x(k2).dataMEAN(ix_plot(k), :), 'linewidth', cline, 'color', ccolor{k2});
        end
        hold on;
        
        if clegend
            
            if k == 1
                fleg = [fleg, {x(k2).condition}];
            end
            
            if k2 == size(x, 1) && k == length(ix_plot)
                
                legend(fleg, 'interpreter', 'none');
                legend('boxoff')
                
            end
            
        end
        
        if k2 == size(x, 1)
            
            if ~isempty(cxrange)
                xlim([xrange1 xrange2]);
            end
            
            if ~isempty(cyrange)
                ylim([yrange1 yrange2]);
            end
            
            grid on;
            
            set(gca, 'fontweight', 'bold');
            
            title(x(k2).data_rows{ix_plot(k)}, 'fontsize', fonts, 'fontweight', 'bold');
            
            hold off;
            
        end
       
        k = k + 1;
        
    end
    
    k2 = k2 + 1;
    
end

end