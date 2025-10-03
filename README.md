# SVG to STL Converter

A toolset for converting SVG files to 3D-printable STL models with automatic plinth generation using OpenSCAD. Works on both Windows (PowerShell) and Linux (Bash) systems.

## Features

- Complete conversion pipeline from SVG to 3D-printable STL
- Automatic plinth generation with customizable dimensions
- Uniform scaling to ensure consistent output size
- Intermediate file handling for reliable conversion
- Support for both Windows and Linux environments

## Requirements

### Windows Requirements
- PowerShell
- [OpenSCAD](https://openscad.org/) (installed at default location or update path in script)
- [Inkscape](https://inkscape.org/) (installed at default location or update path in script)
- [ImageMagick](https://imagemagick.org/) (accessible in PATH as `magick`)
- [Potrace](http://potrace.sourceforge.net/) (accessible in PATH)

### Linux Requirements
- Bash
- [OpenSCAD](https://openscad.org/) (installed via Flatpak or update path in script)
- [Inkscape](https://inkscape.org/) (installed via Flatpak or update path in script)
- [ImageMagick](https://imagemagick.org/) (`convert` command)
- [Potrace](http://potrace.sourceforge.net/)

## Directory Structure

The scripts expect and create the following directory structure:

```
[Parent Directory]
 ├── svg_intermediate/    # Initial SVG files
 ├── png_intermediate/    # Temporary PNG files
 ├── svg_final/           # Traced SVG files
 ├── scad_files/          # Generated OpenSCAD files
 └── stl_output/          # Final STL files for 3D printing
```

## Scripts

### Windows: `svg_to_stl.ps1`

PowerShell script for Windows users.

1. Configure paths at the top of the script
2. Place SVG files in the `svg_intermediate` directory
3. Run the script in PowerShell:
   ```powershell
   .\svg_to_stl.ps1
   ```

### Linux: `svg_to_stl.sh`

Bash script for Linux users.

1. Configure paths at the top of the script
2. Place SVG files in the `svg_intermediate` directory
3. Make the script executable and run:
   ```bash
   chmod +x svg_to_stl.sh
   ./svg_to_stl.sh
   ```

## Workflow

1. SVG → PNG: Converts SVG files to PNG using Inkscape
2. PNG → PBM → SVG: Processes PNG files through ImageMagick and Potrace to create clean, traceable SVGs
3. SVG → SCAD: Generates OpenSCAD files with automatic plinth sizing and uniform scaling
4. SCAD → STL: Renders the final 3D models as STL files suitable for 3D printing

## Customization

You can modify the following parameters in the scripts:

- `$parentFolder`/`PARENT_FOLDER`: Base directory for all operations
- `$plinthHeight`/`PLINTH_HEIGHT`: Height of the base in mm (default: 2)
- `$extrudeHeight`/`EXTRUDE_HEIGHT`: Height of the extruded SVG in mm (default: 1)
- `$maxDimension`/`MAX_DIMENSION`: Maximum dimension for uniform scaling in mm (default: 200)

## Notes

- Make sure all required tools are installed and accessible in your PATH
- The Windows script includes a px-to-mm conversion factor that may need adjustment based on your SVG export settings
- For large SVG files, the process may take some time, especially during the OpenSCAD rendering step

## .gitignore

This repository includes a `.gitignore` file configured for:
- OpenSCAD temporary files
- SVG/PNG intermediate files
- PowerShell and Bash script backups
- Common editor/IDE temporary files
- Build outputs

## License

[APACHE 2.0](LICENSE)