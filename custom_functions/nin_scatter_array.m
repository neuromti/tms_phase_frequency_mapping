function [h, stats] = nin_scatter_array(x, y, varargin)

%% This function creates a scatter plot and calculates correlation statistics
%
% - input:
% x: simple array
% y: simple array
%
% - optional:
% cname: figure name (default: Matlab settings)
% cposition: figure position (default: Matlab settings)
% cxlabel/cylabel: x/y label (default: nothing)
% cxrange/cyrange: x/y range (default: Matlab settings)
% ccolord: marker color (default: 'k')
% ccolorl: color of line (default: 'r')
% clinewidth: line width (default: 3)
% fonts: axis font size (default: 13)
% fontm: annotation font size (default: 13)
% disp_stats: display correlation statistics (default: true)
%
% - example:
% [y] = nin_scatter_array(R);
% [y] = nin_scatter_array(R, 'dim', 1);
% [y] = nin_scatter_array(R, 'dim', 1, sp, [1 1]);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define figure name
if ~exist('cname', 'var')
    h = figure('color', [1 1 1]);
else
    h = figure('name', cname,'color', [1 1 1]);
end

% -- define figure position
if exist('cposition', 'var')
    set(h, 'position', cposition)
end

% -- define x-axis limits
if ~exist('cxrange', 'var')
    cxrange = [];
else
    xrange1 = cxrange(1);
    xrange2 = cxrange(2);
end

% -- define y-axis limits
if ~exist('cyrange', 'var')
    cyrange = [];
else
    yrange1 = cyrange(1);
    yrange2 = cyrange(2);
end

% -- define marker size
if ~exist('cmarker', 'var')
    cmarker = 70;
end

% -- define axis font size
if ~exist('fonts', 'var')
    fonts = 13;
end

% -- define annotation font size
if ~exist('fontm', 'var')
    fontm = 13;
end

% -- define marker color
if ~exist('ccolord', 'var')
    ccolord = 'k';
end

% -- define line color
if ~exist('ccolorl', 'var')
    ccolorl = 'r';
end

% -- define line width
if ~exist('clinewidth', 'var')
    clinewidth = 3;
end

% -- define statistics display flag
if ~exist('disp_stats', 'var')
    disp_stats = true;
end

%% -- remove missing values

ix = ~isnan(x) & ~isnan(y);
x = x(ix);
y = y(ix);

%% -- calculate correlation

[r, p, ci_lower, ci_upper] = corrcoef(x, y);
stats.r = r(2, 1);
stats.Rsquared = r(2, 1)^2;
stats.p = p(2, 1);
stats.ci = [ci_lower(2, 1), ci_upper(2, 1)];

%% -- plot data

% -- plot observations
scatter(x, y, cmarker, 'filled', ccolord);

% -- add least-squares regression line
l = lsline;
set(l, 'LineWidth', clinewidth, 'color', ccolorl);

% -- set x-axis limits
if ~isempty(cxrange)
    xlim([xrange1 xrange2]);
end

% -- set y-axis limits
if ~isempty(cyrange)
    ylim([yrange1 yrange2]);
end

% -- add x-axis label
if exist('cxlabel', 'var')
    xlabel(cxlabel);
end

% -- add y-axis label
if exist('cylabel', 'var')
    ylabel(cylabel);
end

% -- display correlation statistics
if disp_stats
    text([0.01 0.01], [0.9 0.9], ['r = ', num2str(stats.r, '%.2g'), ' R^2 = ', num2str(stats.r^2, '%.2g'), ' p <= ', num2str(stats.p, '%.3g')], 'units', 'normalized', 'fontsize', fontm, 'fontweight', 'bold');
end

% -- format axes
set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

end

