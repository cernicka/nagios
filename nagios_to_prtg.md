Author: Martin Černička

# PRTG differences and workarounds
These notes apply to our installation. They may or may not be relevant to yours.

## General
   * ssh sensors only scale to 50 sensors per probe. However, we need about 30 sensors per monitored object. See the [PRTG Manual](https://www.paessler.com/manuals/prtg/ssh_script_sensor).
   * ssh sensors always allocate TTYs. This practically rules them out.
   * ssh sensors enable arbitrary commands to be executed, not just the ones allowed.
   * PRTG cannot set any parameters for SNMP sensors using snmpset.
   * The "SNMP Custom table" does not work for monitoring processes. It gets broken after cloning or using in a template. Use check_nrpe.pl.exe with check_procs instead.
   * In EXE Sensors, while it is possible to return an Error status, all values are discarded in that case. Workaround: the check_nrpe.pl script returns Warnings also for Errors. Please treat all Warnings like Errors.
   * A channel in a multichannel sensor remains there for ever. It cannot be renamed or removed. This affects filesystems, devices, database files, CPUs, etc. Look out for filesystems in clusters - PRTG will show wrong informations for one of the nodes.
   * Neither the devices, nor the sensors are sorted in any particular way.
   * It is not possible to limit the sensor search to a group, or limit the search criteria in any way.
   * It is not possible to search for sensors by names. Workaround: give the sensors tags equal to the names and browse by tags.
   * It is not possible to zoom into graphs. No additional details are shown, merely the picture is being enlarged. 

## Auto discovery and templates
   * The auto discovery process freezes the PRTG server for some time (minutes). The user interface is not usable during this time.
   * While creating a template from a device, it is not possible to leave out most sensors. Workaround: create a model device using "Clone device", remove any sensors not needed and include them all in the template.
   * It is not possible to edit or view templates.
   * It is not possible to change any limits using templates, once the sensors have been created on the respective devices.
   * It is not possible to see, if the limits come from a template or have been changed manually.
   * Adding sensors to a template and doing an auto discovery on existing devices doesn't create all expected sensors. Workaround: Do an auto-discovery per device.
   * Note that on a device, where some sensors have been deleted, the auto discovery will bring these sensors back.
   * It is not possible to define different templates for different hosts in one auto discovery group.
   * Templates are merely (barely) usable for creating sensors, but not for doing changes. Changes have to be done manually per device and sensor.
   * The PRTG server or Windows is often temporarily unable to resolve partial DNS names. Use fully qualified DNS names.
   * It is not possible to zoom into graphs. Merely the picture is enlarged. 

## Notifications
   * It is not possible to see which notifications you have set. Workaroung: use a notification mail, if you got one, or go manually through all groups, devices and sensors.
   * It is not possible to edit notification settings (days, pause, frequency, etc.) for groups you didn't create. Additionally, notifications can only go to Active Directory groups like mm\prtg-viemce, not to users like mm\viemce. Please make sure you "own" your group.
   * It is not possible to configure notifications for devices by name, covering also devices added in the future. Please make sure you receive notifications by testing them.
   * It is not possible to see the sensor status during a maintenance window. There is no monitoring occuring during that time, the sensors are paused.

