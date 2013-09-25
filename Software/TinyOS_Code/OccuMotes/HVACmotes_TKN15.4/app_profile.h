#ifndef __APP_PROFILE_H
#define __APP_PROFILE_H

#include <AM.h>

typedef nx_struct sf_msg {
  nx_uint8_t Event1;
  nx_uint32_t TS1;
  nx_uint8_t Event2;
  nx_uint32_t TS2;
  nx_uint8_t Event3;
  nx_uint32_t TS3;
  nx_uint8_t Event4;
  nx_uint32_t TS4;
} sf_msg;


typedef nx_struct Radio_msg {	
  nx_uint8_t Event1;
  nx_uint32_t TS1;
  nx_uint8_t Event2;
  nx_uint32_t TS2;
  nx_uint8_t Event3;
  nx_uint32_t TS3;
  nx_uint8_t Event4;
  nx_uint32_t TS4;
} radio_msg;

enum {
  RADIO_CHANNEL = 0x10,
  PAN_ID = 0x1234,
  COORDINATOR_ADDRESS = 0x0000,
  BEACON_ORDER = 7,
  SUPERFRAME_ORDER = 6,
  TX_POWER_BEACON = 0,
  TX_POWER = -20, // in dBm
  AM_TEST_SERIAL_MSG = 0x89,
  TIMER_PERIOD_MILLI = 50,
};
#endif
