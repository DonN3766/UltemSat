{{TMP007 v1.13.spin
Version 1.13

================================================================================================================================
Information
================================================================================================================================

TMP007 is an upgrade to the TMP006. It features a built in math chip and is also more accurate.
This saves us a lot of extra coding since the Parallax does not do floating point math.

Using the TMP006 v1.30 as a reference for the first version of this code.

Datasheet:                      http://www.ti.com/lit/ds/symlink/tmp007.pdf
Calibration Guide:              http://www.ti.com/lit/ug/sbou142/sbou142.pdf

================================================================================================================================
v1.10
================================================================================================================================
This is a continuation from TMP00 v1.01.spin. Configuration menu now works. Reading object temperature
and die temperature works. Added in a reset in the configuration menu.

Next version:
~Add Conversion Ready Flag

--------------------------------------------------------------------------------------------------------------------------------
v1.13
--------------------------------------------------------------------------------------------------------------------------------
Added status register to TMP007 Object and reading die and object temperature now uses the conversion ready flag.


================================================================================================================================
Changelog
================================================================================================================================

--------------------------------------------------------------------------------------------------------------------------------
v1.10           ~Configuration menu fixed
                ~Reset added to config menu
               
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
v1.13           ~Added status registry
                ~Added conversion ready flag for both die and object temperature

               
--------------------------------------------------------------------------------------------------------------------------------

}}

CON
        _clkmode = xtal1 + pll16x                       'xtal1 for low freq crystal, pll 16x5_000_000hz = 80Mhz clkspd
        _xinfreq = 5_000_000                            'crystal freq
        
        i2cSCL = 26                                     'i2c Clock Line
        i2cSDA = 27                                     'i2c Data Line   .
        
        TMP007_Addr = %1000_0000

        TempConv = 0.03125
OBJ
        pst                     : "Parallax Serial Terminal"  'For printing to serial terminal
        i2cObject               : "i2c_write"                 'i2c driver
        TMP007Object            : "TMP007Object v1.00"        'TMP007 driver
        FS                      : "FloatString"               'Float to string conversion
        FM                      : "FloatMath"                 'To do decimal math
VAR
        long _DieTemp
        long _ObjTemp
PUB Main | option 

pst.Start(115200)

pst.DecIn                                                                 'waiting for user input to start program

pst.str(string("Searching for TMP007...",13))

i2cObject.Init(i2cSDA, i2cSCL)                                            'Initiating i2c driver

TMP007Object.init(TMP007_Addr, i2cSDA, i2cSCL)                            'Initiating TMP007 sensor

waitcnt(cnt+clkfreq/100)

repeat
  pst.clear 
  if TMP007Object.isStarted == true                                       'Checks to make sure sensor is started
      pst.str(string("Device Detected",13))
  else
      pst.str(string("Device Not Found",13))
     
  if i2cObject.devicePresent(TMP007_Addr) == true                         'Checks to make sure sensor is responding
      pst.str(string("Device Present", 13))
  else
      pst.str(string("Device Not Present",13))

  pst.str(string("Choose an option: ",13))
  pst.str(string("1. Read die temperature.",13))
  pst.str(string("2. Read object temperature", 13))
  pst.str(string("3. Configuration Register",13))
  pst.str(string("[1-3]: "))
  option := pst.decIn
  
  if option == 1
    RDieTemp     'Reads die temperature

  elseif option == 2
    RObjTemp     'Reads object temperature
      
  elseif option == 3                                                            
    RWConfigReg  'Read and write to config registry
                   


    pst.str(string(13,"Pause"))
    pst.DecIn
  
PUB RDieTemp | rdy

  repeat until rdy == %0100_0000                                          'reads status register and checks for conversion flag
    rdy := TMP007Object.readStatus
    rdy := (rdy >> 8) & %0100_0000
    waitcnt(clkfreq/10 + cnt)
  rdy := 0 
  
  pst.str(string("Device is now reading die temperature...",13))          'If sensor is present begin reading temperature
  _DieTemp := TMP007Object.dieTemp                                        'Retrieves die temperature in binary
  _DieTemp := (_DieTemp >> 2)                                             'Must get rid of 2 LSB

  
  if _DieTemp < %10000000000000
    _DieTemp := FM.FFloat(_DieTemp)
    _DieTemp := FM.FMul(_DieTemp, TempConv)                               'Die temperature in Celcius
    
  else
    _DieTemp := ((!_DieTemp & %11111111111111) + 1)*(-1)
    _DieTemp := FM.FFloat(_DieTemp)
    _DieTemp := FM.FMul(_DieTemp, TempConv)

  pst.str(FS.FloatToString(_DieTemp))                                    'Converts from float to string to print to terminal
  pst.str(string(13))
  waitcnt(clkfreq/2 + cnt)                                     

pst.DecIn

PUB RObjTemp

  pst.str(string("Device is now reading object temperature...", 13))

  repeat until rdy == %0100_0000                                          'reads status register and checks for conversion flag
    rdy := TMP007Object.readStatus
    rdy := (rdy >> 8) & %0100_0000
    waitcnt(clkfreq/10 + cnt)
  rdy := 0 
  
  _ObjTemp := TMP007Object.objectTemp
  _ObjTemp := (_ObjTemp >> 2)

  if _ObjTemp < %10000000000000
    _ObjTemp := FM.FFloat(_ObjTemp)
    _ObjTemp := FM.FMul(_ObjTemp, TempConv)

  else
    _ObjTemp := ((!_ObjTemp & %11111111111111) + 1)*(-1)
    _ObjTemp := FM.FFloat(_ObjTemp)
    _ObjTemp := FM.FMul(_ObjTemp, TempConv)

  pst.str(FS.FloatToString(_ObjTemp))

  pst.DecIn

PUB RWConfigReg | option, _RConfig, _WConfig

    repeat until option == 0
      pst.clear
      _RConfig := TMP007Object.readConfig
      _WConfig := _RConfig
      _RConfig := (_RConfig >> 8)
      pst.str(string(13, "Choose a setting you would like to change.",13,"0. Return to main menu."))

      if _RConfig & %00010000 == %00010000
        pst.str(string(13, "1. Mode of Operation:",9,9, "Sensor and Ambient Continuous Conversion"))
      else
        pst.str(string(13, "1. Mode of Operation:",9, "Power-Down"))

      if _RConfig & %0001110 == 0
        pst.str(string(13, "2. Total Conversion Time:",9, "0.26 sec"))                      
      elseif _RConfig & %00001110 == %00000010                                    
        pst.str(string(13, "2. Total Conversion Time:",9, "0.51 sec"))
      elseif _RConfig & %00001110 == %00000100        
        pst.str(string(13, "2. Total Conversion Time:",9, "1.01 sec")) 
      elseif _RConfig & %00001110 == %00000110
        pst.str(string(13, "2. Total Conversion Time:",9, "2.01 sec"))
      elseif _RConfig & %00001110 == %00001000
        pst.str(string(13, "2. Total Conversion Time:",9, "4.01 sec"))
      elseif _RConfig & %00001110 == %00001010
        pst.str(string(13, "2. Total Conversion Time:",9, "1 sec (idle for 0.75)"))
      elseif _RConfig & %00001110 == %00001100
        pst.str(string(13, "2. Total Conversion Time:",9, "4 sec (idle for 3.5)"))
      elseif _RConfig & %00001110 == %00001110
        pst.str(string(13, "2. Total Conversion Time:",9, "4 sec (idle for 3)"))

      pst.str(string(13,"3. Reset"))

      pst.str(string(13,"[0-3]: "))
      option := pst.DecIn

      if option == 1
        pst.str(string(13, "Current mode of operation: ",9))
        if _RConfig & %01110000 == %01110000
          pst.str(string("Sensor and Ambient Continuous Conversion",13))
        else
          pst.str(string("Power-Down",13))

        pst.str(string(13,"Switch mode?",13))
        pst.str(string("1. Yes",13,"2. No",13))
        pst.str(string("[1-2]: "))
        option := pst.DecIn
        if option := 1
          if _RConfig & %00010000 == %00010000
           _WConfig := _WConfig - (_WConfig & %0001000000000000)
            TMP007Object.writeConfig(_WConfig)
          else
            _WConfig := _WConfig + (%0001000000000000)
            TMP007Object.writeConfig(_WConfig)
        waitcnt(cnt+clkfreq/100)

      elseif option == 2
        pst.str(string(13, "Current conversion time: ",9))

        if _RConfig & %0001110 == 0
          pst.str(string("0.26 sec"))                      
        elseif _RConfig & %00001110 == %0000_0010                                    
          pst.str(string("0.51 sec"))
        elseif _RConfig & %00001110 == %0000_0100        
          pst.str(string("1.01 sec")) 
        elseif _RConfig & %00001110 == %0000_0110
          pst.str(string("2.01 sec"))
        elseif _RConfig & %00001110 == %0000_1000
          pst.str(string("4.01 sec"))
        elseif _RConfig & %00001110 == %0000_1010
          pst.str(string("1 sec (idle for 0.75)"))
        elseif _RConfig & %00001110 == %0000_1100
          pst.str(string("4 sec (idle for 3.5)"))
        elseif _RConfig & %00001110 == %0000_1110
          pst.str(string("4 sec (idle for 3)"))

        pst.str(string(13,"Change conversion time?",13))
        pst.str(string("1. Yes", 13, "2. No",13))
        pst.str(string("[1-2]: "))
        option := pst.decin
        
        if option == 1
          pst.str(string(13,"Select conversion time: "))
          pst.str(string(13, "1. 0.26 sec"))
          pst.str(string(13, "2. 0.51 sec"))
          pst.str(string(13, "3. 1.01 sec"))
          pst.str(string(13, "4. 2.01 sec"))
          pst.str(string(13, "5. 4.01 sec"))
          pst.str(string(13, "6. 1 sec (idle for 0.75)"))
          pst.str(string(13, "7. 4 sec (idle for 3.5)"))
          pst.str(string(13, "8. 4 sec (idle for 3)"))
          pst.str(string(13, "9. Return"))
          pst.str(string(13, "[1-9]: "))
          option := pst.decIn

          if option == 1
            _WConfig := _WConfig - (_WConfig & %0000111000000000)               'resets conversion rate to 000
            TMP007Object.writeConfig(_WConfig)                                  'writes to config
          if option == 2                                                        
            _WConfig := _WConfig - (_WConfig & %0000111000000000)               'resets conversion rate to 000
            _WConfig := _WConfig + (%0000_0010_0000_0000)                          'changes conversion rate to desired
            TMP007Object.writeConfig(_WConfig)                                  'write to config
          if option == 3
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            pst.bin(_WConfig,16)
            _WConfig := _WConfig + (%0000_0100_0000_0000)
            TMP007Object.writeConfig(_WConfig)
          if option == 4
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000_0110_0000_0000)
            TMP007Object.writeConfig(_WConfig)
          if option == 5
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000_1000_0000_0000)
            TMP007Object.writeConfig(_WConfig)
          if option == 6
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000_1010_0000_0000)
            TMP007Object.writeConfig(_WConfig)
          if option == 7
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000_1100_0000_0000)
            TMP007Object.writeConfig(_WConfig)
          if option == 8
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000_1110_0000_0000)
            TMP007Object.writeConfig(_WConfig)

      elseif option == 3
         _WConfig := _WConfig + (%1000_0000_0000_0000)  'Data is written MSB first, MSB is a reset bit in config
         TMP007Object.writeConfig(_WConfig)
       waitcnt(cnt+clkfreq/100)
        
          