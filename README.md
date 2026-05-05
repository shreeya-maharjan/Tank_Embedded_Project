# Tank_Embedded_Project

Overview

This project is a simple embedded Tank Game developed using the C8051F020 microcontroller. The game features player-controlled tank movement, shooting mechanics, and dynamic gameplay elements implemented using low-level hardware control.

Features
- 8-direction tank movement using analog input (potentiometer)
- Shooting mechanism with collision detection
- Multiple maps / playfields
- Adjustable tank speed using DIP switches
- Random respawn positions after each hit
- LCD-based graphics rendering using external memory

Hardware Used:
- C8051F020
- LCD display (memory-mapped)
- Potentiometers (for direction control)
- Push buttons (fire, start/stop)
- DIP switches (speed control)
- How It Works

The system uses interrupts and timers to handle real-time movement and game updates. The tank position is updated based on ADC input, while the display buffer is continuously refreshed to render the game graphics.

Controls:
Movement: Potentiometer (8 directions),
Fire: Push button, 
Speed Control: DIP switches,

Future Improvements:
-Sound effects integration,
-Smarter enemy AI,
-Score tracking system, 
