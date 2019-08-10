# Resolution Manager Plugin for Godot:
## Description:
- This plugin will create a button (Resolution) in canvas editor (2D main page) which allow you to manage game test resolutions and switch between them very quickly from predefined lists. 
![Alt text](screenshots/1.png?raw=true)

- Based on Resolution Switcher plugin [(link)](https://github.com/vinod8990/godot_plugins/tree/master/Resolution%20Switcher), but this one support godot 3.1.
 
## Features:
- Choose stretch mode and aspect from predefiend list, added tooltip for each one.
![Alt text](screenshots/2.png?raw=true)
- Set base resolution, directly or choosing from a list. (will throw error dialog if any value is zero)
![Alt text](screenshots/3.png?raw=true)
- Contain a lists of resolution to choose from (like iphone, ipad, android, basic, most used).
![Alt text](screenshots/4.png?raw=true)
- If the resolution list is custom, you can define your own resolution. Any custom resolution can be set as a base or test resolution. (will throw error dialog if any value is zero)
![Alt text](screenshots/5.png?raw=true)
## How to use:
- Create addons folder in your project directory.
- Copy ResolutionManager folder to addons.
- In Godot goto: Project/ Project Settings/ Plugins tap/ activate ResolutionManager plugin.

## Todo:
- Add functionality to remove a custom resolution.
- Add functionality to add catogary that the custom resolution will be added to. 

Please consider starring the repo if you like the project and let me know if you have any feedback for bugs / feature improvements in the Issues.