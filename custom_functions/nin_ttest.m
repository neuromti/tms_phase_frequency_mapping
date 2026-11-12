function [z] = nin_ttest(x, y, varargin)

%% Simple box plot with data distribution
%
% - input:
% x: structure with input data
%
% - optional:
% match_case: exact/partial type of subselecting data from data field (default: 'exact')
% spliter: read nin_strsplit (default: '_')
% rn1: read nin_strsplit (default: 1)
% rn2: read nin_strsplit (default: 1)
% cn1: read nin_strsplit (default: 2)
% cn2: read nin_strsplit (default: 2)
% srowscolumns: cell array which combination of row and columns will be plotted (default: all)
% srows: cell array of rows which will be plotted (default: all)
% scolumns: cell array of columns which will be plotted (default: all)
% dim: dimension of data matrix (default: 2)
% dim: dimension of data matrix (default: 2)
%
% - example:
% [y] = nin_anova(R);
% [y] = nin_anova(R, 'dim', 1);

% -- read input parameters
nin_import_params(varargin);

if nargin < 2

    y = [];

end

%% -- set default values

% -- type of matching
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

% -- define lower border rows
if ~exist('cn1', 'var')
    cn1 = 2;
end

% -- define upper border rows
if ~exist('cn2', 'var')
    cn2 = 2;
end

% -- define spliter
if ~exist('spliter', 'var')
    spliter = '_';
end

if ~exist('tail', 'var')
tail = 'both';
end

% -- make sure that values in rows are char
if isnumeric(x(1).data_rows{1, 1})
    crows = cellfun(@num2str, x(1).data_rows, 'un', 0);
else
    crows = x(1).data_rows;
end

% -- make sure that values in columns are char
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- define which rows and colums will be ploted
if ~exist('srowscolumns', 'var')

    % -- find selected data rows
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

    % -- find selected data columns
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

    % -- define inputs row and columns
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

% -- define what is going to be plotted on subplots
if ~exist('dim', 'var')
    dim = 2;
end

if dim == 2

    % -- columns will be extracted
    k = 1;
    while k <= length(scolumns)

        % -- get rid of unwanted data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        if isempty(y)

            [~, p, ci, stats] = ttest(sdata);

            n = size(x);
            ix_x = true(max(n), 1);
            ix_y = [];

        else

            sdata2 = nin_struct2cell_form(y, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);
            sdata2(2:end, :) = cellfun(@double, sdata2(2:end, :), 'un', 0);
            sdata2 = double(cell2mat(sdata2(2:end, :)));

            % -- make sure that data are matched
            [sub, ix_x, ix_y] = intersect({x.sub}, {y.sub});
           
            if length(sub) == 1
                ix_x = strcmpi({x.sub}, sub{1, 1});
                ix_y = strcmpi({y.sub}, sub{1, 1});
            end
            sdata = sdata(ix_x, :);
            sdata2 = sdata2(ix_y, :);

            [~, p, ci, stats] = ttest(sdata, sdata2, 'Tail', tail);

        end

        z(k).name = scolumns{k};
        z(k).p = p;
        z(k).ci = ci;
        z(k).t = stats.tstat;
        z(k).df = stats.df;
        z(k).sd = stats.sd;
        z(k).x = x(ix_x);
        z(k).y = y(ix_y);

        k = k + 1;

    end

else

    % -- raw will be extracted
    k = 1;
    while k <= length(srows)

        h(k) = figure('color', [1 1 1], 'name', srows{k});

        % -- get rid of unwanted data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        k = k + 1;

    end

end

end
