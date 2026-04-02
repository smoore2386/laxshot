// Shot classification system for men's and women's lacrosse.
//
// Covers all major shot types, mechanics criteria, and per-shot coaching tips.
// Used by the analysis engine to classify recorded shots and generate
// targeted improvement feedback.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Lacrosse discipline — rules and stick mechanics differ significantly.
enum LacrosseDiscipline {
  mens,
  womens,
}

/// Every recognized shot type across men's and women's lacrosse.
enum ShotType {
  // ── Shared (men's & women's) ──
  overhand,
  sidearm,
  underhand,
  behindTheBack,
  onTheRun,
  quickStick,
  bounceShotLow,

  // ── Men's only ──
  shovelShot,       // low cradle, pushing motion
  batDown,          // stick check redirect / deflection near goal
  airGait,          // diving / jumping shot (named after Gary Gait)
  wormBurner,       // low-release wrist shot that stays on the ground
  fakeAndShoot,     // heavy pump-fake to freeze goalie then release

  // ── Women's only ──
  drawShot,         // disguised as a draw control, quick release
  freePosShot,      // 8-meter free position set shot
  twelveMetreShot,  // 12-metre fan shot (lower angle / more defended)
  shovelWomens,     // women's variant — lower pocket, shorter stick
}

/// Body-relative release angle bucket used for mechanics grading.
enum ReleaseAngle {
  high,       // overhead / three-quarter
  threeFourths,
  sidearm,
  low,        // underhand / shovel
}

/// Arm-side classification for laterality feedback.
enum StickSide {
  dominant,
  nonDominant,
}

// ---------------------------------------------------------------------------
// Shot definition
// ---------------------------------------------------------------------------

/// Static metadata for a single shot type: description, key mechanics,
/// common faults, and coaching cues.
class ShotDefinition {
  final ShotType type;
  final String displayName;
  final String description;
  final List<LacrosseDiscipline> disciplines;

  /// The typical release angle for this shot.
  final ReleaseAngle typicalRelease;

  /// Ordered list of the most important mechanics to evaluate.
  /// Each string is a human-readable criterion name that maps to an
  /// analysis category (e.g. "Wrist Snap", "Hip Rotation").
  final List<String> keyCriteria;

  /// Common mistakes players make with this shot type.
  final List<String> commonFaults;

  /// One-line coaching cue for quick reference.
  final String quickCue;

  const ShotDefinition({
    required this.type,
    required this.displayName,
    required this.description,
    required this.disciplines,
    required this.typicalRelease,
    required this.keyCriteria,
    required this.commonFaults,
    required this.quickCue,
  });
}

// ---------------------------------------------------------------------------
// Shot catalog
// ---------------------------------------------------------------------------

/// Master catalog of every shot type with full coaching metadata.
const List<ShotDefinition> shotCatalog = [
  // ── OVERHAND ──────────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.overhand,
    displayName: 'Overhand',
    description:
        'The fundamental power shot. The stick travels from behind the '
        'head forward with a high release point, generating maximum velocity '
        'through hip rotation and wrist snap.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.high,
    keyCriteria: [
      'Hip Rotation',
      'Shoulder Turn',
      'High Release Point',
      'Wrist Snap',
      'Follow-through Extension',
      'Step Toward Target',
    ],
    commonFaults: [
      'Dropping the elbow, lowering release point',
      'All arm — no hip/core rotation',
      'Short follow-through (stopping the stick early)',
      'Leaning back on release instead of driving forward',
      'Off-hand too far from body, losing leverage',
    ],
    quickCue: 'Hands high, hips first, snap and follow through.',
  ),

  // ── SIDEARM ───────────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.sidearm,
    displayName: 'Sidearm',
    description:
        'A deceptive shot released from hip-to-shoulder height with a '
        'horizontal stick path. Changes the goalie\'s eye level and is '
        'effective for stick-side low/far-side shots.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.sidearm,
    keyCriteria: [
      'Level Stick Path',
      'Torso Rotation',
      'Wrist Roll / Snap',
      'Deceptive Wind-up',
      'Balanced Base',
    ],
    commonFaults: [
      'Telegraphing by pulling stick back too far',
      'Rising during release (becomes three-quarter, not true sidearm)',
      'Weak wrist — ball floats instead of snapping to target',
      'Feet square to goal (limits rotational power)',
    ],
    quickCue: 'Stay low, rotate hard, snap at the hip.',
  ),

  // ── UNDERHAND ─────────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.underhand,
    displayName: 'Underhand',
    description:
        'A rising shot released below the waist. Effective for changing '
        'the goalie\'s eye level after high fakes and for close-range '
        'finishes around the crease.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.low,
    keyCriteria: [
      'Low Hand Position',
      'Rising Ball Path',
      'Wrist Curl / Flick',
      'Body Shield (Protecting Stick)',
      'Accuracy to Top Corners',
    ],
    commonFaults: [
      'Releasing too high (becomes sidearm)',
      'No wrist flick — ball has no rise',
      'Exposing the stick to the defender\'s check',
      'Aiming at the goalie\'s feet instead of top corners',
    ],
    quickCue: 'Hands low, flick up, aim high corners.',
  ),

  // ── BEHIND THE BACK ──────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.behindTheBack,
    displayName: 'Behind the Back',
    description:
        'An advanced shot where the stick swings behind the shooter\'s '
        'back before releasing. Extremely deceptive — changes the '
        'release angle and timing the goalie expects.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.sidearm,
    keyCriteria: [
      'Core Rotation',
      'Off-Hand Placement',
      'Wrist Snap Behind Body',
      'Head/Eyes on Target',
      'Smooth Stick Path',
    ],
    commonFaults: [
      'Looking away from the goal during release',
      'Telegraphing by slowing down before the shot',
      'Poor wrist angle — ball sails wide',
      'No follow-through (flicking instead of driving)',
    ],
    quickCue: 'Eyes on target, snap behind, follow through.',
  ),

  // ── ON THE RUN ───────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.onTheRun,
    displayName: 'On the Run',
    description:
        'Any shot taken at full speed — usually on a dodge, fast break, '
        'or transition play. Accuracy drops at speed so mechanics must '
        'stay compact.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.threeFourths,
    keyCriteria: [
      'Compact Wind-up',
      'Balance at Release',
      'Eyes on Target',
      'Step Into Shot (Even While Running)',
      'Quick Release',
    ],
    commonFaults: [
      'Wide wind-up while running (slow and checkable)',
      'Fading away from the goal on release',
      'Shooting off the back foot',
      'Not planting before release (accuracy drops)',
    ],
    quickCue: 'Shorten up, plant, snap — speed is your advantage.',
  ),

  // ── QUICK STICK ──────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.quickStick,
    displayName: 'Quick Stick',
    description:
        'A one-touch redirect where the ball is caught and immediately '
        'released in one motion. Used on feeds from behind the goal or '
        'cross-crease passes.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.threeFourths,
    keyCriteria: [
      'Soft Hands (Catch & Release in One Motion)',
      'Stick Positioning Before Pass Arrives',
      'Redirecting Momentum',
      'Target Acquisition Pre-Catch',
    ],
    commonFaults: [
      'Cradling instead of immediately releasing',
      'Stick not ready before the pass arrives',
      'Looking at the ball instead of the target',
      'Stiff hands — ball bounces out or shot is weak',
    ],
    quickCue: 'Stick ready, eyes on target, one motion.',
  ),

  // ── BOUNCE SHOT ──────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.bounceShotLow,
    displayName: 'Bounce Shot',
    description:
        'Intentionally aimed at the ground 4–6 feet in front of the goal '
        'so the ball bounces up unpredictably. The irregular hop makes it '
        'one of the hardest shots for goalies to read.',
    disciplines: [LacrosseDiscipline.mens, LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.threeFourths,
    keyCriteria: [
      'Downward Aim Point (4–6 ft out)',
      'Hard Release (More Spin = Bigger Hop)',
      'Wrist Snap',
      'Varying Bounce Distance',
    ],
    commonFaults: [
      'Bouncing too close to the goal (easy save)',
      'Bouncing too far out (ball dies before crease)',
      'Soft release — no spin or hop on the bounce',
      'Aiming bounce shot at the goalie\'s stick side',
    ],
    quickCue: 'Aim 5 feet out, snap hard, let it hop.',
  ),

  // ── SHOVEL SHOT (MEN'S) ──────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.shovelShot,
    displayName: 'Shovel Shot',
    description:
        'A men\'s lacrosse finishing move where the player scoops the '
        'ball from a low cradle and pushes it toward the goal. Used for '
        'dive plays and ground-ball scrambles near the crease.',
    disciplines: [LacrosseDiscipline.mens],
    typicalRelease: ReleaseAngle.low,
    keyCriteria: [
      'Low Stick Position',
      'Forward Push Through Ball',
      'Body Protection',
      'Accuracy Despite Contact',
    ],
    commonFaults: [
      'Lifting the ball too high (over the cage)',
      'Weak push — goalie smothers it',
      'Exposing stick to checks',
    ],
    quickCue: 'Scoop low, push hard, protect your stick.',
  ),

  // ── BAT-DOWN / DEFLECTION ────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.batDown,
    displayName: 'Bat Down / Deflection',
    description:
        'A men\'s lacrosse play where the ball is redirected mid-air '
        '(from a pass or shot) toward the goal using the stick face. '
        'Requires excellent hand-eye coordination.',
    disciplines: [LacrosseDiscipline.mens],
    typicalRelease: ReleaseAngle.high,
    keyCriteria: [
      'Hand-Eye Coordination',
      'Stick Angle at Contact',
      'Timing with Ball Flight',
      'Positioning in Front of Crease',
    ],
    commonFaults: [
      'Swinging at the ball instead of angling the stick',
      'Standing flat-footed instead of being on toes',
      'Not squaring to the goal before redirecting',
    ],
    quickCue: 'Get your stick in the lane, angle it down.',
  ),

  // ── AIR GAIT ─────────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.airGait,
    displayName: 'Air Gait (Dive Shot)',
    description:
        'Named after Gary Gait\'s iconic 1988 NCAA goal — the player '
        'leaps from behind the goal and shoots while airborne over the '
        'crease. Legal in men\'s lacrosse as long as the ball is '
        'released before landing in the crease.',
    disciplines: [LacrosseDiscipline.mens],
    typicalRelease: ReleaseAngle.high,
    keyCriteria: [
      'Explosive Takeoff',
      'Ball Release Before Landing',
      'Shot Placement While Airborne',
      'Body Control',
    ],
    commonFaults: [
      'Landing in the crease before releasing the ball',
      'Losing accuracy because of air-time adrenaline',
      'Telegraphing the jump (goalie reads it)',
    ],
    quickCue: 'Launch, release before you land, pick a corner.',
  ),

  // ── WORM BURNER ──────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.wormBurner,
    displayName: 'Worm Burner',
    description:
        'A low, hard wrist shot that stays on the ground or just above '
        'it. Difficult for goalies who stand tall in their stance. Most '
        'effective far-side low.',
    disciplines: [LacrosseDiscipline.mens],
    typicalRelease: ReleaseAngle.low,
    keyCriteria: [
      'Low Release Point',
      'Hard Wrist Snap',
      'Ball Stays on Ground / Skips',
      'Accuracy to Far-Side Low',
    ],
    commonFaults: [
      'Ball rises — becomes a normal shot, not a worm burner',
      'Weak wrist — shot is slow enough for goalie to get down',
      'Aiming stick-side (goalie\'s stick is already low)',
    ],
    quickCue: 'Snap your wrists down, keep it on the turf.',
  ),

  // ── FAKE & SHOOT ─────────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.fakeAndShoot,
    displayName: 'Fake & Shoot',
    description:
        'A deliberate pump-fake (or multiple fakes) to freeze or move '
        'the goalie, then a quick release to the opened space. The fake '
        'must look identical to a real shot.',
    disciplines: [LacrosseDiscipline.mens],
    typicalRelease: ReleaseAngle.threeFourths,
    keyCriteria: [
      'Realistic Fake (Full Body Commitment)',
      'Eye Discipline (Look Where You Fake)',
      'Quick Transition from Fake to Shot',
      'Reading Goalie Movement',
      'Changing Release Angle After Fake',
    ],
    commonFaults: [
      'Fake is too weak — goalie doesn\'t react',
      'Pausing too long between fake and shot',
      'Not changing the angle after the fake',
      'Double-clutching (cradling between fake and shot)',
    ],
    quickCue: 'Sell the fake, read the goalie, shoot the opening.',
  ),

  // ── DRAW SHOT (WOMEN'S) ──────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.drawShot,
    displayName: 'Draw Shot',
    description:
        'A women\'s lacrosse technique where the shooter disguises the '
        'shot as a draw or passing motion, then redirects to the goal. '
        'The deception beats goalies who read stick motion.',
    disciplines: [LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.threeFourths,
    keyCriteria: [
      'Deceptive Wind-up',
      'Quick Release Change',
      'Wrist Redirection',
      'Body Sells the Fake',
    ],
    commonFaults: [
      'Too obvious — goalie reads the redirection early',
      'Slow transition from draw motion to shot',
      'Inaccurate due to last-second angle change',
    ],
    quickCue: 'Start like a draw, finish like a shot.',
  ),

  // ── FREE POSITION SHOT (WOMEN'S 8-METRE) ─────────────────────────────────
  ShotDefinition(
    type: ShotType.freePosShot,
    displayName: 'Free Position (8m)',
    description:
        'A set shot awarded at the 8-metre arc in women\'s lacrosse. '
        'The shooter has a clear, uncontested look at the goal. Time and '
        'space allow for full mechanics and placement.',
    disciplines: [LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.high,
    keyCriteria: [
      'Full Mechanical Follow-through',
      'Shot Placement to Corners',
      'Pre-Shot Routine Consistency',
      'Hip & Shoulder Alignment',
      'Confident Approach Step',
    ],
    commonFaults: [
      'Rushing the shot (no need — it\'s a free position)',
      'Aiming center instead of corners',
      'Inconsistent pre-shot routine',
      'Poor foot alignment to target',
    ],
    quickCue: 'You have time — pick your corner, full mechanics.',
  ),

  // ── 12-METRE SHOT (WOMEN'S) ──────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.twelveMetreShot,
    displayName: '12-Metre Fan Shot',
    description:
        'A women\'s lacrosse set shot from the 12-metre fan. More '
        'defended than an 8-metre, requiring more velocity and sharper '
        'placement since defenders are closer.',
    disciplines: [LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.high,
    keyCriteria: [
      'Extra Velocity (Longer Distance)',
      'High Release Over Defenders',
      'Quick Decision-Making',
      'Shot Placement Accuracy',
    ],
    commonFaults: [
      'Shooting into the defender\'s stick',
      'Telegraphing wind-up — defender steps to block',
      'Falling away from the goal (losing power)',
      'Aiming wide because of pressure',
    ],
    quickCue: 'Release high, aim low corners, power through.',
  ),

  // ── SHOVEL (WOMEN'S) ─────────────────────────────────────────────────────
  ShotDefinition(
    type: ShotType.shovelWomens,
    displayName: 'Shovel (Women\'s)',
    description:
        'Similar to the men\'s shovel but adapted for the women\'s '
        'shallower pocket and stick. Used for close-range crease '
        'finishes with a flicking/pushing motion.',
    disciplines: [LacrosseDiscipline.womens],
    typicalRelease: ReleaseAngle.low,
    keyCriteria: [
      'Pocket Control (Shallow Pocket)',
      'Quick Forward Flick',
      'Body Positioning for Protection',
      'Accuracy in Tight Spaces',
    ],
    commonFaults: [
      'Ball slips out of the shallow pocket',
      'Over-flicking (ball sails over the cage)',
      'Not protecting the stick from checks',
    ],
    quickCue: 'Cradle tight, flick fast, stay low.',
  ),
];

// ---------------------------------------------------------------------------
// Analysis criteria
// ---------------------------------------------------------------------------

/// Universal mechanics categories evaluated on every shot.
/// Each receives a 0–100 score from the analysis engine.
enum MechanicsCategory {
  hipRotation,
  shoulderTurn,
  releasePoint,
  wristSnap,
  followThrough,
  footwork,
  balance,
  stickProtection,
}

/// Human-readable labels for [MechanicsCategory].
const Map<MechanicsCategory, String> mechanicsCategoryLabels = {
  MechanicsCategory.hipRotation: 'Hip Rotation',
  MechanicsCategory.shoulderTurn: 'Shoulder Turn',
  MechanicsCategory.releasePoint: 'Release Point',
  MechanicsCategory.wristSnap: 'Wrist Snap',
  MechanicsCategory.followThrough: 'Follow-through',
  MechanicsCategory.footwork: 'Footwork',
  MechanicsCategory.balance: 'Balance',
  MechanicsCategory.stickProtection: 'Stick Protection',
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns only shot definitions for a given discipline.
List<ShotDefinition> shotsForDiscipline(LacrosseDiscipline discipline) {
  return shotCatalog
      .where((s) => s.disciplines.contains(discipline))
      .toList();
}

/// Look up a [ShotDefinition] by type.
ShotDefinition? shotDefinitionFor(ShotType type) {
  for (final s in shotCatalog) {
    if (s.type == type) return s;
  }
  return null;
}
