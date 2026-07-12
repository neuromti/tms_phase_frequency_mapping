function [y] = nin_group_data(x, ofields, keys, varargin)

%% This function groups structure entries according to selected key fields
%
% - input:
% x: structure containing input data
% ofields: fields to be grouped
% keys: fields used for grouping
%
% - optional:
% match_case: matching mode for row and column selection: 'exact' or 'partial' (default: 'exact')
%
% - example:
% [y] = nin_group_data(x, {'data', 'logVpp'}, {'sub'})

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- ensure that ofields is a cell array
if ~iscell(ofields)
    ofields = {ofields};
end

% -- ensure that keys is a cell array
if ~iscell(keys)
    keys = {keys};
end

% -- define field matching method
if ~exist('match', 'var')
    match = 'partial';
end


%% -- generate  key combination

key_val = cell(length(keys), 1);
k = 1;
while k <= length(keys)

    % -- extract unique values for each grouping key
    cfield = {x.(keys{k})};

    % -- convert numeric values to strings
    if isnumeric(cfield{1, 1})
        cfield = cellfun(@num2str, cfield, 'un', 0);
    end

    key_val{k} = unique(cfield, 'stable');

    k = k + 1;

end

% -- create all possible key combinations
key_val = allcomb(key_val{:});

% -- build selection criteria for each combination
key_selection = cell(size(key_val, 1), 2*size(key_val, 2));
k1 = 1;
while k1 <= size(key_selection, 1)
    k2 = 0;
    while k2 < size(key_val, 2)
        key_selection(k1, 2*k2+1) = keys(k2+1);
        key_selection(k1, 2*k2+2) = key_val(k1, k2+1);
        k2 = k2 + 1;
    end
    k1 = k1 + 1;
end

% -- group data by key combinations
tokeep = [keys, ofields];

k1 = 1;
s = 1;
while k1 <= size(key_selection, 1)

    % -- select entries matching current key combination
    cx = nin_subselect_dstruct(x, key_selection{k1, :});

    if ~isempty(cx)

        k2 = 1;
        while k2 <= length(tokeep)

            % -- process grouping fields
            switch match

                case 'partial'

                    match_flag = any(contains(keys, tokeep{k2}));

                case 'exact'

                    match_flag = any(strcmpi(keys, tokeep{k2}));

            end

            % -- copy grouping key values
            if match_flag

                y(s).(tokeep{k2}) = cx(1).(tokeep{k2});

            else

                % -- concatenate grouped data
                [m, n, z] = size(cx(1).(tokeep{k2}));

                % -- group 2D matrices
                if m > 1 && n >1
                    if iscell(cx(1).(tokeep{k2}))
                        cdata = cell(m, n, z);
                    else
                        cdata = NaN(m, n, z);
                    end
                    if z == 1
                        k3 = 1;
                        while k3 <= size(cx, 2)
                            cdata(:, :, k3) = cx(k3).(tokeep{k2});
                            k3 = k3 + 1;
                        end
                    else
                        k3 = 1;
                        while k3 <= size(cx, 2)
                            cdata(:, :, :, k3) = cx(k3).(tokeep{k2});
                            k3 = k3 + 1;
                        end
                    end

                    % -- group column vectors
                elseif m > 1 && n == 1
                    if iscell(cx(1).(tokeep{k2}))
                        cdata = cell(m, size(cx, 2));
                    else
                        cdata = NaN(m, size(cx, 2));
                    end
                    k3 = 1;
                    while k3 <= size(cx, 2)
                        cdata(:, k3) = cx(k3).(tokeep{k2});
                        k3 = k3 + 1;
                    end

                    % -- group row vectors or scalars
                elseif m == 1 && n >= 1
                    if iscell(cx(1).(tokeep{k2}))
                        cdata = cell(size(cx, 2), n);
                    else
                        cdata = NaN(size(cx, 2), n);
                    end
                    k3 = 1;
                    while k3 <= size(cx, 2)
                        cdata(k3, :) = cx(k3).(tokeep{k2});
                        k3 = k3 + 1;
                    end
                end

                % -- store grouped data
                y(s).(tokeep{k2}) = cdata;

            end

            k2 = k2 + 1;

        end

        s = s + 1;

    end

    k1 = k1 + 1;

end

end

