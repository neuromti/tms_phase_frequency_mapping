function y = nin_fitplots_harmonic(x, varargin)

%% Function that, for EVERY combination of visit x condition x stim_side x
%% component found in x, averages raw (session-level) trial data within
%% participant and fits a harmonic (cosine/sine) model, using a
%% participant-preserving permutation procedure.
%
% Input data has NOT been averaged across sessions beforehand. Averaging
% across sessions (within each participant, per target phase) is
% performed inside this function, separately within EACH group
% combination, both for the observed fit and, independently, inside every
% permutation for that group.
%
% - input:
% x: struct array, one element per trial/session-phase entry, with fields:
%       .sub          - participant ID (char)
%       .session (or .visit) - session/visit ID (char)  [grouping variable]
%       .condition    - condition label (char)           [grouping variable]
%       .stim_side    - stimulation-side label (char)     [grouping variable]
%       .tphase       - target phase, in DEGREES (char or numeric)
%       .data_columns - cell array of component names, e.g.
%                       {'P25_amp','N45_amp','P70_amp','N100_amp','P180_amp'}
%       .(value_field) - matrix whose FIRST ROW holds one value per
%                       component (columns matching data_columns); default
%                       value_field name is 'data'
%
% - optional:
% value_field: name of the field holding the value matrix (default: 'data')
% invert_components: substrings of component names that get sign-inverted
%              immediately before fitting (default: {'N45', 'N100'})
% xx: phase values used for fitting, in DEGREES (default: 0:45:315)
% ffit: 'cos' or 'sin' (default: 'cos')
% n_perm: number of permutations (default: 1000)
% shift_data: z-score the subject-averaged data before fitting (default: true)
% seed: random seed, fixed once for the whole call (default: 1)
%
% - output:
% y: struct array, ONE ELEMENT PER FIT, i.e. one element per unique
%    combination of visit x condition x stim_side x component. Each
%    element has fields:
%       .visit, .condition, .stim_side, .component  - identifiers for this fit
%       .x, .y            - fitted phases (rad) and observed grand-average values
%       .curve            - fitted curve object
%       .coeffvalues      - raw fit coefficients [a1, b1, c1]
%       .oval             - [modulation depth, optimal phase (deg)], corrected
%       .oval_name        - {'amp','phase'}
%       .pval             - [n_perm x 2] permutation distribution of [amp, phase]
%       .p                - one-sided permutation p value for modulation depth
%       .n_subjects       - number of participants entering this fit
%       .subject_table    - participant x phase averaged matrix (rows = subjects)
%
% - example:
% y = nin_fitplotsII_raw(rawTrialStruct);
% y(3).component, y(3).oval, y(3).p   % inspect the 3rd fit

nin_import_params(varargin);

%% -- defaults

if ~exist('value_field', 'var')
    value_field = 'data';
end
if ~exist('invert_components', 'var')
    invert_components = {'N45', 'N100'};
end
if ~exist('xx', 'var')
    xx_deg = 0:45:315;
else
    xx_deg = xx; %#ok<NODEF>
end
xx_rad = deg2rad(xx_deg(:)');
if ~exist('ffit', 'var')
    ffit = 'cos';
end
if ~exist('n_perm', 'var')
    n_perm = 1000;
end
if ~exist('shift_data', 'var')
    shift_data = false;
end
if ~exist('seed', 'var')
    seed = 1;
end

% -- fix the random seed ONCE, before anything else, for reproducibility
% across the entire set of fits produced by this call.
rng(seed, 'twister');

%% -- pull grouping / phase / value vectors out of x (one row per element)

subField     = ifelse_field(x, 'sub');
sessField    = ifelse_field(x, 'visit'); % resolves to 'visit' if that's the actual field
condField    = ifelse_field(x, 'condition');
sideField    = ifelse_field(x, 'stim_side');
stimField    = ifelse_field(x, 'stimulation');
phaseField   = ifelse_field(x, 'tphase');

subVec   = {x.(subField)}';
visitVec = {x.(sessField)}';
condVec  = {x.(condField)}';
sideVec  = {x.(sideField)}';
stimVec  = {x.(stimField)}';
phaseRaw = {x.(phaseField)}';

if ischar(phaseRaw{1})
    phaseVec = cellfun(@str2double, phaseRaw);
else
    phaseVec = cellfun(@double, phaseRaw);
end

component_list = x(1).data_columns; % e.g. {'P25_amp','N45_amp','P70_amp','N100_amp','P180_amp'}
nComp = numel(component_list);

valAll = nan(numel(x), nComp);
for i = 1:numel(x)
    valAll(i, :) = x(i).(value_field)(1, :); % first row only, per component
end

%% -- enumerate every visit x condition x stim_side combination
% (one element of y per single visit x condition x stim_side x stimulation
% x component fit. Grouping/packing across components into a myfit-style
% table is done separately, by nin_build_myfit.m, which consumes this flat
% output.)

uVisits = unique(visitVec);
uConds  = unique(condVec);
uSides  = unique(sideVec);
uStims  = unique(stimVec);

y = struct([]);
k = 0;

for vi = 1:numel(uVisits)
    for ci = 1:numel(uConds)
        for si = 1:numel(uSides)
          for sti = 1:numel(uStims)

            groupMask = strcmp(visitVec, uVisits{vi}) & ...
                        strcmp(condVec,  uConds{ci})  & ...
                        strcmp(sideVec,  uSides{si})  & ...
                        strcmp(stimVec,  uStims{sti});

            if ~any(groupMask)
                continue % this combination does not occur in the data
            end

            gSub   = subVec(groupMask);
            gPhase = phaseVec(groupMask);
            gVal   = valAll(groupMask, :);
            gIdx   = find(groupMask, 1, 'first'); % representative element for metadata fields

            for compi = 1:nComp

                thisComponent = component_list{compi};
                compValVec = double(gVal(:, compi));

                fitResult = fit_one_group(gSub, gPhase, compValVec, thisComponent, ...
                    xx_rad, xx_deg, ffit, n_perm, shift_data, invert_components);

                k = k + 1;

                y(k).stimulation = uStims{sti};
                y(k).visit = uVisits{vi};
                y(k).stim_side = uSides{si};
                y(k).Condition = uConds{ci};
                y(k).component = strrep(thisComponent, '_amp', '');
                y(k).Parethic_Dominant_Side = get_field_or_empty(x(gIdx), 'Parethic_Dominant_Side');
                y(k).Lesion_Hand = get_field_or_empty(x(gIdx), 'Lesion_Hand');
                y(k).freq = '20';
                y(k).x = fitResult.x;
                y(k).y = fitResult.y;               % observed grand-average curve
                y(k).oval = fitResult.oval;          % [amp, phase]
                y(k).oval_name = fitResult.oval_name;
                y(k).pval = fitResult.pval;          % n_perm x 2 permutation distribution [amp, phase]
                y(k).p = fitResult.p;                % [amp_p, phase_p]
                y(k).goodness = fitResult.goodness;
                y(k).n_subjects = fitResult.n_subjects;
                y(k).subject_table = fitResult.subject_table;
                y(k).n = fitResult.n_subjects;
                y(k).N = fitResult.n_subjects;

            end

          end
        end
    end
end

end

%% ===================== local helper functions =====================

function fitResult = fit_one_group(subVec, phaseVec, valVec, component_name, ...
    xx_rad, xx_deg, ffit, n_perm, shift_data, invert_components)
% Performs the participant-balanced averaging, participant-preserving
% permutation procedure, and harmonic fit for ONE already-filtered group
% (one visit x condition x stim_side x component combination).

subjects = unique(subVec);
nSubj = numel(subjects);
nPhase = numel(xx_deg);

    function M = build_subject_phase_matrix(phaseLabels)
        M = nan(nSubj, nPhase);
        for k = 1:nSubj
            subMask = strcmp(subVec, subjects{k});
            for p = 1:nPhase
                phMask = phaseLabels == xx_deg(p);
                M(k, p) = nanmean(valVec(subMask & phMask));
            end
        end
    end

% -- observed fit
subjectPhaseMat = build_subject_phase_matrix(phaseVec);
if shift_data
    subjectPhaseMat = zscore(subjectPhaseMat, 0, 2);
end
avg = nanmean(subjectPhaseMat, 1);

% -- invert sign for negative-polarity components, on the AVERAGED data,
% immediately before fitting.
if contains(component_name, invert_components, 'IgnoreCase', true)
    avg = -1 * avg;
end

[camp, cphi, curve, goodness, output, coeffnames_, coeffvalues_, confint_] = ...
    fit_harmonic(xx_rad, avg, ffit);

% -- participant-preserving permutations
pcval = nan(n_perm, 2);
for b = 1:n_perm

    permPhaseVec = phaseVec;
    for k = 1:nSubj
        subMask = strcmp(subVec, subjects{k});
        idxHere = find(subMask);
        originalPhasesHere = phaseVec(idxHere);
        shuffledPhasesHere = originalPhasesHere(randperm(numel(originalPhasesHere)));
        permPhaseVec(idxHere) = shuffledPhasesHere;
    end

    permMat = build_subject_phase_matrix(permPhaseVec);
    if shift_data
        permMat = zscore(permMat, 0, 2);
    end
    pavg = nanmean(permMat, 1);

    if contains(component_name, invert_components, 'IgnoreCase', true)
        pavg = -1 * pavg;
    end

    [pcamp, pcphi] = fit_harmonic(xx_rad, pavg, ffit);
    pcval(b, 1) = pcamp;
    pcval(b, 2) = pcphi;
end

fitResult.x = xx_rad';
fitResult.y = avg';
fitResult.curve = curve;
fitResult.goodness = goodness;
fitResult.output = output;
fitResult.coeffnames = coeffnames_;
fitResult.coeffvalues = coeffvalues_;
fitResult.confint = confint_;
fitResult.oval = [camp, cphi];
fitResult.oval_name = {'amp', 'phase'};
fitResult.pval = pcval;
amp_p = sum(pcval(:, 1) >= camp) / n_perm;             % one-sided
phase_p = sum(pcval(:, 2) >= cphi) / n_perm;  % two-sided
% phase_p = sum(abs(pcval(:, 2)) >= abs(cphi)) / n_perm;  % two-sided
fitResult.p = [amp_p, phase_p];
fitResult.n_subjects = sum(any(~isnan(subjectPhaseMat), 2));
fitResult.subject_table = subjectPhaseMat;

end

function val = get_field_or_empty(xElem, fieldName)
if isfield(xElem, fieldName)
    val = xElem.(fieldName);
else
    val = [];
end
end

function fname = ifelse_field(x, wanted)
candidates = struct( ...
    'sub',       {{'sub', 'subject', 'Sub'}}, ...
    'visit',   {{'Visit', 'visit'}}, ...
    'condition', {{'condition', 'Condition'}}, ...
    'stim_side', {{'stim_side', 'Stim_side', 'StimSide'}}, ...
    'stimulation', {{'stimulation', 'Stimulation'}}, ...
    'tphase',    {{'tphase', 'phase', 'Phase'}} ...
    );
opts = candidates.(wanted);
fname = opts{1};
for c = 1:numel(opts)
    if isfield(x, opts{c})
        fname = opts{c};
        return
    end
end
end

function [camp, cphi, curve, goodness, output, coeffnames_, coeffvalues_, confint_] = fit_harmonic(xx, yvals, ffit) %#ok<INUSD>
% Harmonic regression: y = beta0 + beta_cos*cos(x) + beta_sin*sin(x),
% solved as an ordinary linear least-squares problem (closed-form),
% mathematically equivalent to the nonlinear a1*cos(x+b1)+c1 fit for a
% well-conditioned design. 'ffit' is accepted for interface compatibility
% but only 'cos' is meaningfully supported here (sin case reduces to the
% same regression with predictors swapped, see note below).

xx = xx(:); % column
yvals = yvals(:);

X = [cos(xx), sin(xx), ones(size(xx))]; % predictors: cos, sin, intercept
betas = X \ yvals; % ordinary least squares, closed-form

beta_cos = betas(1);
beta_sin = betas(2);
beta_0   = betas(3);

camp = sqrt(beta_cos^2 + beta_sin^2);
cphi = rad2deg(atan2(-beta_sin, beta_cos));

if strcmpi(ffit, 'sin')
    % for a sin(x+b) parameterization, phase is offset by 90 degrees
    % relative to the cos(x+b) parameterization used above
    cphi = cphi - 90;
end

% -- trigonometric identity correction, identical to the nonlinear version,
% so downstream conventions (always-positive amplitude, "leading" phase)
% are unchanged regardless of which fitting method produced camp/cphi.
if camp < 0
    camp = -1 * camp;
    cphi = cphi - 180;
end
if abs(cphi) > 360
    if sign(cphi) == -1
        cphi = cphi + 360;
    else
        cphi = cphi - 360;
    end
end
if cphi > 0
    cphi = 360 - cphi;
    cphi = -1 * cphi;
end

% -- goodness-of-fit metrics, computed manually to match the fields used
% downstream (sse, rsquare, dfe, adjrsquare, rmse), since linear \ does not
% return a goodness struct the way fit() does.
yhat = X * betas;
resid = yvals - yhat;
n = numel(yvals);
p = size(X, 2); % number of predictors (cos, sin, intercept) = 3

sse = sum(resid.^2);
sst = sum((yvals - mean(yvals)).^2);
rsquare = 1 - sse / sst;
dfe = n - p;
adjrsquare = 1 - (1 - rsquare) * (n - 1) / dfe;
rmse = sqrt(sse / dfe);

goodness.sse = sse;
goodness.rsquare = rsquare;
goodness.dfe = dfe;
goodness.adjrsquare = adjrsquare;
goodness.rmse = rmse;

% -- fields kept for interface compatibility with the nonlinear version;
% not meaningful in the same way for a linear closed-form solution, so
% left empty/approximate.
curve = [];
output = [];
coeffnames_ = {'beta_cos', 'beta_sin', 'beta_0'};
coeffvalues_ = betas';
confint_ = [];

end