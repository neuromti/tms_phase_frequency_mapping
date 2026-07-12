function [EEG] = nin_re_ref(EEG, varargin)

%% This function re-references eeg data
%
% - input:
% EEG: input structure organised as EEGLAB structure
%
% - optional:
% method: re-referencing method (default: 'avg')
%
% - example:
% EEG = nin_re_ref(EEG);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define re-referencing method
if ~exist('method', 'var')
    method =  'avg';
end

% -- apply re-referencing
switch method

    case 'avg'

        % -- apply average reference
        EEG.data = EEG.data - mean(EEG.data, 1);

end

end

