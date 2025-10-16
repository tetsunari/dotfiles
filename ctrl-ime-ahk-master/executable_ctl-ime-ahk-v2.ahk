; AutoHotkey v2.0
; 左右 Ctrl キーの空打ちで IME の OFF/ON を切り替える
;
; 左 Ctrl キーの空打ちで IME を「英数」に切り替え
; 右 Ctrl キーの空打ちで IME を「かな」に切り替え
; Ctrl キーを押している間に他のキーを打つと通常の Ctrl キーとして動作

#Requires AutoHotkey v2.0
#SingleInstance Force

; キー入力の遅延を最小化
SetControlDelay 0
SetKeyDelay -1

; IME.ahk の関数をインクルード
#Include IME-v2.ahk

; Razer Synapseなど、キーカスタマイズ系のツールを併用しているときのエラー対策
; v2では A_MaxHotkeysPerInterval 変数を使用
A_MaxHotkeysPerInterval := 350

; 主要なキーを HotKey に設定し、何もせずパススルーする
*~a::
*~b::
*~c::
*~d::
*~e::
*~f::
*~g::
*~h::
*~i::
*~j::
*~k::
*~l::
*~m::
*~n::
*~o::
*~p::
*~q::
*~r::
*~s::
*~t::
*~u::
*~v::
*~w::
*~x::
*~y::
*~z::
*~1::
*~2::
*~3::
*~4::
*~5::
*~6::
*~7::
*~8::
*~9::
*~0::
*~F1::
*~F2::
*~F3::
*~F4::
*~F5::
*~F6::
*~F7::
*~F8::
*~F9::
*~F10::
*~F11::
*~F12::
*~`::
*~~::
*~!::
*~@::
*~#::
*~$::
*~%::
*~^::
*~&::
*~*::
*~(::
*~)::
*~-::
*~_::
*~=::
*~+::
*~[::
*~{::
*~]::
*~}::
*~\::
*~|::
*~;::
*~'::
*~"::
*~,::
*~<::
*~.::
*~>::
*~/::
*~?::
*~Esc::
*~Tab::
*~Space::
*~LAlt::
*~RAlt::
*~Left::
*~Right::
*~Up::
*~Down::
*~Enter::
*~PrintScreen::
*~Delete::
*~Home::
*~End::
*~PgUp::
*~PgDn::
*~LCtrl::
*~RCtrl::
{
    ; パススルー（何もしない）
}

; 左 Ctrl 空打ちで IME を OFF
LCtrl up::
{
    if (A_PriorHotkey == "*~LCtrl")
    {
        IME_SET(0)
    }
}

; 右 Ctrl 空打ちで IME を ON
~RCtrl::
{
    ; 0.5秒待機、タイムアウトならfalseを返す
    if !KeyWait("RCtrl", "T0.5")
        return
    
    ; 他のキーが押されていないかチェック
    if (A_PriorKey == "RControl")
    {
        IME_SET(1)
    }
}
