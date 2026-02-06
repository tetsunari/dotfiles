require("full-border"):setup({
  type = ui.Border.ROUNDED,
})
require("zoxide"):setup({
  update_db = true,
})
require("git"):setup()

function Linemode:p_s_m()
    local cha = self._file.cha

    -- permissions
    -- Unix系では cha:perm() が "rwxrwxrwx" 形式を返します
    -- 取れない場合は "----------" をデフォルトにします
    local permi = (type(cha.perm) == "function" and cha:perm()) 
               or (type(cha.permissions) == "function" and cha:permissions())
               or "----------"

    -- size
    local size = self._file:size()
    local size_str = size and ya.readable_size(size) or "- "

    -- time
    local time_str = ""
    if cha.mtime then
        local time = math.floor(cha.mtime)
        if os.date("%Y", time) == os.date("%Y") then
            time_str = os.date("%b %d %H:%M", time)
        else
            time_str = os.date("%b %d  %Y", time)
        end
    end

    -- 描画
    -- パーミッションが長すぎて隠れないよう、右詰めにせず順番に並べます
    return ui.Line({
        -- ui.Span(permi):style(ui.Style():fg("cyan")),
        -- ui.Span(" "),
        -- ui.Span(string.format("%7s", size_str)):style(ui.Style():fg("yellow")),
        -- ui.Span(" "),
        -- ui.Span(time_str):style(ui.Style():fg("white")),
        ui.Span(permi),
        ui.Span(string.format("%7s ", size_str)):style(ui.Style():fg("yellow")),
        ui.Span(time_str),
    })
end
