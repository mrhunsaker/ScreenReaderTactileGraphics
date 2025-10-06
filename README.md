# README

# 3D Printed Objects for Teaching Screen Layouts

When teaching students who are blind or visually impaired to use screen readers, one of the challenges is helping them understand the layout of a computer screen. While screen readers provide auditory feedback, having a tactile representation of the screen can significantly enhance comprehension and navigation skills. Unfortunately, well-meaning sighted colleagues and students often point to the screen and say something like, "Just go to the link on the top left", which can be confusing without a clear mental model of the screen's layout.

As a way to address this, I have created a set of 3D printable objects that represent different screen layouts that student commonly encounter during their school day. These tactile models be used in conjunction with screen readers to help students visualize and understand the structure of a computer screen. This is done by students exploring the tactile object as they listen to the screen reader's output, allowing them to correlate the auditory information with a physical representation. This hands-on approach can make it easier for students to grasp concepts like navigation, focus, and the arrangement of elements on a screen, enhancing their overall learning experience. This is also useful for sighted teachers who may not be familiar with screen reader layouts.

## Available 3D Models

All of these models are available for free download and can be printed using a standard 3D printer with a >200 mm x 200 mm print surface. The files are provided in STL format, which is widely supported by 3D printing software.  [This link downloads a .zip file of the software](https://github.com/mrhunsaker/ScreenReaderTactileGraphics/archive/refs/heads/main.zip). You can see the entire GitHub Repo to file issues [here](https://github.com/mrhunsaker/ScreenReaderTactileGraphics)

When you download the zipped folder of these models, the files that you import into a slicer like BambuStudio, OrcaSlicer, or PrusaSlicer are located in the "Final3dPrintFiles" folder. The other folders contain the original svg files created in Inkscape and OpenSCAD files used to generate the stl 3d print files. There is also a Pdf folder containing an embossable version of the models for those who do not have access to a 3D printer.

### Available models (as of October 2025):

- CavasDashboard.stl
- CavasModules.stl
- Copilot365Online.stl
- Desktop.stl
- DesktopAltTab.stl
- DesktopCopilot.stl
- DesktopStartMenu.stl
- ExcelOnline.stl
- FileExplorerDetails.stl
- FileExplorerIcons.stl
- GMailOnline.stl
- GoogleDocOnline.stl
- GoogleHome.stl
- GoogleResults.stl
- GoogleSheetsOnline.stl
- GoogleSlidesOnline.stl
- OfficeSplashPage.stl
- OutlookOnline.stl
- PPTOnline.stl
- WebsiteWithHeadings.stl
- WordOnline.stl

### Printing Instructions

These models are designed to be printed flat. Attempts to print them upright resulted in extremely poor quality prints. The models can be printed using PLA or PETG filament, which are both commonly used materials for 3D printing.  

I printed these models using a BambuLab P1S printer with a 0.4 mm nozzle. All print settings in Bambu Studio were left at the program defaults except I changed the PLA filament source from Bambu PLA to be Generic PLA (I use Filastruder PLA+ filament because it fit my price point). Elegoo PLA filament also worked well.

## How to Customize this Resource

If you have access to a 3D printer and are familiar with 3D modeling software, you can customize these models to better suit your specific needs. The original design files are included in the download package, allowing you to modify dimensions, add or remove features, or create entirely new layouts based on the provided templates.

The main design files are created using OpenSCAD, a free and open-source software for creating 3D CAD models. The vector graphics used in the designs were created using Inkscape, which is also free and open-source. Both of these tools have active communities and plenty of tutorials available online to help you get started.

Here are the steps I recommend for customizing the models:

- Install OpenSCAD and Inkscape on your computer.

- Open the .svg files and modify them as needed using Inkscape.

  - All of my application based models are Office365 or Google Docs, so the browser tabs and search bar are present. This means these componsents are present for use in other application models. 
  - If you want to remove these components, you can delete them from the .svg files.

- Save the svg file after making changes. I save them to a folder names svg_intermediate_files to keep them separate from the final files I will create.

- Export the svg file you just saves as a png file from Inkscape. I use a resolution of 300 dpi.

- Open the png file in Inkscape and do the following:

  - Go along the top menu and select Path -> Trace Bitmap.
  - In the Trace Bitmap window, select "Brightness cutoff" and set the threshold to 0.500. Click OK.
  - Delete the original png image from the Inkscape window, leaving only the traced vector image.
  - Save the image as a plain svg file. I save these files to a folder named svg_final_files.

- Open the ScreenReaderVisualizationsOverall.scad file in OpenSCAD.

  - In OpenSCAD, find a line like this and copy it, and paste right after the `}` and before the next `elseif`:

    ```openscad
    else if (design == "CavasModules") {
    translate([-15, -15, 1.75])
    color(c="yellow") {
        linear_extrude(height=1.25)
            import("../svg_final/CanvasModules_traced.svg");
    }
    }
    ```

    becomes

    ```openscad
    else if (design == "CavasModules") {
    translate([-15, -15, 1.75])
    color(c="yellow") {
        linear_extrude(height=1.25)
            import("../svg_final/CanvasModules_traced.svg");
    }
    }
    ```openscad
    else if (design == "MYNEWDESIGN") {
    translate([-15, -15, 1.75])
    color(c="yellow") {
        linear_extrude(height=1.25)
            import("../svg_final/MYNEWDESIGN.svg");
    }
    }
    else if ...
    ```

  - Change `MYNEWDESIGN` to the name of your new design. Make sure it matches the name you will use when you export the stl file.

  - If you go to the top of the file where is says this: 

    ```openscad
    // Universal 3D Print Generator
    // Choose which design to render by changing the 'design' parameter
    // DESIGN SELECTOR - Change this value to select which design to render
    design = "CavasDashboard"; // [CavasDashboard, CavasModules, Copilot365Online, desktop, desktopStartMenu, desktopAltTab, desktopCopilot, ExcelOnline, FileExplorerDetails, FileExplorerIcons, GMailOnline, GoogleDocOnline, GoogleHome, GoogleResults, GoogleSheetsOnline, GoogleSlidesOnline, OfficeSplashPage, OutlookOnline, PPTOnline, WebsiteWithHeadings, WordOnline]
    ```

  - Add your new design name to the list of options in the comment and change the value of `design` to be your new design name. For example:

    ```openscad
    // Universal 3D Print Generator
    // Choose which design to render by changing the 'design' parameter
    
    // DESIGN SELECTOR - Change this value to select which design to render
    design = "CavasDashboard"; // [CavasDashboard, CavasModules, Copilot365Online, desktop, desktopStartMenu, desktopAltTab, desktopCopilot, ExcelOnline, FileExplorerDetails, FileExplorerIcons, GMailOnline, GoogleDocOnline, GoogleHome, GoogleResults, GoogleSheetsOnline, GoogleSlidesOnline, OfficeSplashPage, OutlookOnline, PPTOnline, WebsiteWithHeadings, WordOnline, MYNEWDESIGN]
    ```

- The cutomizer on the right of the screen will let you choose your new design from the dropdown menu.

- Click the Render button (or press F6) to generate the 3D model.Press F6 to render the model

- Once the model is rendered, press F7 STL to save the 3D model file. Name the file according to your design (e.g., MYNEWDESIGN.stl) and save it in the Final3dPrintFiles folder.