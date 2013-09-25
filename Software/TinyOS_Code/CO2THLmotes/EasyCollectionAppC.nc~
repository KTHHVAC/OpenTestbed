configuration EasyCollectionAppC {}
implementation {
  components EasyCollectionC as App;
  components MainC, LedsC, ActiveMessageC;
  components CollectionC as Collector;
  components new CollectionSenderC(0xee);
  components new TimerMilliC();
  components PrintfC;

  App.Boot -> MainC;
  App.RadioControl -> ActiveMessageC;
  App.RoutingControl -> Collector;
  App.Leds -> LedsC;
  App.Timer -> TimerMilliC;
  App.Send -> CollectionSenderC;
  App.RootControl -> Collector;
  App.Receive -> Collector.Receive[0xee];

  components SerialActiveMessageC as AM;
  App.SerialControl -> AM;
  App.AMSend -> AM.AMSend[AM_TEST_SERIAL_MSG];
  App.SerialPacket -> AM; 
  
  components new SensirionSht11C() as Sensor;
  App.ReadHumi -> Sensor.Humidity;
  App.ReadTemp -> Sensor.Temperature; 

  components new Msp430Adc12ClientAutoRVGC() as AutoAdc; 
  App.Resource -> AutoAdc;
  AutoAdc.AdcConfigure -> App;
  App.MultiChannel -> AutoAdc.Msp430Adc12MultiChannel; 
  
  components UserButtonC;
  App.UserButton -> UserButtonC;
}
