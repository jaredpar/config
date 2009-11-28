
function Enable-ViEmu() {
    sp "hkcu:\software\microsoft\VisualStudio\9.0\ViEmu" "Enable" 1 
    sp "hkcu:\software\microsoft\VisualStudio\9.0\ViEmu" "AllowKbdClashes" 0 
    sp "hkcu:\software\microsoft\VisualStudio\10.0\ViEmu" "Enable" 1 
    sp "hkcu:\software\microsoft\VisualStudio\10.0\ViEmu" "AllowKbdClashes" 0 
}

function Disable-ViEmu() {
    sp "hkcu:\software\microsoft\VisualStudio\9.0\ViEmu" "Enable" 0 
    sp "hkcu:\software\microsoft\VisualStudio\9.0\ViEmu" "AllowKbdClashes" 1 
    sp "hkcu:\software\microsoft\VisualStudio\10.0\ViEmu" "Enable" 0 
    sp "hkcu:\software\microsoft\VisualStudio\10.0\ViEmu" "AllowKbdClashes" 1 
}

