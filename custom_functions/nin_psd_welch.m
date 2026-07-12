function [y] = nin_psd_welch(x, eeg, varargin)

%% This function calculates power spectral density using welch's method
%
% - input:
% x: input structure created after date data cleaning/epoching
% eeg: eeg system definition
%
% - optional:
% for details see help pwelch
% win: (default: 5)
% overlap: (default: [])
% f: (default: f)
% fs: (default: fs)
% fmax: maximum frequency to extract (default: fmax)
%
% - example:
% psd  = nin_psd_welch(edata, nin_eeg_system('BrainVision'));

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define window length
if ~exist('win', 'var')
    win = 1000; % 1000 samples
end

% -- define window overlap
if ~exist('overlap', 'var')
    overlap = []; % 50%
end

% -- define sampling frequency
if ~exist('fs', 'var')
    fs = 1000;
end

% -- define fft length
if ~exist('f', 'var')
    f = fs;
end

% -- define frequency range
if ~exist('fmax', 'var')
    fmax = 2:61; % 1-60Hz
else
    fmax = 2:1+fmax; % 1-60Hz
end

%% -- calculate PSD

% -- define output structure
y = x;

% -- initialize psd matrices
cdata = NaN(eeg.nochannels, length(fmax));
cci_lower = NaN(eeg.nochannels, length(fmax));
cci_upper = NaN(eeg.nochannels, length(fmax));
% -- preallocate output fields
k = 1;
while k <= length(x)
    y(k).data = cdata;
    y(k).data_rows = eeg.channels;
    y(k).data_columns = cell(1, f/2 + 1);
    y(k).unit = repmat({'mV^2/Hz'}, 1, eeg.nochannels);
    y(k).ci_lower = cci_lower;
    y(k).ci_upper = cci_upper;
    k = k + 1;
end

% -- calculate psd for each epoc
n = length(x);
k = 1;
while k <= n

    disp(['Epoch ', num2str(k), '/', num2str(n)]);

    try

        % -- estimate power spectral density
        [p, f_out, ci] = pwelch(x(k).data(eeg.ix_channels, :)', win, overlap, f, fs);

        % -- store psd estimates
        y(k).data = double(p(fmax, :)');
        y(k).data_columns = num2cell(f_out(fmax, :)');
        y(k).ci_lower = ci(fmax, 1:2:end-1)';
        y(k).ci_upper = ci(fmax, 2:2:end)';

    catch

        % -- return nan values if psd estimation fails
        y(k).data = NaN(fmax(end)-1, eeg.nochannels)';
        y(k).data_columns = num2cell(NaN(fmax(end)-1, eeg.nochannels)');
        y(k).ci_lower = NaN(fmax(end)-1, eeg.nochannels)';
        y(k).ci_upper = NaN(fmax(end)-1, eeg.nochannels)';

    end

    k = k + 1;

end

end
