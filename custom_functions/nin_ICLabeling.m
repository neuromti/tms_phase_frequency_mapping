function [EEG] = nin_ICLabeling(EEG, varargin)

%% This function rejects ICA components using ICLabel classifications
%
% - input:
% EEG: input structure organised as EEGLAB structure
%
% - optional:
% keep_classes: lIC classes to retain (default: all except 'Other')
%
% - example:
% edata = nin_ICLabeling(EEG);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define IC classes to retain
if ~exist('keep_classes', 'var')
    keep_classes = {'Brain', 'Muscle', 'Eye', 'Heart', 'Line Noise', 'Channel Noise'};
end

%% -- identify components for rejection

% -- get probability and classes for all components
cnames = EEG.etc.ic_classification.ICLabel.classes;
cprobability = EEG.etc.ic_classification.ICLabel.classifications;

% -- keep selected classes only
ix = ismember(cnames, keep_classes);
cnames = cnames(1, ix);
cprobability = cprobability(:, ix);

% -- initialize all components as retained
keep = true(size(cprobability, 1), 1); 

% -- identify the most probable class for each component
[maxProb, typeProb] = max(cprobability, [], 2); 

% -- reject components not classified as brain
ix = find(strcmpi(cnames, 'Brain'));
keep(typeProb ~= ix) = false; 

% -- calculate difference between brain probability and the dominant class probability
diff_prob = cprobability(:, ix) - maxProb;

% -- ensure that at least one component is retained
[minp, ixp] = min(abs(diff_prob));
keep(ixp) = true;

% -- store rejection results
EEG.etc.ic_rejection.ICLabel = [];  
EEG.etc.ic_rejection.ICLabel.nICs = nnz(~keep);
EEG.etc.ic_rejection.ICLabel.rejectedICs = find(~keep);
EEG.etc.ic_rejection.ICLabel.rejectedICSname = cnames(typeProb(~keep));
EEG.etc.ic_rejection.ICLabel.rejectedICSdiff = diff_prob(~keep);

%% -- remove rejected components

EEG = pop_subcomp(EEG, EEG.etc.ic_rejection.ICLabel.rejectedICs, 0);

end

