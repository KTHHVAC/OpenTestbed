/*
 * Copyright (c) 2011, KTH Royal Institute of Technology
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this list
 * 	  of conditions and the following disclaimer.
 *
 * 	- Redistributions in binary form must reproduce the above copyright notice, this
 *    list of conditions and the following disclaimer in the documentation and/or other
 *	  materials provided with the distribution.
 *
 * 	- Neither the name of the KTH Royal Institute of Technology nor the names of its
 *    contributors may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 */
/**
 * @author Aitor Hernandez <aitorhh@kth.se>
 * @version  $Revision: 1.0 Date: 2010/06/05 $ 
 * @modified 2011/04/13
 */

#include "TKN154.h"
#include "app_profile.h"
module TestCoordReceiverC
{
	uses {
		interface Boot;
		interface MCPS_DATA;
		interface MLME_RESET;
		interface MLME_START;
		interface MLME_SET;
		interface MLME_GET;
		interface MLME_GTS;

		interface IEEE154Frame as Frame;
		interface IEEE154TxBeaconPayload;
		interface Leds;

		interface Packet;
		interface Timer<TMilli> as SendTimer;

		interface Get<ieee154_GTSdb_t*> as SetGtsCoordinatorDb;
		interface GtsUtility;

		interface Notify<bool> as IsEndSuperframe;
		interface GetNow<bool> as IsGtsOngoing;

                //serial forwarding
                interface SplitControl as SerialControl;
                interface AMSend;
                interface Packet as SerialPacket;
	}provides {
		interface Notify<bool> as GtsSpecUpdated;
	}
}implementation {
	ieee154_GTSdb_t* GTSdb;

	bool m_ledCount;
        bool locked = FALSE;
	message_t m_frame;
	uint8_t Len;        
        uint8_t Event1;
	uint32_t TS1;
	uint8_t Event2;
	uint32_t TS2;
	uint8_t Event3;
	uint32_t TS3;
	uint8_t Event4;
	uint32_t TS4;   
        message_t sf_pkt;
        message_t radio_pkt;
        sf_msg* sf_payload;
        radio_msg* Radio_payload;

	bool startSend;
	uint8_t switchDescriptor; //Switch between the desired GTS descriptor

	//task void packetSendTask();
        task void SerialSendTask();	
	void setDefaultGtsDescriptor();
	void setEmptyGtsDescriptor();

	event void Boot.booted() {
                call SerialControl.start(); 
		call MLME_RESET.request(TRUE);
		startSend = FALSE;
		switchDescriptor = FALSE;
             sf_payload = (sf_msg*)call SerialPacket.getPayload(&sf_pkt, sizeof(sf_msg));
             //sf_payload->SrcType = 1; // 1:mote  2:PLC
	}
	
       event void SendTimer.fired() {startSend = TRUE;}
  
        task void SerialSendTask()
        {   
  if(locked){
      return;
     }else{
       if(sf_payload == NULL) {return;}
       if(call SerialPacket.maxPayloadLength() < sizeof(sf_msg)){
       return;
	}
      if(call AMSend.send(AM_BROADCAST_ADDR, &sf_pkt, sizeof(sf_msg)) == SUCCESS){
	locked = TRUE;
      }
    }
   }
	
	//task void packetSendTask()
	//{
		/*uint8_t *payloadRegion;
		m_payloadLen = sizeof(m_payload);

		payloadRegion = call Packet.getPayload(&m_frame, m_payloadLen);
		if (m_payloadLen <= call Packet.maxPayloadLength()) {
			memcpy(payloadRegion, &m_payload, m_payloadLen);
		}
		if( call MCPS_DATA.request (
						&m_frame, // frame,
						m_payloadLen, // payloadLength,
						0, // msduHandle,
						TX_OPTIONS_GTS | TX_OPTIONS_ACK // TxOptions,
				) != IEEE154_SUCCESS)
		call Leds.led0Toggle(); //fail!
		else
		call Leds.led0Off();*/

	//} 

	event void MLME_RESET.confirm(ieee154_status_t status)
	{
		if (status != IEEE154_SUCCESS)
		return;
		call MLME_SET.phyTransmitPower(TX_POWER_BEACON);
		call MLME_SET.macShortAddress(COORDINATOR_ADDRESS);
		call MLME_SET.macAssociationPermit(FALSE);
		call MLME_SET.macGTSPermit(TRUE);

		call MLME_START.request(
				PAN_ID, // PANId
				RADIO_CHANNEL, // LogicalChannel
				0, // ChannelPage,
				0, // StartTime,
				BEACON_ORDER, // BeaconOrder
				SUPERFRAME_ORDER, // SuperframeOrder
				TRUE, // PANCoordinator
				FALSE, // BatteryLifeExtension
				FALSE, // CoordRealignment
				0, // CoordRealignSecurity,
				0 // BeaconSecurity
		);
	}

	event void MLME_START.confirm(ieee154_status_t status) {
		/*//char payload[] = "Hello Device!";
		//uint8_t *payloadRegion;
		ieee154_address_t deviceShortAddress;

		// construct the frame
		//m_payloadLen = strlen(payload);
		//payloadRegion = call Packet.getPayload(&m_frame, m_payloadLen);
		//deviceShortAddress.shortAddress = 0x01; // destination

		if (status == IEEE154_SUCCESS && m_payloadLen <= call Packet.maxPayloadLength()) {
			memcpy(payloadRegion, payload, m_payloadLen);
			call Frame.setAddressingFields(
					&m_frame,
					ADDR_MODE_SHORT_ADDRESS, // SrcAddrMode,
					ADDR_MODE_SHORT_ADDRESS, // DstAddrMode,
					PAN_ID, // DstPANId,
					&deviceShortAddress, // DstAddr,
					NULL // security
			);
		}*/

	}

	event message_t* MCPS_DATA.indication ( message_t* frame )
	{
               
              Len =call Frame.getPayloadLength(frame);
              if (Len==sizeof(radio_msg))
               {
                radio_msg* Radio_payload =(radio_msg*) call Frame.getPayload(frame);
	      /*	ieee154_address_t deviceAddr;
		call Frame.getSrcAddr(frame, &deviceAddr);
		
		if (deviceAddr.shortAddress == 0x01) post packetSendTask();*/

                //radio_msg* Radio_payload =(radio_msg*) call Packet.getPayload(radio_pkt);
		  
                atomic {
                Event1=Radio_payload->Event1;
                TS1=Radio_payload->TS1;
                Event2=Radio_payload->Event2;
                TS2=Radio_payload->TS2;
                Event3=Radio_payload->Event3;
                TS3=Radio_payload->TS3;
                Event4=Radio_payload->Event4;
                TS4=Radio_payload->TS4;
                        }
           
                sf_payload->Event1 = Event1;
                sf_payload->TS1 = TS1;
                sf_payload->Event2 = Event2;
                sf_payload->TS2 = TS2;
                sf_payload->Event3 = Event3;
                sf_payload->TS3 = TS3;
		sf_payload->Event4 = Event4;
                sf_payload->TS4 = TS4;
            
       
                post SerialSendTask();

                call Leds.led1Toggle();}

		return frame;
	}

 event void AMSend.sendDone(message_t* bufPtr, error_t error){
    if(&sf_pkt == bufPtr){
      locked = FALSE;
     // call Leds.led0Toggle();
    }
  }

  event void SerialControl.startDone(error_t err){}

  event void SerialControl.stopDone(error_t err){}
  
	event void MCPS_DATA.confirm(
			message_t *msg,
			uint8_t msduHandle,
			ieee154_status_t status,
			uint32_t Timestamp
	) {}

	event void IEEE154TxBeaconPayload.aboutToTransmit() {}

	event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) {}

	event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) {}

	event void IEEE154TxBeaconPayload.beaconTransmitted()
	{
		ieee154_macBSN_t beaconSequenceNumber = call MLME_GET.macBSN();
		if (beaconSequenceNumber & 1)
		call Leds.led2On();
		else
		call Leds.led2Off();

		
	}

	/*****************************************************************************************
	 * G T S   F U N C T I O N S 
	 *****************************************************************************************/
	void setEmptyGtsDescriptor() {
		ieee154_GTSdb_t* GTSdb;
		GTSdb = call SetGtsCoordinatorDb.get();

		GTSdb->numGtsSlots = 0;
		signal GtsSpecUpdated.notify(TRUE);
	}
	
	void setDefaultGtsDescriptor() {
		uint8_t i;
		ieee154_GTSdb_t* GTSdb;

		GTSdb = call SetGtsCoordinatorDb.get();

		GTSdb->numGtsSlots = 0;

		i=0;
		call GtsUtility.addGtsEntry(GTSdb, i+1, IEEE154_aNumSuperframeSlots - (i+1), 1, GTS_RX_ONLY_REQUEST);
		call GtsUtility.addGtsEntry(GTSdb, i+1, IEEE154_aNumSuperframeSlots - (i+1 + 1), 1, GTS_TX_ONLY_REQUEST);

		for (i=2; i < 30; i++)
		call GtsUtility.addGtsEntry(GTSdb, i+1, IEEE154_aNumSuperframeSlots - (i+1+1), 1, GTS_TX_ONLY_REQUEST);
		
		signal GtsSpecUpdated.notify(TRUE);
	}

	event void MLME_GTS.confirm (
			uint8_t GtsCharacteristics,
			ieee154_status_t status) {}

	event void MLME_GTS.indication (
			uint16_t DeviceAddress,
			uint8_t GtsCharacteristics,
			ieee154_security_t *security) {}

	/***************************************************************************************
	 *Superframe events
	 ***************************************************************************************/
	event void IsEndSuperframe.notify( bool val ) {
		// Switch between the default GTS Descriptor and the empty
		if (switchDescriptor == 0){
			setEmptyGtsDescriptor();
			switchDescriptor = 1;
		}else{
			setDefaultGtsDescriptor();
			switchDescriptor = 0;
		}
	}

	/***************************************************************************************
	 * DEFAULTS spec updated commands
	 ***************************************************************************************/
	command error_t GtsSpecUpdated.enable() {return FAIL;}
	command error_t GtsSpecUpdated.disable() {return FAIL;}
	default event void GtsSpecUpdated.notify( bool val ) {return;}
}
