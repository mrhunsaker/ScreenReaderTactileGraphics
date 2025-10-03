# Export-All3DPrints.ps1
# PowerShell script to export all design variants from the universal SCAD file

param(
    [string]$ScadFile = ".\scad_files\ScreenReaderVisualizationsOverall.scad",
    [string]$ConfigFile = ".\scad_files\ScreenReaderVisualizationsOverall.json",
    [string]$OutputDir = ".\Final3dPrintFiles",
    [string]$OpenScadPath = "openscad"
)

# Function to write colored output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Check if OpenSCAD is available
function Test-OpenScad {
    try {
        $version = & $OpenScadPath --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Found OpenSCAD: $($version[0])" "Green"
            return $true
        }
    }
    catch {
        Write-ColorOutput "OpenSCAD not found in PATH. Please ensure OpenSCAD is installed and accessible." "Red"
        Write-ColorOutput "You can download it from: https://openscad.org/downloads.html" "Yellow"
        Write-ColorOutput "Or specify the path using -OpenScadPath parameter" "Yellow"
        return $false
    }
    return $false
}

# Main execution
Write-ColorOutput "=== 3D Print Export Script ===" "Cyan"
Write-ColorOutput "SCAD File: $ScadFile" "Gray"
Write-ColorOutput "Config File: $ConfigFile" "Gray"
Write-ColorOutput "Output Directory: $OutputDir" "Gray"
Write-ColorOutput ""

# Check if OpenSCAD is available
if (-not (Test-OpenScad)) {
    exit 1
}

# Check if SCAD file exists
if (-not (Test-Path $ScadFile)) {
    Write-ColorOutput "Error: SCAD file '$ScadFile' not found!" "Red"
    exit 1
}

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-ColorOutput "Error: Config file '$ConfigFile' not found!" "Red"
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    Write-ColorOutput "Creating output directory: $OutputDir" "Yellow"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Load configuration
try {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-ColorOutput "Loaded configuration with $($config.designs.Count) designs" "Green"
}
catch {
    Write-ColorOutput "Error reading config file: $($_.Exception.Message)" "Red"
    exit 1
}

# Initialize counters
$totalDesigns = $config.designs.Count
$successCount = 0
$failCount = 0
$startTime = Get-Date

Write-ColorOutput "`nStarting export of $totalDesigns designs..." "Cyan"
Write-ColorOutput "===========================================" "Cyan"

# Export each design
for ($i = 0; $i -lt $totalDesigns; $i++) {
    $design = $config.designs[$i]
    $designName = $design.name
    $outputFile = Join-Path $OutputDir $design.filename
    $progress = [math]::Round((($i + 1) / $totalDesigns) * 100, 1)
    
    Write-ColorOutput "`n[$($i + 1)/$totalDesigns] ($progress%) Exporting: $designName" "White"
    Write-ColorOutput "Description: $($design.description)" "Gray"
    Write-ColorOutput "Output: $outputFile" "Gray"
    
    # Create OpenSCAD command with proper parameter passing
    $scadArgs = @(
        "-o", $outputFile,
        "-D", "design=`"$designName`"",
        "--render",
        $ScadFile
    )
    
    Write-ColorOutput "Command: openscad $($scadArgs -join ' ')" "DarkGray"
    
    try {
        # Execute OpenSCAD
        $process = Start-Process -FilePath $OpenScadPath -ArgumentList $scadArgs -Wait -PassThru -NoNewWindow -RedirectStandardError "temp_error.txt" -RedirectStandardOutput "temp_output.txt"
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputFile)) {
            $fileSize = [math]::Round((Get-Item $outputFile).Length / 1KB, 2)
            Write-ColorOutput "✓ Success! ($fileSize KB)" "Green"
            $successCount++
        }
        else {
            $errorContent = ""
            $outputContent = ""
            if (Test-Path "temp_error.txt") {
                $errorContent = Get-Content "temp_error.txt" -Raw
            }
            if (Test-Path "temp_output.txt") {
                $outputContent = Get-Content "temp_output.txt" -Raw
            }
            Write-ColorOutput "✗ Failed! Exit code: $($process.ExitCode)" "Red"
            if ($errorContent) {
                Write-ColorOutput "Error: $errorContent" "Red"
            }
            if ($outputContent) {
                Write-ColorOutput "Output: $outputContent" "Yellow"
            }
            $failCount++
        }
    }
    catch {
        Write-ColorOutput "✗ Exception: $($_.Exception.Message)" "Red"
        $failCount++
    }
    
    # Clean up temp files
    if (Test-Path "temp_error.txt") {
        Remove-Item "temp_error.txt" -Force
    }
    if (Test-Path "temp_output.txt") {
        Remove-Item "temp_output.txt" -Force
    }
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime
$durationStr = "{0:mm\:ss}" -f $duration

Write-ColorOutput "`n===========================================" "Cyan"
Write-ColorOutput "EXPORT COMPLETE!" "Cyan"
Write-ColorOutput "===========================================" "Cyan"
Write-ColorOutput "Total Designs: $totalDesigns" "White"
Write-ColorOutput "Successful: $successCount" "Green"
Write-ColorOutput "Failed: $failCount" "Red"
Write-ColorOutput "Duration: $durationStr" "Yellow"
Write-ColorOutput "Output Directory: $OutputDir" "Gray"

# List generated files
if ($successCount -gt 0) {
    Write-ColorOutput "`nGenerated Files:" "Cyan"
    Get-ChildItem $OutputDir -Filter "*.stl" | Sort-Object Name | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-ColorOutput "  $($_.Name) ($size KB)" "Gray"
    }
}

if ($failCount -gt 0) {
    Write-ColorOutput "`nSome exports failed. Check the error messages above." "Yellow"
    Write-ColorOutput "Common issues:" "Yellow"
    Write-ColorOutput "- SVG files not found in ../svg_final/ directory" "Yellow"
    Write-ColorOutput "- Incorrect file paths in SCAD file" "Yellow"
    Write-ColorOutput "- OpenSCAD version compatibility issues" "Yellow"
    exit 1
}
else {
    Write-ColorOutput "`nAll exports completed successfully! 🎉" "Green"
}

# Pause at end if running interactively
if ($Host.Name -eq "ConsoleHost" -and [Environment]::UserInteractive) {
    Write-Host "`nPress any key to continue..." -NoNewLine
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}