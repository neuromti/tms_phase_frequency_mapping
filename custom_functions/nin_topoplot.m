function [h] = nin_topoplot(x, stats, varargin)

%% This function visualizes data using eeg scalp topographies
%
% - inputs:
% x: data structure
% stats: statistical results structure (p should be the same size as data and the same order). Could be empty if stat is not needed []
%
% - optional:
% eegsys: eegsystem used for data recording (default: 'BrainVision')
% match_case: exact/partial column matching mode (default: 'exact')
% p_th: significance threshold (default: 0.05)
% crange: color scale limits (default: 'absmax')
% display_sp: true/false display data in subplots or just one figure (default: false)
% sp: subplot layout (default: [4 4])
% mymarkersize: electrode marker size (default: 12)
% mymarkersize2: significant electrode marker size (default: 14)
% fonts: title font size (default: 10)
%
% - example:
% [h] = nin_topoplot(R, R.stats.anova);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define eeg recording system
if ~exist('eegsys', 'var')
    eegsys = 'BrainVision';
end

% -- define matching mode
if ~exist('match_case', 'var')
    match_case = 'exact';
end

% -- define significance threshold
if ~exist('p_th', 'var')
    p_th = 0.05;
end

% -- define title font size
if ~exist('fonts', 'var')
    fonts = 10;
end

% -- define colorbar font size
if ~exist('fontsbar', 'var')
    fontsbar = [];
end

% -- define color scale limits
if ~exist('crange', 'var')
    crange = 'absmax';
end
if ~iscell(crange)
    crange = {crange};
end

% -- define display mode
if ~exist('display_sp', 'var')
    display_sp = false;
end

% -- define subplot layout
if ~exist('sp', 'var')
    sp = [4, 4];
end

% -- define electrode marker sizes
if ~exist('mymarkersize', 'var')
    mymarkersize = 6;
end

% -- marker size significan ch
if ~exist('mymarkersize2', 'var')
    mymarkersize2 = 8;
end

% -- define topography style
if ~exist('map_style', 'var')
    map_style = 'normal';
end

% -- load eeg montage information
eegsystem = nin_eeg_system(eegsys);

% -- convert column labels to strings
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- find selected data columns
if ~exist('scolumns', 'var')
    ixc = 1:length(ccolumns);
else
    ixc = false(1, length(ccolumns));
    k = 1;
    while k <= length(ixc)
        switch match_case
            % -- exact column matching
            case 'exact'
                if any(strcmpi(scolumns, ccolumns{k}))
                    ixc(k) = true;
                end
                % -- partial column matching
            case 'partial'
                ixc = contains(ccolumns, scolumns);
        end
        k = k + 1;
    end
end
scolumns = ccolumns(ixc);
ixc = find(ixc);

% -- expand color-scale settings if required
if length(crange) == 1
    crange = repmat(crange, 1, length(scolumns));
    flag_cb = false;
elseif length(crange) < length(scolumns)
    error('Please make sure that no of measures is the same as no of range');
end


%% -- plot data

%% -- create multi-panel topography figure
if display_sp

    if length(scolumns) > sp(1)*sp(2)
        error('Not enough subplots.')
    end

    h = figure('color', [1 1 1], 'name', 'All');

    % -- create topography for each measure
    k = 1;
    while k <= length(scolumns)

        subplot(sp(1), sp(2), k);
        if ~isempty(stats)
            % -- display significant electrodes
            if size(stats.p, 1) == length(eegsystem.ix_channels)
                topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.p(:, ixc(k))' < p_th), 'o', 'k', mymarkersize2, 1});
            else
                % -- draw scalp topography
                topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.p(ixc(k), :) < p_th), 'o', 'k', mymarkersize2, 1});
            end
        else
            topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1});
        end
        % -- add color scale
        if flag_cb
            colorbar;
        else
            if k == length(scolumns)
                cb = colorbar;
                cb.Position = [0.93,0.30,0.02,0.45];
                if ~isempty(fontsbar)
                    cb.FontSize = fontsbar;
                end
            end
        end
        % -- add subplot title
        title(scolumns{k}, 'fontsize', fonts, 'fontweight', 'bold', 'interpreter', 'none');

        k = k + 1;
    end

    set(gcf, 'color', [1 1 1]);

else

    %% -- create separate figures
    k = 1;
    while k <= length(scolumns)

        % -- create figure for current measure
        h(k) = figure('color', [1 1 1], 'name', scolumns{k});

        % -- select visualization style
        switch map_style

            % -- display standard scalp map
            case 'normal'

                if ~isempty(stats)
                    % -- highlight significant electrodes
                    if size(stats.p, 1) == length(eegsystem.ix_channels)
                        topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.p(:, ixc(k))' < p_th), 'o', 'k', mymarkersize2, 1});
                    else
                        topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.p(ixc(k), :) < p_th), 'o', 'k', mymarkersize2, 1});
                    end
                else
                    topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1});
                end
                % -- display color scale
                colorbar;

                % -- display significance-only scalp map
            case 'blank'

                if ~isempty(stats)
                    if size(stats.p, 1) == length(eegsystem.ix_channels)
                        ix_1 = stats.p(:, ixc(k))' <= 0.05;
                        ix_2 = stats.p(:, ixc(k))' <= 0.001;
                    else
                        ix_1 = stats.p(ixc(k), :) <= 0.05;
                        ix_2 = stats.p(ixc(k), :) <= 0.001;
                    end
                    topoplot(ones(size(x.data(:, ixc(k)), 1), 1)*0.05, eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(ix_1), 'o', rgb('orange'), mymarkersize2, 1});
                    topoplot(ones(size(x.data(:, ixc(k)), 1), 1)*0.05, eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(ix_2), 'o', 'r', mymarkersize2, 1});
                    text([0.1 0.1], [0.01 0.01], 'orange: p <= 0.05, red: p <= 0.001', 'units', 'normalized', 'fontsize', fonts, 'fontweight', 'bold');
                else
                    topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'style', 'blank');
                end

                % -- display cluster-based significance mask
            case 'pmask'

                if size(stats.p, 1) == length(eegsystem.ix_channels)
                    topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.mask(:, ixc(k))' == 1), 'o', 'k', mymarkersize2, 1});
                else
                    topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'emarker2', {eegsystem.ix_channels(stats.mask(:, ixc(k)) == 1), 'o', 'k', mymarkersize2, 1});
                end
                % -- apply significance mask to topography
                topoplot(x.data(:, ixc(k)), eegsystem.Channel_Location(eegsystem.ix_channels), 'maplimits', crange{k}, 'electrodes', 'on', 'emarker', {'.', 'k', mymarkersize, 1}, 'pmask', stats.mask(:, ixc(k)));
                colorbar;

        end

        % -- add figure title
        sgtitle(scolumns{k}, 'fontsize', fonts, 'fontweight', 'bold', 'interpreter', 'none');

        % -- format figure background
        set(gcf, 'color', [1 1 1]);

        k = k + 1;

    end

end

end
