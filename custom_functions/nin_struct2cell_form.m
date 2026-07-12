function [y] = nin_struct2cell_form(x, varargin)

%% This function extracts converts matrix data into a flat structure or cell format
%
% - inputs:
% x: input data structure
%
% - optional:
% fieldOrder: stable/sorted metadata field ordering (default: 'stable')
% match_case: exact/partial matching mode for row and column selection (default: 'exact')
% smeta: metadata fields to retain (default: all meta fields)
% srows: selected data rows (default: all rows)
% scolumns: selected data columns (default: all columns)
% otype: struct/cell type of output (default: 'struct')
%
% - example:
% [y] = nin_struct2cell_form(x, {'data', 'data_rows', 'data_columns'});
% [y] = nin_struct2cell_form(x, {'data', 'data_rows', 'data_columns'}, 'match_case', 'partial');
% [y] = nin_struct2cell_form(cpsd, 'srows', eegs.channels, 'scolumns', cellfun(@num2str, num2cell(1:40), 'un', 0), 'otype', 'cell');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define output format
if ~exist('otype', 'var')
    otype = 'struct';
end

% -- define metadata ordering
if ~exist('fieldOrder', 'var')
    fieldOrder = 'stable';
end

% -- define matching mode
if ~exist('match_case', 'var')
    match_case = 'exact';
end

% -- define metadata fields to retain
if ~exist('smeta', 'var')
    smeta = setdiff(fieldnames(x), {'data', 'data_rows', 'data_columns'}, fieldOrder);
else
    if iscell(smeta)
        if isempty(smeta{1, 1})
            toremove = setdiff(fieldnames(x), {'data', 'data_rows', 'data_columns'}, fieldOrder);
            smeta = setdiff(fieldnames(x), {'data', 'data_rows', 'data_columns'}, fieldOrder);
        end
    else
        toremove = setdiff(fieldnames(x), {'data', 'data_rows', 'data_columns'}, fieldOrder);
        smeta = setdiff(fieldnames(x), {'data', 'data_rows', 'data_columns'}, fieldOrder);
    end
end

% -- convert row labels to strings
if isnumeric(x(1).data_rows{1, 1})
    crows = cellfun(@num2str, x(1).data_rows, 'un', 0);
else
    crows = x(1).data_rows;
end

% -- identify selected rows
if ~exist('srows', 'var')
    ixr = 1:length(crows);
else
    ixr = false(1, length(crows));
    k = 1;
    while k <= length(ixr)
        switch match_case
            % -- exact row matching
            case 'exact'
                if any(strcmpi(srows, crows{k}))
                    ixr(k) = true;
                end
                % -- partial row matching
            case 'partial'
                ixr = contains(crows, srows);
        end
        k = k + 1;
    end
end
% -- store selected row labels
srows = crows(ixr);

% -- convert column labels to strings
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- identify selected columns
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
% -- store selected column labels
scolumns = ccolumns(ixc);

%% -- extract data from data field

% -- copy selected metadata fields
cy = nin_subselect_fields(x, smeta);

% -- create flattened variable names
nfields = [];
k = 1;
while k <= length(scolumns)

    % -- combine row and column labels
    nfields = [nfields, strcat(srows, '_', scolumns{k})];

    k = k + 1;

end

% -- convert matrix data to single-feature representation
k = 1;
while k <= length(cy)

    % -- extract selected data
    cdata = x(k).data(ixr, ixc);
    % -- flatten matrix into vector
    cdata = reshape(cdata, 1, size(cdata, 1)*size(cdata, 2));

    k2 = 1;
    while k2 <= length(nfields)
        % -- store feature value
        cy(k).(nfields{k2}) = cdata(k2);
        k2 = k2 + 1;
    end

    k = k + 1;

end

% -- remove meta data if it is needed
if exist('toremove', 'var')
    cy = rmfield(cy, toremove);
end

%% -- create output

switch otype
    case 'struct'
        y = cy;
    case 'cell'
        y = [fieldnames(cy)'; table2cell(struct2table(cy))];
end

end
