function [h] = nin_boxplot(x, varargin)

%% This function creates boxplots with data distribution
%
% - input:
% x: input structure containing data and metadata
%
% - optional:

% match_case: matching mode for row and column selection: 'exact' or 'partial' (default: 'exact')
% spliter: delimiter used by nin_strsplit (default: '_')
% rn1: first row index used by nin_strsplit (default: 1)
% rn2: last row index used by nin_strsplit (default: 1)
% cn1: first column index used by nin_strsplit (default: 2)
% cn2: last column index used by nin_strsplit (default: 2)
% srowscolumns: row-column combinations to plot (default: all)
% srows: selected rows (default: all)
% scolumns: selected columns (default: all)
% dim: plotting dimension (default: 2)
% mycolors: color of bar (default: 'k')
% mymarkersize: scatter marker size (default: 12)
% blinewidth: line width (default: 3)
% fonts: axis font size (default: 10)
% fontm: annotation font size (default: 6)
% mycolorsl: mean line color (default: 'r')
% crange: y-axis limits (default: [0 1])
% sp: subplot arrangement [rows columns] (default: [8 8])
% th_med: median threshold annotation (default: [])
% cylabel:  y-axis label (default: '')
%
% - example:
% [y] = nin_boxplot(R);
% [y] = nin_boxplot(R, 'dim', 1);
% [y] = nin_boxplot(R, 'dim', 1, sp, [1 1]);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define matching mode
if ~exist('match_case', 'var')
    match_case = 'exact';
end

% -- define lower border rows
if ~exist('rn1', 'var')
    rn1 = 1;
end

% -- define upper border rows
if ~exist('rn2', 'var')
    rn2 = 1;
end

% -- define lower border columns
if ~exist('cn1', 'var')
    cn1 = 2;
end

% -- define upper border columns
if ~exist('cn2', 'var')
    cn2 = 2;
end

% -- define spliter
if ~exist('spliter', 'var')
    spliter = '_';
end

% -- convert row identifiers to strings
if isnumeric(x(1).data_rows{1, 1})
    crows = cellfun(@num2str, x(1).data_rows, 'un', 0);
else
    crows = x(1).data_rows;
end

% -- convert column identifiers to strings
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- determine rows and columns for plotting
if ~exist('srowscolumns', 'var')

    % -- find selected rows
    if ~exist('srows', 'var')
        ixr = 1:length(crows);
    else
        ixr = false(1, length(crows));
        k = 1;
        while k <= length(ixr)
            switch match_case
                case 'exact'
                    if any(strcmpi(srows, crows{k}))
                        ixr(k) = true;
                    end
                case 'partial'
                    ixr = contains(crows, srows);
            end
            k = k + 1;
        end
    end
    srows = crows(ixr);

    % -- find selected columns
    if ~exist('scolumns', 'var')
        ixc = 1:length(ccolumns);
    else
        ixc = false(1, length(ccolumns));
        k = 1;
        while k <= length(ixc)
            switch match_case
                case 'exact'
                    if any(strcmpi(scolumns, ccolumns{k}))
                        ixc(k) = true;
                    end
                case 'partial'
                    ixc = contains(ccolumns, scolumns);
            end
            k = k + 1;
        end
    end
    scolumns = ccolumns(ixc);

else

    % -- extract row and column identifiers
    crows = nin_strsplit(ifield, rn1, rn2, 'spliter', spliter);
    ixr = false(1, length(crows));
    k = 1;
    while k <= length(ixr)
        switch match_case
            case 'exact'
                if any(strcmpi(srows, crows{k}))
                    ixr(k) = true;
                end
            case 'partial'
                ixr = contains(crows, srows);
        end
        k = k + 1;
    end
    srows = crows(ixr);

    ccolumns = nin_strsplit(ifield, cn1, cn2, 'spliter', spliter);
    ixc = false(1, length(ccolumns));
    k = 1;
    while k <= length(ixc)
        switch match_case
            case 'exact'
                if any(strcmpi(scolumns, ccolumns{k}))
                    ixc(k) = true;
                end
            case 'partial'
                ixc = contains(ccolumns, scolumns);
        end
        k = k + 1;
    end
    scolumns = ccolumns(ixc);

end

% -- define plotting dimension
if ~exist('dim', 'var')
    dim = 2;
end

% -- define boxplot color
if ~exist('mycolors', 'var')
    mycolors = 'k';
end

% -- define marker size
if ~exist('mymarkersize', 'var')
    mymarkersize = 12;
end

% -- define boxplot line width
if ~exist('blinewidth', 'var')
    blinewidth = 3;
end

% -- define mean line color
if ~exist('mycolorsl', 'var')
    mycolorsl = 'r';
end

% -- define axis font size
if ~exist('fonts', 'var')
    fonts = 10;
end

% -- define annotation font size
if ~exist('fontm', 'var')
    fontm = 6;
end

% -- define y-axis limits
if ~exist('crange', 'var')
    range1 = 0;
    range2 = 1;
else
    if ischar(crange(1))
        if strcmpi(crange, 'minmax')
            % add this
        elseif strcmpi(crange, 'absmax')
            % add this
        end
    else
        range1 = crange(1);
        range2 = crange(2);
    end
end

% -- define subplot layout
if ~exist('sp', 'var')
    sp = [8, 8];
end

% -- define median threshold
if ~exist('th_med', 'var')
    th_med = [];
end

% -- define y-axis label
if ~exist('cylabel', 'var')
    cylabel = '';
end

%% -- plot data

if dim == 2

    % -- columns will be ploted on each figure
    k = 1;
    while k <= length(scolumns)

        % -- plot columns on separate figures
        h(k) = figure('color', [1 1 1], 'name', scolumns{k});

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);

        % -- convert data to numeric format
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract plot labels
        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- generate jitter positions
        m = ones(size(sdata, 1), 1).*(1+(rand(size(sdata, 1), 1)-0.5)/15);

        k2 = 1;
        while k2 <= size(sdata, 2)

            % -- create subplot
            subplot(sp(1), sp(2), k2);

            % -- draw boxplot
            b = boxplot(sdata(:, k2), 'notch', 'on', 'labels', header(k2), 'colors', mycolors);
            for kb = 1:length(b)
                set(b(kb), 'linewidth', blinewidth)
            end

            hold on;

            % -- add individual observations
            s = scatter(m(:,1), sdata(:, k2), mymarkersize, 'k', 'filled');
            s.MarkerFaceAlpha = 0.4;

            % -- draw mean value
            avg = nanmean(sdata(:, k2), 1);
            line([1-0.1 1+0.1],[avg avg], 'linewidth', blinewidth, 'color', mycolorsl);

            % -- annotate median threshold
            if ~isempty(th_med)
                if th_med < median(sdata(:, k2), 1)
                    text([0.01 0.01], [0.8 0.8], ['med > ', num2str(th_med)], 'units', 'normalized', 'fontsize', fontm, 'fontweight', 'bold');
                end
            end

            % -- add y-axis label
            if ~strcmpi(cylabel, '')
                ylabel(cylabel);
            end

            % -- set y-axis limits
            ylim([range1 range2]);

            % -- format axes
            set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

            k2 = k2 + 1;
        end

        % -- add figure title
        sgtitle(scolumns{k}, 'interpreter', 'none');

        k = k + 1;

    end

else

    % -- raw will be ploted on each figure
    k = 1;
    while k <= length(srows)

        % -- plot rows on separate figures
        h(k) = figure('color', [1 1 1], 'name', srows{k});

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);

        % -- convert data to numeric format
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract plot labels
        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- generate jitter positions
        m = ones(size(sdata, 1), 1).*(1+(rand(size(sdata, 1), 1)-0.5)/15);

        k2 = 1;
        while k2 <= size(sdata, 2)

            % -- create subplot
            subplot(sp(1), sp(2), k2);

            % -- draw boxplot
            b = boxplot(sdata(:, k2), 'notch', 'on', 'labels', header(k2), 'colors', mycolors);
            for kb = 1:length(b)
                set(b(kb), 'linewidth', blinewidth)
            end

            hold on;

            % -- add individual observations
            s = scatter(m(:,1), sdata(:, k2), mymarkersize, 'k', 'filled');
            s.MarkerFaceAlpha = 0.4;

            % -- draw mean value
            avg = nanmean(sdata(:, k2), 1);
            line([1-0.1 1+0.1],[avg avg], 'linewidth', blinewidth, 'color', mycolorsl);

            % -- annotate median threshold
            if ~isempty(th_med)
                if th_med < median(sdata(:, k2), 1)
                    text([0.01 0.01], [0.8 0.8], ['med > ', num2str(th_med)], 'units', 'normalized', 'fontsize', fontm, 'fontweight', 'bold');
                end
            end

            % -- add y-axis label
            if ~strcmpi(cylabel, '')
                ylabel(cylabel);
            end

            % -- set y-axis limits
            ylim([range1 range2]);

            % -- format axes
            set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

            k2 = k2 + 1;
        end

        % -- add figure title
        sgtitle(srows{k}, 'interpreter', 'none');

        k = k + 1;

    end

end

end
