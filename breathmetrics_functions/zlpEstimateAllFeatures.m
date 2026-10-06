function [bm, rawVolumes] = zlpEstimateAllFeatures(resp, srate, varargin)
%ZLPESTIMATEALLFEATURES  breathmetrics features from ZLP breath segmentation.
%
%   bm = zlpEstimateAllFeatures(resp, srate)
%   [bm, rawVolumes] = zlpEstimateAllFeatures(resp, srate, 'Name', value, ...)
%
%   Drop-in alternative to bm.estimateAllFeatures() for recordings where the
%   stock extrema / inhale-onset detection struggles (amplitude-non-
%   stationary signals, drifting baselines, paced or very slow breathing,
%   belt/pressure/cannula sensors). Segmentation is replaced by the ZLP
%   (Zelano Lab Preprocessing) engine - validity-ruled extrema
%   (prepBreathTrace_zlp) and a slope-walk "kneeBacktrack" inhale onset
%   (findInhaleOnsets_zlp) - while EVERY downstream feature (exhale onsets,
%   pauses, offsets, durations, volumes, secondary statistics) is still
%   computed by the unmodified breathmetrics class: the landmarks are
%   injected and manualAdjustPostProcess(), the class' own post-manual-edit
%   hook, recomputes the feature set from them. Full algorithm specification
%   and motivation: docs/zlp_segmentation.md.
%
%   INPUTS
%   resp  : respiration trace, numeric vector, inhale positive, RAW units.
%           NaNs are tolerated (filled internally for detection).
%   srate : sampling rate (Hz).
%
%   Name-value options
%   'dataType'       ('humanAirflow') passed to the breathmetrics
%                    constructor. Only the airflow data types are supported
%                    (the manual-adjust path exists only for them).
%   'floorFrac'      (0.05) amplitude-normalization floor, as a fraction of
%                    the median 30-s moving std - stops near-silent
%                    stretches being amplified into fake breaths.
%   'blankBelowFrac' ([]) zero the detection copy where the local amplitude
%                    scale is below this fraction of its median (hardware-
%                    attenuated stretches). [] = off.
%   'sighSpan'       ([]) [startSample endSample] of a paced-sigh /
%                    double-inhale block; inside it, of two detected peaks
%                    closer than 5 s only the first is kept, so the double
%                    inhale segments as one breath. [] = off.
%   'verbose'        (0) passed to the breathmetrics methods.
%
%   OUTPUTS
%   bm         : a breathmetrics object whose inhalePeaks / exhaleTroughs /
%                inhaleOnsets are the ZLP landmarks and whose remaining
%                features were recomputed by the class from them.
%                featuresManuallyEdited is set to 1 so downstream code knows
%                the landmarks were injected. NOTE the object's respiration
%                is the windowed-NORMALIZED detection trace, so its
%                flow/volume features are in locally-rescaled units - see
%                rawVolumes below and the units section of the doc.
%   rawVolumes : (optional) struct with raw-signal-unit volume twins,
%                computed only when requested:
%                .inhaleVolumesRaw / .exhaleVolumesRaw - the toolbox's own
%                volume integral (findRespiratoryVolumes) evaluated on the
%                RAW-unit trace (60-s moving-mean baseline removed) between
%                the SAME onset/offset landmarks stored in bm. The windowed
%                normalization that makes detection robust also makes the
%                object's volumes incomparable across epochs whose breathing
%                depth differs (the 30-s moving-std divisor tracks local
%                depth, so physically large breaths in deep-breathing
%                stretches read SMALLER); these twins restore interpretable
%                amplitude while leaving every timing metric untouched.
%                .note documents the convention. Units remain arbitrary
%                sensor units (not liters): within-recording comparisons are
%                meaningful; normalize per recording for between-subject use.
%
%   REQUIREMENTS: base MATLAB R2017b+ (movmean/movstd/movmax/movmin/movsum,
%   fillmissing) and the Signal Processing Toolbox (findpeaks, used by the
%   'conservative' extrema mode).
%
%   EXAMPLE
%       bmDat = load('sample_data.mat');          % ships with the toolbox
%       [bm, raw] = zlpEstimateAllFeatures(bmDat.resp, bmDat.srate);
%       bm.plotFeatures({'extrema', 'onsets'});
%       median(raw.inhaleVolumesRaw, 'omitnan')

    p = inputParser;
    p.addParameter('dataType', 'humanAirflow');
    p.addParameter('floorFrac', 0.05);
    p.addParameter('blankBelowFrac', []);
    p.addParameter('sighSpan', []);
    p.addParameter('verbose', 0);
    p.parse(varargin{:});
    opt = p.Results;

    if ~ismember(opt.dataType, {'humanAirflow', 'rodentAirflow'})
        error('zlpEstimateAllFeatures:dataType', ...
            ['dataType must be humanAirflow or rodentAirflow - the ' ...
             'manual-adjust path this function relies on exists only for ' ...
             'airflow data types.']);
    end

    if size(resp, 1) > 1, resp = resp'; end
    assert(isvector(resp) && isnumeric(resp), 'resp must be a numeric vector');
    respFilled = fillmissing(double(resp), 'linear', 'EndValues', 'nearest');

    % ---- ZLP segmentation (locked production configuration) ----
    [det, pk0, tr0] = prepBreathTrace_zlp(respFilled, srate, 'conservative', ...
        opt.blankBelowFrac, opt.sighSpan, opt.floorFrac);
    [on, pkP, trP] = findInhaleOnsets_zlp(det, srate, pk0, tr0, ...
        'kneeBacktrack', 0.4, 1.25, 0.50, 0.10);
    on = round(sort(on(:)'));
    assert(numel(on) >= 3, 'zlpEstimateAllFeatures:tooFewBreaths', ...
        'only %d inhale onsets detected - not a usable respiration trace', numel(on));

    % breathmetrics-convention per-inhale landmark arrays: inhalePeaks(k) =
    % the pair peak after onset k; exhaleTroughs(k) = the first trough after
    % that peak (strict alternation makes it the trough inside breath k).
    % Trailing inhales with no following trough are dropped (the class'
    % simplify convention).
    n0 = numel(on);
    pkA = nan(1, n0); trA = nan(1, n0);
    for k = 1:n0
        pcand = pkP(pkP > on(k));
        if isempty(pcand), continue; end
        pkA(k) = pcand(1);
        tcand = trP(trP > pkA(k));
        if ~isempty(tcand), trA(k) = tcand(1); end
    end
    keep = isfinite(pkA);
    on = on(keep); pkA = pkA(keep); trA = trA(keep);
    while ~isempty(on) && ~isfinite(trA(end))
        on(end) = []; pkA(end) = []; trA(end) = [];
    end
    n = numel(on);
    assert(n >= 3, 'zlpEstimateAllFeatures:tooFewBreaths', ...
        'only %d complete breaths after landmark pairing', n);
    pkA = round(pkA); trA = round(trA);

    % ---- inject the landmarks; the class computes everything else ----
    % Sanctioned manual-adjust path: set extrema, let the class derive its
    % own exhale-onset / pause estimates from them (findOnsetsAndPauses),
    % replace the inhale onsets with the ZLP ones, drop any pause onset the
    % new onsets contradict, then manualAdjustPostProcess() recomputes
    % offsets / durations / volumes / secondary features downstream of the
    % adjusted landmarks - exactly what the GUI does after a manual edit.
    bm = breathmetrics(det, srate, opt.dataType);
    bm.correctRespirationToBaseline('sliding', 0, opt.verbose);
    respBC = bm.baselineCorrectedRespiration(:)';
    bm.inhalePeaks   = pkA;
    bm.exhaleTroughs = trA;
    bm.peakInspiratoryFlows  = respBC(pkA);
    bm.troughExpiratoryFlows = respBC(trA);
    bm.findOnsetsAndPauses(opt.verbose);
    bm.inhaleOnsets = on;
    % consistency guard: a pause onset the class estimated from ITS onsets
    % can contradict the injected ones - an inhale pause must fall strictly
    % between the breath's peak and its exhale onset, an exhale pause
    % strictly between the trough and the NEXT inhale onset. Contradicting
    % pauses are set to NaN (= no pause), the class' own missing-pause code.
    inP = bm.inhalePauseOnsets; exP = bm.exhalePauseOnsets;
    exhOn = bm.exhaleOnsets;
    for bi = 1:n
        if bi <= numel(inP) && ~isnan(inP(bi)) && bi <= numel(exhOn) && ...
                ~isnan(exhOn(bi)) && (inP(bi) <= pkA(bi) || inP(bi) >= exhOn(bi))
            inP(bi) = NaN;
        end
        if bi <= numel(exP) && ~isnan(exP(bi)) && (exP(bi) <= trA(bi) || ...
                (bi + 1 <= n && exP(bi) >= on(bi + 1)))
            exP(bi) = NaN;
        end
    end
    bm.inhalePauseOnsets = inP;
    bm.exhalePauseOnsets = exP;
    bm.inhaleTimeToPeak = (pkA - on) / srate;
    bm.manualAdjustPostProcess();
    bm.featuresManuallyEdited = 1;

    % ---- raw-signal-unit volume twins (on request) ----
    if nargout > 1
        rawBC = respFilled - movmean(respFilled, round(60 * srate));
        [vIn, vEx] = findRespiratoryVolumes(rawBC, srate, ...
            bm.inhaleOnsets, bm.exhaleOnsets, bm.inhaleOffsets, bm.exhaleOffsets);
        rawVolumes = struct( ...
            'inhaleVolumesRaw', vIn, ...
            'exhaleVolumesRaw', vEx, ...
            'note', ['findRespiratoryVolumes evaluated on the raw-unit trace ' ...
                     '(60-s moving-mean baseline removed) between the same ' ...
                     'landmarks stored in bm; raw sensor units, not liters']);
    end
end
