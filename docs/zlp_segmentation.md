# ZLP breath segmentation for breathmetrics

An alternative breath-segmentation front end for the `breathmetrics` class,
contributed by the Zelano Lab preprocessing pipeline (ZLP), where it is the
production engine behind every breathmetrics-based output across seven
task pipelines (intracranial + scalp-EEG sessions; belt, pressure and nasal
cannula respiration sensors).

**Entry point:** `zlpEstimateAllFeatures(resp, srate, ...)` — a drop-in
alternative to `bm.estimateAllFeatures()`.

```matlab
[bm, rawVolumes] = zlpEstimateAllFeatures(resp, srate);           % defaults
bm = zlpEstimateAllFeatures(resp, srate, 'sighSpan', [s0 s1]);    % paced sighs
```

---

## 1. Why

Stock breathmetrics finds inhale onsets as the last sample below a global
pause-band threshold in each trough→peak window, with extrema from
global-criterion peak detection. On amplitude-non-stationary recordings —
drifting baselines, breathing depth that changes several-fold between task
blocks, paced slow breathing, acquisition high-pass filters — that places
onsets on exhale troughs, on inhale peaks, or mid-rise, and either splits
single breaths or misses quiet ones depending on where the global criteria
are set.

The ZLP engine replaces breathmetrics' **extrema detection** and
**inhale-onset placement** with a purpose-built two-stage algorithm
(validity-ruled extrema + a slope-walk "kneeBacktrack" onset), while keeping
breathmetrics as the **feature computer**: the landmarks are injected into an
unmodified `breathmetrics` object and every downstream feature (exhale
onsets, pauses, offsets, durations, volumes, secondary statistics) is
recomputed by the class' own sanctioned post-manual-adjustment path
(`manualAdjustPostProcess`), so the whole feature set stays toolbox-native
and toolbox-versioned.

The algorithm was designed through roughly twenty live-reviewed diagnostic
generations plus several single-breath forensic drill-downs on the Zelano
Lab's corpus (≈ 80 task-sessions across seven paradigms, re-reviewed at each
generation), and each rule below exists because a reviewed failure case
demanded it. The configuration shipped here is the locked production version
(rev13, 2026-09).

---

## 2. What replaces what

| breathmetrics step | ZLP replacement |
|---|---|
| `findExtrema` / `findRespiratoryExtrema` | `prepBreathTrace_zlp` (stages 0–1) |
| inhale-onset placement in `findOnsetsAndPauses` | `findInhaleOnsets_zlp` (stages 2–3) |
| everything downstream (exhale onsets, pauses, offsets, durations, volumes, secondary) | **unchanged breathmetrics**, recomputed from the injected landmarks |

Integration sequence inside `zlpEstimateAllFeatures` (usable as a recipe for
injecting any external segmentation):

```matlab
[det, pk0, tr0] = prepBreathTrace_zlp(resp, fs, 'conservative', blankBelowFrac, sighSpan, floorFrac);
[on, pkP, trP]  = findInhaleOnsets_zlp(det, fs, pk0, tr0, 'kneeBacktrack', 0.4, 1.25, 0.50, 0.10);
% pair per-inhale arrays: inhalePeaks(k) = first peak after onset k,
% exhaleTroughs(k) = first trough after that peak; trailing inhales with no
% following trough are dropped (the class' simplify convention)

bm = breathmetrics(det, fs, 'humanAirflow');
bm.correctRespirationToBaseline('sliding', 0, 0);
bm.inhalePeaks   = pkA;                       % OUR extrema
bm.exhaleTroughs = trA;
bm.peakInspiratoryFlows  = respBC(pkA);       % respBC = bm.baselineCorrectedRespiration
bm.troughExpiratoryFlows = respBC(trA);
bm.findOnsetsAndPauses(0);    % class derives exhale onsets + pauses from OUR extrema
bm.inhaleOnsets = on;         % REPLACE inhale onsets with the ZLP ones
% drop any pause onset the new onsets contradict (see the function), then:
bm.inhaleTimeToPeak = (pkA - on) / fs;
bm.manualAdjustPostProcess(); % class recomputes offsets, durations, volumes, secondary
```

`manualAdjustPostProcess` is breathmetrics' own "call this after manually
changing phase onsets" hook — the same path the GUI uses — so nothing inside
the toolbox needed changing.

---

## 3. The algorithm (all constants)

Detection runs on a normalized copy; **the input signal is never modified**.
All thresholds are in normalized units unless marked.

**Stage 0 — detection trace** (`prepBreathTrace_zlp`, common to all modes):

1. Linear NaN fill (nearest at the edges).
2. 500 ms moving-average smoothing.
3. Amplitude normalization: divide by the 30-s moving standard deviation,
   floored at `floorFrac` (default 0.05) × its median. This is what lets one
   prominence criterion serve quiet and deep-breathing epochs alike.
4. Optional blanking: samples whose local scale is below
   `blankBelowFrac` × median are zeroed (hardware-attenuated stretches, e.g.
   a partially unplugged cannula).

**Stage 1 — extrema** (`'conservative'` mode, the locked choice):

5. Peaks: prominence ≥ 0.6, min separation 1.0 s (`findpeaks`); troughs
   identically on the inverted trace.
6. Peak validity: height ≥ 0.5 (floor), **and** some point ≥ 0.5 below the
   peak within the following 1 s (soft descent) — waived for peaks ≥ 1.0.
   Kills exhale-recovery crests before breathing pauses, which pass both
   prominence and the rise filter because each measures against the deep
   trough below them.
7. Strict trough→peak→trough alternation (the more extreme of a same-type
   run wins).
8. Rise filter: a trough→peak rise under 40% of half the local 30-s range is
   a bump, not a breath ⇒ peak deleted.
9. Paced-sigh span only (`sighSpan`): of two peaks within 5 s, keep the
   FIRST — the sigh's top-up peak follows the primary inhale, so the paced
   double inhale segments as one breath.

**Stage 2 — onset eligibility** (`findInhaleOnsets_zlp`; slope = derivative
smoothed 120 ms):

10. Rule 1 (not descending): `x(t) − x(t−0.33 s) > −0.2`.
11. Rule 2 (rising ahead): within `max(0.4 s, 25% of the pair duration)`
    ahead, the trace must exceed `x(t)` by > 0.4. (The window is pair-scaled
    because a fixed 0.4-s window demands a rise rate no slow breath can
    meet.)
12. Eligible = rule 1 AND rule 2.
13. Spurious-pair pruning: a trough→peak window with no eligible sample is a
    false split — trough and peak are deleted and the region absorbs into
    the neighboring breath. (This is why the function returns pruned
    extrema: always take `peaks`/`troughs` from its outputs.)

**Stage 3 — placement (`kneeBacktrack`), one onset per surviving pair:**

14. `dmax` = max slope over the whole window (sets the walk-stop scale);
    the anchor's slope scale = max slope over the window's SECOND HALF only
    (on two-phase breaths a violent first rise otherwise sets a bar the
    final rise cannot meet).
15. Anchor: last point in the second half with slope ≥ 70% of that scale AND
    eligible; fallback: last eligible sample anywhere.
16. Walk back freely until slope < `0.50·dmax` sustained ≥ 0.10 s
    (knife-edge single-sample dips cannot stop the walk).
17. Clean sweep (only if the walk ran to the floor, below trough + 10% of
    the swing — pause-free breaths where no knee exists): onset = last
    upward crossing of the trough/peak midpoint.
18. Late-landing extension (landing above trough + 35%): keep walking under
    slope < `0.05·dmax` sustained 0.15 s — accept only if that stop actually
    fired; on an edge run-out revert to the main walk's landing.
19. Rule-3 refinement: slope contrast over −0.25..+0.5 s must satisfy
    max > 1.25 × max(min, 0.1); a contrast-less landing moves to the nearest
    contrasted sample in-window.
20. Final eligibility snap: a non-eligible landing moves to the nearest
    eligible sample (either direction).
21. Hard floor (applied last so nothing above can undo it): an onset never
    sits in the first 20% of its trough→peak interval — a landing before the
    floor moves forward to the first eligible sample at or after the floor
    (never backward), or to the floor itself if there is none.

---

## 4. Units — and the raw-volume twins

The `breathmetrics` object built by `zlpEstimateAllFeatures` holds the
**windowed-normalized detection trace**, so its flow and volume features are
in locally-rescaled units. That is deliberate (it is what makes detection
robust across epochs) and fine for timing analysis, but it makes amplitude
features **incomparable across epochs whose breathing depth differs**: the
30-s moving-std divisor tracks local depth, so a physically large breath
inside a deep-breathing stretch reads *smaller* than the same breath during
quiet breathing.

For interpretable amplitude analysis, request the second output:

```matlab
[bm, raw] = zlpEstimateAllFeatures(resp, srate);
raw.inhaleVolumesRaw   % toolbox volume integral, raw signal units
raw.exhaleVolumesRaw
```

These are computed by the toolbox's own `findRespiratoryVolumes` on the
raw-unit trace (60-s moving-mean baseline removed) between the **same**
onset/offset landmarks stored in `bm` — timing metrics are untouched; only
the integration trace differs. Units remain arbitrary sensor units (belt or
pressure voltage, not liters): within-recording and cross-condition
comparisons are meaningful; for between-subject comparisons normalize per
recording at analysis time.

Onsets/peaks/troughs are sample indices at `srate`; durations and
time-to-peak are seconds — identical to stock breathmetrics.

---

## 5. Caveats

- The onset thresholds are calibrated to the **normalized** trace of
  stage 0; feeding raw-unit signals into `findInhaleOnsets_zlp` directly
  will not work. Use the functions through `zlpEstimateAllFeatures` (or
  reproduce its conditioning).
- `findInhaleOnsets_zlp` can DELETE extrema (spurious-pair pruning) — always
  take `peaks`/`troughs` from its outputs, not from `prepBreathTrace_zlp`'s.
- Provide `sighSpan` for recordings containing a paced double-inhale (sigh)
  block; without it the double inhale is segmented as two breaths.
- Inhale-pause onsets come from the class' `findOnsetsAndPauses` run on the
  injected extrema; after the inhale onsets are replaced, any pause onset
  the new onsets contradict is set to NaN (no pause) rather than being
  re-estimated. If your analysis leans heavily on inhale-pause detection,
  inspect those estimates.
- Airflow data types only (`humanAirflow` / `rodentAirflow`) — the
  manual-adjust path exists only for them.
- Requirements: base MATLAB R2017b+ and the Signal Processing Toolbox
  (`findpeaks`, used by the `'conservative'` extrema mode; the `'pwl'` mode
  is toolbox-free).

---

## 6. Provenance

Developed and locked in the Zelano Lab preprocessing repository
(`zelanoLabPreprocessing`, where the same two algorithm functions run in
production) over an August–September 2026 QC campaign: ~20 live-reviewed
diagnostic generations on ≈ 80 task-sessions spanning seven paradigms
(free breathing, paced slow breathing and sighs, audiobook listening,
emotional films, meditation, sleep), with per-breath forensic drill-downs
driving each rule. Every constant in §3 is the reviewed production value;
the code here is kept line-identical to the production copies so fixes can
flow both ways.
