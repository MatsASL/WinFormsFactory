# WinFormsFactory - A factory for creating and configuring WinForms controls from primitive parameters.
# Copyright (C) 2025 Mats Anders Soot Larsen
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, see <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>.

# Should be source imported before use and assemblies added.
# The added assemblies in this class only serve as reminders.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


Class WinFormsFactory {
    [string] $global:Author = "Mats A. S. Larsen"
    [string] $global:Version = "1.0.0"
    WinFormsFactory() {}

    [object] NewControl([string]$Name, [hashtable]$Properties) {
        try {
            $type = [System.Windows.Forms.Control].Assembly.GetType("System.Windows.Forms.$Name")
            if (-not $type) {
                throw "Type 'System.Windows.Forms.$Name' not found."
            }
            $c = [Activator]::CreateInstance($type)
            foreach ($key in $Properties.Keys) {
                $propertyInfo = $type.GetProperty($key)
                if ( -not $propertyInfo) {
                    Write-Warning "Property '$key' not found on type 'System.Windows.Forms.$Name'."
                    continue
                }

                $value = $Properties[$key]
                $convertedValue = $this.ConvertValue($value, $propertyInfo.PropertyType)

                if ($null -ne $convertedValue) {
                    $propertyInfo.SetValue($c, $convertedValue)
               
                }
            }
            return $c
        }
        catch {
            Write-Host "Error: $_"
            return $null
        }
    }

    # Helper function to convert values to the target property type
    hidden [object] ConvertValue([object]$value, [type]$targetType) {
        # Direct type match or null
        if ($null -eq $value -or $value.GetType() -eq $targetType) {
            return $value
        }
        # Enum conversion
        if ($targetType.IsEnum) {
            try {
                return [Enum]::Parse($targetType, $value.ToString())
            }
            catch {
                Write-Host "Error converting '$value' to enum type '$($targetType.FullName)': $_"
                return $null
            }
        }
        # Handle System.Drawing.Point
        if ($targetType -eq [System.Drawing.Point]) {
            try {
                if ($value -is [hashtable]) {
                    return [System.Drawing.Point]::new($value.X, $value.Y)
                }
                elseif ($value -is [array] -and $value.Count -eq 2) {
                    return [System.Drawing.Point]::new($value[0], $value[1])
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Point: $_"
                return $null
            }
        }
        # Handle System.Drawing.Size
        if ($targetType -eq [System.Drawing.Size]) {
            try {
                if ($value -is [hashtable]) {
                    return [System.Drawing.Size]::new($value.Width, $value.Height)
                }
                elseif ($value -is [array] -and $value.Count -eq 2) {
                    return [System.Drawing.Size]::new($value[0], $value[1])
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Size: $_"
                return $null
            }
        }
        # Handle System.Drawing.Color
        if ($targetType -eq [System.Drawing.Color]) {
            try {
                if ($value -is [string]) {
                    return [System.Drawing.Color]::FromName($value)
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Color: $_"
                return $null
            }
        }
        # Handle System.Drawing.Font
        if ($targetType -eq [System.Drawing.Font]) {
            try {
                if ($value -is [hashtable]) {
                    # Validate required keys and types
                    if ($value.ContainsKey('Name') -and -not [string]::IsNullOrWhiteSpace($value.Name)) {
                        $fontFamily = $value.Name
                    }
                    else {
                        $fontFamily = "Arial"
                    }
                    $fontSize = if ($value.ContainsKey('Size') -and $value.Size -is [double] -or $value.Size -is [int]) { $value.Size } else { 8.25 }
                    $fontStyle = [System.Drawing.FontStyle]::Regular
                    if ($value.ContainsKey('Style')) {
                        try {
                            $fontStyle = [System.Drawing.FontStyle]::Parse([System.Drawing.FontStyle], $value.Style)
                        }
                        catch {
                            Write-Warning "Invalid font style '$($value.Style)'. Using Regular."
                        }
                    }
                    return [System.Drawing.Font]::new($fontFamily, $fontSize, $fontStyle)
                }
                else {
                    Write-Warning "Font property expects a hashtable with keys Name, Size, and Style."
                }
            }
            catch {
                Write-Error "Error converting '$value' to System.Drawing.Font: $_"
                return $null
            }
        }
        # Handle System.Drawing.Icon
        if ($targetType -eq [System.Drawing.Icon]) {
            try {
                if ($value -is [string] -and (Test-Path $value)) {
                    return [System.Drawing.Icon]::ExtractAssociatedIcon($value)
                }
                elseif ($value -is [byte[]]) {
                    $ms = New-Object System.IO.MemoryStream($value)
                    return [System.Drawing.Icon]::new($ms)
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Icon: $_"
                return $null
            }
        }
        # Handle System.Drawing.Image
        if ($targetType -eq [System.Drawing.Image]) {
            try {
                if ($value -is [string] -and (Test-Path $value)) {
                    return [System.Drawing.Image]::FromFile($value)
                }
                elseif ($value -is [byte[]]) {
                    $ms = New-Object System.IO.MemoryStream($value)
                    return [System.Drawing.Image]::FromStream($ms)
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Image: $_"
                return $null
            }
        }
        # Handle System.Drawing.Rectangle
        if ($targetType -eq [System.Drawing.Rectangle]) {
            try {
                if ($value -is [hashtable]) {
                    return [System.Drawing.Rectangle]::new($value.X, $value.Y, $value.Width, $value.Height)
                }
                elseif ($value -is [array] -and $value.Count -eq 4) {
                    return [System.Drawing.Rectangle]::new($value[0], $value[1], $value[2], $value[3])
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Rectangle: $_"
                return $null
            }
        }
        # Handle System.Windows.Forms.Padding and System.Windows.Forms.Margin
        if ($targetType -eq [System.Windows.Forms.Padding]) {
            try {
                if ($value -is [hashtable]) {
                    $left = $value.Left
                    $top = $value.Top
                    $right = $value.Right
                    $bottom = $value.Bottom
                    return [Activator]::CreateInstance($targetType, $left, $top, $right, $bottom)
                }
                elseif ($value -is [array]) {
                    if ($value.Count -eq 4) {
                        return [Activator]::CreateInstance($targetType, $value[0], $value[1], $value[2], $value[3])
                    }
                    elseif ($value.Count -eq 1) {
                        return [Activator]::CreateInstance($targetType, $value[0])
                    }
                }
                elseif ($value -is [int]) {
                    return [Activator]::CreateInstance($targetType, $value)
                }
            }
            catch {
                Write-Host "Error converting '$value' to $($targetType.Name): $_"
                return $null
            }
        }
        # Handle System.Drawing.Graphics
        if ($targetType -eq [System.Drawing.Graphics]) {
            try {
                # Accept a control or image to create graphics from
                if ($value -is [System.Windows.Forms.Control]) {
                    return $value.CreateGraphics()
                }
                elseif ($value -is [System.Drawing.Image]) {
                    return [System.Drawing.Graphics]::FromImage($value)
                }
                else {
                    Write-Warning "Cannot create Graphics: value must be a Control or Image."
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Graphics: $_"
                return $null
            }
        }
        # Handle System.Drawing.Region
        if ($targetType -eq [System.Drawing.Region]) {
            try {
                # Accept a Rectangle, GraphicsPath, or RegionData
                if ($value -is [System.Drawing.Rectangle]) {
                    return [System.Drawing.Region]::new($value)
                }
                elseif ($value -is [System.Drawing.Drawing2D.GraphicsPath]) {
                    return [System.Drawing.Region]::new($value)
                }
                else {
                    Write-Warning "Cannot create Region: value must be Rectangle, GraphicsPath, or RegionData."
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Region: $_"
                return $null
            }
        }
        # Handle System.Drawing.Brush
        if ($targetType -eq [System.Drawing.Brush]) {
            try {
                # Accept a color name or Color object for SolidBrush
                if ($value -is [string]) {
                    $color = [System.Drawing.Color]::FromName($value)
                    return New-Object System.Drawing.SolidBrush $color
                }
                elseif ($value -is [System.Drawing.Color]) {
                    return New-Object System.Drawing.SolidBrush $value
                }
                else {
                    Write-Warning "Cannot create Brush: value must be a color name or Color object."
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Drawing.Brush: $_"
                return $null
            }
        }
        # Handle System.Windows.Forms.Cursor
        if ($targetType -eq [System.Windows.Forms.Cursor]) {
            try {
                if ($value -is [string]) {
                    # Try static property from Cursors
                    $cursorProp = [System.Windows.Forms.Cursors].GetProperty($value)
                    if ($cursorProp) {
                        return $cursorProp.GetValue($null)
                    }
                    # Try as file path
                    if (Test-Path $value) {
                        return New-Object System.Windows.Forms.Cursor($value)
                    }
                    Write-Warning "String '$value' is not a known cursor or file path."
                }
                elseif ($value -is [System.Windows.Forms.Cursor]) {
                    return $value
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Windows.Forms.Cursor: $_"
                return $null
            }
        }
        # Handle System.Windows.Forms.ImageList
        if ($targetType -eq [System.Windows.Forms.ImageList]) {
            try {
                if ($value -is [System.Windows.Forms.ImageList]) {
                    return $value
                }
                elseif ($value -is [array]) {
                    $imgList = New-Object System.Windows.Forms.ImageList
                    foreach ($item in $value) {
                        if ($item -is [string] -and (Test-Path $item)) {
                            $img = [System.Drawing.Image]::FromFile($item)
                            $imgList.Images.Add($img) | Out-Null
                        }
                        elseif ($item -is [System.Drawing.Image]) {
                            $imgList.Images.Add($item) | Out-Null
                        }
                    }
                    return $imgList
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Windows.Forms.ImageList: $_"
                return $null
            }
        }
        # Handle System.Windows.Forms.BindingSource
        if ($targetType -eq [System.Windows.Forms.BindingSource]) {
            try {
                if ($value -is [System.Windows.Forms.BindingSource]) {
                    return $value
                }
                elseif ($value -is [hashtable]) {
                    $bs = New-Object System.Windows.Forms.BindingSource
                    foreach ($k in $value.Keys) {
                        $prop = $bs.GetType().GetProperty($k)
                        if ($prop) { $prop.SetValue($bs, $value[$k]) }
                    }
                    return $bs
                }
            }
            catch {
                Write-Host "Error converting '$value' to System.Windows.Forms.BindingSource: $_"
                return $null
            }
        }


        # Try direct conversion for primitives and other types
        try {
            return [Convert]::ChangeType($value, $targetType)
        }
        catch {
            Write-Warning "Could not convert value of type '$($value.GetType().Name)' to '$($targetType.Name)'"
            return $null
        }
    }
}
