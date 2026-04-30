#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------
; PARÁMETROS CLI
; ---------------------------
SetTitleMatchMode(2) ; Búsqueda parcial de títulos

logFile := ""
action := ""
targetPID := ""
targetTitle := ""

for i, param in A_Args {
    if (param = "/toggle")
        action := "toggle"
    else if (param = "/on")
        action := "on"
    else if (param = "/off")
        action := "off"
    else if (InStr(param, "/pid:") = 1)
        targetPID := SubStr(param, 6)
    else if (InStr(param, "/title:") = 1)
        targetTitle := SubStr(param, 8)
    else if (InStr(param, "/log:") = 1)
        logFile := SubStr(param, 6)
    else if (param = "/help")
        action := "help"
}

; ---------------------------
; HELP
; ---------------------------
ShowHelp() {
    helpText := "
(
Pin2Top v2 - AlwaysOnTop Utility
--------------------------------

Uso:
  Pin2Top.exe /toggle
  Pin2Top.exe /on
  Pin2Top.exe /off
  Pin2Top.exe /pid:1234
  Pin2Top.exe /title:""Texto ventana""
  Pin2Top.exe /log:""ruta.log""
  Pin2Top.exe /help

Descripción:
  /toggle        Alterna AlwaysOnTop en la ventana objetivo
  /on            Activa AlwaysOnTop
  /off           Desactiva AlwaysOnTop
  /pid:1234      Aplica a un proceso por PID
  /title:Texto   Aplica a una ventana cuyo título contenga el texto
  /log:ruta      Guarda registro de acciones
  /help          Muestra esta ayuda
)"
    MsgBox(helpText)
}

; ---------------------------
; LOG
; ---------------------------
Log(msg) {
    global logFile
    if (logFile != "")
        FileAppend(A_Now " - " msg "`n", logFile)
}

; ---------------------------
; OBTENER VENTANA OBJETIVO
; ---------------------------
GetTargetWindow() {
    global targetPID, targetTitle

    if (targetPID != "") {
        return WinExist("ahk_pid " targetPID)
    }

    if (targetTitle != "") {
        return WinExist(targetTitle)
    }

    Sleep(500) ; Pausa para dar tiempo a cambiar de ventana si se usa desde CLI
    return WinExist("A")
}

; ---------------------------
; APLICAR ACCIÓN
; ---------------------------
ApplyAction(action) {
    hWnd := GetTargetWindow()
    if (!hWnd) {
        MsgBox("No se encontró ventana objetivo")
        return
    }

    exStyle := WinGetExStyle("ahk_id " hWnd)

    if (action = "toggle") {
        WinSetAlwaysOnTop(!(exStyle & 0x8), "ahk_id " hWnd)
    }
    else if (action = "on") {
        WinSetAlwaysOnTop(true, "ahk_id " hWnd)
    }
    else if (action = "off") {
        WinSetAlwaysOnTop(false, "ahk_id " hWnd)
    }
}

; ---------------------------
; PUENTE CON EL NAVEGADOR (NATIVE MESSAGING)
; ---------------------------
; Si no se pasaron argumentos de acción, nos quedamos escuchando al navegador
if (action == "") {
    ; Abrimos stdin y stdout usando handles de sistema para asegurar modo binario puro (UTF-8-RAW)
    try {
        stdin := FileOpen(DllCall("GetStdHandle", "UInt", -10, "Ptr"), "h", "UTF-8-RAW")
        stdout := FileOpen(DllCall("GetStdHandle", "UInt", -11, "Ptr"), "h", "UTF-8-RAW")

        if !stdin || !stdout
            ExitApp()
    } catch {
        ; Si no se puede abrir el stream (ej: ejecutado manualmente), salimos sin mostrar nada
        ExitApp()
    }

    ; En v2, Persistent asegura que el host no muera si el loop espera datos
    Persistent(true)
    loop {
        ListenToBrowser()
    }
} else if (action == "help") {
    ShowHelp()
    ExitApp()
} else {
    ; Si es una acción CLI pura, ejecutamos y salimos
    ApplyAction(action)
    Log("CLI Action: " action " | PID: " targetPID " | Title: " targetTitle)
    ExitApp()
}

ListenToBrowser() {
    global stdin, stdout

    ; Intentamos leer la longitud (esto bloquea hasta que llegue algo o se cierre)
    try {
        readBytes := stdin.RawRead(bufLength := Buffer(4), 4)
    } catch {
        ExitApp()
    }

    if (readBytes == 4) {
        msgLength := NumGet(bufLength, 0, "UInt")

        if (msgLength > 0 && msgLength < 1024 * 1024) { ; Protección contra mensajes gigantes
            bufMsg := Buffer(msgLength)
            stdin.RawRead(bufMsg, msgLength)
            msgJson := StrGet(bufMsg, "UTF-8")
            Log("Mensaje recibido: " msgJson)

            ; Extraer la acción y el ID único mediante RegEx simple
            msgType := ""
            uniqueTitleId := ""

            if (RegExMatch(msgJson, '"text":"([^"]*)"', &match))
                msgType := match[1]

            if (RegExMatch(msgJson, '"uniqueTitleId":"([^"]*)"', &match))
                uniqueTitleId := match[1]

            if (msgType = "pin_window_by_title_id" && uniqueTitleId != "") {
                targetTitle := "PopUp WEB - " . uniqueTitleId
                Log("Buscando ventana específica: " targetTitle)

                ; Esperar a que la ventana aparezca (máximo 3 segundos)
                hWnd := 0
                loop 30 {
                    hWnd := WinExist(targetTitle)
                    if (hWnd) {
                        Log("Ventana encontrada (hWnd: " hWnd ")")
                        break
                    }
                    Sleep(100)
                }

                if (hWnd) {
                    WinSetAlwaysOnTop(true, "ahk_id " . hWnd)
                    Log("Fijado exitoso: " targetTitle)
                    SendResponse("fixed")
                } else {
                    Log("Error: No se encontró la ventana con ID " . uniqueTitleId)
                    SendResponse("not_found")
                }
            } else if (msgType = "ping") {
                SendResponse("pong")
            }
        }
    } else if (readBytes == 0) {
        ; Si el navegador cerró la tubería, terminamos para no consumir CPU
        ExitApp()
    }
}

SendResponse(text) {
    global stdout
    json := '{"status":"' . text . '"}'

    ; 1. Calcular longitud exacta en bytes UTF-8 (sin el terminador nulo)
    utf8_len := StrPut(json, "UTF-8") - 1

    ; 2. Crear un único buffer para la longitud (4 bytes) + el mensaje
    outBuf := Buffer(4 + utf8_len)

    ; 3. Escribir la longitud en formato Little Endian (requerido por Chrome)
    NumPut("UInt", utf8_len, outBuf, 0)

    ; 4. Escribir el JSON justo después de los 4 bytes de longitud, sin nulo al final
    StrPut(json, outBuf.Ptr + 4, utf8_len, "UTF-8")

    ; 5. Enviar todo el bloque de una vez para evitar problemas de buffering
    stdout.RawWrite(outBuf, outBuf.Size)
    stdout.Read(0) ; Forzar el vaciado del stream (flush)
}

; ---------------------------
; MODO NORMAL (ATAJO)
; ---------------------------
^Space:: {
    ApplyAction("toggle")
    Log("Hotkey toggle manual")
}
