#Requires AutoHotkey v2.0
#SingleInstance Force

; 1. Solicitar privilegios de administrador (Corregido para evitar bucles)
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    }
    ExitApp()
}

; 2. Obtener ruta de LocalAppData
localAppData := EnvGet("LOCALAPPDATA")
if (localAppData == "") {
    MsgBox("Error: No se pudo localizar la carpeta LocalAppData.", "Error", 16)
    ExitApp()
}

installDir := localAppData . "\PopUpWeb"
exePath := installDir . "\pin2top.exe"
jsonPath := installDir . "\com.popupweb.pin2top.json"
; ID de la extensión derivado del 'key' en manifest.json
extensionId := "pibofbhfcmldckpnhfceidbkcnlmfmge"

; 3. Interfaz de instalación
if (MsgBox("¿Instalar PopUp WEB 'Siempre Arriba' en este equipo?", "Instalador", 36) = "No")
    ExitApp()

; 4. Extracción y copiado (FileInstall empaqueta el archivo en el EXE)
try {
    if !DirExist(installDir)
        DirCreate(installDir)

    FileInstall("pin2top.exe", exePath, 1)
} catch Error as e {
    MsgBox("Error al extraer archivos: " e.Message, "Error", 16)
    ExitApp()
}

; 5. Crear manifiesto JSON con el origen permitido específico
escapedPath := StrReplace(exePath, "\", "\\")
jsonContent := '{' .
    '`n  "name": "com.popupweb.pin2top",' .
    '`n  "description": "Bridge for PopUp WEB Always on Top",' .
    '`n  "path": "' . escapedPath . '",' .
    '`n  "type": "stdio",' .
    '`n  "allowed_origins": ["chrome-extension://' . extensionId . '/"]' .
    '`n}'

if FileExist(jsonPath)
    FileDelete(jsonPath)
FileAppend(jsonContent, jsonPath, "UTF-8")

; 6. Escribir en el Registro (Chrome y Edge)
try {
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.popupweb.pin2top")
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.popupweb.pin2top")
} catch Error as e {
    MsgBox("Error al escribir en el registro: " e.Message, "Error", 16)
}

MsgBox("Instalación terminada con ID " . extensionId . ". Reinicia el navegador para activar el modo Siempre Arriba.",
    "Éxito", 64)
ExitApp()