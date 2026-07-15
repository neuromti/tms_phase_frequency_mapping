% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    publication figures
% -------------------------------------------------------------------------

% -- clear workspace, close all figures, and clear command window
clear all; close all; clc;

% -- initialize project settings and enable saving of results
pout = def_pro('IA_22a', 'saveWork', false);

%% -- diary and load eeglab

if pout.saveWork
    % -- extract timestamp information from archive path
    time = strsplit(pout.archive_NIN_path, filesep);
    time = time{contains(time, 'NIN')};

    % -- create diary file for software version tracking
    diary([pout.archive_path, 'softare_version', strrep(time, 'NIN', ''), '.txt'])

    % -- display current MATLAB version
    disp(['Matlab ', version]);

    eeglab;

    diary off

else
    eeglab;
end

%% -- define input parameters
% d:\Studies\2026_IMONAS_MSK\
% -- define input directory
pout.path_in = 'd:\Studies\2026_IMONAS_MSK\data_results\';

% -- gateway
pout.path_gateway = 'd:\Studies\2026_IMONAS_MSK\data_out\gateway\';

% -- group analysis
pout.path_folder_g_100 = 'main_phase_dependency_group_100_IA100_22a_2023_05_19\';
pout.path_folder_g_120 = 'main_phase_dependency_group_120_IA120_22a_2023_05_19\';
% -- individual analysis

pout.path_folder_i = {'main_phase_dependency_individual_100_IA100_22a_2023_05_19\';...
    'main_phase_dependency_individual_120_IA120_22a_2023_05_20\';};

% -- define output directory
% pout.path_out = ['/mnt/data/data09/2026_IMONAS_MSK/data_out/ERP_', pout.pro_name, '/'];
pout.path_out = ['d:\Studies\2026_IMONAS_MSK\data_results\', pout.function_name, '_', pout.pro_name, '_', nin_ctime, '\'];

%% -- create data out folder

if ~exist(pout.path_out, 'dir') && pout.saveWork
    mkdir(pout.path_out);
end

%% -- ERP plot (Figure 3)

% -- load and average ERP data at 100% RMT
load([pout.path_gateway, 'ERP_IA100_22a.mat']);

% -- keep frequency- and phase-specific conditions only
erp_mod = terp(~strcmpi({terp.tfreq}, 'all'));
erp_mod = erp_mod(~strcmpi({erp_mod.tphase}, 'all'));

% -- sort frequencies and phases
ufreq = unique({erp_mod.tfreq});
ufreq_s = cellfun(@str2num, ufreq, 'un', 0);
[~, ix] = sort(cell2mat(ufreq_s));
ufreq = ufreq(ix);
uphase = unique({erp_mod.tphase});
uphase_s = cellfun(@str2num, uphase, 'un', 0);
[~, ix] = sort(cell2mat(uphase_s));
uphase = uphase(ix);

% -- calculate grand-average ERP
erp_group = nin_group_data(erp_mod, {'data'}, {'group'});

[erp_group.data_rows] = deal(erp_mod(1).data_rows);
[erp_group.data_columns] = deal(erp_mod(1).data_columns);
[erp_group.time] = deal(erp_mod(1).time);
erp_group = nin_function(erp_group, @(x) size(x, 3), {'data'}, {'N'});
erp_group = nin_function(erp_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});
erp_group = nin_function(erp_group, @(x) nanmean(x, 3), {'data'}, {'data'});

erp_group_100 = erp_group;

% -- load and average ERP data at 120% RMT
load([pout.path_gateway, 'ERP_IA120_22a.mat']);

% -- keep frequency- and phase-specific conditions only
erp_mod = terp(~strcmpi({terp.tfreq}, 'all'));
erp_mod = erp_mod(~strcmpi({erp_mod.tphase}, 'all'));

% -- sort frequencies and phases
ufreq = unique({erp_mod.tfreq});
ufreq_s = cellfun(@str2num, ufreq, 'un', 0);
[~, ix] = sort(cell2mat(ufreq_s));
ufreq = ufreq(ix);
uphase = unique({erp_mod.tphase});
uphase_s = cellfun(@str2num, uphase, 'un', 0);
[~, ix] = sort(cell2mat(uphase_s));
uphase = uphase(ix);

% -- calculate grand-average ERP
erp_group = nin_group_data(erp_mod, {'data'}, {'group'});

[erp_group.data_rows] = deal(erp_mod(1).data_rows);
[erp_group.data_columns] = deal(erp_mod(1).data_columns);
[erp_group.time] = deal(erp_mod(1).time);
erp_group = nin_function(erp_group, @(x) size(x, 3), {'data'}, {'N'});
erp_group = nin_function(erp_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});
erp_group = nin_function(erp_group, @(x) nanmean(x, 3), {'data'}, {'data'});

erp_group_120 = erp_group;

% -- define figure settings
fW = 17.5;
fH = 6;
fFont = 'Ariel';
fFontSize = 9;
fFontSizeTick = 8;
fFontSizeSTitle = 10;
fFontSizeTitle = 11;
fFontWeight = 'bold';
fFontWeightTick = 'normal';
lineWidth = 0.6;
lineWidth2 = 2.5;
axesLineWidth = 0.75;
markerSize = 4;
alphaerrorBand = 0.2;
alphafreqHighlight = 0.25;

% -- create ERP figure
h = figure('Units', 'centimeters', 'Position', [2, 2, fW, fH], 'Color', [1 1 1]);
t = tiledlayout(1, 2, 'TileSpacing', 'tight');
ix_0 = find(erp_group.time == 0);
samplet = ix_0-50:ix_0+400;
sample = samplet;
cylim = [-8 8];
cxlim = [-50 400];

% -- plot ERP at 100% RMT
nexttile(1);
k = 1;
while k <= length(erp_group_100.data_rows)

    % -- plot ERP from individual channels
    cdata = erp_group_100.data(k, :);
    plot(erp_group_100.time(samplet), cdata(1, sample), 'linewidth', lineWidth);

    hold on;

    k = k + 1;

end
hold on;

% -- highlight C3 channel
plot(erp_group_100.time(samplet), erp_group_100.data(strcmpi(erp_group_100.data_rows, 'C3'), samplet), 'k', 'linewidth', lineWidth2);

ylim(cylim);
xlim(cxlim);

% -- mark TMS interpolation period
fill([erp_group_100.time(ix_0-10) erp_group_100.time(ix_0-10) erp_group_100.time(ix_0+10) erp_group_100.time(ix_0+10)], [cylim fliplr(cylim)], 'k', 'FaceAlpha', 1,'linestyle','none');%%

title('100% RMT', ...
    'FontName', fFont, ...
    'FontSize', fFontSizeSTitle, ...
    'FontWeight', fFontWeight, ...
    'interpreter', 'none');

set(gca, 'FontName', fFont, ...
    'FontSize', fFontSizeTick, ...
    'FontWeight', fFontWeightTick, ...
    'LineWidth', axesLineWidth);

% -- plot ERP at 120% RMT
nexttile(2);
k = 1;
while k <= length(erp_group_120.data_rows)

    % -- plot ERP from individual channels
    cdata = erp_group_120.data(k, :);
    plot(erp_group_120.time(samplet), cdata(1, sample), 'linewidth', lineWidth);

    hold on;

    k = k + 1;

end
hold on;

% -- highlight C3 channel
plot(erp_group_120.time(samplet), erp_group_120.data(strcmpi(erp_group_120.data_rows, 'C3'), samplet), 'k', 'linewidth', lineWidth2);

ylim(cylim);
xlim(cxlim);

% -- mark TMS interpolation period
fill([erp_group_120.time(ix_0-10) erp_group_120.time(ix_0-10) erp_group_120.time(ix_0+10) erp_group_120.time(ix_0+10)], [cylim fliplr(cylim)], 'k', 'FaceAlpha', 1,'linestyle','none');%%

% -- remove y-axis labels from second panel
ylab = get(gca, 'yticklabels');
ylab = repmat({''}, size(ylab));
set(gca, 'yticklabels', ylab);

title('120% RMT', ...
    'FontName', fFont, ...
    'FontSize', fFontSizeSTitle, ...
    'FontWeight', fFontWeight, ...
    'interpreter', 'none');

set(gca, 'FontName', fFont, ...
    'FontSize', fFontSizeTick, ...
    'FontWeight', fFontWeightTick, ...
    'LineWidth', axesLineWidth);

% -- add shared axis labels
ylabel(t,'Amplitude (\muV)','FontName', fFont, 'FontSize', fFontSize);
xlabel(t,'Time (ms)','FontName', fFont, 'FontSize', fFontSize);

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_3_ERP.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_3_ERP.tiff'], 'Resolution', 300);
end

%% -- TEP component topographies (Figure 4)

% -- define figure settings
fW = 17.5;
fH = 6;
fFont = 'Ariel';
fFontSize = 9;
fFontSizeTick = 8;
fFontSizeSTitle = 10;
fFontSizeTitle = 11;
fFontWeight = 'bold';
fFontWeightTick = 'normal';
lineWidth = 0.6;
lineWidth2 = 2.5;
axesLineWidth = 0.75;
markerSize = 2;
alphaerrorBand = 0.2;
alphafreqHighlight = 0.25;

% -- load 100% RMT peak data
load([pout.path_gateway, 'TEP_IA100_22a.mat']);

% -- prepare peak amplitudes for topographical visualization
% -- keep frequency- and phase-specific conditions only
epeak_mod = epeak(~strcmpi({epeak.tfreq}, 'all'));
epeak_mod = epeak_mod(~strcmpi({epeak_mod.tphase}, 'all'));

% -- keep amplitude measures only
ix = contains(epeak_mod(1).data_columns, '_amp');
k1 = 1;
while k1 <= size(epeak_mod, 2)

    epeak_mod(k1).data = epeak_mod(k1).data(:, ix, :);
    epeak_mod(k1).data_columns = epeak_mod(k1).data_columns(ix);

    k1 = k1 +1;

end

% -- calculate grand-average peak amplitudes
cpeak_group = nin_group_data(epeak_mod, {'data'}, {'group'});
[cpeak_group.data_rows] = deal(epeak_mod(1).data_rows);
[cpeak_group.data_columns] = deal(strrep(epeak_mod(1).data_columns, '_amp', ''));
cpeak_group = nin_function(cpeak_group, @(x) size(x, 3), {'data'}, {'N'});
cpeak_group = nin_function(cpeak_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});
cpeak_group = nin_function(cpeak_group, @(x) nanmean(x, 3), {'data'}, {'data'});

% -- generate topographical maps of TEP components
h = nin_topoplot(cpeak_group, [], 'crange', [-10, 10], 'display_sp', true, 'sp', [1, 5], 'fonts', fFontSizeSTitle, 'fontsbar', fFontSizeTick, 'mymarkersize', markerSize);

% -- adjust figure layout
set(h, 'units', 'centimeter','position', [5, 5, fW, fH]);

% -- shift topographies to optimize figure spacing
axAll = findobj(gcf, 'Type', 'axes');
axAll = flipud(axAll);

shiftLeft = 0.08;

for i = 1:numel(axAll)
    pos = axAll(i).Position;
    pos(1) = pos(1) - shiftLeft;
    axAll(i).Position = pos;
end

% -- adjust colorbar position and size
cb = findobj(gcf, 'Type', 'colorbar');
pos = cb.Position;
pos(1) = pos(1) - shiftLeft;
newHeight = pos(4) * 0.6;
pos(2) = pos(2) + (pos(4) - newHeight)/2;
pos(4) = newHeight;
cb.Position = pos;

% -- add panel label
ax1 = axAll(1);
pos1 = ax1.Position;
letterW = 0.01;
letterH = pos1(4);
letterX = pos1(1) - letterW - 0.02;
letterY = pos1(2);

annotation('textbox', [letterX, letterY, letterW, letterH], ...
    'String', 'A', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', 12);

% -- add colorbar unit label
cbPos = cb.Position;
axFig = axes('Position', [0 0 1 1], 'Visible', 'off');
text(cbPos(1)+cbPos(3)+0.04, cbPos(2)+cbPos(4)/2, '\muV', ...
    'Parent', axFig, ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', fFontSizeTick);

% -- add figure title
axFirst = axAll(1);
axLast  = axAll(end);

posFirst = axFirst.Position;
posLast  = axLast.Position;

leftEdge  = posFirst(1);
rightEdge = posLast(1) + posLast(3);
centerX   = (leftEdge + rightEdge) / 2;

titleW = 0.15;
titleH = 0.06;
titleY = posFirst(2) + posFirst(4) - 0.08;

annotation('textbox', [centerX - titleW/2, titleY, titleW, titleH], ...
    'String', '100% RMT', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', fFontSizeTitle);

% -- apply figure formatting
set(findall(gcf, '-property', 'FontName'), 'FontName', fFont);

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_4_Topomap_100_A.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_4_Topomap_100_A.tiff'], 'Resolution', 300);
end

% -- load 120% RMT peak data
load([pout.path_gateway, 'TEP_IA120_22a.mat']);

% -- prepare peak amplitudes for topographical visualization
% -- keep frequency- and phase-specific conditions only
epeak_mod = epeak(~strcmpi({epeak.tfreq}, 'all'));
epeak_mod = epeak_mod(~strcmpi({epeak_mod.tphase}, 'all'));

% -- keep amplitude measures only
ix = contains(epeak_mod(1).data_columns, '_amp');
k1 = 1;
while k1 <= size(epeak_mod, 2)

    epeak_mod(k1).data = epeak_mod(k1).data(:, ix, :);
    epeak_mod(k1).data_columns = epeak_mod(k1).data_columns(ix);

    k1 = k1 +1;

end

% -- calculate grand-average peak amplitudes
cpeak_group = nin_group_data(epeak_mod, {'data'}, {'group'});
[cpeak_group.data_rows] = deal(epeak_mod(1).data_rows);
[cpeak_group.data_columns] = deal(strrep(epeak_mod(1).data_columns, '_amp', ''));
cpeak_group = nin_function(cpeak_group, @(x) size(x, 3), {'data'}, {'N'});
cpeak_group = nin_function(cpeak_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});
cpeak_group = nin_function(cpeak_group, @(x) nanmean(x, 3), {'data'}, {'data'});

% -- generate topographical maps of TEP components
h = nin_topoplot(cpeak_group, [], 'crange', [-10, 10], 'display_sp', true, 'sp', [1, 5], 'fonts', fFontSizeSTitle, 'fontsbar', fFontSizeTick, 'mymarkersize', markerSize);

% -- adjust figure layout
set(h, 'units', 'centimeter','position', [5, 5, fW, fH]);

% -- shift topographies to optimize figure spacing
axAll = findobj(gcf, 'Type', 'axes');
axAll = flipud(axAll);

shiftLeft = 0.08;

for i = 1:numel(axAll)
    pos = axAll(i).Position;
    pos(1) = pos(1) - shiftLeft;
    axAll(i).Position = pos;
end

% -- adjust colorbar position and size
cb = findobj(gcf, 'Type', 'colorbar');
pos = cb.Position;
pos(1) = pos(1) - shiftLeft;
newHeight = pos(4) * 0.6;
pos(2) = pos(2) + (pos(4) - newHeight)/2;
pos(4) = newHeight;
cb.Position = pos;

% -- add panel label
ax1 = axAll(1);
pos1 = ax1.Position;
letterW = 0.01;
letterH = pos1(4);
letterX = pos1(1) - letterW - 0.02;
letterY = pos1(2);

annotation('textbox', [letterX, letterY, letterW, letterH], ...
    'String', 'C', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', 12);

% -- add colorbar unit label
cbPos = cb.Position;
axFig = axes('Position', [0 0 1 1], 'Visible', 'off');
text(cbPos(1)+cbPos(3)+0.04, cbPos(2)+cbPos(4)/2, '\muV', ...
    'Parent', axFig, ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', fFontSizeTick);

% -- add figure title
axFirst = axAll(1);
axLast  = axAll(end);

posFirst = axFirst.Position;
posLast  = axLast.Position;

leftEdge  = posFirst(1);
rightEdge = posLast(1) + posLast(3);
centerX   = (leftEdge + rightEdge) / 2;

titleW = 0.15;
titleH = 0.06;
titleY = posFirst(2) + posFirst(4) - 0.08;

annotation('textbox', [centerX - titleW/2, titleY, titleW, titleH], ...
    'String', '120% RMT', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', fFontSizeTitle);

% -- apply figure formatting
set(findall(gcf, '-property', 'FontName'), 'FontName', fFont);

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_4_Topomap_120_A.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_4_Topomap_120_A.tiff'], 'Resolution', 300);
end

% -- load cluster-based permutation results 100% RMT
load([pout.path_in, pout.path_folder_g_100, 'clustered data\', 'clustered_data.mat']);

% -- create significance mask
clu_stat.p = ~clu.mask;

% -- plot cluster topographies
h = nin_topoplot(clu, clu_stat, 'crange', [-10, 10], 'display_sp', true, 'sp', [1, 5], 'p_th', 1, 'fonts', fFontSizeSTitle, 'fontsbar', fFontSizeTick, 'mymarkersize', markerSize, 'mymarkersize2', markerSize);

% -- remove default subplot titles
ha = get(h, 'children');
k = length(ha);
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;

% -- adjust figure layout
set(h, 'units', 'centimeter','position', [5, 5, fW, fH]);

axAll = findobj(gcf, 'Type', 'axes');
axAll = flipud(axAll);

% -- shift topographies to optimize figure spacing
shiftLeft = 0.08;

for i = 1:numel(axAll)
    pos = axAll(i).Position;
    pos(1) = pos(1) - shiftLeft;
    axAll(i).Position = pos;
end

% -- adjust colorbar position and size
cb = findobj(gcf, 'Type', 'colorbar');
pos = cb.Position;
pos(1) = pos(1) - shiftLeft;
newHeight = pos(4) * 0.6;
pos(2) = pos(2) + (pos(4) - newHeight)/2;
pos(4) = newHeight;
cb.Position = pos;

% -- add panel label
ax1 = axAll(1);
pos1 = ax1.Position;
letterW = 0.01;
letterH = pos1(4);
letterX = pos1(1) - letterW - 0.02;
letterY = pos1(2);

annotation('textbox', [letterX, letterY, letterW, letterH], ...
    'String', 'B', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', 12);

% -- add colorbar label
cbPos = cb.Position;
axFig = axes('Position', [0 0 1 1], 'Visible', 'off');
text(cbPos(1)+cbPos(3)+0.04, cbPos(2)+cbPos(4)/2, 't-value', ...
    'Parent', axFig, ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', fFontSizeTick);

% -- apply figure formatting
set(findall(gcf, '-property', 'FontName'), 'FontName', fFont);

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_4_Topomap_100_B.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_4_Topomap_100_B.tiff'], 'Resolution', 300);
end

% -- load cluster-based permutation results 120% RMT
load([pout.path_in, pout.path_folder_g_120, 'clustered data\', 'clustered_data.mat']);

% -- create significance mask
clu_stat.p = ~clu.mask;

% -- plot cluster topographies
h = nin_topoplot(clu, clu_stat, 'crange', [-10, 10], 'display_sp', true, 'sp', [1, 5], 'p_th', 1, 'fonts', fFontSizeSTitle, 'fontsbar', fFontSizeTick, 'mymarkersize', markerSize, 'mymarkersize2', markerSize);

% -- remove default subplot titles
ha = get(h, 'children');
k = length(ha);
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;
set(h,'CurrentAxes',ha(k))
title(gca, '');
k = k - 1;

% -- adjust figure layout
set(h, 'units', 'centimeter','position', [5, 5, fW, fH]);

axAll = findobj(gcf, 'Type', 'axes');
axAll = flipud(axAll);

% -- shift topographies to optimize figure spacing
shiftLeft = 0.08;

for i = 1:numel(axAll)
    pos = axAll(i).Position;
    pos(1) = pos(1) - shiftLeft;
    axAll(i).Position = pos;
end

% -- adjust colorbar position and size
cb = findobj(gcf, 'Type', 'colorbar');
pos = cb.Position;
pos(1) = pos(1) - shiftLeft;
newHeight = pos(4) * 0.6;
pos(2) = pos(2) + (pos(4) - newHeight)/2;
pos(4) = newHeight;
cb.Position = pos;

% -- add panel label
ax1 = axAll(1);
pos1 = ax1.Position;
letterW = 0.01;
letterH = pos1(4);
letterX = pos1(1) - letterW - 0.02;
letterY = pos1(2);

annotation('textbox', [letterX, letterY, letterW, letterH], ...
    'String', 'D', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', 'FontSize', 12);

% -- add colorbar label
cbPos = cb.Position;
axFig = axes('Position', [0 0 1 1], 'Visible', 'off');
text(cbPos(1)+cbPos(3)+0.04, cbPos(2)+cbPos(4)/2, 't-value', ...
    'Parent', axFig, ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', fFontSizeTick);

% -- apply figure formatting
set(findall(gcf, '-property', 'FontName'), 'FontName', fFont);

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_4_Topomap_120_B.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_4_Topomap_120_B.tiff'], 'Resolution', 300);
end

close all;

%% -- Modulation depth (Figure 5)

% -- load modulation depth data at 100% RMT
load([pout.path_in, pout.path_folder_g_100, 'fit Clustered\', 'fit_amp.mat'])

% -- sort frequencies
ufreq = {fit_amp.freq};
ufreq_s = cellfun(@str2num, ufreq, 'un', 0);
[~, ix] = sort(cell2mat(ufreq_s));
ufreq = ufreq(ix);

% -- extract modulation depth, phase, and surrogate estimates
cdata_100 = [];
sdata_100 = [];
sdata_sd_100 = [];
cphase_100 = [];
k1 = 1;
while k1 <= length(ufreq)

    kc = strcmpi({fit_amp.freq}, ufreq{k1});
    cdata_100 = [cdata_100; fit_amp(kc).data(strcmpi(fit_amp(kc).data_rows, 'amp'), :)];
    cphase_100 = [cphase_100; fit_amp(kc).data(strcmpi(fit_amp(kc).data_rows, 'phase'), :)];
    sdata_100 = [sdata_100; mean(fit_amp(kc).data_surogat(strcmpi(fit_amp(kc).data_rows, 'amp'), :, :), 3)];
    sdata_sd_100 = [sdata_sd_100; std(fit_amp(kc).data_surogat(strcmpi(fit_amp(kc).data_rows, 'amp'), :, :), [], 3)];
    k1 = k1 + 1;

end

% -- extract permutation p-values
if size(fit_amp, 1) == 2
    fit_amp = nin_function(fit_amp_new, @(x) x(1, :)', {'p'}, {'p'});
else
    fit_amp = nin_function(fit_amp, @(x) x(1, 1:2:end-1)', {'p'}, {'p'});
end
p_100 = [fit_amp.p]';

% -- apply FDR correction
fdr_p_100 = reshape(mafdr(p_100(:), 'BHFDR', true), size(p_100));

clear fit_amp fit_amp_all fit_amp_rest

% -- load modulation depth data at 120% RMT
load([pout.path_in, pout.path_folder_g_120, 'fit Clustered\', 'fit_amp.mat'])

% -- extract modulation depth, phase, and surrogate estimates
cdata_120 = [];
sdata_120 = [];
sdata_sd_120 = [];
cphase_120 = [];
k1 = 1;
while k1 <= length(ufreq)

    kc = strcmpi({fit_amp.freq}, ufreq{k1});
    cdata_120 = [cdata_120; fit_amp(kc).data(strcmpi(fit_amp(kc).data_rows, 'amp'), :)];
    cphase_120 = [cphase_120; fit_amp(kc).data(strcmpi(fit_amp(kc).data_rows, 'phase'), :)];
    sdata_120 = [sdata_120; mean(fit_amp(kc).data_surogat(strcmpi(fit_amp(kc).data_rows, 'amp'), :, :), 3)];
    sdata_sd_120 = [sdata_sd_120; std(fit_amp(kc).data_surogat(strcmpi(fit_amp(kc).data_rows, 'amp'), :, :), [], 3)];
    k1 = k1 + 1;

end

% -- extract permutation p-values and apply FDR correction
if size(fit_amp, 1) == 2
    fit_amp = nin_function(fit_amp_new, @(x) x(1, :)', {'p'}, {'p'});
else
    fit_amp = nin_function(fit_amp, @(x) x(1, 1:2:end-1)', {'p'}, {'p'});
end
p_120 = [fit_amp.p]';

% -- apply FDR correction
fdr_p_120 = reshape(mafdr(p_120(:), 'BHFDR', true), size(p_120));

% -- load individual modulation depth results
fitamp_tot = [];
kf = 1;
while kf <= length(pout.path_folder_i)

    % -- load individual clustered data
    cpath = [pout.path_in, pout.path_folder_i{kf}];
    load([cpath, 'clustered_data.mat']);

    cname = nin_strsplit({cpath}, 5, 5, 'spliter', '\');
    cname = strsplit(cname{:}, '_');

    ix = find(strcmp(cname, 'IA'));
    if isempty(ix)
        ix = find(strcmp(cname, 'IA100'));
    end
    if isempty(ix)
        ix = find(strcmp(cname, 'IA120'));
    end
    cname = strjoin(cname(ix:ix+1), '_');

    [fit_all.pro_name] = deal(cname);
    [fit_all.iter] = deal(1);

    sub = unique({fit_all.sub})';
    visit = unique([fit_all.visit])';
    freq = unique({fit_all.tfreq})';
    [~, ix_f] = sort(cell2mat(cellfun(@str2num, freq, 'un', 0)));
    freq = freq(ix_f);

    % -- prepare individual modulation depth dataset
    fitamp_tot = [fitamp_tot, fit_all];

    kf = kf + 1;

end

[fitamp_tot.data_rows] = deal(fitamp_tot(1).data_rows);
col = {fitamp_tot.name};
col = strrep(col, 'inv', '');
col = num2cell(col);
[fitamp_tot.data_columns] = col{:};
col = [col{:}];
[fitamp_tot.name] = col{:};

ixr = true(size(fitamp_tot, 2), 1);
for k = 1:size(fitamp_tot, 2)

    if any(isnan(fitamp_tot(k).data))

        ixr(k) = false;

    end

end
fitamp_tot = fitamp_tot(ixr);

% -- define peaks, frequencies, and experimental conditions
npeaks = {'P25', 'N45', 'P70', 'N100', 'P180'};
ufreq = cellfun(@num2str, num2cell(4:1:40), 'un', 0);
ufreqc = cellfun(@num2str, num2cell(4:4:40), 'un', 0);
pro_name = {'IA100_22a', 'IA120_22a'};
uphase = cellfun(@num2str, num2cell(0:45:315), 'un', 0);

% -- remove incomplete frequency datasets
sanity_data = nin_group_data(fitamp_tot, {'data'}, {'sub', 'name', 'pro_name', 'visit', 'iter'}, 'match', 'exact');
sanity_data = nin_function(sanity_data, @(x) size(x, 2), {'data'}, {'N'});
ix_c = [sanity_data.N] > length(ufreqc);

sanity_data_c = sanity_data(ix_c);

kr = 1;
while  kr <= size(sanity_data_c, 2)

    [cdata, ix] = nin_subselect_dstruct(fitamp_tot, 'pro_name', sanity_data_c(kr).pro_name, 'sub', sanity_data_c(kr).sub, 'visit', num2str(sanity_data_c(kr).visit), 'iter', num2str(sanity_data_c(kr).iter), 'name', sanity_data_c(kr).name);

    ix = find(ix);

    if size(cdata, 2) == 2*length(ufreqc)

        ix = ix(1:length(ufreqc));

    else

        [cdata2, ix2] = intersect({cdata.tfreq}, ufreqc, 'stable');

        ix = ix(setdiff(1:length(ix), ix2));

    end

    fitamp_tot(ix) = [];

    kr = kr + 1;

end

sanity_data = nin_group_data(fitamp_tot, {'data'}, {'sub', 'name', 'pro_name', 'visit', 'iter'}, 'match', 'exact');
sanity_data = nin_function(sanity_data, @(x) size(x, 2), {'data'}, {'N'});
ix_r = [sanity_data.N] < length(ufreqc);
ix_c = [sanity_data.N] > length(ufreqc);

sanity_data_r = sanity_data(ix_r);

kr = 1;
while  kr <= size(sanity_data_r, 2)

    [cdata, ix] = nin_subselect_dstruct(fitamp_tot, 'pro_name', sanity_data_r(kr).pro_name, 'sub', sanity_data_r(kr).sub, 'visit', num2str(sanity_data_r(kr).visit), 'iter', num2str(sanity_data_r(kr).iter), 'name', sanity_data_r(kr).name);

    fitamp_tot(ix) = [];

    kr = kr + 1;

end

% -- test modulation depth against surrogate data
k = 1;
kn = 1;
p_th = 0.05;
while kn <= length(pro_name)

    kp = 1;
    while kp <= length(npeaks)

        kf = 1;
        while kf <= length(ufreqc)

            cdata = nin_subselect_dstruct(fitamp_tot, 'pro_name', pro_name{kn}, 'name', [npeaks{kp}, '_amp'], 'tfreq', ufreqc{kf});
            cdata_sur = cdata;
            cdata_sur = nin_function(cdata_sur, @(x) nanmean(x, 2), 'data_surogat', 'data');
            ct = nin_ttest(cdata, cdata_sur, 'srows', {'amp'});

            [ct.pro_name] = pro_name{kn};
            [ct.tfreq] = ufreqc{kf};
            [ct.p_new] = nan(1, 1);
            [ct.sig] = false;
            stat_o(k) = ct;

            stat_o(k).p_new = stat_o(k).p;
            stat_o(k).sig = stat_o(k).p < p_th;

            k = k + 1;

            kf = kf + 1;

        end

        kp = kp + 1;

    end

    kn = kn + 1;

end

stat = stat_o;

% -- apply FDR correction to modulation depth statistics
stat_fdr = stat;
p_new = nan(numel(stat_fdr),1);

kn = 1;
while kn <= length(pro_name)

    % Select all tests belonging to the current processing type
    [cdata, cix] = nin_subselect_dstruct(stat_fdr, 'pro_name', pro_name{kn});

    % Apply BH-FDR correction across all p-values within this processing type
    cp = mafdr([cdata.p], 'BHFDR', true);

    % Store corrected p-values at the corresponding indices
    p_new(cix) = cp;

    kn = kn + 1;
end

% Save corrected p-values
for k = 1:numel(stat_fdr)
    stat_fdr(k).p_fdr = p_new(k);
end

% -- calculate group-level modulation depth estimates
fit_group = nin_group_data(fitamp_tot, {'data', 'data_surogat'}, {'tfreq', 'name', 'pro_name'}, 'match', 'exact');
[fit_group.data_rows] = deal(fitamp_tot(1).data_rows);
col = {fit_group.name};
col = strrep(col, '_amp', '');
col = num2cell(col);
[fit_group.data_columns] = col{:};
fit_group = nin_function(fit_group, @(x) size(x, 2), {'data'}, {'N'});
fit_group = nin_function(fit_group, @(x) sum(~isnan(x), 2), {'data'}, {'n'});
fit_group = nin_function(fit_group, @(x) squeeze(nanmean(x, 2)), {'data_surogat'}, {'data_surogat'});
fit_group = nin_function(fit_group, @(x) [nanstd(x(1, :), [], 2); wrapTo360(rad2deg(circ_std(x(2, :), [], [], 2)))], {'data'}, {'dataSTD'});
fit_group = nin_function(fit_group, @(x) [nanstd(x(1, :), [], 2); wrapTo360(rad2deg(circ_std(x(2, :), [], [], 2)))], {'data_surogat'}, {'data_surogatSTD'});
fit_group = nin_function(fit_group, @(x) [nanmean(x(1, :), 2); wrapTo360(rad2deg(circ_mean(x(2, :), [], 2)))], {'data'}, {'data'});
fit_group = nin_function(fit_group, @(x) [nanmean(x(1, :), 2); wrapTo360(rad2deg(circ_mean(x(2, :), [], 2)))], {'data_surogat'}, {'data_surogat'});

fit_group = nin_merge_structures(fit_group, stat_fdr, {'pro_name', 'name', 'tfreq'});

% -- define figure settings
fW = 17.5;
fH = 18;
fFont = 'Ariel';
fFontSize = 9;
fFontSizeTick = 8;
fFontSizeSTitle = 10;
fFontSizeTitle = 11;
fFontWeight = 'bold';
fFontWeightTick = 'normal';
lineWidth = 1.25;
axesLineWidth = 0.75;
markerSize = 4;
alphaerrorBand = 0.2;
alphafreqHighlight = 0.25;

% -- create figure
h = figure('Units', 'centimeters', 'Position', [2, 2, fW, fH], 'Color', [1 1 1]);
drawnow;

t = tiledlayout(length(npeaks), length(pro_name), 'TileSpacing', 'tight');

p_th = 0.05;

% -- plot modulation depth for each peak and stimulation intensity
kn = 1;
while kn <= length(pro_name)

    k = kn;

    kp = 1;
    while kp <= length(npeaks)

        cp = nin_subselect_dstruct(fit_group, 'pro_name', pro_name{kn}, 'name', [npeaks{kp}, '_amp']);
        [~, ix_f] = sort(cell2mat(cellfun(@str2num, {cp.tfreq}, 'un', 0)));
        cp = cp(ix_f);

        cdata = nin_subselect_dstruct(fit_group, 'pro_name', pro_name{kn}, 'name', [npeaks{kp}, '_amp']);
        [~, ix_f] = sort(cell2mat(cellfun(@str2num, {cdata.tfreq}, 'un', 0)));
        cdata = cdata(ix_f);

        ccdata = [cdata.data]; ccdata = ccdata(1, :)';
        ecdata = [cdata.dataSTD]; ecdata = ecdata(1, :)';
        ccdata_suro = [cdata.data_surogat]; ccdata_suro = ccdata_suro(1, :)';
        ecdata_suro = [cdata.data_surogatSTD]; ecdata_suro = ecdata_suro(1, :)';
        nexttile(k);
        ka = 1;
        % -- plot group modulation depth
        p(ka) = plot(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), ccdata, 'Marker', 'o', 'MarkerSize', markerSize, 'MarkerEdgeColor', [0.90 0.60 0.00], 'MarkerFaceColor', [0.90 0.60 0.00], 'linestyle', 'none');
        ka = ka + 1;
        hold on;
        curve1 = ccdata + ecdata;
        curve2 = ccdata - ecdata;
        cfreq = [cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), fliplr(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)))];
        inBetween = [curve1', fliplr(curve2')];
        % -- add confidence band around group estimate
        p(ka) = fill(cfreq, inBetween, [0.90 0.60 0.00], 'FaceAlpha', alphaerrorBand,'linestyle','none');
        ka = ka + 1;
        hold on;
        % -- plot surrogate modulation depth
        p(ka) = plot(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), ccdata_suro, 'linewidth', lineWidth, 'color',  [0.45 0.45 0.45]);
        ka = ka + 1;
        curve1 = ccdata_suro + ecdata_suro;
        curve2 = ccdata_suro - ecdata_suro;
        cfreq = [cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), fliplr(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)))];
        inBetween = [curve1', fliplr(curve2')];
        % -- add confidence band around surrogate estimate
        p(ka) = fill(cfreq, inBetween, [0.45 0.45 0.45], 'FaceAlpha', alphaerrorBand,'linestyle','none');
        ka = ka + 1;
        hold on;

        % -- plot grand-average modulation depth
        if contains(pro_name(kn), '100')
            p(ka) = plot(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), cdata_100(:, kp), 'Marker', 'o', 'MarkerSize', markerSize, 'MarkerEdgeColor', [0.00 0.45 0.70], 'MarkerFaceColor', [0.00 0.45 0.70], 'linestyle', 'none');
            ka = ka + 1;
        else
            p(ka) = plot(cell2mat(cellfun(@str2num, ufreqc, 'un', 0)), cdata_120(:, kp), 'Marker', 'o', 'MarkerSize', markerSize, 'MarkerEdgeColor', [0.00 0.45 0.70], 'MarkerFaceColor', [0.00 0.45 0.70], 'linestyle', 'none');
            ka = ka + 1;
        end

        % -- format axes
        xlim([4, 40]);
        cylim = [0, 1.2];
        ylim([cylim(1), cylim(2)]);
        set(gca, 'ytick', 0:0.5:1.2);

        if kn == 2
            set(gca, 'yticklabel', {[]})
        end

        if kp ~= length(npeaks)
            set(gca, 'xticklabel', {[]})
        end

        % -- highlight stimulation frequency range
        if kp == 1 && contains(pro_name(kn), '100')
            p(ka) = fill([[27, 27], [29, 29]], [[cylim(1), cylim(2)], fliplr([cylim(1), cylim(2)])], rgb('DarkRed'), 'FaceAlpha', alphafreqHighlight, 'linestyle','none');
        end
        ka = ka + 1;

        % -- mark nominally significant frequencies
        if any([cp.p] < p_th)
            ix_f = [cp.p] < p_th;
            p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), ccdata(ix_f), 'linewidth', lineWidth, 'color', rgb('black'), 'linestyle', 'none', 'marker', 'square', 'MarkerSize', markerSize+1);
            ka = ka + 1;
        end

        % -- mark FDR-corrected significant frequencies
        if any([cp.p_new] < p_th)
            ix_f = [cp.p_new] < p_th;
            p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), ccdata(ix_f), 'linewidth', lineWidth, 'color', 'r', 'linestyle', 'none', 'marker', '*', 'MarkerSize', markerSize+1);
            ka = ka + 1;
        end

        if contains(pro_name(kn), '100')
            % -- mark significant frequencies from cluster-level analysis
            if any(p_100(:, kp) < p_th)
                ix_f = p_100(:, kp) < p_th;
                p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), cdata_100(ix_f, kp), 'linewidth', lineWidth, 'color', 'k', 'linestyle', 'none', 'marker', 'square', 'MarkerSize', markerSize+1);
                ka = ka + 1;
            end
            % -- mark FDR-corrected cluster-level results
            if any(fdr_p_100(:, kp) < p_th)
                ix_f = fdr_p_100(:, kp) < p_th;
                p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), cdata_100(ix_f, kp), 'linewidth', lineWidth, 'color', 'r', 'linestyle', 'none', 'marker', 'square', 'MarkerSize', markerSize+1);
                ka = ka + 1;
            end
        else
            if any(p_120(:, kp) < p_th)
                % -- mark significant frequencies from cluster-level analysis
                ix_f = p_120(:, kp) < p_th;
                p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), cdata_120(ix_f, kp), 'linewidth', lineWidth, 'color', 'k', 'linestyle', 'none', 'marker', 'square', 'MarkerSize', markerSize+1);
                ka = ka + 1;
            end
            % -- mark FDR-corrected cluster-level results
            if any(fdr_p_120(:, kp) < p_th)
                ix_f = fdr_p_120(:, kp) < p_th;
                p(ka) = plot(cell2mat(cellfun(@str2num, freq(ix_f), 'un', 0)), cdata_120(ix_f, kp), 'linewidth', lineWidth, 'color', 'r', 'linestyle', 'none', 'marker', 'square', 'MarkerSize', markerSize+1);
                ka = ka + 1;
            end
        end

        % -- apply subplot formatting
        set(gca, 'FontName', fFont, ...
            'FontSize', fFontSizeTick, ...
            'FontWeight', fFontWeightTick, ...
            'LineWidth', axesLineWidth);

        % -- add column titles
        if k == 1
            title('100% RMT', ...
                'FontName', fFont, ...
                'FontSize', fFontSizeSTitle, ...
                'FontWeight', fFontWeight, ...
                'interpreter', 'none');

        elseif k == 2
            title('120% RMT', ...
                'FontName', fFont, ...
                'FontSize', fFontSizeSTitle, ...
                'FontWeight', fFontWeight, ...
                'interpreter', 'none');
        end

        % -- add peak labels
        if rem(k, 2) ~= 0
            ylabel(npeaks{kp}, 'FontName', fFont, 'FontSize', fFontSizeSTitle, 'FontWeight', fFontWeight);
        end

        % -- add legend
        if kp == 5 && kn == 2
            l = legend(p([1, 5]), 'Individual', 'Group');
            l.Orientation = 'horizontal';
            l.Box = 'off';
            l.FontName = fFont;
            l.FontSize = fFontSizeTick;
            l.Units = "centimeters";
            l.Position = [11.018 0.88729 4.7096 0.48215];
        end

        k = k + 2;

        kp = kp + 1;

    end

    kn = kn + 1;

end

% -- add shared axis labels
xlabel(t, 'Frequency (Hz)', 'FontSize', fFontSize);
ylabel(t, 'Strength Of Modulation Depth', 'FontSize', fFontSize);

% -- save figure
if pout.saveWork
    pout.fielname_out = 'Figure_5_ModulationDepth';
    saveas(h, [pout.path_out, pout.fielname_out, '.fig']);
    exportgraphics(h, [pout.path_out, pout.fielname_out, '.tiff'], 'Resolution', 300);
end
close(h);

%% -- Optimal phase (Figure 6)

% -- group modulation phase estimates across subjects
cdata_group = nin_group_data(fitamp_tot, {'data'}, {'pro_name', 'tfreq', 'name'}, 'match', 'exact');
% -- extract phase values
cdata_group = nin_function(cdata_group, @(x) abs(x(2, :)), {'data'}, {'PLV'});
% -- convert phases to unit vectors
cdata_group = nin_function(cdata_group, @(x) exp(1i*deg2rad((abs(x(2, :))))), {'data'}, {'PLV'});
% -- calculate sample size
cdata_group = nin_function(cdata_group, @(x) length(x), {'PLV'}, {'n'});
% -- calculate phase-locking value
cdata_group = nin_function(cdata_group, @(x) abs(sum(x.PLV, 2))/x.n, {''}, {'PLV'});

% -- calculate circular mean phase
cdata_group = nin_function(cdata_group, @(x) circ_mean(deg2rad((abs(x(2, :))))'), {'data'}, {'MEAN'});
cdata_group = nin_function(cdata_group, @(x) rad2deg(x), {'MEAN'}, {'MEANdeg'});

% -- express phases as phase leads
kp = 1;
while kp <= size(cdata_group, 2)

    if cdata_group(kp).MEANdeg > 0

        cdata_group(kp).MEANdeg = -1*(360 - cdata_group(kp).MEANdeg);

    end

    kp = kp + 1;

end

% -- organize optimal phase and PLV estimates
cphase_100_i = zeros(length(ufreqc), length(npeaks));
cphase_120_i = zeros(length(ufreqc), length(npeaks));
cR_100_i = zeros(length(ufreqc), length(npeaks));
cR_120_i = zeros(length(ufreqc), length(npeaks));

kf = 1;
while  kf <= length(ufreqc)

    kp = 1;
    while kp <= length(npeaks)

        % -- extract individual optimal phase and PLV at 100% RMT
        [cdata, ix] = nin_subselect_dstruct(cdata_group, 'pro_name', pro_name{1}, 'tfreq', ufreqc{kf}, 'name', [npeaks{kp}, '_amp']);
        cphase_100_i(kf, kp) = cdata.MEANdeg;
        cPLV_100_s(kf, kp) = cdata.PLV;

        % -- extract individual optimal phase and PLV at 120% RMT
        [cdata, ix] = nin_subselect_dstruct(cdata_group, 'pro_name', pro_name{2}, 'tfreq', ufreqc{kf}, 'name', [npeaks{kp}, '_amp']);
        cphase_120_i(kf, kp) = cdata.MEANdeg;
        cPLV_120_s(kf, kp) = cdata.PLV;

        kp = kp + 1;

    end

    kf = kf + 1;

end

% -- define figure settings
fW = 8.5;
fH = fW*0.75;
% fFont = 'Helvetica';
fFont = 'Ariel';
fFontSize = 9;
fFontSizeTick = 8;
fFontSizeSTitle = 10;
fFontSizeTitle = 11;
fFontWeight = 'bold';
fFontWeightTick = 'normal';
lineWidth = 1.25;
axesLineWidth = 0.75;
markerSize = 2;
alphaerrorBand = 0.2;
alphafreqHighlight = 0.25;

% -- create polar plot of optimal phase
h = figure('Units', 'centimeters', 'Position', [2, 2, fW, fH], 'Color', [1 1 1]);

% -- select example peak and frequency
k1 = strcmpi(npeaks, 'P25');
k2 = strcmpi(freq, '28');

% -- prepare individual optimal phase vector
theta_s = [deg2rad(abs(cphase_100_i(k2, k1))); deg2rad(abs(cphase_100_i(k2, k1)))];
ro_s = [0; cPLV_100_s(k2, k1)];

% -- prepare group optimal phase vector
theta = [deg2rad(abs(cphase_100(k2, k1))); deg2rad(abs(cphase_100(k2, k1)))];
ro = [0; 0.5];

% -- plot individual and group optimal phases
c(1) = polarplot(theta_s, ro_s);
ax(1) = gca;
hold on;
c(2) = polarplot(theta, ro);

% -- mark vector endpoints
c(3) = polarplot(theta_s(2), ro_s(2), 'Marker',  'o', 'MarkerSize', markerSize);
c(4) = polarplot(theta(2), ro(2), 'Marker',  'o', 'MarkerSize', markerSize);

% -- format individual phase vector
c(1).LineWidth = lineWidth;
c(2).LineWidth = lineWidth;
c(1).Color = [0.90 0.60 0.00];
c(2).Color = [0.00 0.45 0.70];
c(3).Color = [0.90 0.60 0.00];
c(4).Color = [0.00 0.45 0.70];
c(3).MarkerFaceColor = [0.90 0.60 0.00];
c(4).MarkerFaceColor = [0.00 0.45 0.70];

% -- format polar axes
ax(1).FontName = fFont;
ax(1).FontSize = fFontSizeTick;
ax(1).FontWeight = fFontWeightTick;
ax(1).RLim = [0 0.8];

% -- remove radial labels
rleb = ax(1).RTickLabel;
ax(1).RTickLabel = repmat({''}, size(rleb));

% -- simplify phase labels
ax(1).ThetaTick = 0:22.5:337.5;
tleb = ax(1).ThetaTickLabel;
tleb(2:2:end) = {''};
ax(1).ThetaTickLabel = tleb;
ax(1).LineWidth = axesLineWidth;

% -- add title and legend
title([npeaks{k1}, ' at ', freq{k2}, 'Hz'],...
    'FontName', fFont, ...
    'FontSize', fFontSizeTitle, ...
    'FontWeight', fFontWeight, ...
    'interpreter', 'none');

text(-0.291346031246763, 0.18985139104453, 'Optimal Phase (\circ)', 'FontSize', fFontSizeSTitle, 'Rotation', 90, 'Units', 'normalized')
l = legend('Individual', 'Group', 'box', 'off');
l.FontName = fFont;
l.FontSize = fFontSizeTick;
l.Position = [0.73921187515944, 0.846333903154189, 0.252799994897842, 0.146055433033372];

% -- save figure
if pout.saveWork
    saveas(h, [pout.path_out, 'Figure_6_OptimalPhase.fig']);
    exportgraphics(h, [pout.path_out, 'Figure_6_OptimalPhase.tiff'], 'Resolution', 300);
end
close(h);
