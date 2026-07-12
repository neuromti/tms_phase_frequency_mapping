function [y] = nin_session_exclusion(x, key_fields, varargin)

%% This function removes redundant sessions
%
% - inputs:
% x: data structure
% key_fields: fields used for session grouping
%
% - optional:
% method: session selection method (default: 'maxcount')
%
% - example:
% [h] = nin_topoplot(x);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define session selection method
if ~exist('method', 'var')
    method = 'maxcount';
end

%% -- remove redundant sessionsShow more lines

y = [];
switch method

    case 'maxcount'

        % -- group sessions according to selected keys
        mdata = nin_group_data(x, {'N', 'n'}, key_fields);

        % -- identify maximum number of available epochs
        mdata = nin_function(mdata, @(x, y) max(x), {'N'}, {'maxN'});

        % -- identify session with maximum epoch count
        mdata = nin_function(mdata, @(x) find(x.N == x.maxN), '', {'ix_max'});

        % -- retain best session for each group
        k = 1;
        while k <= length(mdata)
            ckey = [];
            k2 = 1;
            while k2 <= length(key_fields)

                % -- convert grouping values to selection format
                if ischar(mdata(k).(key_fields{k2}))
                    ckey = [ckey, key_fields(k2), mdata(k).(key_fields{k2})];
                else
                    ckey = [ckey, key_fields(k2), num2str(mdata(k).(key_fields{k2}))];

                end
                k2 = k2 + 1;
            end

            % -- extract matching sessions
            cdata = nin_subselect_dstruct(x, ckey{:});

            % -- keep session with highest epoch count
            y = [y, cdata(mdata(k).ix_max)];

            k = k + 1;

        end

end

end

