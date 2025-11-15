# Converting MMD Models to KHM in 3DS MAX

WORK IN PROGRESS.

Prerequisites:

- 3ds max 2026
- Gimp (or equivalent)

This guide goes through the process of taking MMD models, re-texturing and re-rigging them, and exporting them to KHM format.

install the 3ds Max khm exporter plugin from `\Steam\steamapps\common\DoorKickers2\tools\3dsmax_khm_exporter` (instructions are in there).

download the pmx importer (instructions are also in there):

https://www.moddb.com/downloads/3ds-max-2010-pmx-importer1

you can get mmd models from either:
- https://gf2exilium.sunborngame.com/main/art (offical, but only for global)
- https://www.aplaybox.com/u/636064186/model (unoffical, has all models from CN, ripped from game files, also requires giving phone number to sign up and download)

3ds max:

first make sure your units are set to meters, open `Customize > Units Setup...` and change it to the picture:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/units.png)

run the pmx importer script - `Scripting > Run Script...` then open `PmxToolv1_2`. you should see a window popup with two bottons "Import" and "Export" and a section below that called "Import Options".

Click on "import options" to un-fold the section, we're now going to edit the scale of the import - it's probably set to something like 3.937 by default, this is WAY to big. DK2 expects all models to be a height of 1.9m, but unfortunately there is no way (that I'm aware of) for us to determine what scale value will get us to 1.9m so we need to do trial and error. I suggest starting at a scale of 0.1, so enter that and press the "Import" button.

Then go to the folder you extracted the model into and select the `.pmx` file, for me that will be `GirlsFrontline QiongJiuDefault.pmx`. It can take a few minutes to import, so be patient - 3DS Max will appear frozen, but that's normal.

Once the model is in the viewport, we need to check it's height. Make sure the model is selected in the list on the left (the model is usually called `Object001`) and then press the "wrench" icon on the top bar in the panel on the right. And under "Utilities", click "Measure". This will open a new section with "Dimensions" where you can see the X, Y, Z values of the model. We want the "Z" value to be as close to 1.9m as possible (I've found anything from 1.88 to 1.92 to be acceptable).

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/measure.png)

This shows a Z dimension of 2.01m which will not work, we need to re-import it with a different scale. Since we need to make it only slightly smaller, I'm going to try a scale of 0.095 this time, which is -0.005 from 0.1.

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/measure2.png)

Nice! That will work.

Now we're going to remove all the existing bones from the model (all the pyramid shapes you see everywhere). First back to the left side panel, find the "Select" menu at the top, click it and toggle "Select Children" on. This means we will now select all the children of whatever top level parent is selected now.

Then you can just CTRL-click on everything that isn't the model (again, the model is usually called `Object001`) and then right click in the panel and click "Delete". This will also probably freeze 3ds Max for a while. Now you should have a clean viewport with just the model, that looks like something like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/viewport.png)

You'll notice the model is very shiny, the PMX importer adds a shiny/reflective material to the model. To remove this, we need to remove the reflections from all materials using a script.

Open the script listener with F11 (or `Scripting > Scripting Listener`), delete everything that's already in there, and paste in the following script:

```3ds
for mat in sceneMaterials where classof mat == Multimaterial do for sub in mat.materialList where sub != undefined and classof sub == PhysicalMaterial do (sub.base_weight = 1.0; sub.reflectivity = 0.0; sub.roughness = 1.0; sub.metalness = 0.0)
```

Put your text cursor at the end of the script and press Enter to run it (make sure the cursor is on the same line as this script, at the end of the line). Your model should no longer be shiny.

Now we need to optimise the model to reduce its vertex count. With the model selected (oh and if you still have select all children toggled, you can turn that off now, it won't be useful anymore), open the "Modify" panel and in the "Modifier List" search for "ProOptimizer" and click it. In the list underneath that dropdown, drag "ProOptimizer" to be below "Skin". And then select "ProOptimizer" - a few sections should appear below.

First we want to toggle "Keep Textures" under "Materials and UVs", then we press the "Calculate" button at the top. The right side panel should then look something like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/optimise.png)

The important number we need to look at is "Faces" - mine says "39989 / 39989". This is already perfect! We want to keep it under "44000" (ideally "40000").

But even though we have an acceptable vertex/face count, I still like to run it through the optimizer anyway, but I'll only be optimising it a little. So if you want to do that, or need to optimise it because it has too many faces - enter a new percentage into the "Vertex %" and click "Calculate" again.

I'm only going to enter "99" but if you need to actually reduce the vertex count, you should go somewhere between 90% and 80%.

After entering 99 into the input box and pressing Enter, the faces count now says "39989 / 39740" where 39740 is the new amount once we apply it. I'm happy with that so let's right click on the "ProOptimizer" modifier back at the top list and then click "Collapse To" to apply it - there will be a warning message, but it's fine so just press "Yes".

Now is a good time to save the model as a checkpoint so we can revert back to it if we need to. But before doing that I suggest renaming the model to not be `Object001` anymore - I'm going to rename mine to "qbz191". After that just save it with Ctrl-S and name the `.max` file however you want.

Nice, now what we're going to do is merge all the textures that the model uses into one big texture that can then be used in DK2.

Make sure the model is selected and in the "Modify" panel, search for "Unwrap UVW" and click it. Then click on the triangle next to "Unwrap UVW" and select "Polygon", then enter Ctrl-A to select all polygons. Your viewport should look like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/uvwselect.png)

Then in the "Channel" section, change "Map Channel:" from "1" to "2" and hit enter. Press "OK" on any warnings that appear. In the "Edit UVs" section above it, click "Open UV Editor ...". This will open a new window.

Now at the top bar of that window click "Mapping > Flatten Mapping...". This will open another window, here you just change the "Spacing" value from "0.001" to "0", then click "OK". This will also take a while. Once that's done your "Edit UVWs" window should look like this, with the UVs flattened:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/edituvws.png)

Now close that window, go back to the right panel and in the "Channel" section, click "Save" - I'm going to save mine as "qbz191.uvw".

We're now going to render the texture into a `.dds`, but we first need to make sure our rendering settings are correct. Go to `Rendering > Render Setup...` and change your settings to this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/rendersettings.png)

The important thing is that we're using "Scanline Renderer", you should also probably click "Save as Default" so you don't have to do this every time. 

With that done we also need to create a temporary light in the scene so that the texture is evenly lit when rendering it. On the right side panel, click the "Create" tab (the plus symbol) and search in the search box for "Skylight". Place that anywhere in the scene, it's position does not matter.

Now we're ready to render it. With the model selected, go to `Rendering > Render To Texture...` to open the "Render To Texture" window. Scroll down to the "Mapping Coordinates" section and change the channel to "2". Scroll down to the "Output" section and click "Add...". Double click on "DiffuseMap".

In the section under that you should see "File Name and Type:" be something like "qbz191DiffuseMap.tga", click the three dots button next to that and change "Save as type" to "DDS Image File (*.dds)" and click "Save". Another window will appear, you can just press "OK" for that to leave it as the default. Now find the "Width" and "Height" fields and change them to be both "4096". In the end it should look like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/rendertexturesettings.png)

Now you can click "Render". This will render it and save it as "qbz191DiffuseMap.dds" or whatever you named it in the path we saw previously.

Once that's done, you can close the rendering windows and then delete the skylight we made. Select the model again and delete the "Unwrap UVW" modifier by right clicking it.

In the modifier list, find and create an "Edit Poly" modifier and drag this to be under "Skin" but above "Editable Mesh" in the list. Click on the modifier and in the "Selection" section, click the polygon option (the blue square), use Ctrl-A to select all polygons. Then find the "Polygon: Material IDs" section (it should be near the end), and enter "1" into the "Set ID:" field and press Enter. When you do that, the "Select ID" field should then also become "1".

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/editpoly.png)

Now right click on the "Edit Poly" modifier and click "Collapse To", again ignoring the warning and pressing "Yes".

Then create another "Unwrap UVW" modifier, and under the "Channel" section click "Load..." and open the ".uvw" file you saved earlier. Now we need to add the textures back (well, we don't *need* to, but I think it's easier to work with if we have them). Press "M" on your keyboard (I don't know where this option is in the menu, I'm sorry) to open the "Material Editor" window. Scroll down until you get to the "Generic Maps" section and click on the "No Map" button for "Base Color". Search for a "Bitmap" (just "Bitmap"), and then select the "qbz191DiffuseMap.dds" file you rendered earlier. Make sure your model is selected and click `Material > Assign to Selection` in the menu.

Your model should now have the textures applied. It will be shiny again and the textures look a little weird, but that's fine since it won't be seen in game (this is just the defaults 3ds Max applies).

Now we're ready to re-rig the model with new bones. You can use the "dk2_characters_rig_ver2019.max" reference file in the DK2 tools folder to do this, but that will require editing the pose of that armature since our models use different poses.

Instead I suggest using the scene file I provide in this repo at `/tools/3ds_scenes/springfield_bones.max`. This has the bones already in the correct pose, so all you need to do is edit the size of them to match your model.

To do this, open `File > Import > Merge...` in the top menu bar, open the scene file, and select everything except "gfl_springfield".

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/bonesselect.png)

Now your viewport should look like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/bonesstart.png)

First, move the "@Collision.capsule" object to become a child of "qbz191":

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/collisionchild.png)

Now you should work on scaling the bones to match your model as close as possible. To make it easier, I suggest setting your "Selection Filter" to "Bone" so you can only select on bones.

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/selectionfilter.png)

For this model, I need to scale the spine and hands to be shorter too. One thing to note, is that I generally will NOT touch the legs, as DK2 appears to want the pelvis bone in a specific place or else everything gets messed up. So adjusting the legs will change the position of the pelvis, which we can't do. This means the model's hip joints are never where they're supposed to be - we can't do anything about this.

After shortening the spine and hands, my model now looks like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/bonesedited.png)

Now we want to select the "qbz191" object, go to the "Modify" tab and select the "Skin" modifier. This will mess up the textures, don't worry about it. In "Parameters" click "Bones: Add", this will open a new window, you should just see "Bip001" in the list. In the menu bar of that window click `Select > Select All` and click the "Select" button on the bottom. This will put all the bones in the list.

Still in the "Skin" modifier, go to "Weight Properties", find "Weight Solver" and make sure the dropdown is set to "Voxel". Then click the three dots button next to it, and in the window that opens, click "Apply". Once that runs, you can close the window.

To check the weights have been applied, scroll back to the top of the "Parameters" section and click "Edit Envelopes" and then click on any bone in the list (I like to use `Bip001 Head`). Once that's clicked, you should see the head of the model shaded in red/orange/blue.

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/checkweights.png)

For characters with longer hair like mine, we also want to set the weights of her hair to the head bone so it doesn't become messed up in game. 

Select the vertices checkbox in "Select" and then select "Select Element".

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/selectelement.png)

Now Ctrl-Click on all the hair of the model to select them. Make sure you ONLY select the hair.

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/selecthair.png)

Then go back down to the "Weight Properties" and click the weight tool (the "wrench" next to "Weight Table"). You should see a window like this:

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/weightnohead.png)

But we have a problem here - there's no "Bip001 Head" in the list! This means that the hair vertices do not have enough weights assigned to the head bone to be put in this list. So instead, we need to first select the hair elements that are close to the head, and gradually add other hair elements to them.

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/selecthair2.png)

Here we can see I've select only a portion of the hair, including ones right on the head, and now we have "Bip001 Head" in the list. What we want to do now is set the weights to be 100% for the head bone. Click on the "Bip001 Head" bone in the list and then click on the "1" button. Now it should be set to "1.000".

![units](https://github.com/beanpuppy/girl-kickers/blob/main/docs/media/model_conversionimg/selecthair3.png)

Now continue Ctrl-Clicking on hair elements and setting the weights to be 100% for the head bone. This will gradually build up the weights for the head bone, allowing the hair to be properly controlled by the head bone. If you select a new hair element, but the "Bip001 Head" still says "1.000", you should still click "1" - make sure all the hair elements are completely red.

Once your done with that, you're finally ready to export it!

Make sure nothing is selected in the left panel, then click `File > Export` and export it as a `.khm` file. For us you should save it to `girl-kickers\mod\models\dolls`. 

You also need save the texture file to that path. Open the "qbz191DiffuseMap.dds" (it's usually saved to `\Documents\3ds Max 2026\sceneassets\images` file in Gimp (do not "Flip image vertically"), then export it to the same path as the `.khm` file (yes to "Flip image vertically on export").

That's it! You're ready to work on adding the character to the game. If you want to test it first, just replace an existing character's model in the mod and look at it in game.
