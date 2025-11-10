
## License
WinFormsFactory is free software licensed under the GNU Lesser General Public License, version 2.1 or (at your option) any later version.  
See LICENSE for details.

**Using this library in your scripts or applications:** You can import and use the module in non‑LGPL code. If you modify the library itself and distribute those modifications, you must provide the modified source under the LGPL. If you redistribute the module together with your app, include this license and comply with the terms described in the LICENSE file.


This Should be an easy library to use, but here is a simple use case:
# Add assemblies, which the class will need when called, the assemblies added in the class file only serve as reminders
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Dot-source the class file, this is important since the file will not compile on it's own due to quirks with powershell classes
. "$PSScriptRoot\WinFormsFactory.ps1"

# Create an instance of the factory
$UI = [WinFormsFactory]::new()

# Create a form
$form = $UI.NewControl('Form', @{
    Text = "Demo Form"
    Size = @(400, 200)
    StartPosition = "CenterScreen"
})

# Create a label
$label = $UI.NewControl('Label', @{
    Text = "Hello, World!"
    Location = @(30, 30)
    AutoSize = $true
    Font = @{
        Name = "Segoe UI"
        Size = 14
        Style = "Bold"
    }
})

# Create a button
$button = $UI.NewControl('Button', @{
    Text = "Click Me"
    Size = @(120, 40)
    Location = @(30, 80)
    FlatStyle = "Flat"
    Font = @{
        Name = "Arial"
        Size = 12
        Style = "Regular"
    }
})

# Add a click event to the button
$button.Add_Click({
    $label.Text = "Button clicked!"
})

# Add controls to the form
$form.Controls.Add($label)
$form.Controls.Add($button)

# Show the form
[void]$form.ShowDialog()

This, atleast for me, is more human readable, and serves to create more order in the code, even if it abstracts the actual code quite a bit.
