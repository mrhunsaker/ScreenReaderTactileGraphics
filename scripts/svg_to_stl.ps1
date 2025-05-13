# Paths
$inkscapePath = "C:\Program Files\Inkscape\bin\inkscape.com"
$openScadPath = "C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
$parentFolder = "F:\WindowsProgram3DPrint"
$svgIntermediateFolder = "$parentFolder\svg_intermediate"
$pngIntermediateFolder = "$parentFolder\png_intermediate"
$svgFinalFolder = "$parentFolder\svg_final"
$scadFolder = "$parentFolder\scad_files"
$stlFolder = "$parentFolder\stl_output"

# Create folders if missing
$folders = @($svgIntermediateFolder, $pngIntermediateFolder, $svgFinalFolder, $scadFolder, $stlFolder)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

# Check for required tools
$requiredTools = @("magick", "potrace")
foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "$tool is not installed or not in PATH"
        exit 1
    }
}

if (-not (Test-Path $openScadPath)) {
    Write-Error "OpenSCAD not found at $openScadPath"
    exit 1
}

# STEP 1: Export SVG → PNG using Inkscape
Get-ChildItem -Path $svgIntermediateFolder -Filter "*.svg" | ForEach-Object {
    $svgFile = $_.FullName
    $pngFile = "$pngIntermediateFolder\$($_.BaseName).png"
    & "$inkscapePath" --export-filename="$pngFile" --export-type="png" --export-background-opacity=0 "$svgFile"
}

# STEP 2: PNG → PBM → SVG via ImageMagick + Potrace
$pngFiles = Get-ChildItem -Path $pngIntermediateFolder -Filter *.png
foreach ($png in $pngFiles) {
    $pbmFile = "$($png.DirectoryName)\$($png.BaseName).pbm"
    $svgOut = "$svgFinalFolder\$($png.BaseName)_traced.svg"
    & magick $png.FullName "$pbmFile"
    & potrace "$pbmFile" -s -o "$svgOut"
    Remove-Item "$pbmFile" -Force
}

# STEP 3: Generate .scad files from traced SVGs with auto plinth sizing and uniform scaling
function Convert-SVGToScad {
    param (
        [string]$svgFilePath,
        [string]$scadFilePath,
        [string]$openScadPath,
        [int]$plinthHeight = 2,
        [int]$extrudeHeight = 1,
        [int]$maxDimension = 200,
        [bool]$exportStl = $true
    )

    # Conversion factor from px to mm (970 px = 250 mm)
    $pxToMm = 250 / 970

    # Read SVG dimensions
    [xml]$svgXml = Get-Content -Path $svgFilePath
    $widthAttr = $svgXml.svg.width
    $heightAttr = $svgXml.svg.height

    $widthPx = [double]($widthAttr -replace '[^0-9.]', '')
    $heightPx = [double]($heightAttr -replace '[^0-9.]', '')

    # Convert to mm
    $widthMm = $widthPx * $pxToMm
    $heightMm = $heightPx * $pxToMm

    # Add 10 mm padding to create plinth size
    #$plinthWidth = $widthMm + 10
    #$plinthHeightXY = $heightMm + 10
    $plinthWidth = 310
    $plinthHeightXY = 310
    
	# Uniform scale to fit entire object within maxDimension
    $scaleX = $maxDimension / $plinthWidth
    $scaleY = $maxDimension / $plinthHeightXY
    $uniformScale = [math]::Min($scaleX, $scaleY)

    # Relative path for OpenSCAD
    $svgFullPath = Resolve-Path $svgFilePath
    $scadBasePath = Split-Path -Path $scadFilePath
    Push-Location $scadBasePath
    $relativePath = Resolve-Path -Relative $svgFullPath
    Pop-Location

    $escapedSvgPath = $relativePath -replace '\\', '/'

    $scadContent = @"
module plinth(size_x, size_y, thickness) {
    cube([size_x, size_y, thickness], center=false);
}
scale([$uniformScale, $uniformScale, 1])
    union() {
        translate([0, 0, 0])
            plinth(310, 310, 2);

        translate([-15, -15, 1.75])
            linear_extrude(height=1.25)
                import("../svg_final/CavasDashboard_traced.svg");
    }
"@
    Set-Content -Path $scadFilePath -Value $scadContent

    if ($exportStl -and (Test-Path $openScadPath)) {
        $stlPath = [System.IO.Path]::ChangeExtension($scadFilePath, "stl")
        & "$openScadPath" -o "$stlPath" "$scadFilePath"
        if (-Not (Test-Path $stlPath)) {
            Write-Warning "❌ STL export failed for $scadFilePath"
        }
    }
}

# STEP 4: Render to STL using OpenSCAD
$tracedSvgs = Get-ChildItem -Path $svgFinalFolder -Filter "*_traced.svg"
foreach ($svg in $tracedSvgs) {
    $scadFile = "$scadFolder\$($svg.BaseName).scad"
    $stlFile = "$stlFolder\$($svg.BaseName).stl"
    Convert-SVGToScad -svgFilePath $svg.FullName -scadFilePath $scadFile
    & "$openScadPath" -o "$stlFile" "$scadFile"
}

Write-Host "n✅ SVG to STL batch processing complete!"

