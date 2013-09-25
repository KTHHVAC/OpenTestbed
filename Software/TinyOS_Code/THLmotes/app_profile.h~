

#ifndef __APP_PROFILE_H
#define __APP_PROFILE_H

#include <AM.h>
#define CC2420_DEF_CHANNEL 15
#define CC2420_DEF_RFPOWER 31

typedef nx_struct sf_msg {
  nx_uint8_t           SrcType; // 1:mote  2:PLC
  nx_uint8_t 	       Node_ID;
  nx_uint16_t          data1;
  nx_uint16_t          data2;
  nx_uint16_t          data3;
  nx_uint16_t          data4;
  //nx_uint16_t          Npkt_send;
 } sf_msg; 


typedef nx_struct Radio_msg {	
  nx_uint8_t 	      Node_ID;
  nx_uint16_t         data1;
  nx_uint16_t         data2;
  nx_uint16_t         data3;
  nx_uint16_t         data4;
  //nx_uint16_t         Npkt_send;
  } radio_msg;

enum {
  COORDINATOR_ADDRESS = 0,
  AM_TEST_SERIAL_MSG = 0x89,
};

#endif
