# Goshapes for Godot 4
![goshapes1](https://raw.githubusercontent.com/daleblackwood/goshapes/main/logo.png)

## Intuitive path-based level creation for Godot 4

Goshapes makes it easy to rapidly generate levels in Godot 4.

This tool augments Path3D nodes with abilities to:
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

### Installation
To install, clone this repository into the addons folder of your Godot 4 project, so that its path in your project is `res://addons/goshapes`.

### Demo Scene
A sample scene, and some sample shape styles and materials have been included under the `samples` subdirectory. Have a play around there, it should become obvious what the tools can do.

### What about GDBlocks for Godot 3?
I initially developed this addon for Godot 3, as [GDBlocks](https://github.com/daleblackwood/gdblocks). This version marks an increase in scope that was made possible thanks to new tools and performance improvements in Godot 4. As the change is quite dramatic, I've decided to fork my own project and make the improvements here. Going forward, this will be the only active project in development.
