### Getting Started

* From transmitter's main screen, long hold the `Page` button (down d-pad on X-Lite) to show custom screens, short press `Page` to the iNav screen
* If you get a `not enough memory` error when starting Lua Telemetry, please see the [Tips & Common Problems](../Tips-&-Common-Problems) wiki

### General Information

* Flashing values indicate a warning (for example: no telemetry, battery low, altitude too high)
* Beeping/vibration is associated with critical warnings and there will be an associated flashing value to indicate what the beep/vibration is a result of
* The script gives voice feedback for flight modes, battery levels and warnings (no need to manually set this up)
* Voice alerts will play in background even if iNav Lua Telemetry screen is not displayed
* When not armed you can flip between max/min and current values by using the dial or +/- buttons
* Short press `Enter` to quickly flip between the views

### Status Messages View

Compatible CRSF telemetry sources can display status text together with its MAVLink severity. The newest message is shown first, adjacent repeats are combined with an `xN` count, and the history is limited to 20 entries.

This integrated view is a validated proof of concept. It is not memory-stable on the TBS Tango 2 once live messages accumulate. A future standalone message-only telemetry script is recommended there, configured instead of the full iNav telemetry script rather than concurrently with it.

* On monochrome radios, short press `Enter` to cycle to the Messages view. Use up/down to scroll and `Exit` to return to the Classic view.
* On colour radios, press `Enter` (right stick while disarmed) to open or close Messages. On a TX16S touchscreen, tap the title bar to open it and tap the page to close it.
* New non-debug messages briefly appear over the normal telemetry view. Repeated copies update the history count without keeping the popup visible indefinitely.
* ExpressLRS can convert MAVLink `STATUSTEXT` into the supported CRSF status-text frame. Long MAVLink 2 messages cannot be reassembled because the CRSF conversion does not carry chunk identifiers.

### Classic View

![sample](https://raw.githubusercontent.com/iNavFlight/LuaTelemetry/development/assets/iNavKey.png "Classic view screen description")
![sample](https://raw.githubusercontent.com/iNavFlight/LuaTelemetry/development/assets/iNavKeyX9D.png "Classic view screen description for X9D")

* To flip between compass-based direction and launch/pilot-based orientation and location, use the dial or +/- buttons
* The launch/pilot-based orientation view is useful if model orientation is unknown
* If model is further than 25 feet away, the launch/pilot-based view will show the direction of the model based on launch/pilot position and orientation (useful to locate a lost model)

### Pilot (Glass Cockpit) View

![sample](https://raw.githubusercontent.com/iNavFlight/LuaTelemetry/development/assets/iNavPilotKey.png "Pilot view screen description")&nbsp;&nbsp;


### Radar (Map) View

![sample](https://raw.githubusercontent.com/iNavFlight/LuaTelemetry/development/assets/iNavQX7radarKey.png "Radar view screen description")&nbsp;&nbsp;
![sample](https://raw.githubusercontent.com/iNavFlight/LuaTelemetry/development/assets/iNavX9DradarKey.png "Radar view screen description for X9D")

* To flip between compass-based and launch/pilot-based orientation and radar, use the dial or +/- buttons
