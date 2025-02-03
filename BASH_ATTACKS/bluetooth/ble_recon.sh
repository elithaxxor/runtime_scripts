#!/bin/sh
function runBluetoothRecon () { ble.recon on && ble.show  && ble.enum $_mac  }
echo"hi"
runBluetoothRecon
echo "bye "
