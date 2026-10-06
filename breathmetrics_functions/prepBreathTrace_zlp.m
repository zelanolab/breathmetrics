function [det, peaks, troughs, info] = prepBreathTrace_zlp(rsp, fs, mode, blankBelowFrac, cySpan, floorFrac)
%PREPBREATHTRACE_ZLP  Detection-trace conditioning + breath extrema (ZLP stage 0-1).
%
%   [det, peaks, troughs, info] = prepBreathTrace_zlp(rsp, fs, mode, ...
%                                     blankBelowFrac, cySpan, floorFrac)
%
%   First half of the ZLP (Zelano Lab Preprocessing) breath-segmentation
%   engine: condition the respiration trace into a normalized DETECTION copy
%   and find validity-ruled inhale peaks / exhale troughs on it. The second
%   half (findInhaleOnsets_zlp) places one inhale onset per trough->peak pair
%   on the returned det trace. zlpEstimateAllFeatures drives both and feeds
%   the result through the breathmetrics class; see docs/zlp_segmentation.md
%   for the full algorithm specification and motivation.
%
%   Developed against amplitude-non-stationary human respiration recordings
%   (intracranial + scalp-EEG sessions with belt/pressure/cannula sensors,
%   drifting baselines, paced-breathing blocks) through ~20 live-reviewed QC
%   generations (Zelano Lab, Aug 2026). It addresses two recurring stage-1
%   failures of global-criterion detection on such data: (a) over-detection
%   of peaks/troughs carving single breaths into several, and (b) uniform
%   smoothing erasing the sharp inhale uptick along with the noise.
%
%   INPUTS
%   rsp            : respiration trace, numeric vector (raw units; inhale
%                    positive). NaNs are filled internally.
%   fs             : sampling rate (Hz).
%   mode           : 'conservative' (RECOMMENDED - the locked production
%                    choice), 'pwl', or 'twoscale' (kept for comparison).
%   blankBelowFrac : optional; zero the detection copy where the local
%                    amplitude scale falls below this fraction of its median
%                    (for hardware-attenuated stretches, e.g. a partially
%                    unplugged cannula). Default [] = no blanking.
%   cySpan         : optional [startSample endSample] of a paced-sigh /
%                    double-inhale block: inside the span, of two peaks
%                    closer than 5 s only the FIRST is kept, so the paced
%                    double inhale segments as one breath. Default [].
%   floorFrac      : amplitude-normalization floor as a fraction of the
%                    median moving scale (default 0.05) - stops near-silent
%                    stretches from being amplified into fake breaths.
%
%   OUTPUTS (breathmetrics conventions)
%   det            : the normalized detection trace ('pwl': the polyline
%                    reconstruction). NORMALIZED units - all downstream
%                    onset thresholds are calibrated to this trace.
%   peaks, troughs : sample-index row vectors, strictly alternating
%                    trough -> peak -> trough - drop-in replacements for the
%                    breathmetrics inhalePeaks / exhaleTroughs vectors.
%   info           : struct with the mode and ('pwl') breakpoint count.
%
%   Conditioning, common to all modes: linear NaN fill (nearest at the
%   edges), 500-ms moving-average smoothing, then windowed amplitude
%   normalization - divide by the 30-s moving standard deviation, floored at
%   floorFrac x its median. The windowed normalization is what makes a
%   single prominence criterion work across quiet and deep-breathing epochs;
%   note that it also means det (and any feature integrated on it) is in
%   locally-rescaled units - see zlpEstimateAllFeatures' raw-volume output
%   for amplitude measures in raw signal units.
%
%   MODES
%   'pwl'          piecewise-linear (Douglas-Peucker at 20 Hz)
%                  reconstruction: breakpoints only where line-fit error
%                  > 0.15 normalized units - micro-bumps vanish, sharp slope
%                  changes are preserved exactly. Extrema = alternating
%                  polyline vertices. No toolbox required.
%   'conservative' (the locked production mode) no smoothing beyond the
%                  common 500 ms; over-detection is attacked at the
%                  criteria: prominence >= 0.6 (normalized), 1.0-s min
%                  separation, peak validity (height >= 1.0, or >= 0.5 with
%                  a 0.5 drop within the next 1 s), trough->peak rise
%                  >= 40% of the local breath amplitude, strict alternation.
%                  Uses findpeaks (Signal Processing Toolbox).
%   'twoscale'     extrema on a further 500-ms-smoothed skeleton (bumps
%                  cannot survive), each refined to the true extremum on det
%                  within +/-0.6 s. Uses findpeaks.

    if nargin < 4, blankBelowFrac = []; end
    if nargin < 5, cySpan = []; end
    if nargin < 6 || isempty(floorFrac), floorFrac = 0.05; end
    rsp = double(rsp(:))';
    rsp = fillmissing(rsp, 'linear', 'EndValues', 'nearest');

    base = movmean(rsp, round(0.50 * fs));            % 500-ms common smoothing (300 ms left extrema over-detection)
    sc = movstd(base, round(30 * fs));
    scFloor = floorFrac * median(sc);
    x = base ./ max(sc, scFloor);                     % normalized, light
    if ~isempty(blankBelowFrac)
        x(sc < blankBelowFrac * median(sc)) = 0;
    end
    N = numel(x);
    info = struct('mode', mode, 'nBreakpoints', NaN);

    switch mode
        case 'pwl'
            % Douglas-Peucker at 20 Hz, tolerance 0.15 normalized units
            ds = max(1, round(fs / 20));
            gi = 1:ds:N; g = x(gi); ng = numel(g);
            keepBP = false(1, ng); keepBP([1 ng]) = true;
            stack = [1 ng];
            while ~isempty(stack)
                a = stack(end, 1); b = stack(end, 2); stack(end, :) = [];
                if b - a < 2, continue; end
                seg = g(a:b);
                lin = linspace(seg(1), seg(end), b - a + 1);
                [emax, ei] = max(abs(seg - lin));
                if emax > 0.15
                    c = a + ei - 1;
                    keepBP(c) = true;
                    stack(end+1, :) = [a c]; %#ok<AGROW>
                    stack(end+1, :) = [c b]; %#ok<AGROW>
                end
            end
            bp = gi(keepBP);
            det = interp1(bp, x(bp), 1:N, 'linear', 'extrap');
            info.nBreakpoints = numel(bp);
            % extrema = interior polyline vertices that are local max/min
            v = x(bp); pk = []; tr = [];
            for k = 2:numel(bp)-1
                if v(k) > v(k-1) && v(k) > v(k+1), pk(end+1) = bp(k); end %#ok<AGROW>
                if v(k) < v(k-1) && v(k) < v(k+1), tr(end+1) = bp(k); end %#ok<AGROW>
            end
            [peaks, troughs] = enforceAlt(det, pk, tr, 0.5, round(1.5 * fs));

        case 'conservative'
            det = x;
            [~, pk] = findpeaks(det,  'MinPeakProminence', 0.6, 'MinPeakDistance', round(1.0 * fs));
            [~, tr] = findpeaks(-det, 'MinPeakProminence', 0.6, 'MinPeakDistance', round(1.0 * fs));
            % (min separation was 2.0 s originally - nearby real breaths were
            % being eliminated; the validity rules below carry the load)
            % peak validity: exhale-recovery crests just before a breathing
            % pause pass prominence AND the rise filter because both measure
            % against the deep trough BELOW them. Two absolute demands kill
            % them without touching real breaths: HEIGHT FLOOR - a peak must
            % reach +0.5 (a pause crest sits at baseline); SOFT DESCENT -
            % some point within the next 1 s must be 0.5 below the peak (a
            % real peak is followed by an exhale, a pause crest by flatness).
            fwdMin = movmin(det, [0 round(1.0 * fs)]);
            % (peaks >= 1.0 are exempt from the descent demand - a tall peak
            % is real even if the exhale is slow to start)
            pk = pk(det(pk) >= 1.0 | (det(pk) >= 0.5 & (det(pk) - fwdMin(pk)) >= 0.5));
            [peaks, troughs] = enforceAlt(det, pk, tr, 0, 0);
            % rise-fraction filter: a trough->peak rise under 40% of the local
            % breath amplitude is a bump, not a breath
            locAmp = movmax(det, round(30 * fs)) - movmin(det, round(30 * fs));
            good = true(size(peaks));
            for k = 1:numel(peaks)
                t0 = troughs(troughs < peaks(k));
                if isempty(t0), continue; end
                if det(peaks(k)) - det(t0(end)) < 0.4 * 0.5 * locAmp(peaks(k)), good(k) = false; end
            end
            [peaks, troughs] = enforceAlt(det, peaks(good), troughs, 0, 0);

        case 'twoscale'
            det = x;
            skel = movmean(x, round(0.5 * fs));
            [~, pk] = findpeaks(skel,  'MinPeakProminence', 0.45, 'MinPeakDistance', round(2 * fs));
            [~, tr] = findpeaks(-skel, 'MinPeakProminence', 0.45, 'MinPeakDistance', round(2 * fs));
            w = round(0.6 * fs);
            for k = 1:numel(pk)
                a = max(1, pk(k)-w); b = min(N, pk(k)+w);
                [~, m] = max(det(a:b)); pk(k) = a + m - 1;
            end
            for k = 1:numel(tr)
                a = max(1, tr(k)-w); b = min(N, tr(k)+w);
                [~, m] = min(det(a:b)); tr(k) = a + m - 1;
            end
            [peaks, troughs] = enforceAlt(det, pk, tr, 0, 0);

        otherwise
            error('unknown prep mode %s', mode);
    end

    % paced-sigh span: a paced sigh cycle has a DOUBLE inhale. Regular peak
    % detection runs first; then inside the span, whenever two peaks fall
    % within 5 s of each other the FIRST wins and the second is removed (the
    % sigh's top-up peak follows the primary inhale), so one onset per cycle
    % follows automatically.
    if ~isempty(cySpan) && numel(peaks) > 1
        keep = true(size(peaks)); last = -Inf;
        for k = 1:numel(peaks)
            inSpan = peaks(k) >= cySpan(1) && peaks(k) <= cySpan(2);
            if inSpan && (peaks(k) - last) < 5 * fs
                keep(k) = false;          % keep the FIRST of the pair
            else
                last = peaks(k);
            end
        end
        [peaks, troughs] = enforceAlt(det, peaks(keep), troughs, 0, 0);
    end
end

function [peaks, troughs] = enforceAlt(det, pk, tr, minProm, minSep)
% strict trough->peak->trough alternation; of two same-type extrema in a row
% the more extreme wins. Optional extra prominence/separation pre-filter.
    if minProm > 0 || minSep > 0
        % (used by pwl where vertices carry no findpeaks guarantees)
        keep = true(size(pk));
        for k = 2:numel(pk)
            if pk(k) - pk(k-1) < minSep, keep(k) = false; end
        end
        pk = pk(keep);
    end
    ev = [pk(:), ones(numel(pk), 1); tr(:), -ones(numel(tr), 1)];
    ev = sortrows(ev, 1);
    keep = true(size(ev, 1), 1);
    i = 1;
    while i < size(ev, 1)
        j = i + 1;
        while j <= size(ev, 1) && ~keep(j), j = j + 1; end
        if j > size(ev, 1), break; end
        if ev(i, 2) == ev(j, 2)
            if ev(i, 2) == 1
                if det(ev(i, 1)) >= det(ev(j, 1)), keep(j) = false; else, keep(i) = false; i = j; end
            else
                if det(ev(i, 1)) <= det(ev(j, 1)), keep(j) = false; else, keep(i) = false; i = j; end
            end
        else
            i = j;
        end
    end
    ev = ev(keep, :);
    peaks   = ev(ev(:, 2) == 1, 1)';
    troughs = ev(ev(:, 2) == -1, 1)';
end
