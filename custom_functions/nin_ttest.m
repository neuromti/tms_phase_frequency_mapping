function [z] = nin_ttest(x, y, varargin)

%% This function performs one-sample or paired t-tests
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
%
% - example:
% [y] = nin_ttest(R);

% -- read input parameters
nin_import_params(varargin);

% -- initialize comparison dataset
if nargin < 2

    y = [];

end

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

% -- identify selected columns and rows
if ~exist('srowscolumns', 'var')

    % -- find selected data rows
    if ~exist('srows', 'var')
        ixr = 1:length(crows);
    else
        ixr = false(1, length(crows));
        k = 1;
        while k <= length(ixr)
            switch match_case
                % -- exact matching
                case 'exact'
                    if any(strcmpi(srows, crows{k}))
                        ixr(k) = true;
                    end
                    % -- partial matching
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
                % -- exact matching
                case 'exact'
                    if any(strcmpi(scolumns, ccolumns{k}))
                        ixc(k) = true;
                    end
                    % -- partial matching
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
            % -- exact matching
            case 'exact'
                if any(strcmpi(srows, crows{k}))
                    ixr(k) = true;
                end
                % -- partial matching
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
            % -- exact matching
            case 'exact'
                if any(strcmpi(scolumns, ccolumns{k}))
                    ixc(k) = true;
                end
                % -- partial matching
            case 'partial'
                ixc = contains(ccolumns, scolumns);
        end
        k = k + 1;
    end
    scolumns = ccolumns(ixc);

end

% -- define testing dimension
if ~exist('dim', 'var')
    dim = 2;
end

%% -- perform column-wise t-tests

if dim == 2

    k = 1;
    while k <= length(scolumns)

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);

        % -- convert cell data to numeric values
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract labels
        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        if isempty(y)
            % -- perform one-sample t-test
            [~, p, ci, stats] = ttest(sdata);

            n = size(x);
            ix_x = true(max(n), 1);
            ix_y = [];

        else
            % -- perform paired t-test
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
            % -- extract comparison data
            sdata2 = sdata2(ix_y, :);

            [~, p, ci, stats] = ttest(sdata, sdata2);

        end

        % -- store statistical results
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

    %% -- prepare row-wise analysis

    k = 1;
    while k <= length(srows)

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);
        % -- convert cell data to numeric values
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- extract labels
        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        if isempty(y)
            % -- perform one-sample t-test
            [~, p, ci, stats] = ttest(sdata);

            n = size(x);
            ix_x = true(max(n), 1);
            ix_y = [];

        else
            % -- perform paired t-test
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
            % -- extract comparison data
            sdata2 = sdata2(ix_y, :);

            [~, p, ci, stats] = ttest(sdata, sdata2);

        end

        % -- store statistical results
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

end

end
