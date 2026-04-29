#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------
; PARÁMETROS CLI
; ---------------------------
silent := false
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
    else if (param.Find("/pid:") = 1)
        targetPID := SubStr(param, 6)
    else if (param.Find("/title:") = 1)
        targetTitle := SubStr(param, 8)
    else if (param = "/silent")
        silent := true
    else if (param.Find("/log:") = 1)
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
  Pin2Top.exe /silent
  Pin2Top.exe /log:""ruta.log""
  Pin2Top.exe /help

Descripción:
  /toggle        Alterna AlwaysOnTop en la ventana objetivo
  /on            Activa AlwaysOnTop
  /off           Desactiva AlwaysOnTop
  /pid:1234      Aplica a un proceso por PID
  /title:Texto   Aplica a una ventana cuyo título contenga el texto
  /silent        No muestra mensajes
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

    if (targetPID != "")
        return WinGetID("ahk_pid " targetPID)

    if (targetTitle != "")
        return WinGetID(targetTitle)

    return WinGetID("A")
}

; ---------------------------
; APLICAR ACCIÓN
; ---------------------------
ApplyAction(action) {
    try {
        hWnd := GetTargetWindow()
        if (!hWnd)
            return

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
    } catch Error as e {
        Log("Error en ApplyAction: " e.Message)
    }
}

; ---------------------------
; PUENTE CON EL NAVEGADOR (NATIVE MESSAGING)
; ---------------------------
; Si no se pasaron argumentos de acción, nos quedamos escuchando al navegador
if (action == "") {
    ; Abrimos stdin y stdout para comunicación binaria
    stdin := FileOpen("*", "r")
    stdout := FileOpen("*", "w")

    ; Iniciamos el bucle de escucha
    SetTimer(ListenToBrowser, 100)
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

    ; Chrome envía 4 bytes de longitud
    if (stdin.RawRead(bufLength := Buffer(4), 4)) {
        msgLength := NumGet(bufLength, 0, "UInt")

        if (msgLength > 0) {
            msgJson := stdin.Read(msgLength)

            if (InStr(msgJson, "pin_last_window")) {
                Sleep(500) ; Esperar a que la ventana se asiente
                ApplyAction("on")
                SendResponse("fixed")
            } else if (InStr(msgJson, "ping")) {
                SendResponse("pong")
            }
        }
    }
}

SendResponse(text) {
    global stdout
    json := '{"status": "' text '"}'
    len := StrLen(json)

    bufLen := Buffer(4)
    NumPut("UInt", len, bufLen, 0)
    stdout.RawWrite(bufLen, 4)
    stdout.Write(json)
    stdout.Read(0) ; Flush
}

; ---------------------------
; MODO NORMAL (ATAJO)
; ---------------------------
^Space:: {
    ApplyAction("toggle")
    Log("Hotkey toggle manual")
}
