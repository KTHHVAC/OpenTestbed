// $Id: BlinkToRadioC.nc,v 1.6 2010-06-29 22:07:40 scipio Exp $

/*
 * Copyright (c) 2000-2006 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Implementation of the BlinkToRadio application.  A counter is
 * incremented and a radio message is sent whenever a timer fires.
 * Whenever a radio message is received, the three least significant
 * bits of the counter in the message payload are displayed on the
 * LEDs.  Program two motes with this application.  As long as they
 * are both within range of each other, the LEDs on both will keep
 * changing.  If the LEDs on one (or both) of the nodes stops changing
 * and hold steady, then that node is no longer receiving any messages
 * from the other node.
 *
 * @author Prabal Dutta
 * @date   Feb 1, 2006
 */
#include <Timer.h>
#include "BlinkToRadio.h"

module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;

  uses interface SplitControl as SerialControl;
  uses interface AMSend as SerialSend;
  uses interface Packet as SerialPacket;
}
implementation {

  uint8_t Event[200];
  uint32_t TS[200];
  
  uint32_t indexofwrite = 0;
  uint32_t indexofread = 0;
  uint8_t indexofbuffer = 0;
  uint8_t buffersize = 200;
  
  
  uint8_t Event_send;
  uint32_t TS_send;
  uint16_t Number_received=1;
  uint16_t Number_send=0;


  message_t pkt;
  message_t sf_pkt;
  bool busy = FALSE;
  
   event void Boot.booted() {
    call AMControl.start();
    call SerialControl.start();      
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
     
          for (indexofbuffer=0;indexofbuffer<buffersize;indexofbuffer++)
    {
    Event[indexofbuffer] = 0xff;
    }     
    call Timer0.startPeriodic(TIMER_PERIOD_MILLI); 
         }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {}


  event void SerialControl.startDone(error_t err){}

  event void SerialControl.stopDone(error_t err){}

  event void Timer0.fired() {
     
    call Leds.led0Toggle();
     
 if(indexofread < indexofwrite){ 

     indexofbuffer = indexofread % buffersize;
     indexofread++;
    
     Event_send = Event[indexofbuffer];
     TS_send = TS[indexofbuffer];
     
   if (Event_send != 0xff)
   {    
        sf_msg* sf_payload = (sf_msg*)call SerialPacket.getPayload(&sf_pkt, sizeof(sf_msg));
        sf_payload-> Event1 = Event_send;
        sf_payload->TS1 = TS_send;  
        sf_payload->Number_send = Number_send;      
        sf_payload->Number_received = Number_received;      
   if(busy){
             return;
            }
   else{
       if(sf_payload == NULL) {return;}
       if(call SerialPacket.maxPayloadLength() < sizeof(sf_msg)){
       return;
	}
      if(call SerialSend.send(AM_BROADCAST_ADDR, &sf_pkt, sizeof(sf_msg)) == SUCCESS){
	busy = TRUE;
      }
      }
    }
   }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {}

  event void SerialSend.sendDone(message_t* msg, error_t err) {call Leds.led1Toggle();busy = FALSE;Number_received++;}

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
      
      indexofbuffer = indexofwrite % buffersize;
      
      Event[indexofbuffer] = btrpkt->Event1;
      TS[indexofbuffer] = btrpkt->TS1;
/*    Event[indexofbuffer+1] = btrpkt->Event2;
      TS[indexofbuffer+1] = btrpkt->TS2; 
      Event[indexofbuffer+2] = btrpkt->Event3;
      TS[indexofbuffer+2] = btrpkt->TS3;
      Event[indexofbuffer+3] = btrpkt->Event4;
      TS[indexofbuffer+3] = btrpkt->TS4;*/
    
      Number_send = btrpkt->Number_Event;
      indexofwrite=indexofwrite + 1;       
    }
    return msg;
  }


}
