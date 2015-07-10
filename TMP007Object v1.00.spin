{{TMP007Object v1.00.spin

Driver for TMP007.

}}
VAR
  long TMP007Address
  long started
  long sensVolt
  long tempC
  
OBJ
  i2cObject     : "i2c_write" 

CON
  _DieTemp      = $01              'Address for die temperature
  _SensVolt     = $00              'Address for sensor voltage
  _AccessConfig = $02              'Address for configuration register
  _ObjectTemp   = $03              'Address for Object Temperature
  _StatusReg    = $04              'Address for Status Register (Read Only)

pub Init(_deviceAddress,_i2cSDA,_i2cSCL): okay  
  TMP007Address := _deviceAddress
  i2cObject.init(_i2cSDA,_i2cSCL)

  ' start
  okay := start

  return okay
PUB start : okay
  ' try a restart - recheck the device
  if started == false
    if i2cObject.devicePresent(TMP007Address) == true
      started := true
    else
      started := false     
  return started

PUB isStarted : result
  ' return the started state
  return started

PUB dieTemp

    if started == true
      tempC := i2cObject.read(TMP007Address, _DieTemp, 8, 16)
      return tempC

PUB objectTemp : objtemp

  if started == true
    objtemp := i2cObject.read(TMP007Address, _ObjectTemp, 8, 16)
    return objtemp

PUB writeConfig(configByte) : AckBit
  
  if started == true
    i2cObject.write(TMP007Address, _AccessConfig, configByte, 8,16)
    return AckBit

PUB readConfig : configReg
  
  if started == true
    configReg := i2cObject.read(TMP007Address, _AccessConfig, 8,16)
    return configReg

PUB readStatus : statusReg

  if started == true
    statusReg := i2cObject.read(TMP007Address, _StatusReg, 8,16)
    return statusReg
      