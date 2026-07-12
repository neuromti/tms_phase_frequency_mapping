function [EEG] = nin_interpolation(EEG, stimuli, varargin)

%% This function interpolates TMS stimulation artifacts in continuous EEG data
%
% - input:
% EEG: structure containing continuous EEG data
% stimuli: sample indices of TMS pulses
%
% - optional:
% fs: sampling frequency (default: 1000)
% win_d: window around each stimulus in seconds (default: 3)
% win_s: half-width of interpolation window in samples (default: 10)
% win_max: additional samples included around the artifact (default: 2)
% method: interpolation method ('spline' or 'interp1')
% disp_inter: display interpolation results (default: false)
%
% - example:
% edata = nin_data_epoching(EEG, 28730);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define sampling frequency
if ~exist('fs', 'var')
    fs = 1000;
end

% -- define data window around each stimulus in seconds
if ~exist('win_d', 'var')
    win_d = 3;
end

% -- define half-width of artifact window in samples
if ~exist('win_s', 'var')
    win_s = 10;
end

% -- define additional samples around detected artifact boundaries
if ~exist('win_max', 'var')
    win_max = 2;
end

% -- define interpolation method
if ~exist('method', 'var')
    method = 'spline';
end

% -- display interpolation results
if ~exist('disp_inter', 'var')
    disp_inter = false;
end

% -- process current stimulus
ks = 1;
nl = length(stimuli);
while ks <= nl

    disp(['Interpolation ', num2str(ks), '/', num2str(nl)]);

    % -- define data segment around stimulus
    if fix(stimuli(ks))-win_d*fs < 1
        lb = 1;
    else
        lb = fix(stimuli(ks))-win_d*fs;
    end
    if ceil(stimuli(ks))+win_d*fs-1 > size(EEG.data, 2)
        rb = size(EEG.data, 2);
    else
        rb = ceil(stimuli(ks))+win_d*fs-1;
    end
    % -- extract data segment
    x = lb:rb;
    y_tot = EEG.data(:, x);
    y_out = EEG.data;

    % -- process channels separately
    k = 1;
    while k <= size(y_tot, 1)

        % -- extract current channel
        y = y_tot(k, :);

        % -- locate stimulus position within segment
        ix_s = find(x == stimuli(ks));

        % -- extract artifact window around stimulus
        xx = x(ix_s-win_s:ix_s+win_s);
        yy = y(ix_s-win_s:ix_s+win_s);
        n_xx = length(xx);

        % -- baseline-shift artifact window
        if yy(1) > 0
            yy_b = yy - yy(1);
        else
            yy_b = yy + yy(1);
        end

        % -- interpolate baseline-shifted artifact window
        switch method
            case 'spline'
                yy_i = spline([1 n_xx] ,[yy_b(1) yy_b(end)], 1:n_xx);
            case 'interp1'
                yy_i = interp1([1 n_xx] ,[yy_b(1) yy_b(end)], 1:n_xx);
        end

        % -- calculate mean and sem of interpolated window
        chunk_m = mean(yy_i);
        chunk_sem = std(yy_i)/sqrt(length(yy_i));

        % -- detect positive peaks
        [p_max, ix_max] = findpeaks(yy_b);
        % -- detect negative peaks
        [p_min, ix_min] = findpeaks(-yy_b);

        % -- combine positive and negative peaks
        p = [p_max, p_min];
        ix_p = [ix_max, ix_min];

        % -- order peaks by occurrence
        [ix_p, s] = sort(ix_p);
        p = p(s);

        % -- identify largest artifact peak
        [~, ii_max] = max(abs(p));

        % -- determine interpolation boundaries
        if ~isempty(ii_max)

            % -- find left interpolation boundary
            if ii_max == 1
                ix_l =  ix_p(ii_max)-win_max;
            else
                ix_t = ix_p(ii_max-1:-1:1);
                p_t = p(ii_max-1:-1:1);
                keep = abs(p_t) <= abs(chunk_m) + chunk_sem;
                if any(keep)
                    ix_l =  ix_t(find(keep == true, 1, 'last'));
                else
                    ix_l =  ix_t(find(keep == false, 1, 'first'))-win_max;
                end
            end
            if ix_l < 1
                ix_l = 1;
            end

            % -- find right interpolation boundary
            if ii_max == length(p)
                ix_r =  ix_p(ii_max)+win_max;
            else
                ix_t = ix_p(ii_max+1:1:length(p));
                p_t = p(ii_max+1:1:length(p));
                keep = abs(p_t) <= abs(chunk_m) + chunk_sem;
                if any(keep)
                    ix_r =  ix_t(find(keep == true, 1, 'first'));
                else
                    ix_r =  ix_t(find(keep == false, 1, 'last'))+win_max;
                end
            end
            if ix_r > n_xx
                ix_r = n_xx;
            end

        else

            % -- use full window if no peaks are detected
            ix_l = 1;
            ix_r = n_xx;

        end

        % -- interpolate artifact in original signal
        x1 = [1 n_xx];
        y1 = [yy(ix_l) yy(ix_r)];
        x2 = 1:n_xx;
        switch method
            case 'spline'
                y2 = spline(x1 ,y1, x2);
            case 'interp1'
                y2 = interp1(x1 ,y1, x2);
        end

        yr = y;
        yr(ismember(x, xx)) = y2;

        % -- display interpolation results
        if disp_inter

            figure('Position', [2525,559,570,413]);
            plot(xx, yy, xx, y2, 'r');
            hold on
            plot(xx(ix_p), yy(ix_p), '*');
            xlim([xx(ix_p(1)) xx(ix_p(end))]);

            figure('Position', [1921,554,570,413]);
            subplot(2, 1, 1)
            plot(x, y);
            ylim([-(max(abs(y))+10) (max(abs(y))+10)]);
            xlim([x(1) x(end)]);
            subplot(2, 1, 2)
            plot(x, yr, 'r');
            ylim([-(max(abs(y))+10) (max(abs(y))+10)]);
            xlim([x(1) x(end)]);

        end

        % -- replace artifact segment
        y_out(k, x) = yr;

        k = k + 1;

    end

    % -- update EEG data
    EEG.data = y_out;

    ks = ks + 1;

end

end

