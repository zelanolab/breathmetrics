function [onsets, peaks, troughs] = findInhaleOnsets_zlp(resp, fs, peaks, troughs, method, r2Factor, r3Factor, dipFrac, dipDur)
%FINDINHALEONSETS_ZLP  Inhale onsets, one per trough->peak pair (ZLP stage 2-3).
%
%   [onsets, peaks, troughs] = findInhaleOnsets_zlp(det, fs, peaks, troughs, ...
%                                  method, r2Factor, r3Factor, dipFrac, dipDur)
%
%   Second half of the ZLP breath-segmentation engine (see
%   prepBreathTrace_zlp for the first half, zlpEstimateAllFeatures for the
%   breathmetrics integration, and docs/zlp_segmentation.md for the full
%   specification). The locked production call is
%
%       findInhaleOnsets_zlp(det, fs, peaks, troughs, 'kneeBacktrack', ...
%                            0.4, 1.25, 0.50, 0.10)
%
%   INPUTS
%   resp   : the DETECTION trace from prepBreathTrace_zlp (windowed-
%            normalized units - every threshold below is calibrated to that
%            scale; feeding a raw-unit trace will not work), row vector.
%   peaks/troughs : strictly alternating extrema from prepBreathTrace_zlp
%            (breathmetrics-style sample indices).
%   method : 'kneeBacktrack' (RECOMMENDED - the locked production choice),
%            'slopeGate', or 'changepoint' (kept for comparison).
%   r2Factor (default 0.4): rule-2 rising-ahead demand in normalized units.
%   r3Factor (default 1.25 in production): rule-3 slope-contrast ratio.
%   dipFrac/dipDur (default 0.50 / 0.10 s): the kneeBacktrack walk's
%            sustained-dip stop - slope < dipFrac*dmax continuously for
%            >= dipDur seconds.
%
%   OUTPUTS
%   onsets : inhale-onset sample indices, one per surviving trough->peak
%            pair (breathmetrics inhaleOnsets convention).
%   peaks, troughs : the PRUNED extrema - this function can DELETE spurious
%            trough/peak pairs (see below), so always take the extrema from
%            these outputs, not from prepBreathTrace_zlp's.
%
%   Morphology (the working definition behind every rule): a true inhale
%   onset is a FAST UPWARD deflection beginning near baseline - a sharp
%   positive increase in slope while the value sits well above the trough
%   and below the peak. Zero crossings alone fail (pauses hover around zero;
%   onsets can start below zero), and the stock last-sample-below-a-global-
%   pause-band placement fails on drifting / amplitude-non-stationary data
%   (onsets land on exhale troughs, on peaks, or mid-rise - the failure mode
%   that motivated this function). Exactly one onset is returned per
%   trough->peak pair.
%
%   METHODS
%   slopeGate     first SUSTAINED crossing of a slope threshold (20% of the
%                 window's max slope) within the amplitude mid-band
%                 (trough+15% .. peak-25% of the range)
%   kneeBacktrack from the steepest point of the rise, walk backward until
%                 the slope collapses: the foot/knee of the fast rise. The
%                 locked variant adds an anchor rule, a clean-sweep fallback,
%                 a late-landing extension and three eligibility rules - each
%                 one the product of a reviewed failure case (inline
%                 comments give the rationale; the doc gives the full list).
%   changepoint   two-line least-squares fit (flat-ish left segment, rising
%                 right segment); onset = breakpoint minimizing total
%                 residual with rightSlope > leftSlope

    resp = double(resp(:))';
    % slope on a 120-ms smoothed derivative (light - over-smoothing drags
    % onsets early)
    d = movmean([0, diff(resp)] * fs, round(0.12 * fs));

    % HARD ELIGIBILITY RULE 1: a sample sitting more than THETA below where
    % the trace was 0.33 s earlier is mid-descent or just landed in a trough
    % - never an inhale onset. Candidates must satisfy
    % x(t) - x(t - 0.33 s) > -THETA (normalized units).
    LAG = round(0.33 * fs);
    THETA = 0.20;
    d33 = resp - [repmat(resp(1), 1, LAG), resp(1:end-LAG)];
    elig = d33 > -THETA;
    % rule 2 (rising ahead): within a window after a true onset the trace
    % must AT SOME POINT rise r2Factor normalized units above the onset
    % value - agnostic to exactly when in that window. Flat/drifting
    % stretches can never qualify. The window is PAIR-SCALED,
    % max(0.4 s, 25% of the pair's trough->peak duration): a fixed 0.4-s
    % window demands ~1.9 units/s of rise, which no slow breath can meet -
    % whole pairs got pruned and detected rates collapsed.
    Aloc = movstd(resp, round(30 * fs)); %#ok<NASGU>  (local scale, kept for diagnostics)
    % rule 3: the rise must be ACCELERATING at the onset - slope contrast
    % across a window straddling the mark (-0.25s..+0.5s): max slope must
    % exceed r3Factor x the min slope (clamped at +0.1 units/s - the min is
    % ~0/negative at true onsets, which is the point: flat-behind,
    % steep-ahead passes easily even when the mark is slightly late; uniform
    % mid-rise and flat traces fail). Rule 3 is NOT a global gate - smooth
    % trough-to-peak sweeps have no flat/steep contrast anywhere, so gating
    % on it wrongly invalidated whole windows. It refines knee placement
    % only, AFTER a knee is found - see the kneeBacktrack two-pass flow.
    if nargin < 6 || isempty(r2Factor), r2Factor = 0.75; end
    if nargin < 7 || isempty(r3Factor), r3Factor = 3; end
    if nargin < 8 || isempty(dipFrac), dipFrac = 0.50; end
    if nargin < 9 || isempty(dipDur),  dipDur  = 0.10; end
    LB = round(0.25 * fs); LF = round(0.5 * fs);
    dMaxW = movmax(d, [LB LF]);
    dMinW = movmin(d, [LB LF]);
    r3v = dMaxW > r3Factor * max(dMinW, 0.1);
    valid = elig;                       % rules 1 (+2 per pair) gate candidates
    % rule 2 is ABSOLUTE: somewhere in the pair-scaled window the trace must
    % sit r2Factor normalized units above the candidate (a multiplicative-
    % in-local-amplitude variant was tried and rejected; 0.25 is remapped to
    % the reviewed 0.4 for legacy callers)
    if r2Factor == 0.25, r2Factor = 0.4; end
    pairValid = @(w) valid(w) & ...
        (movmax(resp(w), [0 max(round(0.4 * fs), round(0.25 * numel(w)))]) ...
         - resp(w)) > r2Factor;

    % SPURIOUS-PAIR PRUNING: a trough->peak window with NO dual-valid sample
    % is a false split of one breath (extrema over-detection) - eliminate
    % that trough and peak so the region absorbs into the adjacent breath.
    pruned = true;
    while pruned
        pruned = false;
        for k = 1:numel(peaks)
            t0 = troughs(troughs < peaks(k));
            if isempty(t0), continue; end
            t0 = t0(end);
            if ~any(pairValid(t0:peaks(k)))
                troughs(troughs == t0) = [];
                peaks(k) = [];
                pruned = true;
                break;
            end
        end
    end

    % pair each peak with the last trough before it
    onsets = nan(1, numel(peaks));
    for k = 1:numel(peaks)
        pk = peaks(k);
        tr = troughs(troughs < pk);
        if isempty(tr), continue; end
        tr = tr(end);
        w = tr:pk;
        if numel(w) < round(0.2 * fs), continue; end
        seg  = resp(w);
        dseg = d(w);
        eSeg = pairValid(w);   % all three rules, rule 2 pair-scaled
        rng_ = resp(pk) - resp(tr);
        lo = resp(tr) + 0.15 * rng_;
        hi = resp(pk) - 0.25 * rng_;
        switch method
            case 'slopeGate'
                th = 0.20 * max(dseg);
                sustain = round(0.10 * fs);
                cand = find(dseg(1:end-sustain) > th & seg(1:end-sustain) >= lo & seg(1:end-sustain) <= hi & eSeg(1:end-sustain));
                o = NaN;
                for c = cand
                    if all(dseg(c:c+sustain) > th * 0.5), o = c; break; end
                end
                if isnan(o) && ~isempty(cand), o = cand(1); end

            case 'kneeBacktrack'
                % Anchor at the LAST major slope surge before the peak,
                % computed WITHOUT an amplitude cap - a mid-band cap
                % excluded the final rise of multi-stage inhales, anchoring
                % the walk on an early sub-rise.
                dmax = max(dseg);
                % The anchor's slope scale is the max slope of the SECOND
                % HALF of the pair only - on two-phase breaths a violent
                % first rise otherwise sets a 70% bar the final rise cannot
                % meet, dragging the anchor (and the onset) onto the early
                % sub-rise. The anchor must also pass rules 1+2 (an anchor
                % inside rule 2's near-peak cutoff zone starts the walk with
                % no valid landing ahead). Walk-stop thresholds stay on the
                % WHOLE-window dmax.
                h2 = ceil(numel(dseg) / 2);
                dmaxA = max(dseg(h2:end));
                % The primary anchor search is CONFINED to the second half
                % of the pair - unconfined, the "last valid70" landed on the
                % tail of a violent first-half exhale-recovery limb (slope
                % and eligibility overlap there too) and the walk ran to the
                % floor from the wrong rise.
                im = find(dseg >= 0.7 * dmaxA & eSeg & ((1:numel(dseg)) >= h2), 1, 'last');
                % fallback: when slope and eligibility never overlap in the
                % second half (a shallow final rise - rule 2's demand is
                % nearly the whole rise), anchor at the LAST ELIGIBLE
                % sample: the anchor belongs where onsets are allowed to
                % exist. (Pruning guarantees an eligible sample exists;
                % later fallbacks are safety only.)
                if isempty(im), im = find(eSeg, 1, 'last'); end
                if isempty(im), im = find(dseg >= 0.7 * dmaxA, 1, 'last'); end
                if isempty(im), [~, im] = max(dseg); end
                % Stop only on a SUSTAINED dip (slope < dipFrac*dmax for
                % >= dipDur s) - knife-edge single-sample dips cannot halt
                % the walk.
                susLen = max(1, round(dipDur * fs));
                susDip = movsum(double(dseg < dipFrac * dmax), [susLen - 1, 0]) >= susLen;
                % walk freely: eligibility applies to the LANDING (final
                % snap), not the path - per-step gating halted walks at the
                % anchor when rule 2's near-peak cutoff sat right behind it.
                % Descents stop the walk via susDip anyway.
                o = im;
                while o > 1 && ~susDip(o - 1)
                    o = o - 1;
                end
                % no-inflection fallback: the clean sweep fires ONLY when
                % the MAIN walk itself ran to the floor (below trough + 10%
                % of the swing) - pause-free breaths where no knee exists.
                % Take the LAST upward crossing of the trough/peak MIDPOINT:
                % on a smooth rise that is the steepest region, i.e. the
                % morphological onset.
                if seg(o) < resp(tr) + 0.1 * rng_
                    midLvl = resp(tr) + 0.5 * rng_;
                    cr = find(seg(1:end-1) < midLvl & seg(2:end) >= midLvl);
                    if ~isempty(cr), o = cr(end) + 1; end
                else
                    % late-landing extension: a landing above trough+35% of
                    % the swing may be midway up a TWO-PHASE inhale - try
                    % the stricter-flatness walk, but accept its landing
                    % ONLY if its sustained stop actually fired. An
                    % extension that runs to the window edge found no base
                    % (0.05 dmax is unreachable on drifting plateaus) -
                    % REVERT to the main walk's landing rather than handing
                    % a knee-ful breath to the clean sweep.
                    if seg(o) > resp(tr) + 0.35 * rng_
                        susLen2 = max(1, round(0.15 * fs));
                        susDip2 = movsum(double(dseg < 0.05 * dmax), [susLen2 - 1, 0]) >= susLen2;
                        o2 = o;
                        while o2 > 1 && ~susDip2(o2 - 1)
                            o2 = o2 - 1;
                        end
                        if o2 > 1, o = o2; end
                    end
                    % rule 3 refines the LANDING: if the mark lacks slope
                    % contrast, move to the nearest contrasted sample in-window
                    r3seg = r3v(w);
                    if ~r3seg(min(o, numel(r3seg))) && any(r3seg)
                        cnd = find(r3seg);
                        [~, ci] = min(abs(cnd - o)); o = cnd(ci);
                    end
                end

            case 'changepoint'
                n = numel(seg);
                step = max(1, round(fs / 100));            % 10-ms grid
                cands = round(0.05 * n):step:round(0.95 * n);
                x = 1:n;
                best = Inf; o = NaN;
                for c = cands
                    xl = x(1:c);  yl = seg(1:c);
                    xr = x(c:end); yr = seg(c:end);
                    pl = polyfit(xl, yl, 1); pr = polyfit(xr, yr, 1);
                    if pr(1) <= pl(1) + 1e-9, continue; end
                    r = sum((yl - polyval(pl, xl)).^2) + sum((yr - polyval(pr, xr)).^2);
                    if r < best, best = r; o = c; end
                end

            otherwise
                error('unknown method %s', method);
        end
        % ineligible landing (e.g. changepoint at a descent) -> advance to the
        % first eligible sample in the window
        if isfinite(o) && ~eSeg(min(o, numel(eSeg)))
            cand = find(eSeg);   % nearest eligible in EITHER direction
            if isempty(cand), o = NaN; else, [~, ci] = min(abs(cand - o)); o = cand(ci); end
        end
        % HARD FLOOR (applied last so no walk/sweep/snap can undo it): an
        % onset can NEVER sit in the first 20% of the trough->peak interval
        % - placements there are trough landings, not inhale onsets. If the
        % floor sample is ineligible, take the first eligible sample at or
        % after the floor (forward only - snapping back would defeat the
        % rule), else the floor itself stands.
        if isfinite(o)
            floorIdx = 1 + ceil(0.20 * (numel(w) - 1));
            if o < floorIdx
                cand = find(eSeg(floorIdx:end), 1, 'first');
                if isempty(cand), o = floorIdx; else, o = floorIdx + cand - 1; end
            end
        end
        if isfinite(o), onsets(k) = tr + o - 1; end
    end
    onsets = onsets(isfinite(onsets));
end
