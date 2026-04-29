#Requires AutoHotkey v2.0
#SingleInstance Force

; 1. Obtener la ruta de LocalAppData correctamente en AHK v2
localAppData := EnvGet("LOCALAPPDATA")
if (localAppData == "") {
    MsgBox("No se pudo encontrar la carpeta LocalAppData.", "Error", 16)
    ExitApp()
}

; 2. Configurar rutas permanentes
installDir := localAppData . "\PopUpWeb"
exePath := installDir . "\pin2top.exe"
jsonPath := installDir . "\com.popupweb.pin2top.json"

; 3. Confirmación
if (MsgBox("¿Deseas instalar PopUp WEB 'Siempre Arriba' en este equipo?", "Instalador PopUp WEB", 36) = "No")
    ExitApp()

; 4. Crear carpeta y mover archivos
try {
    if !DirExist(installDir)
        DirCreate(installDir)

    if FileExist("pin2top.exe") {
        FileCopy("pin2top.exe", exePath, 1)
    } else {
        throw Error("No se encontró pin2top.exe en la carpeta actual.")
    }
} catch Error as e {
    MsgBox("Error al copiar archivos: " e.Message, "Error", 16)
    ExitApp()
}

; 5. Generar JSON con la ruta permanente
escapedPath := StrReplace(exePath, "\", "\\")
jsonContent := '{' .
    '`n  "name": "com.popupweb.pin2top",' .
    '`n  "description": "Bridge for PopUp WEB Always on Top",' .
    '`n  "path": "' . escapedPath . '",' .
    '`n  "type": "stdio",' .
    '`n  "allowed_origins": ["chrome-extension://*/*"]' .
    '`n}'

if FileExist(jsonPath)
    FileDelete(jsonPath)
FileAppend(jsonContent, jsonPath, "UTF-8")

; 6. Registro (Chrome y Edge)
keys := [
    "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.popupweb.pin2top",
    "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.popupweb.pin2top"
]

for key in keys {
    try {
        RegWrite(jsonPath, "REG_SZ", key)
    }
}

MsgBox("¡Instalación completada con éxito!`n`nReinicia tu navegador para empezar a usar 'Siempre Arriba'.", "Éxito", 64
)
ExitApp()