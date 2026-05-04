#Requires AutoHotkey v2.0
#SingleInstance Force

; NOTA: NO EJECUTAR COMO ADMINISTRADOR.
; Si se ejecuta como Admin, el registro se hace en el perfil de Administrador
; y el navegador (que corre como usuario normal) no encontrará el host.

; 2. Obtener ruta de LocalAppData
localAppData := EnvGet("LOCALAPPDATA")
if (localAppData == "") {
    MsgBox("Error: No se pudo localizar la carpeta LocalAppData.", "Error", 16)
    ExitApp()
}

; IMPORTANTE: Este ID debe coincidir con el que ves en chrome://extensions
extensionId := "enammhlcbbmdkfenilddkmjonmbnblop"

installDir := localAppData . "\PopUpWeb"
exePath := installDir . "\pinontop.exe"
jsonPath := installDir . "\com.popupweb.pinontop.json"

; 3. Interfaz de instalación
if (MsgBox("¿Instalar el puente nativo 'Siempre Arriba'?", "Instalador", 36) = "No")
    ExitApp()

; 4. Cerrar procesos existentes para permitir la sobrescritura
if ProcessExist("pinontop.exe") {
    try {
        ProcessClose("pinontop.exe")
        if ProcessWaitClose("pinontop.exe", 5) {
            MsgBox(
                "No se pudo cerrar pinontop.exe automáticamente. Por favor, ciérralo desde el Administrador de Tareas.",
                "Error", 16)
            ExitApp()
        }
    }
}

; 4. Extracción y copiado (FileInstall empaqueta el archivo en el EXE)
try {
    if !DirExist(installDir)
        DirCreate(installDir)

    FileInstall("pinontop.exe", exePath, 1)
} catch Error as e {
    MsgBox("Error al copiar pinontop.exe: " e.Message, "Error", 16)
    ExitApp()
}

; 5. Crear manifiesto JSON con el origen permitido específico
escapedPath := StrReplace(exePath, "\", "\\")
jsonContent := '{' .
    '`n  "name": "com.popupweb.pinontop",' .
    '`n  "description": "Bridge for PopUp WEB Always on Top",' .
    '`n  "path": "' . escapedPath . '",' .
    '`n  "type": "stdio",' .
    '`n  "allowed_origins": ["chrome-extension://' . extensionId . '/"]' .
    '`n}'

if FileExist(jsonPath)
    FileDelete(jsonPath)

; Escribir sin BOM (UTF-8-RAW) para que Chromium no falle al parsear
f := FileOpen(jsonPath, "w", "UTF-8-RAW")
f.Write(jsonContent)
f.Close()

; 6. Escribir en el Registro (Chrome y Edge)
try {
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.popupweb.pinontop")
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.popupweb.pinontop"
    )
    ; Soporte adicional para Brave, Vivaldi y Opera (Chromium-based)
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Brave-Browser\NativeMessagingHosts\com.popupweb.pinontop")
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Vivaldi\NativeMessagingHosts\com.popupweb.pinontop")
    RegWrite(jsonPath, "REG_SZ", "HKEY_CURRENT_USER\Software\Opera Software\NativeMessagingHosts\com.popupweb.pinontop"
    )
} catch Error as e {
    MsgBox("Error al escribir en el registro: " e.Message, "Error", 16)
}

MsgBox("Instalación terminada. Reinicia el navegador para activar el modo Siempre Arriba.",
    "Éxito", 64)
ExitApp()