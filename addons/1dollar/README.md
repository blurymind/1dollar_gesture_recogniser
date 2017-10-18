# godot_1dollar_addon 

A godot engine addon implementation of the 1$ gesture recognition algorithm.
Created by Todor Imreorov , based on n13r0's port of http://depts.washington.edu/madlab/proj/dollar/index.html

You can use it to make games like this:

https://www.youtube.com/watch?v=86Wps6afMdY

http://www.google.com/doodles/halloween-2016

It can recognise the following shapes out of the box (in the json file):
- carret
- v
- pigtail
- lineH
- lineV
- heart
- circle

![screenshot](https://github.com/blurymind/1dollar_gesture_recogniser/blob/master/addons/1dollar/plugin-icon.png) It can record shapes for recognition- and add them to a json file ("\recordedGestures.json") , which gets loaded on start

![screenshot](https://raw.githubusercontent.com/blurymind/1dollar_gesture_recogniser/master/addons/1dollar/screenshot.png)

The developer can set limited ink - to limit the size of shapes that can be drawn
Upon recognising a shape, it also emits a signal of what shape it is and how much ink was left when it was completed
If the ink left is > 0, it will create a collision shape from the drawing, that can be used to interact with other parts of the game
You can limit how many colision shapes can be drawn optionally

Optional particle effect and ability to set line thickness and color
Ability to set the allowed drawing area and change the mouse cursor to a pencil then it is over it

# How to use:
Copy this to your project's addons folder (myprject/addons/godot_1dollar/--files--), then enable it
This addon extends the control node.
To set up drawing area - resize the node to the square size you want it to use

# Variables :
- Input map action (string)-  Set the input action you want this addon to use to start drawing strokes. Leaving this empty will make the addon use the left mouse button as the button to hold to draw a stroke 
- Max Ink - This determines the maximum length of a line a user can draw - use it to limit the size of scribbles they can make on screen
- Ink Loss rate - When enabled this will add ink health bar mechanic - the user will lose ink while drawing and the lost ink would affect future strokes #set to 0 in order to disable tracking ink altogether and replenishing it automatically upon releasing the draw
- Replenish ink speed - The speed with which ink health bar gets replenished while the user is not drawing a line #set to 0 in order to disable replenishing ink altogether
- Recording - Turning this on would make the addon work in developer mode- show debug information and gui for recording new stroke recognition patterns
- Particle effect - enabling this would add a fancy particle effect while the user is drawing
- Particle color - set the color of the particle effect
- Line thickness - The line thickness of drawn strokes #set this to 0 to disable drawing a line on screen
- Line color - use to set color of line
- Ink health bar width - Ink indicator health bar width #Set to 0 if you want to disable the health bar
- Create collisions - Enabling this the addon will create collision shapes upon detecting a gesture - if the user hasnt run out of ink. It also puts the collision shapes in appropriately named groups "drawnShapes" and "drawnShape:<recognisedShape>"
- Max Drawn Collision shapes - This is used to limit how many shapes can exist in the game. The addon will automatically destroy the oldest before adding a new one above the threshold #set to 0 if you do not the addon to automatically limit the collision shapes number
