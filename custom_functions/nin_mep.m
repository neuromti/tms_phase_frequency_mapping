function [y] = nin_mep(x, stimuli, varargin)

%%  This function should be used for extracting MEP
%
% - input:
% x: input structure created after pulling, field eeg
% stimuli: array of samples when stimuly happened
%
% - optional:
% fs: samplyng frequency (default: 1000)
% win: time window for MEP detection in sec (default: 1)
% rtransform: results transformation (default: '')
%
% - example:
% psd  = nin_mep(rdata.eeg, [q.time]);

% -- read input parameters
nin_import_params(varargin);

% -- sampling frequency
if ~exist('fs', 'var')
    fs = 1000;
end

% -- window for extracting MEP
if ~exist('win', 'var')
    win = 1;
end

% -- window log output results
if ~exist('rtransform', 'var')
    rtransform = '';
end

eegsys = nin_eeg_system('BrainVision');

%% -- calculate peak to peak

k = 1;
cy = NaN(length(stimuli), length(eegsys.ix_channels_emg));
while k <= length(stimuli)
    
    cdata = x.data(eegsys.ix_channels_emg, stimuli(k):stimuli(k)+fs*win-1);
    cy(k, :) = peak2peak(cdata, 2)';
    
    k = k+1;
    
end

switch rtransform
    
    case 'log'
        
        cy = log(cy);
        
    case ''
        
end

% -- add stimuly
if size(stimuli, 1) == 1
    stimuli = stimuli';
end

cy = [stimuli, cy];

% -- export dat in structure form
fnames = [{'sample'}, strcat('MEP_', eegsys.channels_emg)];
y = cell2struct(num2cell(cy), fnames, 2);

end

