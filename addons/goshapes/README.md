
# Goshapes for Godot 4
![goshapes1](https://raw.githubusercontent.com/daleblackwood/goshapes/main/addons/goshapes/logo.png)

## Intuitive path-based level creation for Godot 4

Goshapes makes it easier to rapidly generate level geometry in Godot 4.

This tool augments Path3D nodes with the following abilities:
- create custom block meshes (earth, buildings, etc)
- create path meshes (fences, paths, roads)
- scatter instances (trees, rocks, grass, etc)

This makes it ideal for quickly putting together 3D environments.

Goshapes wraps your custom meshes to a path you specify in the editor:
![goshapes1](https://user-images.githubusercontent.com/386025/174088620-768776d1-d5d4-4103-a8cd-0bb0286f670f.gif)

You can also use paths to procedurally place instances:
![goshapes2](https://user-images.githubusercontent.com/386025/174088773-30d98cad-5912-402b-a485-0c824f798408.gif)
^ Notice that the trees above both snap to ground and ignore the footpath. This can be toggled by layer masks.

[Screenshots](https://imgur.com/a/R0b3cXD)

### What's New in 1.1.0
Goshapes 1.1.0 has been released Feb 14th, 2023 and follows RC1 of Godot 4. It fixes several issues that arose due to changes throughout the alpha and beta.
- Goshapes' folder structure now correctly adheres to the Godot plugin specification, making it an easy include from the Asset Store.
- Compilation fixes to issues that arose from changes made to GDScript during the Godot 4 alpha period. 
- Line-pathed Goshapes now generate much cleaner and more even corners, making squared paths easy to generate.
- Inspector hints have been added.

### Installation
To install, use the Godot Asset Library or clone this repository into the addons folder of your Godot 4 project, so that its path in your project is `res://addons/goshapes`.

### Demo Scene
A few sample scenes, and some sample shape styles and materials have been included under the `addons/goshapes/samples` folder. Have a play around there, it should help demonstrate what's possible.

### Editor Tools
Goshapes works mainly in the inspector. You can add a new Goshape through the add menu or the Goshapes menu in the top toolbar.

#### Inspector
![image](https://user-images.githubusercontent.com/386025/174332654-e77556d3-c884-4353-83f6-8269afde5c8a.png)

The inspector will always have shape native properties and path options. Path options can be copied between shapes, while shape native properties are individual. The data for shapes is contained within Resources. This means you can rapidly assemble shapes using preset styles and options or set to local to set custom for each shape.

For a Goshape, all functions and configurations can be achieved using **the inspector**.
 - **Axis matched editing** is useful for inorganic shapes like buildings or structures. When enabled it will caused axis-aligned points to move with the point you're currently editing.
 - **Invert and recenter** alow you to change the direction and origin respectively.

#### Inspector: Block Options
Alongside that, there's the Path Options which can be copied between shapes.
 - **Flatten** will force the path to flatten the Y axis, which is useful when you're editing flat surfaces for a player or NPC to traverse.
 - **Twist** will allow you to bend the path in weird and wonderful ways for shapes like corkscrews and vertical spirals.
 - **Line** will cause the shape to extrude along the path instead of filling the path. This is useful for footpaths, roads and fences.
 - **Rounding** will round the edges of the shape by the desired distance
 - **Interpolate** affects the detail of the shape
 - **Points On Ground** will cause the points to align to the surface below them using Raycasting
 - **Offset Y** shifts the shape up or down
 - **Ground Placement Mask** will affect which objects are selected in a Points On Ground raycast

#### Choosing Shapers
![image](https://user-images.githubusercontent.com/386025/174336140-0f291c1e-d41a-4062-a36d-d88fd0dacc62.png)

### The Shaper Resource: The thing that tells a Goshape what to generate
The Shaper Resource contains the data that is used as instructions for what to generate within the Goshape. You can use these to have your Goshape generate geometry or objects using the type of Shaper used.

Shapers can be picked from the top of the GoShape inspector (Shaper must be expanded.)

#### BlockShapers: The main geometry generator
![image](https://user-images.githubusercontent.com/386025/174334424-8b0242c7-8508-4429-8924-a81d4a2ad140.png)

Blockshapers are the main Shaper type for rendering geometry, they combine up to three Shapers to make geometry: the **CapShaper**, the **WallShaper** and the **BottomShaper**. For the most part, this is automatic.

##### The CapShaper (generates a cap at the top, best used as part of a BlackShaper)
There are three cap shaper types: **Flat**, **Plane** and **Line**. Flat and Plane are great for building most shapes (with Plane containing more detail) and Line is useful when using the line PathOption (see above). These three methods alter the triangulation technique used for the caps.

![image](https://user-images.githubusercontent.com/386025/174335390-e10761f4-2ae9-4006-a33f-e115f9df2794.png)

All Cap shapers take a material and render its UVs 1:1 in world space.

##### The WallShapers (generates a wall around the path, best used as part of a BlackShaper)
There are two wall shaper types: **Bevel** and **Mesh**. Bevel will generate a straight wall and allows tapering and bevelling. **MeshWall** is the most useful, allowing you to **create custom geometry and wrap it to a wall**. There are some tricks to creating that geometry, that I go into below (see Making Mesh Walls).

![image](https://user-images.githubusercontent.com/386025/174335860-a66f9344-9209-487b-b2b1-fdd604b1de5c.png)

#### The ScatterShaper: Useful for randomly placing objects within an area
![image](https://user-images.githubusercontent.com/386025/174336335-7daa2bd6-2e64-4426-88f6-4da5b4f35cee.png)

A ScatterShaper allows for as many instances as is needed within an area:
 - **Density** controls how likely an instance is to spawn
 - **Spread** changes how far apart the instances are (actual distance from neighbour is between 0 and spread * 2
 - **Seed** changes the random seed
 - **Place on ground** causes the genernated instances to be placed on the ground using Raycasting
 - **Noise** lets you override the inbuilt random function with a noise texture
 - **Evenness** changes how well aligned the instances are to each other. The higher the value, the less *organic* the scatter selection is.


### What happened to GDBlocks for Godot 3?
I initially developed this addon for Godot 3, as [GDBlocks](https://github.com/daleblackwood/gdblocks). Goshapes marks an increase in scope that was made possible thanks to new tools and performance improvements in Godot 4 and was developed predominantly during the Godot 4 alpha period. As the change is quite dramatic, I've decided to fork my own project and make the improvements here. Going forward, this will be the only active project in development - though I'm working on it as slowly as a hobby.

### Contribution Policy
I will endeavour to review any pull requests on Github that fix, optimise or compliment existing functionality without changing the nature of previously generated output. Please note that, while I'm a hobbyist and may sometimes take a little while to respond, I do enjoy and welcome the code contributions of others.
