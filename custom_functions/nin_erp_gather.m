function [y] = nin_erp_gather(x, varargin)

%% This function calculates ERP averages across phases and frequencies
%
% - input:
% x: input structure containing epoched data
%
% - optional:
% method: method for gruping ERP data (default: 'phase_and_freq')
% group_fields: read help for nin_group_data (default: {'data'})
% group_keys: read help for nin_group_data (default: {'sub'})
% fphase: subselect phases (default: [])
% ffreq: subselect freq (default: [])
% out_method: original/const_freq/const_phase/all/keep_all - what to be kept in outot structure (default: keep_all)
%
% - example:
% y  = nin_erp_gather(edata);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define grouping method
if ~exist('method', 'var')
    method = 'phase_and_freq';
end

% -- define fields used for averaging
if ~exist('group_fields', 'var')
    group_fields = {'data'};
end

% -- define grouping variables
if ~exist('group_keys', 'var')
    group_keys = {'sub'};
end

% -- convert frequencies to numeric values
if ischar(x(1).tfreq)
    tfreq = cellfun(@str2num, {x.tfreq}, 'un', 0);
    [x.tfreq] = tfreq{:};
end

% -- convert phases to numeric values
if ischar(x(1).tphase)
    tphase = cellfun(@str2num, {x.tphase}, 'un', 0);
    [x.tphase] = tphase{:};
end

% -- define selected phases
if ~exist('fphase', 'var')
    fphase = [];
end

% -- define selected frequencies
if ~exist('ffreq', 'var')
    ffreq = [];
end

% -- define output mode
if ~exist('out_method', 'var')
    out_method = 'keep_all';
end

%% -- aggregate data according to selected method

switch method

    case 'phase_and_freq'

        % -- extract available frequencies
        cfreq = unique([x.tfreq])';

        % -- keep selected frequencies
        if ~isempty(ffreq)
            cfreq = intersect(cfreq, ffreq);
            cfreq = cfreq(~isnan(cfreq));
        end

        % -- extract available phases
        cphase = unique([x.tphase])';

        % -- keep selected phases
        if ~isempty(fphase)
            cphase = intersect(cphase, fphase);
            cphase = cphase(~isnan(cphase));
        end

        % -- define frequency-phase combinations
        pf = [];
        switch out_method

            case 'original'

                % -- keep individual frequency-phase combinations
                pf = cellfun(@num2str, num2cell(allcomb(cfreq, cphase)), 'un', 0);

            case 'const_freq'

                % -- average across phases
                pf = [cellfun(@num2str, num2cell(cfreq), 'un', 0), repmat({'all'}, length(cfreq), 1)];

            case 'const_phase'

                % -- average across frequencies
                pf = [repmat({'all'}, length(cphase), 1), cellfun(@num2str, num2cell(cphase), 'un', 0)];

            case 'all'

                % -- average across all conditions
                pf = {'all', 'all'};

            case 'keep_all'

                % -- include all aggregation levels
                pf = cellfun(@num2str, num2cell(allcomb(cfreq, cphase)), 'un', 0);
                pf = [pf; [repmat({'all'}, length(cphase), 1), cellfun(@num2str, num2cell(cphase), 'un', 0)]];
                pf = [pf; [cellfun(@num2str, num2cell(cfreq), 'un', 0), repmat({'all'}, length(cfreq), 1)]];
                pf = [pf; {'all', 'all'}];

        end

        %% -- compute erp statistics for each condition

        y = [];
        k = 1;
        while k <= size(pf, 1)

            % -- select data for current frequency-phase combination
            if  strcmpi(pf{k, 1}, 'all') && strcmpi(pf{k, 2}, 'all')
                cdata = x;
            elseif strcmpi(pf{k, 1}, 'all') && ~strcmpi(pf{k, 2}, 'all')
                cdata = nin_subselect_dstruct(x, 'tphase', pf{k, 2});
            elseif ~strcmpi(pf{k, 1}, 'all') && strcmpi(pf{k, 2}, 'all')
                cdata = nin_subselect_dstruct(x, 'tfreq', pf{k, 1});
            else
                cdata = nin_subselect_dstruct(x, 'tfreq', pf{k, 1}, 'tphase', pf{k, 2});
            end

            if ~isempty(cdata)

                % -- group data by subject
                mdata = nin_group_data(cdata, group_fields, group_keys);

                if size(mdata.data, 1) ~= 1 && size(mdata.data, 2) ~= 1

                    % -- calculate number of total epochs and number of clean epochs
                    mdata = nin_function(mdata, {@(x) isnan(x), @(x) any(x, 1), @(x) any(x, 2)}, {'data', 'N', 'N'}, {'N', 'N', 'N'});
                    [mdata.n] = mdata.N;
                    mdata = nin_function(mdata, {@(x) length(x), @(x) length(x) - nnz(x)}, {'N', 'n'}, {'N', 'n'});

                    % -- calculate mean, std and sem of data
                    mdata = nin_function(mdata, {@(x) nanmean(x, 3), @(x) nanstd(x, [], 3), @(x) x.dataSTD/x.n}, {'data', 'data', ''}, {'dataMEAN', 'dataSTD', 'dataSEM'});

                else

                    % -- calculate number of total epochs and number of clean epochs
                    mdata = nin_function(mdata, @(x) isnan(x), {'data'}, {'N'});
                    [mdata.n] = mdata.N;
                    mdata = nin_function(mdata, {@(x) length(x), @(x) length(x) - nnz(x)}, {'N', 'n'}, {'N', 'n'});

                    % -- calculate mean, std and sem of data
                    mdata = nin_function(mdata, {@(x) nanmean(x, 1), @(x) nanstd(x, [], 1), @(x) x.dataSTD/x.n}, {'data', 'data', ''}, {'dataMEAN', 'dataSTD', 'dataSEM'});

                end

                % -- store metadata
                [mdata.data_rows] = deal(cdata(1).data_rows);
                [mdata.data_columns] = deal(cellfun(@num2str, num2cell(cdata(1).time), 'un', 0));
                [mdata.unit] = deal(cdata(1).unit);
                [mdata.tfreq] = deal(pf{k, 1});
                [mdata.tphase] = deal(pf{k, 2});

                % -- remove raw epoch data
                mdata = rmfield(mdata, 'data');

            else

                % -- create empty output structure
                [mdata.(group_keys{1, 1})] = deal(x(1).(group_keys{1, 1}));
                [mdata.N] = deal(0);
                [mdata.n] = deal(0);
                [mdata.dataMEAN] = deal(NaN(size(x(1).data, 1), size(x(1).data, 2)));
                [mdata.dataSTD] = deal(NaN(size(x(1).data, 1), size(x(1).data, 2)));
                [mdata.dataSEM] = deal(NaN(size(x(1).data, 1), size(x(1).data, 2)));
                [mdata.data_rows] = deal(x(1).data_rows);
                [mdata.data_columns] = deal(cellfun(@num2str, num2cell(x(1).time), 'un', 0));
                [mdata.unit] = deal(x(1).unit);
                [mdata.tfreq] = deal(pf{k, 1});
                [mdata.tphase] = deal(pf{k, 2});

            end

            % -- append results to output structure
            y = [y; mdata];

            clear mdata

            k = k + 1;

        end

end

end
