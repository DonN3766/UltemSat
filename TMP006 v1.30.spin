{{ TMP006 v1.30.spin
Version 1.30

================================================================================================================================

This program is used to work with the TMP006, an Infrared Thermopile Sensor.

Data Sheet:     http://dlnmh9ip6v2uc.cloudfront.net/datasheets/Sensors/Temp/tmp006.pdf
                http://www.ti.com/product/TMP006/datasheet
User's Guide:   http://www.ti.com/lit/ug/sbou107/sbou107.pdf

This is the first working version of the program that currently includes a lot of extra text for debugging.
For the later versions I will be trimming down the code and adding more features.

================================================================================================================================

To Do List:
  ~Properly calibrate the sensor using the method in the User's guide
  ~Automatic temperature reading at timed intervals or at a particular date and time
        -Reqires time keeping object to be written
  ~Record large array of data and send to seperate cog for logging
        -Requires SD Card object to be written
  ~Record from multiple sensors at once
================================================================================================================================

================================================================================================================================
v1.10+
================================================================================================================================
**From v1.00**
Features that I will be adding include:
  ~Software reset if some errors occur *Errors yet to be determined
  ~Option to power down and power up
  ~Increase conversion rate, increasing total number of averaged samples and reducing noise while maintaining
  constant power use
  ~Enable data ready bit to allow temp sensor enough time to process data before reading
  ~Properly read temps under 0 degrees C (Not sure if I can or cannot yet)

Later features:
  ~Automatic temperature reading at timed intervals or at a particular date and time
  ~Record large array of data and send to seperate cog for logging
  ~Record from multiple sensors at once
****

Most of the features listed above are going to be implemented when the config registry write function is in and working.
The later features are going to be worked on after version 1.20 when I add the write to config. Calibration also still needs to
be done.

================================================================================================================================
v1.20
================================================================================================================================
With this version I have added the ability to edit the configuration register. This means that I can now implement restarting
the sensor and using the data bit. This one was particularly tough because the I2C driver I am using did not support writing more
than 8 bits. Using the I2C read as an example, I essentially copied over the code from the read portion into the write and changed
it to work with the write. Once that was working properly, adding the ability to edit the config reg was an easy task.

I want to split up the seperate menus into their own public or maybe even private program. This will make the code much cleaner
to look at. Right now everything is under one program and it would be a pain to read for anyone.

For the next version I would like to have:
  ~All menu options in seperate PUB/PRI
  ~Ability to reset
  ~Use data ready bit when reading data

================================================================================================================================
v1.30
================================================================================================================================
This version has separated each function of the program into its own separate object. This version also has the ability to
change the default settings of the sensor. On boot up of the program and activation of the sensor, the program will write to the
sensor and change its settings registry. Currently the default settings can only be changed through the code, perhaps
as a future feature the default settings can be changed from the program. Currently the default setting enables the data ready
bit at start up.  

The program now uses the data ready bit. The program will wait for the sensor to give the okay then read data from the sensor.



================================================================================================================================
Changelog
================================================================================================================================
--------------------------------------------------------------------------------------------------------------------------------
v1.01           ~Switched to using I2C SPIN Object by Dave Custer (Jan 2008 Version 2.0) *WITH REMOVED DRIVELINE          
--------------------------------------------------------------------------------------------------------------------------------
v1.10           ~Added menu with options
                ~Added reading config registry
--------------------------------------------------------------------------------------------------------------------------------
v1.10+          ~Updated notes
--------------------------------------------------------------------------------------------------------------------------------
v1.20           ~Added the ability to edit the configuration registry
                ~It is now possible to:
                  ~Power down and power up sensor
                  ~Change conversion rate
                  ~Enable data ready bit
                ~Also updated I2C SPIN Object to support writing for up to 32 bits of data
                  ~New file is called i2c_write.spin
--------------------------------------------------------------------------------------------------------------------------------
v1.30           ~Organized all of the functions of the program into seperate functions
                ~Added a default settings function so that you can set the settings of the sensor before you start
                  using it. Currently default settings can only be set from the program
                ~Added the data ready bit, the microcontroller now waits for the sensor to give the okay before
                  reading the next temp
                ~Object temperature will now be measured 'n' times and put into an array
                ~Added a calibration mode which will give millivolts and die temperature
--------------------------------------------------------------------------------------------------------------------------------

        
        

}}
CON
        _clkmode = xtal1 + pll16x                       'xtal1 for low freq crystal, pll 16x5_000_000hz = 80Mhz clkspd
        _xinfreq = 5_000_000                            'crystal freq
        
        i2cSCL = 26                                     'i2c Clock Line
        i2cSDA = 27                                     'i2c Data Line   .
        
                                                        
        TMP006_Addr = %1000_0000                        'TMP006 Default Address
        m = 222.6                                      'Slope for object temperature calculation
        b = 28.926                                      'y=mx+b
        Vconv = 0.00015625                              'Constant voltage conversion rate, 1LSB = 15.625nV, mV
OBJ
        pst                     : "Parallax Serial Terminal"  'For printing to serial terminal
        i2cObject               : "i2c_write"                 'i2c driver
        TMP006Object            : "TMP006Object"              'TMP006 driver
        FS                      : "FloatString"               'Float to string conversion
        FM                      : "FloatMath"                 'To do decimal math
VAR
        long _DieTemp           'Temperature of the die                                                       
        long _SensVolt          'Sensor Voltage
        long _ObjTemp           'Object Temperature
        long _RConfig           'Read Config
        long _WConfig           'Write Config
        byte option
PUB Start
pst.Start(115200)

pst.DecIn                                                                       'waiting for user input to start program

pst.str(string("Searching for TMP006...",13))

i2cObject.Init(i2cSDA, i2cSCL)                                                  'Initiating i2c driver

TMP006Object.init(TMP006_Addr, i2cSDA, i2cSCL)                                  'Initiating TMP006 sensor

waitcnt(cnt+clkfreq/100)

DefConfig

repeat
  pst.clear 
  if TMP006Object.isStarted == true                                             'Checks to make sure sensor is started
      pst.str(string("Device Detected",13))
  else
      pst.str(string("Device Not Found",13))
     
  if i2cObject.devicePresent(TMP006_Addr) == true                               'Checks to make sure sensor is responding
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

  elseif option == 11
    SnsCal       'Hidden mode for manual calibration, gives sensor voltage and die temp

    pst.str(string(13,"Pause"))
    pst.DecIn

PUB RDieTemp

      pst.str(string("Device is now reading die temperature...",13))          'If sensor is present begin reading temperature
      _DieTemp := TMP006Object.dieTemp                                        'Retrieves die temperature in binary
      _DieTemp := (_DieTemp >> 2)                                             'Must get rid of 2 LSB
      _DieTemp := FM.FDiv(FM.FFloat(_DieTemp),32.0)                           'Divides _DieTemp by 32 to get Celcius
      pst.clear
      pst.str(string("Die Temperature (C): ",9))
      pst.str(FS.FloatToString(_DieTemp))
      pst.decin

PUB RObjTemp | array[50], ready, n

  n := 0 
  repeat until n == 21                                                          'Initializes the array for writing into
    array[n] := 0
    n++
    
  n := 0
  repeat until n == 21                                                          'Read the object temperature n+1 times
    repeat until ready == %10000000                                             'Reads the data ready bit and waits until the sensor is ready
      ready := TMP006Object.readConfig
      ready := ready - (ready & %1111111101111111)
      
    ready := 0 
    _SensVolt := TMP006Object.objectTemp                                        'Gets sensor value in 16 bit binary
    if _SensVolt < 32767                                                        'This checks to see if the value we get back from the sensor is positive or negative
      pst.clear
      pst.str(string("Device is now reading object temperature...",13))
      _SensVolt := FM.FMul(FM.FFloat(_SensVolt),Vconv)                          'Converting the binary value to mV
      _ObjTemp := _SensVolt                                                     'Converts voltage to temperature C
      _ObjTemp := FM.FMul(_ObjTemp,m)
      _ObjTemp := FM.FAdd(_ObjTemp,b)
      pst.str(string(13,"Object Temperature (C): ",9)) 
      pst.str(FS.FloatToString(_ObjTemp))                                       'Converts the voltage value to celcius using mx+b          
    elseif _SensVolt > 32767                                                    'Runs if binary output is negative                                         
      pst.clear
      pst.str(string("Device is now reading object temperature...",13))
      _SensVolt := (!_SensVolt & %1111111111111111) - 1                         'Two's compliment conversion (flip all bits & subtract 1)
      _SensVolt := FM.FNeg(FM.FMul(FM.FFloat(_SensVolt),Vconv))                 'Converts binary value to voltage, mV                                      
      _ObjTemp  := _SensVolt                                                    'Converts voltage to temperature C
      _ObjTemp := FM.FMul(_ObjTemp,m)
      _ObjTemp := FM.FAdd(_ObjTemp,b)
      pst.str(string(13,"Object Temperature (C): ",9)) 
      pst.str(FS.FloatToString(_ObjTemp))
    array[n] := _ObjTemp                                                        'Stores temperature value into array[n]
    n++

  n := 0
  pst.clear
  pst.str(string("Ready to print from array!",13))
  pst.decin
  pst.str(string("Printing from array: ",13))
  repeat until n == 21                                                          'Prints from array
    pst.str(FS.FloatToString(array[n]))
    pst.str(string(13))
    waitcnt(cnt+clkfreq/10)
    n++

  pst.decin
  

PUB RWConfigReg

    repeat until option == 0
      pst.clear
      _RConfig := TMP006Object.readConfig
      _WConfig := _RConfig
      _RConfig := (_RConfig >> 8)
      pst.str(string(13, "Choose a setting you would like to change.",13, "0. Return to main menu."))

      if _RConfig & %01110000 == %01110000                                        'This is the mode of operation, whether it is on or off
       pst.str(string(13, "1. Mode of Operation:",9, "Sensor and Ambient Continuous Conversion"))
      else
       pst.str(string(13, "1. Mode of Operation:",9, "Power-Down"))
       
      if _RConfig & %00001110 == 0                                                'Shows what is the current conversion rate
       pst.str(string(13, "2. Conversion Rate:",9, "4/sec"))                      
      elseif _RConfig & %00001110 == %00000010                                    
       pst.str(string(13, "2. Conversion Rate:",9, "2/sec"))
      elseif _RConfig & %00001110 == %00000100        
       pst.str(string(13, "2. Conversion Rate:",9, "1/sec")) 
      elseif _RConfig & %00001110 == %00000110
       pst.str(string(13, "2. Conversion Rate:",9, "0.5/sec"))
      elseif _RConfig & %00001110 == %00001000
       pst.str(string(13, "2. Conversion Rate:",9, "0.25/sec"))
       
      if _RConfig & %00000001 == 0                                               'Shows if the data bit is disabled or enabled 
        pst.str(string(13, "3. Data Ready Bit:",9,"Disabled",13))
      elseif _RConfig & %00000001 == 1
        pst.str(string(13, "3. Data Ready Bit:",9,"Enabled",13))
      pst.str(string("[0-3]"))
      option := pst.DecIn
      
      if option == 1                                                             'Selection 1 gives you the option to change the "Current Mode of Operation" 
        pst.str(string(13, "Current mode of operation: ",9))                                            
        if _RConfig & %01110000 == %01110000                                                          
          pst.str(string("Sensor and Ambient Continuous Conversion",13)) 
        else
          pst.str(string("Power-Down",13))

        pst.str(string(13,"Switch mode?",13))
        pst.str(string("1. Yes", 13, "2. No",13))
        pst.str(string("[1-2]: "))
        option:=pst.decin
        if option == 1
          if _RConfig & %01110000 == %01110000
           _WConfig := _WConfig - (_WConfig & %0111000000000000)
            TMP006Object.writeConfig(_WConfig)
          else
            _WConfig := _WConfig + (%0111000000000000)
            TMP006Object.writeConfig(_WConfig)
        waitcnt(cnt+clkfreq/100)
            
      elseif option == 2                                                        'Selection 2 gives you the option to change the "Conversion Rate"
        pst.str(string(13, "Current mode of operation: ",9))

        if _RConfig & %00001110 == 0                                                
          pst.str(string("4/sec"))                                                  
        elseif _RConfig & %00001110 == %00000010                                    
          pst.str(string("2/sec"))
        elseif _RConfig & %00001110 == %00000100        
          pst.str(string("1/sec")) 
        elseif _RConfig & %00001110 == %00000110
          pst.str(string("0.5/sec"))
        elseif _RConfig & %00001110 == %00001000
          pst.str(string("0.25/sec"))

        pst.str(string(13,"Switch mode?",13))
        pst.str(string("1. Yes", 13, "2. No",13))
        pst.str(string("[1-2]: "))
        option := pst.decin
        
        if option == 1                                                          
          pst.str(string(13, "Please select conversion rate: "))
          pst.str(string(13, "1. 4/sec"))
          pst.str(string(13, "2. 2/sec"))
          pst.str(string(13, "3. 1/sec"))
          pst.str(string(13, "4. 0.5/sec"))
          pst.str(string(13, "5. 0.25/sec"))
          pst.str(string(13, "[1-5]: "))
          option := pst.decIn
          
           
          if option == 1
            _WConfig := _WConfig - (_WConfig & %0000111000000000)               'resets conversion rate to 000
            TMP006Object.writeConfig(_WConfig)                                  'writes to config
          if option == 2                                                        
            _WConfig := _WConfig - (_WConfig & %0000111000000000)               'resets conversion rate to 000
            _WConfig := _WConfig + (%0000001000000000)                          'changes conversion rate to desired
            TMP006Object.writeConfig(_WConfig)                                  'write to config
          if option == 3
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000010000000000)
            TMP006Object.writeConfig(_WConfig)
          if option == 4
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000011000000000)
            TMP006Object.writeConfig(_WConfig)
          if option == 5
            _WConfig := _WConfig - (_WConfig & %0000111000000000)
            _WConfig := _WConfig + (%0000100000000000)
            TMP006Object.writeConfig(_WConfig)
        waitcnt(cnt+clkfreq/100)
        
      elseif option == 3                                                        'Selection 3 lets you enable or disable the "Data Ready Bit"                                                     
          pst.str(string(13, "Current mode of operation: ",9))
          if _RConfig & %00000001 == 0                                               
            pst.str(string("Disabled",13))
          elseif _RConfig & %00000001 == 1
            pst.str(string("Enabled",13))
           
          pst.str(string(13,"Switch mode?",13))
          pst.str(string("1. Yes", 13, "2. No",13))
          pst.str(string("[1-2]: "))
          option:=pst.decin
           
          if option == 1
            if _RConfig & %00000001 == 0
              _WConfig := _WConfig + %0000000100000000
              TMP006Object.writeConfig(_WConfig)
            else
              _WConfig := _WConfig - %0000000100000000
              TMP006Object.writeConfig(_WConfig)
        waitcnt(cnt+clkfreq/100)
PUB DefConfig

{ This is an object for writing the default settings of the sensor, whenever the sensor resets it always boots up with the same settings
}

  _WConfig := TMP006Object.readConfig                                           'Turns on data ready bit immediately after sensor boots up                                           
  if _WConfig & %0000000100000000 == 0
    _WConfig := _WConfig + %0000000100000000
    TMP006Object.writeConfig(_WConfig)

  waitcnt(cnt+clkfreq/100)

PUB SnsCal | ready, n, Array[50], sum

{This object is hidden to the normal user and is only used for calibration. It gives the values required for manual calibration, Sensor Voltage
and Die Temperature}

pst.clear
pst.str(string("Manual Sensor Calibration Mode"))
pst.decin
n := 0
repeat until n == 99
  repeat until n == 21                                                          'Reads data ready bit, waits until sensor is done compiling data
    repeat until ready == %10000000
      ready := TMP006Object.readConfig
      ready := ready - (ready & %1111111101111111)
      
    ready := 0 
  
  
    _SensVolt := TMP006Object.objectTemp                                        'Reads in binary from sensor                                        
    if _SensVolt < 32767                                                        'If binary is positive
      pst.clear                                                                 'Conver to millivolts
      _SensVolt := FM.FMul(FM.FFloat(_SensVolt),Vconv)                          
      pst.str(string("Object Voltage (mV): ",9)) 
      pst.str(FS.FloatToString(_SensVolt))                                       
    elseif _SensVolt > 32767                                                    'If binary is negative                                                
      pst.clear
      _SensVolt := (!_SensVolt & %1111111111111111) - 1                         'Flip bits and minus 1      
      _SensVolt := FM.FNeg(FM.FMul(FM.FFloat(_SensVolt),Vconv))                 'Convert to millivolts       
      pst.str(string("Object Voltage (mV): ",9))                                
      pst.str(FS.FloatToString(_SensVolt))                                      

    Array[n] := _SensVolt                                                       'Stores millivolts into array
    n++

  n := 0
  repeat until n == 21                                                          'Prints out data in the array
    pst.str(FS.FloatToString(Array[n]))
    pst.str(string(13))
    n++

  n:= 0
  sum := 0.0
  repeat until n == 21                                                          'Calculates the average millivolts from array
    sum := FM.FAdd(sum,Array[n])
    n++
  sum := FM.FDiv(sum,20.0)

  pst.str(string(13, "Average (mv): ",9))
  pst.str(FS.FloatToString(sum))                                                'Print average millivolts  

  _DieTemp := TMP006Object.dieTemp                                        'Retrieves die temperature in binary
  _DieTemp := (_DieTemp >> 2)                                             'Get rid of 2 LSB
  _DieTemp := FM.FDiv(FM.FFloat(_DieTemp),32.0)                           'Divides _DieTemp by 32 to get Celcius
  
  pst.str(string(13,"Die Temperature (C): ",9))                                 'Print die temperature (Celcius)
  pst.str(FS.FloatToString(_DieTemp))

  n := pst.decin  