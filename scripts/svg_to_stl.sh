#!/bin/bash

# Paths
INKSCAPE_PATH="flatpak run org.inkscape.Inkscape"
OPENSCAD_PATH="flatpak org.openscad.OpenSCAD  "
PARENT_FOLDER="$/run/media/ryhunsaker/250GB/WindowsProgram3DPrint"
SVG_INTERMEDIATE_FOLDER="$PARENT_FOLDER/svg_intermediate"
PNG_INTERMEDIATE_FOLDER="$PARENT_FOLDER/png_intermediate"
SVG_FINAL_FOLDER="$PARENT_FOLDER/svg_final"
SCAD_FOLDER="$PARENT_FOLDER/scad_files"
STL_FOLDER="$PARENT_FOLDER/stl_output"

# Create folders if missing
for FOLDER in "$SVG_INTERMEDIATE_FOLDER" "$PNG_INTERMEDIATE_FOLDER" "$SVG_FINAL_FOLDER" "$SCAD_FOLDER" "$STL_FOLDER"; do
    if [ ! -d "$FOLDER" ]; then
        mkdir -p "$FOLDER"
    fi
done

# Check for required tools
for TOOL in "convert" "potrace" "$INKSCAPE_PATH" "$OPENSCAD_PATH"; do
    if ! command -v "$TOOL" &> /dev/null; then
        echo "Error: $TOOL is not installed or not in PATH"
        exit 1
    fi
done

# STEP 1: Export SVG → PNG using Inkscape
for SVG_FILE in "$SVG_INTERMEDIATE_FOLDER"/*.svg; do
    if [ -f "$SVG_FILE" ]; then
        FILENAME=$(basename "$SVG_FILE")
        BASE_NAME="${FILENAME%.svg}"
        PNG_FILE="$PNG_INTERMEDIATE_FOLDER/$BASE_NAME.png"
        "$INKSCAPE_PATH" --export-filename="$PNG_FILE" --export-type="png" --export-background-opacity=0 "$SVG_FILE"
    fi
done

# STEP 2: PNG → PBM → SVG via ImageMagick + Potrace
for PNG_FILE in "$PNG_INTERMEDIATE_FOLDER"/*.png; do
    if [ -f "$PNG_FILE" ]; then
        FILENAME=$(basename "$PNG_FILE")
        BASE_NAME="${FILENAME%.png}"
        PBM_FILE="$PNG_INTERMEDIATE_FOLDER/$BASE_NAME.pbm"
        SVG_OUT="$SVG_FINAL_FOLDER/${BASE_NAME}_traced.svg"
        convert "$PNG_FILE" "$PBM_FILE"
        potrace "$PBM_FILE" -s -o "$SVG_OUT"
        rm -f "$PBM_FILE"
    fi
done

# STEP 3: Generate .scad files from traced SVGs with auto plinth sizing and uniform scaling
convert_svg_to_scad() {
    SVG_FILE_PATH="$1"
    SCAD_FILE_PATH="$2"
    PLINTH_HEIGHT="${3:-2}"
    EXTRUDE_HEIGHT="${4:-1}"
    MAX_DIMENSION="${5:-200}"
    
    # Extract SVG dimensions using grep and sed
    WIDTH=$(grep -o 'width="[^"]*"' "$SVG_FILE_PATH" | sed 's/width="\([^"]*\)"/\1/' | sed 's/[^0-9.]//g')
    HEIGHT=$(grep -o 'height="[^"]*"' "$SVG_FILE_PATH" | sed 's/height="\([^"]*\)"/\1/' | sed 's/[^0-9.]//g')
    
    # Default values if extraction fails
    if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
        WIDTH=100
        HEIGHT=100
        echo "Warning: Could not extract dimensions from SVG, using defaults"
    fi
    
    PLINTH_WIDTH=$(echo "$WIDTH + 10" | bc)
    PLINTH_HEIGHT_XY=$(echo "$HEIGHT + 10" | bc)
    
    # Uniform scale to fit within MAX_DIMENSION
    SCALE_X=$(echo "$MAX_DIMENSION / $PLINTH_WIDTH" | bc -l)
    SCALE_Y=$(echo "$MAX_DIMENSION / $PLINTH_HEIGHT_XY" | bc -l)
    
    # Get the minimum of SCALE_X and SCALE_Y for uniform scaling
    if (( $(echo "$SCALE_X < $SCALE_Y" | bc -l) )); then
        UNIFORM_SCALE="$SCALE_X"
    else
        UNIFORM_SCALE="$SCALE_Y"
    fi
    
    # Relative path for OpenSCAD (use absolute path instead in bash)
    SVG_FULLPATH=$(realpath "$SVG_FILE_PATH")
    
    # Create OpenSCAD content
    cat > "$SCAD_FILE_PATH" << EOF
module plinth(size_x, size_y, thickness) {
    cube([size_x, size_y, thickness], center=false);
}

scale([$UNIFORM_SCALE, $UNIFORM_SCALE, 1])
    union() {
        translate([0, 0, 0])
            plinth($PLINTH_WIDTH, $PLINTH_HEIGHT_XY, $PLINTH_HEIGHT);

        translate([5, 5, $PLINTH_HEIGHT])
            linear_extrude(height=$EXTRUDE_HEIGHT)
                import("$SVG_FULLPATH");
    }
EOF
}

# STEP 4: Render to STL using OpenSCAD
for SVG_FILE in "$SVG_FINAL_FOLDER"/*_traced.svg; do
    if [ -f "$SVG_FILE" ]; then
        FILENAME=$(basename "$SVG_FILE")
        BASE_NAME="${FILENAME%.svg}"
        SCAD_FILE="$SCAD_FOLDER/$BASE_NAME.scad"
        STL_FILE="$STL_FOLDER/$BASE_NAME.stl"
        
        convert_svg_to_scad "$SVG_FILE" "$SCAD_FILE"
        "$OPENSCAD_PATH" -o "$STL_FILE" "$SCAD_FILE"
        
        if [ ! -f "$STL_FILE" ]; then
            echo "⚠️ Warning: STL export failed for $SCAD_FILE"
        fi
    fi
done

echo -e "\n✅ SVG to STL batch processing complete!"
