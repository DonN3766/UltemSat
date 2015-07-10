{{MAX31850 v0.90

v0.90

-Able to read thermocouple temperature for one device

To-do:

- Fix SearchROM
- CRC
- Family Code



}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  MAX_DEVICES = 2

OBJ
  pst     : "Parallax Serial Terminal"
  ow      : "MAX31850OBJ"
  fm      : "FloatMath"
  fs      : "FloatString"
  sd      : "MicroSD v0.01"
VAR

long addrs[2*MAX_DEVICES]

PUB start | addr, numDevices, select, tempC, printC 

ow.start(25)
pst.start(115200)

pst.decin
pst.str(string("Ready to search for device. Press 'Enter' to continue.",13))
pst.decin


if ow.reset
  pst.str(string("Devices Located"))
else
  pst.str(string("Devices Not Located"))


pst.str(string(13,"Beginning to search for devices..."))
numDevices := ow.searchROM(MAX_DEVICES, @addrs)
pst.str(string(13,"Number of Devices: "))
pst.dec(numDevices)
'sd.sdMount

sd.sdWrite(string("Temperature(°C)",13))                                 
repeat until select == 111 
  pst.str(string(13,"Select device (1 - "))
  pst.dec(numDevices)
  pst.str(string("): "))
  select := pst.decin

  addr := @addrs + ((select-1) << 3)

  repeat 10  
        'Print 64-bit address
    pst.str(string(13,"Device Address: "))
    pst.bin(LONG[addr + 4], 32)
    pst.bin(LONG[addr],32)
    pst.str(string(13,"Reading temperature..."))
    tempC := ReadTemp(addr)
    printC := tempC
    sd.sdWrite(tempC)
    sd.sdWrite(string(13)) 
    pst.str(string(13,13,13))
    pst.clear
    waitcnt(cnt+clkfreq)


  
repeat
pri ReadTemp(addr): stringC | temp, degC

  ow.reset
  ow.writeByte(ow#MATCH_ROM)
  ow.writeAddr(addr)
  pst.str(string(13,"Match Rom Sent"))
  ow.writeByte(ow#CONVERT_T)
  pst.str(string(13,"Convert T Sent"))

  repeat
    waitcnt(clkfreq/100+cnt)
  
    if ow.read(1)
     
      ow.reset
      ow.writeByte(ow#MATCH_ROM)
      ow.writeAddr(addr)
     
      ow.writeByte(ow#READ_SCRATCHPAD)
     
      temp := ow.read(16)
      pst.str(string(13,"Temperature Data: ", 13))
      pst.bin(temp,16)
      temp >>= 2
      pst.str(string(13,"Temperature Data Shift: ", 13))
      pst.bin(temp,16)
      
      degC := fm.fmul(fm.FFloat(temp), 0.25)   
     
      pst.str(string(13,"°C :"))
      stringC := fs.FloatToString(degC)
      pst.str(stringC)
     
      return