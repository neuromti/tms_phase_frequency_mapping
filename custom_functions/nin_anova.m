function [y] = nin_anova(x, varargin)

%% This function performs one-way anova on selected data
%
% - input:
% x: input structure containing data and metadata
%
% - optional:
% match_case: matching mode for row and column selection: 'exact' or 'partial'  (default: 'exact')
% spliter: delimiter used by nin_strsplit (default: '_')
% rn1: first row index used by nin_strsplit (default: 1)
% rn2: last row index used by nin_strsplit (default: 1)
% cn1: first column index used by nin_strsplit (default: 2)
% cn2: last column index used by nin_strsplit (default: 2)
% srowscolumns: row-column combinations to analyze (default: all)
% srows: selected data rows (default: all)
% scolumns: selected data columns (default: all)
% dim: analysis dimension (default: 2)
%
% - example:
% [y] = nin_anova(R);
% [y] = nin_anova(R, 'dim', 1);

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

% -- determine rows and columns for analysis
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

    % --  extract row and column identifiers
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

% --  define analysis dimension
if ~exist('dim', 'var')
    dim = 2;
end

if dim == 2

    % -- perform anova across columns
    k = 1;
    while k <= length(scolumns)

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);

        % -- convert cell data to numeric values
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract group labels
        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- run one-way anova
        [p, tbl, stats] = anova1(sdata,[],'off');

        % -- perform post hoc multiple comparisons
        m = multcompare(stats);

        % -- store statistical results
        y(k).name = scolumns{k};
        y(k).p = p;
        y(k).tbl = tbl;
        y(k).n = stats.n;
        y(k).means = stats.means;
        y(k).df = stats.df;
        y(k).s = stats.s;
        y(k).m = m;

        k = k + 1;

    end

else

    % -- perform anova across rows
    k = 1;
    while k <= length(srows)

        h(k) = figure('color', [1 1 1], 'name', srows{k});

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);

        % -- convert cell data to numeric values
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract group labels
        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        % -- run one-way anova
        [p, tbl, stats] = anova1(sdata,[],'off');

        % -- perform post hoc multiple comparisons
        m = multcompare(stats);

        % -- store statistical results
        y(k).name = scolumns{k};
        y(k).p = p;
        y(k).tbl = tbl;
        y(k).n = stats.n;
        y(k).means = stats.means;
        y(k).df = stats.df;
        y(k).s = stats.s;
        y(k).m = m;

        k = k + 1;

    end

end

end
