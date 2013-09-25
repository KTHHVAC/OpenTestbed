/*
 * Copyright (c) 2010, KTH Royal Institute of Technology
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
 * @modified 2010/11/29 
 */

#include "TKN154.h"
#include "app_profile.h"

module TestDeviceSenderC
{
	uses {
		interface Boot;
		interface MCPS_DATA;
		interface MLME_RESET;
		interface MLME_SET;
		interface MLME_GET;
		interface MLME_SCAN;
		interface MLME_SYNC;
		interface MLME_BEACON_NOTIFY;
		interface MLME_SYNC_LOSS;
		interface MLME_GTS;

		interface GtsUtility;
		interface IEEE154Frame as Frame;
		interface IEEE154BeaconFrame as BeaconFrame;
		interface Leds;
		interface Packet;
		interface Random;

		interface Notify<bool> as IsEndSuperframe;
		interface GetNow<bool> as IsGtsOngoing;
                
                /*interface Read<uint16_t> as ReadTemp; 
                interface Read<uint16_t> as ReadHumi;
                interface Read<uint16_t> as ReadLight;*/
               
                interface Timer<TMilli> as Timer0;
                interface LocalTime<TMilli>;                
	   }

           //ADC  
	  uses interface Resource;
	  uses interface Msp430Adc12MultiChannel as MultiChannel;
	  provides interface AdcConfigure<const msp430adc12_channel_config_t*>;
          
}implementation {
        //Modification
          uint16_t Sens1=0xffff;
	  uint16_t Sens2=0xffff;
	  uint16_t DoorVal=0xffff;

	  uint16_t buffer[15];
	  uint8_t Event[20];   
	  uint32_t TS[20];
	  uint8_t Event_Send[4];   
	  uint32_t TS_Send[4];
	  
	  uint8_t i=0;
	  uint8_t j=0;
	  bool DoorOpen  = FALSE;
	  bool DoorClose = FALSE;
	  bool PassSens1 = FALSE;
	  bool PassSens2 = FALSE;         
       
	  uint16_t *data_ADC;
	  const msp430adc12_channel_config_t config = {
			INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
			SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
			SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1};

	//message_t m_frame;
        message_t radio_pkt;
        radio_msg* Radio_payload;

	ieee154_PANDescriptor_t m_PANDescriptor;
	bool m_ledCount;
	bool m_wasScanSuccessful;
        uint8_t Node_id;
      
        //uint16_t tempdata=0;
        //uint16_t humidata=0;
        //uint16_t lightdata=0;
        //uint16_t co2data=0xffff;
        uint8_t  m_payloadLen;
	void startApp();

	task void packetSendTask();

	event void Boot.booted() {
                  call MLME_RESET.request(TRUE);
                //start timer
                call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
                //initialize
                for(j=0;j<20;j++)
		    {
		     Event[j]=0xff;
		     TS[j]=0xffffffff;
		    }
	}

	event void MLME_RESET.confirm(ieee154_status_t status)
	{
		if (status == IEEE154_SUCCESS)
		startApp();                
	}

	void startApp()
	{                   

		ieee154_phyChannelsSupported_t channelMask;
		uint8_t scanDuration = BEACON_ORDER;

		call MLME_SET.phyTransmitPower(TX_POWER);
		call MLME_SET.macShortAddress(TOS_NODE_ID);

		// scan only the channel where we expect the coordinator
		channelMask = ((uint32_t) 1) << RADIO_CHANNEL;

		// we want all received beacons to be signalled 
		// through the MLME_BEACON_NOTIFY interface, i.e.
		// we set the macAutoRequest attribute to FALSE
		call MLME_SET.macAutoRequest(FALSE);
		m_wasScanSuccessful = FALSE;
		call MLME_SCAN.request (
				PASSIVE_SCAN, // ScanType
				channelMask, // ScanChannels
				scanDuration, // ScanDuration
				0x00, // ChannelPage
				0, // EnergyDetectListNumEntries
				NULL, // EnergyDetectList
				0, // PANDescriptorListNumEntries
				NULL, // PANDescriptorList
				0 // security
		);
               
	}

	event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame)
	{
               
		// received a beacon frame
		ieee154_phyCurrentPage_t page = call MLME_GET.phyCurrentPage();
		ieee154_macBSN_t beaconSequenceNumber = call BeaconFrame.getBSN(frame);


                    
		
if (!m_wasScanSuccessful) {
			// received a beacon during channel scanning
			if (call BeaconFrame.parsePANDescriptor(
							frame, RADIO_CHANNEL, page, &m_PANDescriptor) == SUCCESS) {
				// let's see if the beacon is from our coordinator...
				if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
						m_PANDescriptor.CoordPANId == PAN_ID &&
						m_PANDescriptor.CoordAddress.shortAddress == COORDINATOR_ADDRESS) {
					// yes! wait until SCAN is finished, then syncronize to the beacons
					m_wasScanSuccessful = TRUE;
				}
			}
		} else {
                                               

			// Transmit a packet if we have a slot allocated for us
			if (call IsGtsOngoing.getNow()) 
                       {
                       //call ReadTemp.read();
                       //call ReadHumi.read();
                       //call ReadLight.read();

			for(j=0;j<4;j++)
			    {
			     Event_Send[j]=Event[j];
			     TS_Send[j]=TS[j];
			    }

			  for(j=0;j<16;j++)
			    {
			     Event[j]=Event[j+4];
			     TS[j]=TS[j+4];
			    }

			  if(i-4>=0)
			   {i=i-4;}
			  else {i=0;}  

			//if(Event_Send[0]!=0xff||Event_Send[1]!=0xff||Event_Send[2]!=0xff||Event_Send[3]!=0xff)
			//{post packetSendTask(); call Leds.led0Toggle();}
                       
                      post packetSendTask();
                      
                      }
      

			//received a beacon during synchronization, toggle LED2
			if (beaconSequenceNumber & 1)
			call Leds.led2On();
			else
			call Leds.led2Off();
		}
		return frame;
	}

   /*event void ReadHumi.readDone(error_t result, uint16_t data)
  {
    if(result == SUCCESS){
      humidata = data;
    }
  }

  event void ReadTemp.readDone(error_t result, uint16_t data)
  {
    if(result == SUCCESS){
      tempdata = data;
    }
  }

    event void ReadLight.readDone(error_t result, uint16_t data)
  {
    if(result == SUCCESS){
      lightdata = data;
    }
}*/

//***************************************ADC***************************************************************
async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration()
	{
		return &config;
	}


  event void Resource.granted()
	{
		adc12memctl_t memctl[] = {{INPUT_CHANNEL_A1, REFERENCE_VREFplus_AVss}, {INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss}};
		if (call MultiChannel.configure(&config, memctl, 2, buffer, 15,0) == SUCCESS) {
			call MultiChannel.getData();
		}
	}  


async event void MultiChannel.dataReady(uint16_t *buf, uint16_t numSamples)
	{
	atomic {
		data_ADC = buf;
                Sens1=(data_ADC[0]+data_ADC[3]+data_ADC[6]+data_ADC[9]+data_ADC[12])/5;
                Sens2=(data_ADC[1]+data_ADC[4]+data_ADC[7]+data_ADC[10]+data_ADC[13])/5;
                DoorVal=(data_ADC[2]+data_ADC[5]+data_ADC[8]+data_ADC[11]+data_ADC[14])/5;
                                          
              }                
 
if(DoorOpen == FALSE&&DoorVal<3160)
                  {                   
                   DoorOpen = TRUE;
                   Event[i] = 1;
                   TS[i] = call LocalTime.get();
                   i++;                                  
                  }
            
                        
if(DoorOpen == TRUE&&DoorVal>=3160)
                  {
                    
                    DoorOpen = FALSE;
                    TS[i] = call LocalTime.get();
                    Event[i] = 2;
                    i++;                                    
               }

if(PassSens1==FALSE&&Sens1<50)
                  { 
                    
                    PassSens1 = TRUE;
                    TS[i] = call LocalTime.get();
                    Event[i] = 3;
                    i++; 
                   
                  }

  if(PassSens1==TRUE&&Sens1>=50)
                  {
                    PassSens1 = FALSE;
                    TS[i] = call LocalTime.get();
                    Event[i] = 4;
                    i++;
                   
                  }

 if(PassSens2==FALSE&&Sens2<50)
                  {
                    PassSens2 = TRUE;
                    TS[i] = call LocalTime.get();
                    Event[i] = 5;
                    i++;
                                      
                  }

 if(PassSens2==TRUE&&Sens2>=50)
                  {
                    PassSens2 = FALSE;
                    TS[i] = call LocalTime.get();
                    Event[i] = 6;
                    i++;                  
                  }
  }


  event void Timer0.fired() {
    
       
       if (!call Resource.isOwner()) {
					call Resource.request();                                                                           
                                     }
				else {
					call MultiChannel.getData();
                                      }
   
}

//***********************************TKN15.4********************************************************

	event void MLME_SCAN.confirm (
			ieee154_status_t status,
			uint8_t ScanType,
			uint8_t ChannelPage,
			uint32_t UnscannedChannels,
			uint8_t EnergyDetectListNumEntries,
			int8_t* EnergyDetectList,
			uint8_t PANDescriptorListNumEntries,
			ieee154_PANDescriptor_t* PANDescriptorList
	)
	{
		if (m_wasScanSuccessful) {
			// we received a beacon from the coordinator before
			call MLME_SET.macCoordShortAddress(m_PANDescriptor.CoordAddress.shortAddress);
			call MLME_SET.macPANId(m_PANDescriptor.CoordPANId);
			call MLME_SYNC.request(m_PANDescriptor.LogicalChannel, m_PANDescriptor.ChannelPage, TRUE);
			call Frame.setAddressingFields(
					&radio_pkt,
					ADDR_MODE_SHORT_ADDRESS, // SrcAddrMode,
					ADDR_MODE_SHORT_ADDRESS, // DstAddrMode,
					m_PANDescriptor.CoordPANId, // DstPANId,
					&m_PANDescriptor.CoordAddress, // DstAddr,
					NULL // security
			);
		} else
		startApp();
	}

	task void packetSendTask()
	{

        radio_msg* Radio_payload =
      (radio_msg*)call Packet.getPayload(&radio_pkt, sizeof(radio_msg));
       Radio_payload->Event1 = Event_Send[0];
       Radio_payload->TS1 = TS_Send[0];
       Radio_payload->Event1 = Event_Send[1];
       Radio_payload->TS1 = TS_Send[1];
       Radio_payload->Event1 = Event_Send[2];
       Radio_payload->TS1 = TS_Send[2];  
       Radio_payload->Event1 = Event_Send[3];
       Radio_payload->TS1 = TS_Send[3]; 
       
      m_payloadLen = sizeof(radio_msg);

		if (!m_wasScanSuccessful) {
			return;
		} else if( call MCPS_DATA.request (
						&radio_pkt, // frame,
						m_payloadLen, // payloadLength,
						0, // msduHandle,
						TX_OPTIONS_GTS | TX_OPTIONS_ACK // TxOptions,
				) != IEEE154_SUCCESS) {
			//call Leds.led0Toggle(); //fail!
		} else {
		//call Leds.led0Off();
               
                }

	}

	event void MLME_SYNC_LOSS.indication(
			ieee154_status_t lossReason,
			uint16_t PANId,
			uint8_t LogicalChannel,
			uint8_t ChannelPage,
			ieee154_security_t *security)
	{
		m_wasScanSuccessful = FALSE;
		//call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		startApp();

	}

	event void MCPS_DATA.confirm (
			message_t *msg,
			uint8_t msduHandle,
			ieee154_status_t status,
			uint32_t timestamp )
	{	
		if (status == IEEE154_SUCCESS)
		call Leds.led1Toggle();
	}

	event message_t* MCPS_DATA.indication (message_t* frame) {return frame;}

	event void IsEndSuperframe.notify( bool val ) {}

	/*****************************************************************************************
	 * G T S   F U N C T I O N S 
	 *****************************************************************************************/
	event void MLME_GTS.indication (
			uint16_t DeviceAddress,
			uint8_t GtsCharacteristics,
			ieee154_security_t *security
	) {}

	event void MLME_GTS.confirm (
			uint8_t GtsCharacteristics,
			ieee154_status_t status
	) {}

}
