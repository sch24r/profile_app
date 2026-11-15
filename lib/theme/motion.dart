import 'package:flutter/animation.dart';

/// Motion tokens — measured from the original recording
/// (docs/observed-motion-spec.md §3a). Pattern ids P1..P26 refer to that doc.
abstract final class Motion {
  // ── Curves ────────────────────────────────────────────────────────────
  /// Main curve: reveals, nav drop, accordion, chip swap, slide-outs.
  static const Curve expoOut = Cubic(0.19, 1.0, 0.22, 1.0);

  /// Opacity-only fades (nav collapse, block-decode swap).
  static const Curve sineOut = Cubic(0.39, 0.575, 0.565, 1.0);

  /// Polygon zoom (P1) — applied in log-scale space.
  static const Curve zoom = Curves.easeInOutSine;

  /// ONLY for the chapter-indicator dot ↔ bar (P15).
  static const Curve indicator = Cubic(0.4, 1.35, 0.5, 0.97);

  /// In-page scrollTo.
  static const Curve scrollTo = Curves.easeInOutCubic;

  // ── Durations ─────────────────────────────────────────────────────────
  static const introMask = Duration(milliseconds: 1000); // P1 intro
  static const introMaskMobile = Duration(milliseconds: 900);
  static const routeHold = Duration(
    milliseconds: 200,
  ); // P1 route: solid overlay
  static const routeMask = Duration(milliseconds: 900); // P1 route: zoom
  static const routeMaskMobile = Duration(milliseconds: 700);
  static const reducedFade = Duration(milliseconds: 150);
  static const ctaMorph = Duration(milliseconds: 400); // P3 (starts at +400ms)
  static const navDrop = Duration(milliseconds: 700); // P4 (starts at +800ms)
  static const avatarRise = Duration(
    milliseconds: 800,
  ); // P5 (starts at +1000ms)
  static const avatarRiseMobile = Duration(milliseconds: 600);
  static const toastFade = Duration(milliseconds: 300);
  static const navFade = Duration(milliseconds: 400); // P6
  static const menuOpen = Duration(milliseconds: 350);
  static const menuClose = Duration(milliseconds: 250);
  static const hoverIn = Duration(milliseconds: 200); // P19
  static const hoverOut = Duration(milliseconds: 400);
  static const accordionIn = Duration(milliseconds: 450); // P11
  static const accordionOut = Duration(milliseconds: 500);
  static const chipSwap = Duration(milliseconds: 300); // P12
  static const labelRoll = Duration(milliseconds: 300); // P17
  static const press = Duration(milliseconds: 120);
  static const fade = Duration(milliseconds: 300);
  static const themeSwitch = Duration(milliseconds: 200); // P20
  static const segmentThumb = Duration(milliseconds: 250); // P25
  static const segmentContent = Duration(milliseconds: 500);
  static const indicatorStep = Duration(milliseconds: 300); // P15
  static const indicatorSlide = Duration(milliseconds: 400);
  static const storyItem = Duration(milliseconds: 300); // P23
  static const visualSwap = Duration(milliseconds: 200);
  static const polyReveal = Duration(milliseconds: 700); // P24
  static const mobileReveal = Duration(milliseconds: 500); // mobile fallback
  static const cardFlip = Duration(milliseconds: 600); // mobile chapter 1
  static const insetClip = Duration(milliseconds: 700); // mobile chapter 2
  static const scrollToDuration = Duration(milliseconds: 900);

  // P13 block-decode (observed: 200 ms line stagger, 120 fade, hold to 800, 150 swap)
  static const blockLineStagger = Duration(milliseconds: 200);
  static const blockFadeIn = Duration(milliseconds: 120);
  static const blockHold = Duration(milliseconds: 800);
  static const blockSwap = Duration(milliseconds: 150);

  // ── Stagger (mobile fallback lists only) ─────────────────────────────
  static const stagger = Duration(milliseconds: 60);
  static const maxStaggerIndex = 6;

  // ── Distances / factors ───────────────────────────────────────────────
  static const navDropFrom = -28.0;
  static const avatarRiseFrom = 72.0;
  static const chipSwapOffset = 10.0;
  static const mobileRevealDistance = 32.0;

  /// P10 side cards rise from this fraction of the viewport height (scrubbed).
  static const riseFromVh = 0.75;

  /// Nav collapses after scrolling this fraction of viewport height (P6).
  static const navCollapseVh = 0.12;
  static const navExpandScrollUp = 24.0;

  /// Mobile one-shot trigger: element fraction visible.
  static const mobileTriggerFraction = 0.35;

  // ── Loops ─────────────────────────────────────────────────────────────
  static const marqueeStrip = 90.0; // px/s desktop
  static const marqueeStripMobile = 40.0;
  static const marqueeWall = 40.0;

  // ── Pointer ───────────────────────────────────────────────────────────
  static const pointerLerp = 0.12; // P14 look
  static const tiltLerp = 0.10; // P18
  static const tiltMaxY = 14.0; // degrees
  static const tiltMaxX = 6.0;
  static const lookMax = 12.0;

  /// Per-frame smoothing for scrubbed PinnedStage progress.
  static const scrubSmoothing = 0.25;
}
