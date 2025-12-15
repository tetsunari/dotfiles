; AutoHotkey v2.0

#Requires AutoHotkey v2.0
#SingleInstance Force

; キー入力の遅延を最小化
SetControlDelay 0
SetKeyDelay -1

; IME.ahk の関数をインクルード
#Include IME-v2.ahk

; エラー対策
A_MaxHotkeysPerInterval := 350

; =============================================================================
; 状態管理（キーリピート時の競合を防止）
; =============================================================================

global rctrlPressed := false
global lctrlPressed := false

; RCtrl 押下時に状態フラグを設定
~$RCtrl::
{
    global rctrlPressed
    rctrlPressed := true
}

; LCtrl 押下時に状態フラグを設定
~$LCtrl::
{
    global lctrlPressed
    lctrlPressed := true
}

; =============================================================================
; IME制御用パススルーキー設定
; RCtrlが押されている間はパススルーを無効化（Emacsキーバインド優先）
; =============================================================================

; RCtrlが押されていないときのみ、パススルーキーを有効化
; LCtrlはデフォルト機能を使用可能
#HotIf !GetKeyState("RCtrl", "P")

; 主要なキーをパススルー
; 注：a, b, d, e, f, h, n, p, k は Emacsキーバインド用に除外
~c::
~g::
~i::
~j::
~l::
~m::
~o::
~q::
~r::
~s::
~t::
~u::
~v::
~w::
~x::
~y::
~z::
~F1::
~F2::
~F3::
~F4::
~F5::
~F6::
~F7::
~F8::
~F9::
~F10::
~F11::
~F12::
~`::
~~::
~!::
~@::
~#::
~$::
~%::
~^::
~&::
~*::
~(::
~)::
~-::
~_::
~=::
~+::
~{::
~}::
~\::
~|::
~;::
~'::
~"::
~,::
~<::
~.::
~>::
~/::
~?::
~Esc::
~Tab::
~Space::
~LAlt::
~RAlt::
~Left::
~Right::
~Up::
~Down::
~Enter::
~PrintScreen::
~Delete::
~Home::
~End::
~PgUp::
~PgDn::
{
    ; パススルー（何もしない）
}

; #HotIfコンテキストを終了（以降のホットキーは常に有効）
#HotIf

; =============================================================================
; PowerToys ショートカットキー設定
; =============================================================================

; -----------------------------------------------------------------------------
; Alt キーベースのショートカット
; -----------------------------------------------------------------------------

; Alt + Tab → Ctrl + Tab (タブ切り替え)
!Tab::Send "^{Tab}"

; Alt + Left → Ctrl + [ (左移動)
!Left::Send "^["

; Alt + Right → Ctrl + ] (右移動)
!Right::Send "^]"

; Alt + F4 → Ctrl + Q (ウィンドウを閉じる)
!F4::Send "^q"

; Alt + Shift + Tab → Ctrl + Shift + Tab (逆タブ切り替え)
!+Tab::Send "^+{Tab}"

; -----------------------------------------------------------------------------
; Ctrl キーベースのショートカット
; -----------------------------------------------------------------------------

; Ctrl + Tab → Alt + Tab (タスクビュー表示)
^Tab::
{
    Send "{Alt down}{Tab}"
    KeyWait "Ctrl"
    Send "{Alt up}"
}

; Ctrl + Q → アプリ終了 (1秒長押し)
^q::
{
    ; Qキーが離されるまで最大1秒待機
    if KeyWait("q", "T1")
    {
        ; 1秒以内に離された場合は何もしない
        return
    }
    else
    {
        ; 1秒間押し続けた場合はアプリを終了
        WinClose "A"
    }
}

; Ctrl + [ → Alt + Left (左移動)
^[::Send "!{Left}"

; Ctrl + ] → Alt + Right (右移動)
^]::Send "!{Right}"

; =============================================================================
; Emacsキーバインド（グローバル - 最初に定義して優先度を上げる）
; 【重要】この定義をパススルーコンテキストより**前に配置**することで、
; GetKeyState() の判定よりも先に >^ ホットキーが評価される
; =============================================================================

; VSCode & Cursor 専用：>^a と >^x は元の Ctrl+a/x を保持
#HotIf WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Cursor.exe")
>^a::Send "^a"
>^x::Send "^x"
>^d::Send "^d"
#HotIf

; その他のアプリケーション用 Emacsキーバインド（グローバル）
; これらは常に優先的に評価される
>^e::Send "{End}"
>^b::Send "{Left}"
>^f::Send "{Right}"
>^n::Send "{Down}"
>^p::Send "{Up}"
>^h::Send "{Backspace}"
>^d::Send "{Delete}"
>^k::Send "+{End}{Delete}"

; VSCode以外で >^a を Emacs Home として定義
#HotIf !WinActive("ahk_exe Code.exe")
>^a::Send "{Home}"
#HotIf

; =============================================================================
; Ctrl + Shift ベースのショートカット
; =============================================================================

; Ctrl + Shift + Tab → Ctrl + Alt + Tab (詳細タブ切り替え)
^+Tab::Send "^!{Tab}"

; Ctrl + Shift + [ → Ctrl + PgUp (ページアップ)
^+[::Send "^{PgUp}"

; Ctrl + Shift + ] → Ctrl + PgDn (ページダウン)
^+]::Send "^{PgDn}"

; Ctrl + Shift + H → Win + Shift + Left (ウィンドウ左画面移動)
; ^+h::Send "#+{Left}"
^>^h::Send "#+{Left}"

; Ctrl + Shift + L → Win + Shift + Right (ウィンドウ右画面移動)
; ^+l::Send "#+{Right}"
^>^l::Send "#+{Right}"

; Ctrl + Shift + V → Win + V (クリップボード履歴)
^+v::Send "#{v}"

; =============================================================================
; Ctrl + PgUp/PgDn ベースのショートカット
; =============================================================================

; Ctrl + PgUp → Ctrl + Shift + [ (ページアップ逆)
^PgUp::Send "^+["

; Ctrl + PgDn → Ctrl + Shift + ] (ページダウン逆)
^PgDn::Send "^+]"

; =============================================================================
; IME 制御（改善版）
; =============================================================================

; 左 Ctrl 空打ちで IME を OFF
; A_PriorKeyで判定し、他のキーと組み合わせの場合は発動しない
LCtrl up::
{
    ; LCtrlが単独で押されて離された場合のみIME OFF
    ; 他のキーと組み合わせで使われた場合は何もしない
    if (A_PriorKey == "LControl")
    {
        IME_SET(0)
    }
    global lctrlPressed
    lctrlPressed := false
}

; 右 Ctrl 空打ちで IME を ON
RCtrl up::
{
    ; 他のキーが押されていないかチェック
    if (A_PriorKey == "RControl")
    {
        IME_SET(1)
    }
    global rctrlPressed
    rctrlPressed := false
}

; =============================================================================
; ウィンドウ配置用の共通関数
; DwmGetWindowAttribute APIで見えない境界線を補正
; =============================================================================

; 指定したウィンドウのハンドルからモニター番号を取得するヘルパー関数
MonitorFromWindow(hWnd)
{
    ; MONITOR_DEFAULTTONEAREST = 2
    hMonitor := DllCall("MonitorFromWindow", "Ptr", hWnd, "UInt", 2, "Ptr")

    monitorCount := MonitorGetCount()
    Loop monitorCount
    {
        ; 各モニターをチェック
        MonitorGet A_Index, &mLeft, &mTop, &mRight, &mBottom

        ; ウィンドウの中心座標を取得
        WinGetPos &winX, &winY, &winW, &winH, hWnd
        winCenterX := winX + (winW // 2)
        winCenterY := winY + (winH // 2)

        ; ウィンドウ中心がモニター内にあればそのモニター番号を返す
        if (winCenterX >= mLeft && winCenterX < mRight && winCenterY >= mTop && winCenterY < mBottom)
            return A_Index
    }
    return 1  ; 見つからない場合はプライマリモニターを返す
}

; ウィンドウを指定方向の半分に配置する関数（余白完全除去版）
; side: "Left", "Right", "Top", "Bottom"
MoveWindowToHalf(side)
{
    try
    {
        activeWin := WinExist("A")
        if !activeWin
            return

        ; 1. ウィンドウを通常状態に戻す
        WinRestore activeWin
        Sleep 100

        ; 2. ウィンドウの矩形情報を取得（境界線含む）
        rect := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", activeWin, "Ptr", rect)
        left := NumGet(rect, 0, "Int")
        top := NumGet(rect, 4, "Int")
        right := NumGet(rect, 8, "Int")
        bottom := NumGet(rect, 12, "Int")

        ; 3. 実際の表示領域を取得（境界線除く）
        ; DWMWA_EXTENDED_FRAME_BOUNDS = 9
        extendedFrame := Buffer(16, 0)
        DllCall("dwmapi\DwmGetWindowAttribute",
            "Ptr", activeWin,
            "Int", 9,
            "Ptr", extendedFrame,
            "Int", 16)
        frameLeft := NumGet(extendedFrame, 0, "Int")
        frameTop := NumGet(extendedFrame, 4, "Int")
        frameRight := NumGet(extendedFrame, 8, "Int")
        frameBottom := NumGet(extendedFrame, 12, "Int")

        ; 4. 見えない境界線のサイズを計算
        cropLeft := frameLeft - left
        cropTop := frameTop - top
        cropRight := right - frameRight
        cropBottom := bottom - frameBottom

        ; 5. ウィンドウが存在するモニターの作業領域を取得
        monIndex := MonitorFromWindow(activeWin)
        MonitorGetWorkArea(monIndex, &mLeft, &mTop, &mRight, &mBottom)

        ; 6. 作業領域のサイズを計算
        workAreaWidth := mRight - mLeft
        workAreaHeight := mBottom - mTop
        halfWidth := workAreaWidth // 2
        halfHeight := workAreaHeight // 2

        ; 7. 境界線補正を適用した座標とサイズを計算
        if (side = "Left")
        {
            newX := mLeft - cropLeft
            newY := mTop - cropTop
            newW := halfWidth + cropLeft + cropRight
            newH := workAreaHeight + cropTop + cropBottom
            WinMove newX, newY, newW, newH, activeWin
        }
        else if (side = "Right")
        {
            newX := mLeft + halfWidth - cropLeft
            newY := mTop - cropTop
            newW := (workAreaWidth - halfWidth) + cropLeft + cropRight
            newH := workAreaHeight + cropTop + cropBottom
            WinMove newX, newY, newW, newH, activeWin
        }
        else if (side = "Top")
        {
            newX := mLeft - cropLeft
            newY := mTop - cropTop
            newW := workAreaWidth + cropLeft + cropRight
            newH := halfHeight + cropTop + cropBottom
            WinMove newX, newY, newW, newH, activeWin
        }
        else if (side = "Bottom")
        {
            newX := mLeft - cropLeft
            newY := mTop + halfHeight - cropTop
            newW := workAreaWidth + cropLeft + cropRight
            newH := (workAreaHeight - halfHeight) + cropTop + cropBottom
            WinMove newX, newY, newW, newH, activeWin
        }
    }
    catch as err
    {
        return
    }
}

; =============================================================================
; Ctrl + Alt ベースのショートカット (ウィンドウ配置)
; 余白完全除去版 + 関数化によるコード削減
; =============================================================================

; Ctrl + Alt + H → ウィンドウ左半分配置
$^!h::MoveWindowToHalf("Left")

; Ctrl + Alt + J → ウィンドウ下半分配置
$^!j::MoveWindowToHalf("Bottom")

; Ctrl + Alt + K → ウィンドウ上半分配置
$^!k::MoveWindowToHalf("Top")

; Ctrl + Alt + L → ウィンドウ右半分配置
$^!l::MoveWindowToHalf("Right")

; Ctrl + Alt + M → ウィンドウ最大化
$^!m::
{
    try
    {
        if WinExist("A")
            WinMaximize "A"
    }
    catch as err
    {
        return
    }
}

#HotIf WinActive("ahk_exe wezterm-gui.exe")

; RCtrl + k を行末削除として実装（End+Delete）
; WezTermで CTRL+k は ScrollByLine(-1) に設定されているため、
; キー入力そのものを送信することで Kill-line 動作を実現
>^k::Send "{End}{Delete}"

; LCtrl+V を Ctrl+Q に変換して送る（"Send"でアプリに渡す）
>^v::Send "^{q}"

; LCtrl+cをCtrl+Shift+cに変換して送る
>^c::send "^+{c}"

#HotIf

; =============================================================================
; Win + 数字 → 仮想デスクトップ切り替え
; =============================================================================

; #1::Send "^#{Left}"   ; Win+1 → 左のデスクトップへ
; #2::Send "^#{Right}"  ; Win+2 → 右のデスクトップへ

; =============================================================================
; Ctrl + 矢印 → 仮想デスクトップ切り替え
; =============================================================================

^Left::SendInput "^#{Left}"   ; Ctrl+← → 左のデスクトップへ
^Right::SendInput "^#{Right}"  ; Ctrl+→ → 右のデスクトップへ

