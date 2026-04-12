/*
 * test_packet_builder.cpp
 * Native unit test for 48-byte BLE motion packet assembly.
 *
 * Tests that the packet builder produces the correct byte layout:
 *   [0-11]   float32[3] accelerometer (x, y, z) in g
 *   [12-23]  float32[3] gyroscope (x, y, z) in deg/s
 *   [24-39]  float32[4] quaternion (w, x, y, z)
 *   [40]     uint8 battery percentage (0-100)
 *   [41]     uint8 flags (bit 0: in-shot, bit 1: session-active)
 *   [42-45]  uint32 timestamp (ms since boot)
 *   [46-47]  uint16 reserved
 */

#include <unity.h>
#include <cstring>
#include <cstdint>

// ─── Replicate firmware constants ────────────────────────────────
#define BLE_PACKET_SIZE  48

// ─── Replicate firmware types ────────────────────────────────────
struct ImuData {
    float ax, ay, az;
    float gx, gy, gz;
    bool valid;
};

// ─── Packet builder (mirrors firmware's buildMotionPacket) ───────
static void buildMotionPacket(uint8_t* buffer,
                              const ImuData& imu,
                              const float q[4],
                              uint8_t battPct,
                              bool inShot,
                              bool sessionActive,
                              uint32_t timestamp) {
    memset(buffer, 0, BLE_PACKET_SIZE);
    uint16_t offset = 0;

    // Accelerometer: float32[3] (12 bytes)
    memcpy(&buffer[offset], &imu.ax, sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &imu.ay, sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &imu.az, sizeof(float)); offset += sizeof(float);

    // Gyroscope: float32[3] (12 bytes)
    memcpy(&buffer[offset], &imu.gx, sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &imu.gy, sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &imu.gz, sizeof(float)); offset += sizeof(float);

    // Quaternion: float32[4] (16 bytes)
    memcpy(&buffer[offset], &q[0], sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &q[1], sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &q[2], sizeof(float)); offset += sizeof(float);
    memcpy(&buffer[offset], &q[3], sizeof(float)); offset += sizeof(float);

    // Battery: uint8 (1 byte)
    buffer[offset] = battPct; offset += 1;

    // Flags: uint8 (1 byte)
    uint8_t flags = 0;
    if (inShot)        flags |= 0x01;
    if (sessionActive) flags |= 0x02;
    buffer[offset] = flags; offset += 1;

    // Timestamp: uint32 (4 bytes)
    memcpy(&buffer[offset], &timestamp, sizeof(uint32_t)); offset += sizeof(uint32_t);

    // Reserved: uint16 (2 bytes) — already zeroed
}

// ─── Packet parser (for round-trip verification) ─────────────────
struct ParsedPacket {
    float ax, ay, az;
    float gx, gy, gz;
    float qw, qx, qy, qz;
    uint8_t battery;
    uint8_t flags;
    uint32_t timestamp;
    uint16_t reserved;
};

static ParsedPacket parseMotionPacket(const uint8_t* buffer) {
    ParsedPacket p;
    uint16_t offset = 0;

    memcpy(&p.ax, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.ay, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.az, &buffer[offset], sizeof(float)); offset += sizeof(float);

    memcpy(&p.gx, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.gy, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.gz, &buffer[offset], sizeof(float)); offset += sizeof(float);

    memcpy(&p.qw, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.qx, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.qy, &buffer[offset], sizeof(float)); offset += sizeof(float);
    memcpy(&p.qz, &buffer[offset], sizeof(float)); offset += sizeof(float);

    p.battery = buffer[offset]; offset += 1;
    p.flags   = buffer[offset]; offset += 1;

    memcpy(&p.timestamp, &buffer[offset], sizeof(uint32_t)); offset += sizeof(uint32_t);
    memcpy(&p.reserved,  &buffer[offset], sizeof(uint16_t)); offset += sizeof(uint16_t);

    return p;
}

// ─── Test fixtures ───────────────────────────────────────────────
static uint8_t packet[BLE_PACKET_SIZE];

void setUp(void) {
    memset(packet, 0xFF, BLE_PACKET_SIZE);  // Fill with 0xFF to detect missed zeros
}

void tearDown(void) {
    // nothing
}

// ─── Tests ───────────────────────────────────────────────────────

void test_packet_size_is_48_bytes(void) {
    TEST_ASSERT_EQUAL(48, BLE_PACKET_SIZE);
}

void test_build_and_parse_round_trip(void) {
    ImuData imu = {1.5f, -2.5f, 9.81f, 100.0f, -50.0f, 25.0f, true};
    float q[4] = {0.707f, 0.0f, 0.707f, 0.0f};
    uint32_t ts = 123456;

    buildMotionPacket(packet, imu, q, 85, true, true, ts);
    ParsedPacket p = parseMotionPacket(packet);

    // Accelerometer
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.5f, p.ax);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -2.5f, p.ay);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 9.81f, p.az);

    // Gyroscope
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 100.0f, p.gx);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -50.0f, p.gy);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 25.0f, p.gz);

    // Quaternion
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.707f, p.qw);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, p.qx);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.707f, p.qy);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, p.qz);

    // Battery
    TEST_ASSERT_EQUAL_UINT8(85, p.battery);

    // Flags: inShot=1, sessionActive=1 -> 0x03
    TEST_ASSERT_EQUAL_UINT8(0x03, p.flags);

    // Timestamp
    TEST_ASSERT_EQUAL_UINT32(123456, p.timestamp);

    // Reserved
    TEST_ASSERT_EQUAL_UINT16(0, p.reserved);
}

void test_byte_layout_accelerometer(void) {
    ImuData imu = {1.0f, 2.0f, 3.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);

    // Verify accelerometer bytes at expected offsets
    float ax_read, ay_read, az_read;
    memcpy(&ax_read, &packet[0],  sizeof(float));
    memcpy(&ay_read, &packet[4],  sizeof(float));
    memcpy(&az_read, &packet[8],  sizeof(float));

    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, ax_read);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 2.0f, ay_read);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 3.0f, az_read);
}

void test_byte_layout_gyroscope(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 100.0f, 200.0f, 300.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);

    float gx_read, gy_read, gz_read;
    memcpy(&gx_read, &packet[12], sizeof(float));
    memcpy(&gy_read, &packet[16], sizeof(float));
    memcpy(&gz_read, &packet[20], sizeof(float));

    TEST_ASSERT_FLOAT_WITHIN(0.001f, 100.0f, gx_read);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 200.0f, gy_read);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 300.0f, gz_read);
}

void test_byte_layout_quaternion(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {0.5f, 0.5f, 0.5f, 0.5f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);

    float qw, qx, qy, qz;
    memcpy(&qw, &packet[24], sizeof(float));
    memcpy(&qx, &packet[28], sizeof(float));
    memcpy(&qy, &packet[32], sizeof(float));
    memcpy(&qz, &packet[36], sizeof(float));

    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.5f, qw);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.5f, qx);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.5f, qy);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.5f, qz);
}

void test_byte_layout_battery_and_flags(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 72, true, false, 0);

    TEST_ASSERT_EQUAL_UINT8(72, packet[40]);
    TEST_ASSERT_EQUAL_UINT8(0x01, packet[41]);  // inShot only
}

void test_flags_session_active_only(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 50, false, true, 0);

    TEST_ASSERT_EQUAL_UINT8(0x02, packet[41]);  // sessionActive only
}

void test_flags_none_set(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);

    TEST_ASSERT_EQUAL_UINT8(0x00, packet[41]);
}

void test_byte_layout_timestamp(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};
    uint32_t ts = 0xDEADBEEF;

    buildMotionPacket(packet, imu, q, 0, false, false, ts);

    uint32_t ts_read;
    memcpy(&ts_read, &packet[42], sizeof(uint32_t));
    TEST_ASSERT_EQUAL_UINT32(0xDEADBEEF, ts_read);
}

void test_reserved_bytes_are_zero(void) {
    ImuData imu = {1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, true};
    float q[4] = {0.5f, 0.5f, 0.5f, 0.5f};

    buildMotionPacket(packet, imu, q, 100, true, true, 999999);

    TEST_ASSERT_EQUAL_UINT8(0, packet[46]);
    TEST_ASSERT_EQUAL_UINT8(0, packet[47]);
}

void test_negative_values_preserved(void) {
    ImuData imu = {-16.0f, -8.0f, -1.0f, -2000.0f, -1000.0f, -500.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);
    ParsedPacket p = parseMotionPacket(packet);

    TEST_ASSERT_FLOAT_WITHIN(0.001f, -16.0f, p.ax);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -8.0f, p.ay);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, p.az);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -2000.0f, p.gx);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1000.0f, p.gy);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -500.0f, p.gz);
}

void test_zero_timestamp(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 0, false, false, 0);

    uint32_t ts_read;
    memcpy(&ts_read, &packet[42], sizeof(uint32_t));
    TEST_ASSERT_EQUAL_UINT32(0, ts_read);
}

void test_max_battery_value(void) {
    ImuData imu = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, true};
    float q[4] = {1.0f, 0.0f, 0.0f, 0.0f};

    buildMotionPacket(packet, imu, q, 100, false, false, 0);
    TEST_ASSERT_EQUAL_UINT8(100, packet[40]);
}

// ─── Main ────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_packet_size_is_48_bytes);
    RUN_TEST(test_build_and_parse_round_trip);
    RUN_TEST(test_byte_layout_accelerometer);
    RUN_TEST(test_byte_layout_gyroscope);
    RUN_TEST(test_byte_layout_quaternion);
    RUN_TEST(test_byte_layout_battery_and_flags);
    RUN_TEST(test_flags_session_active_only);
    RUN_TEST(test_flags_none_set);
    RUN_TEST(test_byte_layout_timestamp);
    RUN_TEST(test_reserved_bytes_are_zero);
    RUN_TEST(test_negative_values_preserved);
    RUN_TEST(test_zero_timestamp);
    RUN_TEST(test_max_battery_value);
    return UNITY_END();
}
