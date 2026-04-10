VOIDTERM = VOIDTERM or {}
VOIDTERM.Input = {}
local state = nil
local frame = nil
local inputs = {
    console = nil,
    code = nil,
    password = nil
}
function VOIDTERM.Input.Init(mainFrame, menuState, playSoundFunc)
    frame = mainFrame
    state = menuState
    if playSoundFunc then
        VOIDTERM.Input.PlaySound = playSoundFunc
    end
    inputs.console = vgui.Create("DTextEntry", frame)
    inputs.console:SetVisible(false)
    inputs.console:SetAlpha(0)
    inputs.console:SetFont("Petrov_Console")
    inputs.console:SetTextColor(Color(0, 255, 65))
    inputs.console:SetDrawBackground(false)
    inputs.console:SetCursorColor(Color(0, 255, 65))
    inputs.console.Paint = function(self, w, h) end
    inputs.console.PaintOver = function() end
    inputs.console.OnKeyCodeTyped = function(self, code)
        local isGameRunning = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning()
        if isGameRunning then
            return
        end
        if code ~= KEY_ENTER and VOIDTERM.Input.PlaySound then
            VOIDTERM.Input.PlaySound("INPUT1")
        end
        if code == KEY_UP then
            VOIDTERM.Input.NavigateHistory(-1)
        elseif code == KEY_DOWN then
            VOIDTERM.Input.NavigateHistory(1)
        elseif code == KEY_ENTER then
            self:OnEnter()
        elseif code == KEY_TAB then
            if VOIDTERM.BASIC and VOIDTERM.BASIC.Stop then
                VOIDTERM.BASIC.Stop()
            end
        end
    end
    inputs.console.OnEnter = function(self)
        local cmd = self:GetValue()
        if cmd and cmd ~= "" then
            if VOIDTERM.Commands and VOIDTERM.Commands.Execute then
                VOIDTERM.Commands.Execute(cmd)
            end
            table.insert(state.commandHistory, cmd)
            state.historyIndex = #state.commandHistory + 1
            self:SetText("")
            self:RequestFocus()
        end
    end
    inputs.code = vgui.Create("DTextEntry", frame)
    inputs.code:SetVisible(false)
    inputs.code:SetAlpha(0)
    inputs.code:SetFont("Petrov_Console")
    inputs.code:SetTextColor(Color(255, 255, 255))
    inputs.code:SetDrawBackground(false)
    inputs.code:SetCursorColor(Color(255, 255, 255))
    inputs.code.Paint = function(self, w, h) end
    inputs.code.PaintOver = function() end
    local CODE_TABLE = {
        ["[REDACTED_CODE]"] = {
            action = function(s) s.logsUnlocked = true end,
            msg = "ACCESS GRANTED: CLASSIFIED ARCHIVE UNLOCKED"
        },
    }
    inputs.code.OnEnter = function(self)
        local entered = string.upper(string.Trim(self:GetValue()))
        local codeData = CODE_TABLE[entered]
        if codeData then
            codeData.action(state)
            state.codeMessage = codeData.msg
            state.codeMessageTime = CurTime()
            state.codeMessageSuccess = true
        else
            state.codeMessage = "INVALID CODE: ACCESS DENIED"
            state.codeMessageTime = CurTime()
            state.codeMessageSuccess = false
        end
        self:SetText("")
        self:RequestFocus()
    end
    if VOIDTERM.Graphics and VOIDTERM.Graphics.SetInputCallback then
        VOIDTERM.Graphics.SetInputCallback(function(visible)
            if inputs.console then
                if visible then
                    inputs.console:SetVisible(true)
                    inputs.console:RequestFocus()
                else
                    inputs.console:SetVisible(false)
                    inputs.console:KillFocus()
                    inputs.console:SetText("")
                end
            end
        end)
    end
    VOIDTERM.Input.consoleEntry = inputs.console
    VOIDTERM.Input.codeEntry = inputs.code
    if frame then
        local oldOnMousePressed = frame.OnMousePressed
        frame.OnMousePressed = function(self, mouseCode)
            if mouseCode == MOUSE_LEFT and state then
                local isGameRunning = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning()
                local mx, my = self:CursorPos()
                if state.screen == "login" then
                    if self.passEntry and IsValid(self.passEntry) then
                        self.passEntry:RequestFocus()
                    end
                    return
                end
                if state.screen == "computer" and not isGameRunning then
                    if state.currentTab == "CONSOLE" then
                        if inputs.console and inputs.console:IsVisible() then
                            inputs.console:RequestFocus()
                            local textStartX = 20
                            local clickRelX = mx - textStartX
                            if clickRelX > 0 then
                                local txt = inputs.console:GetValue()
                                local prefix = "> "
                                surface.SetFont("Petrov_Console")
                                local prefixW = surface.GetTextSize(prefix)
                                clickRelX = clickRelX - prefixW
                                if clickRelX <= 0 then
                                    inputs.console:SetCaretPos(0)
                                else
                                    local bestPos = #txt
                                    for ci = 1, #txt do
                                        local subW = surface.GetTextSize(txt:sub(1, ci))
                                        if subW >= clickRelX then
                                            bestPos = ci - 1
                                            local prevW = ci > 1 and surface.GetTextSize(txt:sub(1, ci - 1)) or 0
                                            if (clickRelX - prevW) > (subW - clickRelX) then
                                                bestPos = ci
                                            end
                                            break
                                        end
                                    end
                                    inputs.console:SetCaretPos(bestPos)
                                end
                            else
                                inputs.console:SetCaretPos(0)
                            end
                        end
                    elseif state.currentTab == "CODE" then
                        if inputs.code and inputs.code:IsVisible() then
                            inputs.code:RequestFocus()
                        end
                    end
                end
            end
            if oldOnMousePressed then
                oldOnMousePressed(self, mouseCode)
            end
        end
    end
end
function VOIDTERM.Input.OnTabChanged(newTab)
    if not state or not frame then return end
    local isGameRunning = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning()
    if inputs.console then
        inputs.console:SetVisible(false)
        inputs.console:KillFocus()
    end
    if inputs.code then
        inputs.code:SetVisible(false)
        inputs.code:KillFocus()
    end
    if newTab == "CONSOLE" then
        if inputs.console and not isGameRunning then
            inputs.console:SetVisible(true)
            inputs.console:RequestFocus()
            inputs.console:SetCaretPos(#inputs.console:GetValue())
        end
    elseif newTab == "CODE" then
        if inputs.code then
            inputs.code:SetVisible(true)
            inputs.code:RequestFocus()
        end
    elseif newTab == "FILES" then
        if VOIDTERM.FileSystem then
            state.files = VOIDTERM.FileSystem.List()
            state.fileSelection = 1
            state.viewingFile = nil
        end
    elseif newTab == "EXPERIMENTS" then
        state.selectedExperiment = state.selectedExperiment or 1
        if VOIDTERM.Experiments and VOIDTERM.Experiments.Install then
            VOIDTERM.Experiments.Install()
        end
        if frame then
            frame:RequestFocus()
            frame:SetKeyboardInputEnabled(true)
        end
    elseif newTab == "LOGS" then
        if state.logsUnlocked and not state.logsConnected and not state.logsConnecting then
            state.logsConnecting = true
            state.logsConnectStart = CurTime()
        end
        if frame then
            frame:RequestFocus()
            frame:SetKeyboardInputEnabled(true)
        end
    end
end
function VOIDTERM.Input.UpdateLayout(w, h, margin)
    if not state or not frame then return end
    local isComputer = (state.screen == "computer")
    local tab = state.currentTab
    if inputs.console then
        inputs.console:SetPos(-9999, -9999)
        inputs.console:SetSize(400, 22)
        local isGraphicsMode = state.graphicsMode or false
        local isGameRunning = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning()
        local shouldShow = isComputer and (tab == "CONSOLE") and (not isGraphicsMode) and (not isGameRunning)
        if inputs.console:IsVisible() ~= shouldShow then
            inputs.console:SetVisible(shouldShow)
            if shouldShow then
                inputs.console:RequestFocus()
                inputs.console:SetCaretPos(#inputs.console:GetValue())
            else
                inputs.console:KillFocus()
                inputs.console:SetText("")
            end
        end
        if (isGraphicsMode or isGameRunning) and inputs.console:HasFocus() then
            inputs.console:KillFocus()
            inputs.console:SetText("")
        end
    end
    if inputs.code then
        inputs.code:SetPos(-9999, -9999)
        inputs.code:SetSize(190, 20)
        local shouldShow = isComputer and (tab == "CODE")
        if inputs.code:IsVisible() ~= shouldShow then
            inputs.code:SetVisible(shouldShow)
            if shouldShow then inputs.code:RequestFocus() end
        end
    end
    local isGameRunning = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning()
    local showTabs = isComputer and not isGameRunning
    if state.tabButtons then
        for _, btn in ipairs(state.tabButtons) do
            if IsValid(btn) then
                btn:SetVisible(showTabs)
            end
        end
    end
    if not isComputer then
        if inputs.console and inputs.console:IsVisible() then inputs.console:SetVisible(false) end
        if inputs.code and inputs.code:IsVisible() then inputs.code:SetVisible(false) end
    end
end
function VOIDTERM.Input.HandleKey(key)
    if not state then return end
    if state.screen == "computer" and state.currentTab == "FILES" then
        if state.viewingFile then
            if key == KEY_BACKSPACE or key == KEY_ESCAPE then
                state.viewingFile = nil
                state.fileScrollOffset = 0
            elseif key == KEY_UP then
                state.fileScrollOffset = math.max(0, (state.fileScrollOffset or 0) - 1)
            elseif key == KEY_DOWN then
                state.fileScrollOffset = (state.fileScrollOffset or 0) + 1
            end
        else
            if key == KEY_UP then
                state.fileSelection = math.max(1, state.fileSelection - 1)
            elseif key == KEY_DOWN then
                state.fileSelection = math.min(#state.files, state.fileSelection + 1)
            elseif key == KEY_ENTER then
                local filename = state.files[state.fileSelection]
                if filename then
                    local content = VOIDTERM.FileSystem.Load(filename)
                    if content then
                        state.viewingFile = {name = filename, content = content}
                    else
                    end
                end
            end
        end
        return true
    end
    if state.screen == "computer" and state.currentTab == "EXPERIMENTS" then
        if VOIDTERM.Experiments and VOIDTERM.Experiments.IsRunning and VOIDTERM.Experiments.IsRunning() then
            if key == KEY_TAB then
                VOIDTERM.Experiments.Stop()
            end
            return true
        end
        local expCount = VOIDTERM.Experiments and VOIDTERM.Experiments.List and #VOIDTERM.Experiments.List or 0
        if key == KEY_UP then
            state.selectedExperiment = math.max(1, (state.selectedExperiment or 1) - 1)
        elseif key == KEY_DOWN then
            state.selectedExperiment = math.min(expCount, (state.selectedExperiment or 1) + 1)
        elseif key == KEY_ENTER then
            local sel = state.selectedExperiment or 1
            if VOIDTERM.Experiments and VOIDTERM.Experiments.Launch then
                VOIDTERM.Experiments.Launch(sel)
            end
        end
        return true
    end
    if state.screen == "computer" and state.currentTab == "LOGS" then
        if state.logsConnected then
            if key == KEY_UP then
                state.logsScrollOffset = math.max(0, (state.logsScrollOffset or 0) - 1)
            elseif key == KEY_DOWN then
                state.logsScrollOffset = (state.logsScrollOffset or 0) + 1
            end
        end
        return true
    end
    return false
end
function VOIDTERM.Input.NavigateHistory(dir)
    if not inputs.console or #state.commandHistory == 0 then return end
    state.historyIndex = math.Clamp(state.historyIndex + dir, 1, #state.commandHistory + 1)
    if state.historyIndex > #state.commandHistory then
        inputs.console:SetText("")
    else
        local cmd = state.commandHistory[state.historyIndex]
        if cmd then
            inputs.console:SetText(cmd)
            inputs.console:SetCaretPos(#cmd)
        end
    end
end
