function [y, ix] = nin_subselect_dstruct(x, varargin)

%% This function selects structure elements according to field values
%
% - inputs:
% x: data structure
% varargin: field-value selection pairs
%
% - optional:
% match_case: exact/partial matching mode (default: 'exact')
%
% - example:
% [y] = nin_subselect_dstruct(emg, 'recording', 'LuLi01');
% [y] = nin_subselect_dstruct(emg, 'recording', 'LuLi01', 'match_case', 'partial');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define matching mode
if ~any(strcmpi(varargin, 'match_case'))
    match_case = 'exact';
else
    % -- extract matching mode from input arguments
    ix = find(strcmpi(varargin, 'match_case'));
    match_case = varargin{ix + 1};

    % -- remove matching arguments from selection criteria
    ix_new = true(1, length(varargin));
    ix_new(1, ix:ix+1) = false;
    varargin = varargin(ix_new);
end

% -- verify selection criteria
if isempty(varargin)
    error('Criteria for filtering is not defined.')
end

%% -- select structure elements

% -- initialize output structure
y = x;
k = 1;
while k <= length(varargin)

    % -- extract current field values
    cdata = {y.(varargin{k})};

    % -- convert numeric values to strings
    if any(cell2mat(cellfun(@isnumeric, cdata, 'un', 0)))
        cdata = cellfun(@num2str, cdata, 'un', 0);
    end

    % -- identify matching entries
    switch match_case

        % -- exact matching
        case 'exact'

            k1 = 1;
            ix = false(1, length(cdata));
            while k1 <= length(cdata)
                if strcmpi(cdata{k1}, varargin{k + 1})
                    ix(k1) = true;
                end
                k1 = k1 + 1;
            end

            % -- partial matching
        case 'partial'

            ix = contains(cdata, varargin{k + 1});

    end

    % -- update filtered structure
    y = y(ix);

    k = k + 2;

end

%% -- create logical index for original structure2 

ix = true(size(x, 2), 1);
k = 1;
while k <= length(varargin)

    % -- extract original field values
    cdata = {x.(varargin{k})}';

    % -- convert numeric values to strings
    if isnumeric(cdata{1})
        cdata = cellfun(@num2str, cdata, 'un', 0);
    end

    % -- update selection mask
    ix = ix & strcmpi(cdata, varargin{k + 1});

    k = k + 2;

end

end