; AutoHotkey v2.0
; IME制御用 関数群 (IME-v2.ahk)
;
; AutoHotkey: v2.0+
; Platform:   Windows NT系
;
; v1からv2への主な変更点:
; - VarSetCapacity → Buffer
; - NumPut/NumGet の型指定を先頭に配置
; - ControlGet HWND → WinGetID
; - WinGet PID → WinGetPID
; - DllCall のパラメータ型を "UInt" → "Ptr" に変更
; - 戻り値を持つ関数は明示的にreturnを使用
; - := を使用した代入

#Requires AutoHotkey v2.0

;-----------------------------------------------------------
; IME制御用定数定義
;-----------------------------------------------------------
global WM_IME_CONTROL := 0x0283
global IMC_GETOPENSTATUS := 0x0005
global IMC_SETOPENSTATUS := 0x0006
global IMC_GETCONVERSIONMODE := 0x0001
global IMC_SETCONVERSIONMODE := 0x0002
global IMC_GETSENTENCEMODE := 0x0003
global IMC_SETSENTENCEMODE := 0x0004

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_GETOPENSTATUS,
        "Ptr", 0,
        "Ptr")
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_SETOPENSTATUS,
        "Ptr", SetSts,
        "Ptr")
}

;-------------------------------------------------------
; IME 入力モード取得
;   WinTitle="A"    対象Window
;   戻り値          入力モード
;--------------------------------------------------------
IME_GetConvMode(WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_GETCONVERSIONMODE,
        "Ptr", 0,
        "Ptr")
}

;-------------------------------------------------------
; IME 入力モードセット
;   ConvMode        入力モード
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;--------------------------------------------------------
IME_SetConvMode(ConvMode, WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_SETCONVERSIONMODE,
        "Ptr", ConvMode,
        "Ptr")
}

;------------------------------------------------------------------
; IME 変換モード取得
;   WinTitle="A"    対象Window
;   戻り値 MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;          ATOK系  0:固定   1:複合語           4:自動 8:連文節
;          WXG              1:複合語  2:無変換 4:自動 8:連文節
;------------------------------------------------------------------
IME_GetSentenceMode(WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_GETSENTENCEMODE,
        "Ptr", 0,
        "Ptr")
}

;----------------------------------------------------------------
; IME 変換モードセット
;   SentenceMode
;       MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;       ATOK系  0:固定   1:複合語           4:自動 8:連文節
;       WXG              1:複合語  2:無変換 4:自動 8:連文節
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------------
IME_SetSentenceMode(SentenceMode, WinTitle := "A") {
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    return DllCall("SendMessage",
        "Ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr"),
        "UInt", WM_IME_CONTROL,
        "Ptr", IMC_SETSENTENCEMODE,
        "Ptr", SentenceMode,
        "Ptr")
}

;==========================================================================
;  IME 文字入力の状態を返す
;       WinTitle="A"   対象Window
;       ConvCls=""     入力窓のクラス名 (正規表現表記)
;       CandCls=""     候補窓のクラス名 (正規表現表記)
;       戻り値      1 : 文字入力中 or 変換中
;                   2 : 変換候補窓が出ている
;                   0 : その他の状態
;==========================================================================
IME_GetConverting(WinTitle := "A", ConvCls := "", CandCls := "") {
    ; IME毎の 入力窓/候補窓Class一覧
    ConvCls .= (ConvCls ? "|" : "")
            .  "ATOK\d+CompStr"
            .  "|imejpstcnv\d+"
            .  "|WXGIMEConv"
            .  "|SKKIME\d+\.*\d+UCompStr"
            .  "|MSCTFIME Composition"
    
    CandCls .= (CandCls ? "|" : "")
            .  "ATOK\d+Cand"
            .  "|imejpstCandList\d+|imejpstcand\d+"
            .  "|mscandui\d+\.candidate"
            .  "|WXGIMECand"
            .  "|SKKIME\d+\.*\d+UCand"
    
    CandGCls := "GoogleJapaneseInputCandidateWindow"
    
    try {
        hwnd := WinGetID(WinTitle)
    } catch {
        hwnd := 0
    }
    
    if WinActive(WinTitle) {
        ptrSize := A_PtrSize
        stGTI := Buffer(cbSize := 4 + 4 + (ptrSize * 6) + 16, 0)
        NumPut("UInt", cbSize, stGTI, 0)
        
        if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", stGTI) {
            hwnd := NumGet(stGTI, 8 + ptrSize, "UInt")
        }
    }
    
    pid := WinGetPID("ahk_id " hwnd)
    tmm := A_TitleMatchMode
    SetTitleMatchMode "RegEx"
    
    ret := WinExist("ahk_class " CandCls " ahk_pid " pid) ? 2
        :  WinExist("ahk_class " CandGCls) ? 2
        :  WinExist("ahk_class " ConvCls " ahk_pid " pid) ? 1
        :  0
    
    SetTitleMatchMode tmm
    return ret
}