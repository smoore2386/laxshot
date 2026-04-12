/*
 * test_madgwick.cpp
 * Native unit test for Madgwick AHRS filter quaternion output.
 *
 * Since the actual MadgwickAHRS library has private quaternion members,
 * we implement a minimal Madgwick filter here for testing purposes.
 * This verifies that the algorithm produces unit quaternions and
 * converges to expected orientations with known inputs.
 */

#include <unity.h>
#include <cmath>

// ─── Minimal Madgwick filter (self-contained for native test) ────
// Simplified from the original Madgwick algorithm.
class MadgwickFilter {
public:
    float q0, q1, q2, q3;  // quaternion (w, x, y, z)
    float beta;
    float invSampleFreq;

    MadgwickFilter() : q0(1.0f), q1(0.0f), q2(0.0f), q3(0.0f),
                       beta(0.1f), invSampleFreq(1.0f / 416.0f) {}

    void begin(float sampleFreq) {
        invSampleFreq = 1.0f / sampleFreq;
    }

    void updateIMU(float gx, float gy, float gz,
                   float ax, float ay, float az) {
        float recipNorm;
        float s0, s1, s2, s3;
        float qDot1, qDot2, qDot3, qDot4;
        float _2q0, _2q1, _2q2, _2q3;
        float _4q0, _4q1, _4q2;
        float _8q1, _8q2;
        float q0q0, q1q1, q2q2, q3q3;

        // Convert gyroscope degrees/s to radians/s
        gx *= 0.0174533f;
        gy *= 0.0174533f;
        gz *= 0.0174533f;

        // Rate of change of quaternion from gyroscope
        qDot1 = 0.5f * (-q1 * gx - q2 * gy - q3 * gz);
        qDot2 = 0.5f * ( q0 * gx + q2 * gz - q3 * gy);
        qDot3 = 0.5f * ( q0 * gy - q1 * gz + q3 * gx);
        qDot4 = 0.5f * ( q0 * gz + q1 * gy - q2 * gx);

        // Compute feedback only if accelerometer measurement valid
        if (!((ax == 0.0f) && (ay == 0.0f) && (az == 0.0f))) {
            // Normalize accelerometer measurement
            recipNorm = 1.0f / sqrtf(ax * ax + ay * ay + az * az);
            ax *= recipNorm;
            ay *= recipNorm;
            az *= recipNorm;

            // Auxiliary variables to avoid repeated arithmetic
            _2q0 = 2.0f * q0;
            _2q1 = 2.0f * q1;
            _2q2 = 2.0f * q2;
            _2q3 = 2.0f * q3;
            _4q0 = 4.0f * q0;
            _4q1 = 4.0f * q1;
            _4q2 = 4.0f * q2;
            _8q1 = 8.0f * q1;
            _8q2 = 8.0f * q2;
            q0q0 = q0 * q0;
            q1q1 = q1 * q1;
            q2q2 = q2 * q2;
            q3q3 = q3 * q3;

            // Gradient descent corrective step
            s0 = _4q0 * q2q2 + _2q2 * ax + _4q0 * q1q1 - _2q1 * ay;
            s1 = _4q1 * q3q3 - _2q3 * ax + 4.0f * q0q0 * q1 - _2q0 * ay - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * az;
            s2 = 4.0f * q0q0 * q2 + _2q0 * ax + _4q2 * q3q3 - _2q3 * ay - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * az;
            s3 = 4.0f * q1q1 * q3 - _2q1 * ax + 4.0f * q2q2 * q3 - _2q2 * ay;

            float sMag = s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3;
            if (sMag > 1e-12f) {
                recipNorm = 1.0f / sqrtf(sMag);
                s0 *= recipNorm;
                s1 *= recipNorm;
                s2 *= recipNorm;
                s3 *= recipNorm;

                // Apply feedback step
                qDot1 -= beta * s0;
                qDot2 -= beta * s1;
                qDot3 -= beta * s2;
                qDot4 -= beta * s3;
            }
        }

        // Integrate rate of change of quaternion to yield quaternion
        q0 += qDot1 * invSampleFreq;
        q1 += qDot2 * invSampleFreq;
        q2 += qDot3 * invSampleFreq;
        q3 += qDot4 * invSampleFreq;

        // Normalize quaternion
        recipNorm = 1.0f / sqrtf(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
        q0 *= recipNorm;
        q1 *= recipNorm;
        q2 *= recipNorm;
        q3 *= recipNorm;
    }

    float quaternionNorm() const {
        return sqrtf(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
    }
};

// ─── Test fixtures ───────────────────────────────────────────────
static MadgwickFilter filter;

void setUp(void) {
    filter = MadgwickFilter();
    filter.begin(416.0f);  // Same as firmware
}

void tearDown(void) {
    // nothing
}

// ─── Tests ───────────────────────────────────────────────────────

void test_initial_quaternion_is_identity(void) {
    TEST_ASSERT_FLOAT_WITHIN(0.0001f, 1.0f, filter.q0);
    TEST_ASSERT_FLOAT_WITHIN(0.0001f, 0.0f, filter.q1);
    TEST_ASSERT_FLOAT_WITHIN(0.0001f, 0.0f, filter.q2);
    TEST_ASSERT_FLOAT_WITHIN(0.0001f, 0.0f, filter.q3);
}

void test_quaternion_is_unit_after_single_update(void) {
    // Gravity pointing down (sensor flat, right-side up)
    filter.updateIMU(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);

    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.0001f, 1.0f, norm);
}

void test_quaternion_stays_unit_after_many_updates(void) {
    // Feed 1000 samples of stationary data (gravity = +Z)
    for (int i = 0; i < 1000; i++) {
        filter.updateIMU(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);
    }

    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, norm);
}

void test_stationary_z_up_converges(void) {
    // Accelerometer reports gravity on +Z axis (device flat, Z up)
    // With no gyro input, the filter should converge to identity quaternion
    for (int i = 0; i < 5000; i++) {
        filter.updateIMU(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);
    }

    // Should be close to identity (w=1, x=0, y=0, z=0)
    // or its negative (w=-1, x=0, y=0, z=0) — both represent same orientation
    float w_abs = fabsf(filter.q0);
    TEST_ASSERT_FLOAT_WITHIN(0.05f, 1.0f, w_abs);
    TEST_ASSERT_FLOAT_WITHIN(0.05f, 0.0f, filter.q1);
    TEST_ASSERT_FLOAT_WITHIN(0.05f, 0.0f, filter.q2);
    TEST_ASSERT_FLOAT_WITHIN(0.05f, 0.0f, filter.q3);
}

void test_quaternion_unit_with_gyro_rotation(void) {
    // Simulate constant rotation around Z axis (yaw)
    for (int i = 0; i < 1000; i++) {
        filter.updateIMU(0.0f, 0.0f, 90.0f,  // 90 deg/s around Z
                         0.0f, 0.0f, 1.0f);   // gravity on Z
    }

    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, norm);
}

void test_quaternion_changes_with_rotation(void) {
    // Record initial state
    float initial_q0 = filter.q0;

    // Apply rotation around X axis (pitch) — gravity feedback won't cancel this
    for (int i = 0; i < 500; i++) {
        filter.updateIMU(180.0f, 0.0f, 0.0f,  // fast pitch rotation
                         0.0f, 0.0f, 1.0f);
    }

    // Quaternion should have changed
    bool changed = (fabsf(filter.q0 - initial_q0) > 0.001f) ||
                   (fabsf(filter.q1) > 0.001f) ||
                   (fabsf(filter.q2) > 0.001f) ||
                   (fabsf(filter.q3) > 0.001f);
    TEST_ASSERT_TRUE(changed);
}

void test_zero_accel_uses_gyro_only(void) {
    // Zero accelerometer = freefall; filter should use gyro only
    filter.updateIMU(0.0f, 0.0f, 100.0f, 0.0f, 0.0f, 0.0f);

    // Should still produce a unit quaternion
    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, norm);
}

void test_high_acceleration_produces_unit_quaternion(void) {
    // Simulate a shot — very high accelerometer reading
    for (int i = 0; i < 50; i++) {
        filter.updateIMU(100.0f, 50.0f, 200.0f,  // wild gyro
                         12.0f, 5.0f, 8.0f);      // high-g accel
    }

    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, norm);
}

void test_negative_gravity_x_axis(void) {
    // Gravity on -X axis (device tilted 90 degrees)
    for (int i = 0; i < 5000; i++) {
        filter.updateIMU(0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f);
    }

    // Should converge to a 90-degree rotation around Y axis
    // The quaternion should NOT be identity
    float w_abs = fabsf(filter.q0);
    TEST_ASSERT_TRUE(w_abs < 0.95f);  // definitely rotated

    float norm = filter.quaternionNorm();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, norm);
}

void test_sample_rate_affects_integration(void) {
    // Higher sample rate = smaller time step = less rotation per call
    MadgwickFilter fast_filter;
    fast_filter.begin(1000.0f);

    MadgwickFilter slow_filter;
    slow_filter.begin(100.0f);

    // One update with gyro rotation around Z — from identity, this primarily
    // changes q3 via qDot4 = 0.5 * q0 * gz_rad, where q0 starts at 1.0
    fast_filter.updateIMU(0.0f, 0.0f, 90.0f, 0.0f, 0.0f, 1.0f);
    slow_filter.updateIMU(0.0f, 0.0f, 90.0f, 0.0f, 0.0f, 1.0f);

    // Slow filter (larger dt) should have more change in q3
    float fast_q3_change = fabsf(fast_filter.q3);
    float slow_q3_change = fabsf(slow_filter.q3);

    TEST_ASSERT_TRUE(slow_q3_change > fast_q3_change);
}

// ─── Main ────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_initial_quaternion_is_identity);
    RUN_TEST(test_quaternion_is_unit_after_single_update);
    RUN_TEST(test_quaternion_stays_unit_after_many_updates);
    RUN_TEST(test_stationary_z_up_converges);
    RUN_TEST(test_quaternion_unit_with_gyro_rotation);
    RUN_TEST(test_quaternion_changes_with_rotation);
    RUN_TEST(test_zero_accel_uses_gyro_only);
    RUN_TEST(test_high_acceleration_produces_unit_quaternion);
    RUN_TEST(test_negative_gravity_x_axis);
    RUN_TEST(test_sample_rate_affects_integration);
    return UNITY_END();
}
