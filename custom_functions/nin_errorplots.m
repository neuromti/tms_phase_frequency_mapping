function [h] = nin_errorplots(x, varargin)

%% This function creates error bar plots with group statistics
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
% blinewidth: line width (default: 3)
% fonts: plot color (default: 10)
% fontm: annotation font size (default: 6)
% mycolorsl: fitting line color (default: 'r')
% cyrange: y-axis limits (default: [0 1])
% cxrange: x-axis limits (default: [-0.5 6])
% fmethod: fitting method (default: cos)
% cylabel: y-axis label (default: '')
% cxlabel: x-axis label (default: '')
% xx: x-axis values (default: [0:45:315] in rad)
%
% - example:
% [y] = nin_errorplots(R);
% [y] = nin_errorplots(R, 'dim', 1);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define type of matching
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

% -- define lower border colimns
if ~exist('cn1', 'var')
    cn1 = 2;
end

% -- define upper border columns
if ~exist('cn2', 'var')
    cn2 = 2;
end

% -- define delimiter
if ~exist('spliter', 'var')
    spliter = '_';
end

% -- convert row labels to strings
if isnumeric(x(1).data_rows{1, 1})
    crows = cellfun(@num2str, x(1).data_rows, 'un', 0);
else
    crows = x(1).data_rows;
end

% -- convert column labels to strings
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

% -- define plot color
if ~exist('mycolors', 'var')
    mycolors = 'k';
end

% -- define line width
if ~exist('blinewidth', 'var')
    blinewidth = 3;
end

% -- define fitting line color
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
    if ~isempty(crange)
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
end

% -- define x-axis limits
if ~exist('cxrange', 'var')
    xrange1 = -0.5;
    xrange2 = 6;
else
    if ~isempty(cxrange)
        if ischar(crange(1))
            if strcmpi(crange, 'minmax')
                % add this
            elseif strcmpi(crange, 'absmax')
                % add this
            end
        else
            xrange1 = cxrange(1);
            xrange2 = cxrange(2);
        end
    end
end

% -- define y-axis label
if ~exist('cylabel', 'var')
    cylabel = '';
end

% -- define x-axis label
if ~exist('cxlabel', 'var')
    cxlabel = '';
end

% -- define x-axis values
if ~exist('xx', 'var')
    xx = [0:45*3.14/180:315*3.14/180];
end

%% -- plot data

if dim == 2

    % -- plot selected columns
    k = 1;
    while k <= length(scolumns)

        h(k) = figure('color', [1 1 1], 'name', scolumns{k});

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract plot labels
        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- calculate mean values
        avg = nanmean(sdata, 1);
        % -- calculate standard error of the mean
        sem = nanstd(sdata, 1)./sqrt(sum(~isnan(sdata), 1));

        errorbar(xx, avg, sem, 'linestyle', 'none', 'marker', 'o', 'color', mycolors, 'linewidth', blinewidth);
        % -- format x-axis
        set(gca, 'xtick', xx);
        xlim([xrange1, xrange2]);
        set(gca, 'xticklabel', cellfun(@num2str, num2cell(round(rad2deg(xx))), 'un', 0));
        % -- enable grid
        grid;

        % -- add y-axis label
        if ~strcmpi(cylabel, '')
            ylabel(cylabel);
        end

        % -- add x-axis label
        if ~strcmpi(cxlabel, '')
            xlabel(cxlabel);
        end

        % -- set y-axis limits
        if ~isempty(crange)
            ylim([range1 range2]);
        end

        % -- format axes
        set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

        % -- add figure title
        sgtitle(scolumns{k}, 'interpreter', 'none');

        k = k + 1;

    end

else

    % -- plot selected rows
    k = 1;
    while k <= length(srows)

        h(k) = figure('color', [1 1 1], 'name', srows{k});

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract plot labels
        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- calculate mean values
        avg = nanmean(sdata, 1);
        % -- calculate standard error of the mean
        sem = nanstd(sdata, 1)./sqrt(sum(~isnan(sdata), 1));

        errorbar(xx, avg, sem, 'linestyle', 'none', 'marker', 'o', 'color', mycolors, 'linewidth', blinewidth);
        % -- format x-axis
        set(gca, 'xtick', xx);
        xlim([xrange1, xrange2]);
        set(gca, 'xticklabel', cellfun(@num2str, num2cell(round(rad2deg(xx))), 'un', 0));
        % -- enable grid
        grid;

        % -- add y-axis label
        if ~strcmpi(cylabel, '')
            ylabel(cylabel);
        end

        % -- add x-axis label
        if ~strcmpi(cxlabel, '')
            xlabel(cxlabel);
        end

        % -- set y-axis limits
        if ~isempty(crange)
            ylim([range1 range2]);
        end

        % -- format axes
        set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

        % -- add figure title
        sgtitle(scolumns{k}, 'interpreter', 'none');

        k = k + 1;

    end

end

end
