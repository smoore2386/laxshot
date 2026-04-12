/*
 * test_shot_detection.cpp
 * Native unit test for shot detection state machine.
 *
 * Since the actual firmware uses Arduino-specific APIs (millis(), Serial, etc.),
 * we replicate the core shot detection logic here with a minimal,
 * self-contained implementation that mirrors the firmware's algorithm.
 */

#include <unity.h>
#include <cmath>
#include <cstdint>

// ─── Replicate firmware constants ────────────────────────────────
#define SHOT_ACCEL_THRESHOLD  8.0f   // g — peak accel to trigger shot
#define SHOT_COOLDOWN_MS      2000   // ms — minimum time between shots
#define SHOT_WINDOW_MS        500    // ms — capture window after trigger

// ─── Replicate firmware types ────────────────────────────────────
struct ImuData {
    float ax, ay, az;
    float gx, gy, gz;
    bool valid;
};

enum class ShotState {
    IDLE,
    DETECTED,
    CAPTURING,
    COOLDOWN
};

struct ShotEvent {
    float peakAccelG;
    unsigned long startTimeMs;
    unsigned long durationMs;
};

// ─── Minimal shot detector (mirrors firmware logic) ──────────────
class ShotDetector {
public:
    ShotState state;
    ShotEvent lastEvent;
    uint32_t shotCount;
    float peakAccel;
    unsigned long shotStartTime;
    unsigned long lastShotEndTime;

    ShotDetector() { reset(); }

    void reset() {
        state = ShotState::IDLE;
        shotCount = 0;
        peakAccel = 0.0f;
        shotStartTime = 0;
        lastShotEndTime = 0;
    }

    static float accelMagnitude(const ImuData& data) {
        return sqrtf(data.ax * data.ax + data.ay * data.ay + data.az * data.az);
    }

    // Returns true if a shot was just completed
    bool update(const ImuData& data, unsigned long nowMs) {
        if (!data.valid) return false;

        float accelMag = accelMagnitude(data);

        switch (state) {
            case ShotState::IDLE:
                if (accelMag > SHOT_ACCEL_THRESHOLD) {
                    if (nowMs - lastShotEndTime > SHOT_COOLDOWN_MS) {
                        state = ShotState::DETECTED;
                        shotStartTime = nowMs;
                        peakAccel = accelMag;
                    }
                }
                break;

            case ShotState::DETECTED:
                state = ShotState::CAPTURING;
                // fall through intentionally

            case ShotState::CAPTURING:
                if (accelMag > peakAccel) {
                    peakAccel = accelMag;
                }
                if (nowMs - shotStartTime > SHOT_WINDOW_MS) {
                    lastEvent.peakAccelG = peakAccel;
                    lastEvent.startTimeMs = shotStartTime;
                    lastEvent.durationMs = nowMs - shotStartTime;
                    shotCount++;
                    lastShotEndTime = nowMs;
                    state = ShotState::COOLDOWN;
                    return true;
                }
                break;

            case ShotState::COOLDOWN:
                if (nowMs - lastShotEndTime > SHOT_COOLDOWN_MS) {
                    state = ShotState::IDLE;
                    peakAccel = 0.0f;
                }
                break;
        }

        return false;
    }
};

// ─── Test fixtures ───────────────────────────────────────────────
static ShotDetector detector;

static ImuData makeImuData(float ax, float ay, float az) {
    ImuData d;
    d.ax = ax;
    d.ay = ay;
    d.az = az;
    d.gx = 0.0f;
    d.gy = 0.0f;
    d.gz = 0.0f;
    d.valid = true;
    return d;
}

void setUp(void) {
    detector.reset();
}

void tearDown(void) {
    // nothing
}

// ─── Tests ───────────────────────────────────────────────────────

void test_initial_state_is_idle(void) {
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);
    TEST_ASSERT_EQUAL_UINT32(0, detector.shotCount);
}

void test_low_accel_not_detected(void) {
    // 1g gravity — should NOT trigger a shot
    ImuData data = makeImuData(0.0f, 0.0f, 1.0f);
    bool result = detector.update(data, 1000);
    TEST_ASSERT_FALSE(result);
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);
}

void test_moderate_accel_not_detected(void) {
    // 5g — below threshold (8g)
    ImuData data = makeImuData(3.0f, 3.0f, 2.0f); // ~4.69g
    bool result = detector.update(data, 1000);
    TEST_ASSERT_FALSE(result);
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);
}

void test_high_accel_triggers_detection(void) {
    // 12g spike — above threshold
    ImuData data = makeImuData(10.0f, 5.0f, 4.0f); // ~12.04g
    bool result = detector.update(data, 3000);  // well past any cooldown
    TEST_ASSERT_FALSE(result);  // Not complete yet, just detected
    TEST_ASSERT_EQUAL(ShotState::DETECTED, detector.state);
}

void test_shot_completes_after_window(void) {
    // Phase 1: Trigger
    ImuData spike = makeImuData(10.0f, 5.0f, 4.0f); // ~12.04g
    detector.update(spike, 3000);
    TEST_ASSERT_EQUAL(ShotState::DETECTED, detector.state);

    // Phase 2: During capture window — transitions to CAPTURING
    ImuData mid = makeImuData(6.0f, 3.0f, 2.0f);
    detector.update(mid, 3200);
    TEST_ASSERT_EQUAL(ShotState::CAPTURING, detector.state);

    // Phase 3: After window elapses (3000 + 500 = 3500, so 3501 should complete)
    ImuData tail = makeImuData(1.0f, 0.0f, 1.0f);
    bool result = detector.update(tail, 3501);
    TEST_ASSERT_TRUE(result);
    TEST_ASSERT_EQUAL(ShotState::COOLDOWN, detector.state);
    TEST_ASSERT_EQUAL_UINT32(1, detector.shotCount);
}

void test_peak_accel_tracked(void) {
    // Initial spike
    ImuData spike1 = makeImuData(10.0f, 0.0f, 0.0f); // 10g
    detector.update(spike1, 3000);

    // Higher spike during capture
    ImuData spike2 = makeImuData(14.0f, 0.0f, 0.0f); // 14g
    detector.update(spike2, 3200);

    // Complete
    ImuData tail = makeImuData(1.0f, 0.0f, 0.0f);
    detector.update(tail, 3501);

    TEST_ASSERT_FLOAT_WITHIN(0.1f, 14.0f, detector.lastEvent.peakAccelG);
}

void test_exactly_at_threshold_not_triggered(void) {
    // Exactly 8.0g — NOT above threshold (> not >=)
    ImuData data = makeImuData(8.0f, 0.0f, 0.0f);
    bool result = detector.update(data, 3000);
    TEST_ASSERT_FALSE(result);
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);
}

void test_just_above_threshold_triggers(void) {
    // 8.01g — just above threshold
    ImuData data = makeImuData(8.01f, 0.0f, 0.0f);
    bool result = detector.update(data, 3000);
    TEST_ASSERT_FALSE(result);  // detected but not completed
    TEST_ASSERT_EQUAL(ShotState::DETECTED, detector.state);
}

void test_cooldown_prevents_immediate_redetection(void) {
    // First shot
    ImuData spike = makeImuData(12.0f, 0.0f, 0.0f);
    detector.update(spike, 3000);
    ImuData tail = makeImuData(1.0f, 0.0f, 0.0f);
    detector.update(tail, 3200);
    detector.update(tail, 3501);
    TEST_ASSERT_EQUAL_UINT32(1, detector.shotCount);

    // Wait for cooldown transition
    detector.update(tail, 5502);  // 3501 + 2001 = past cooldown
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);

    // Now try another shot during cooldown — should still be blocked
    detector.reset();
    detector.update(spike, 3000);
    detector.update(tail, 3501);  // first shot done at 3501
    TEST_ASSERT_EQUAL_UINT32(1, detector.shotCount);

    // Attempt second shot too soon (within 2000ms of end)
    ImuData spike2 = makeImuData(12.0f, 0.0f, 0.0f);
    detector.update(spike2, 4000);  // only 499ms after first shot ended
    TEST_ASSERT_EQUAL(ShotState::COOLDOWN, detector.state);
    TEST_ASSERT_EQUAL_UINT32(1, detector.shotCount);
}

void test_invalid_data_ignored(void) {
    ImuData invalid;
    invalid.ax = 20.0f;
    invalid.ay = 0.0f;
    invalid.az = 0.0f;
    invalid.gx = 0.0f;
    invalid.gy = 0.0f;
    invalid.gz = 0.0f;
    invalid.valid = false;

    bool result = detector.update(invalid, 3000);
    TEST_ASSERT_FALSE(result);
    TEST_ASSERT_EQUAL(ShotState::IDLE, detector.state);
}

void test_shot_count_increments(void) {
    unsigned long t = 3000;

    for (int i = 0; i < 3; i++) {
        // Trigger
        ImuData spike = makeImuData(12.0f, 0.0f, 0.0f);
        detector.update(spike, t);

        // Complete
        ImuData tail = makeImuData(1.0f, 0.0f, 0.0f);
        detector.update(tail, t + 200);
        detector.update(tail, t + 501);

        // Advance past cooldown
        detector.update(tail, t + 2502);

        t += 3000;  // next shot well past cooldown
    }

    TEST_ASSERT_EQUAL_UINT32(3, detector.shotCount);
}

void test_accel_magnitude_calculation(void) {
    ImuData data = makeImuData(3.0f, 4.0f, 0.0f);
    float mag = ShotDetector::accelMagnitude(data);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 5.0f, mag);

    ImuData data2 = makeImuData(0.0f, 0.0f, 0.0f);
    float mag2 = ShotDetector::accelMagnitude(data2);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, mag2);
}

// ─── Main ────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_initial_state_is_idle);
    RUN_TEST(test_low_accel_not_detected);
    RUN_TEST(test_moderate_accel_not_detected);
    RUN_TEST(test_high_accel_triggers_detection);
    RUN_TEST(test_shot_completes_after_window);
    RUN_TEST(test_peak_accel_tracked);
    RUN_TEST(test_exactly_at_threshold_not_triggered);
    RUN_TEST(test_just_above_threshold_triggers);
    RUN_TEST(test_cooldown_prevents_immediate_redetection);
    RUN_TEST(test_invalid_data_ignored);
    RUN_TEST(test_shot_count_increments);
    RUN_TEST(test_accel_magnitude_calculation);
    return UNITY_END();
}
