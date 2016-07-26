--
-- �������������/Secret��������߅���ѵ����ܣ��������g������
--
HM_Secret = {
	bShowButton = true,
}
HM.RegisterCustomData("HM_Secret")

---------------------------------------------------------------------
-- ���غ�����׃��
---------------------------------------------------------------------
local _HM_Secret = {
	szName = "����/Secret",
	szIniFile = "interface\\HM\\HM_Secret\\HM_Secret.ini",
}

-- format time
--[[
_HM_Secret.FormatTime = function(nTime)
	local nNow = GetCurrentTime()
	nTime = nNow - (tonumber(nTime) or nNow)
	if nTime < 60 then
		return "����"
	elseif nTime < 3600 then
		return string.format("%d���ǰ", nTime / 60)
	elseif nTime < 86400 then
		return string.format("%dС�rǰ", nTime / 3600)
	else
		return string.format("%d��ǰ", nTime / 86400)
	end
end

-- ��a���� table
_HM_Secret.TableDecode = function(t)
	if type(t) == "table" then
		for k, v in pairs(t) do
			if type(v) == "table" then
				_HM_Secret.TableDecode(v)
			elseif type(v) == "string" and string.find(v, "%", 1, 1) then
				t[k] = HM.UrlDecode(v)
			end
		end
	end
end

-- �h��Ո��ս��� urlencoed-JSON�����e�r�Ԅӏ� alert
_HM_Secret.RemoteCall = function(szAction, tParam, fnCallback)
	local t = {}
	for k, v in pairs(tParam) do
		table.insert(t, k .. "=" .. HM.UrlEncode(tostring(v)))
	end
	table.insert(t, "_=" .. GetCurrentTime())
	HM.RemoteRequest("http://jx3.hightman.cn/sr/" .. szAction .. ".php?" .. table.concat(t, "&"), function(szTitle, szContent)
		if fnCallback and szContent and szContent ~= "" then
			local data, err = HM.JsonDecode(szContent)
			if not data then
				--HM.Alert("���� JSON �����e�`��" .. tostring(err), fnCallback)
				HM.Sysmsg("���� JSON �����e�`��" .. tostring(err))
			elseif type(data) == "table" and data.error then
				--HM.Alert("���ն˳��e��" .. HM.UrlDecode(data.error), fnCallback)
				HM.Sysmsg("������ն˳��e��" .. HM.UrlDecode(data.error))
			else
				_HM_Secret.TableDecode(data)
				pcall(fnCallback, data)
			end
		end
	end)
end

-- post notify (myself + friend ids)
_HM_Secret.PostNotify = function(dwID, fnAction, bForward)
	local me, t = GetClientPlayer(), {}
	local aGroup = me.GetFellowshipGroupInfo() or {}
	local szList = me.szName .. "-" .. me.dwID
	table.insert(aGroup, 1, { id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND })
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if szList == "" then
				szList = vv.name .. "-" .. vv.id
			else
				szList = szList .. "," .. vv.name .. "-" .. vv.id
				if string.len(szList) > 512 then
					table.insert(t, szList)
					szList = ""
				end
			end
		end
	end
	if szList ~= "" then
		table.insert(t, szList)
	end
	for i = 1, #t, 1 do
		_HM_Secret.RemoteCall("notify", { d = dwID, f = t[i], z = bForward and 1 }, i == #t and fnAction)
	end
end

-- post new
_HM_Secret.PostNew = function()
	local frm = _HM_Secret.eFrame
	if not frm then
		local nMaxLen, szFormatLen = 198, "�֔���%d/%d"
		frm = HM.UI.CreateFrame("HM_Secret_Post", { close = false, w = 380, h = 360, title = "��������С����", drag = true })
		frm:Append("Text", "Text_Length", { txt = szFormatLen:format(0, nMaxLen), x = 0, y = 0, font = 27 })
		frm:Append("WndEdit", "Edit_Content", { x = 0, y = 28, limit = nMaxLen, w = 290, h = 140, multi = true }):Change(function(szText)
			frm:Fetch("Text_Length"):Text(string.format(szFormatLen, string.len(szText), nMaxLen))
		end)
		-- add btn_face
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local btn = dummy:Lookup("Btn_Face")
		btn:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		btn:SetRelPos(270, 6)
		btn:SetSize(20, 20)
		btn:Show()
		btn.OnLButtonClick = function()
			local frame = Wnd.OpenWindow("EmotionPanel")
			local _, nH = frame:GetSize()
			local nX, nY = this:GetAbsPos()
			frame:SetAbsPos(nX, nY - nH)
			frame.bSecret = true
		end
		-- buttons
		frm:Append("WndButton", "Btn_Submit", { txt = "�l��", x = 45, y = 180 }):Click(function()
			local szContent = frm:Fetch("Edit_Content"):Text()
			_HM_Secret.RemoteCall("post", { c = szContent }, function(data)
				if not data then
					frm:Fetch("Btn_Submit"):Enable(true)
				else
					_HM_Secret.PostNotify(data, function()
						_HM_Secret.LoadList()
						frm:Toggle(false)
						frm:Fetch("Edit_Content"):Text("")
					end)
				end
			end)
			frm:Fetch("Btn_Submit"):Enable(false)
		end)
		frm:Append("WndButton", "Btn_Cancel", { txt = "ȡ��", x = 145, y = 180 }):Click(function()
			frm:Toggle(false)
		end)
		frm:Append("Text", { txt = "��ʾ���l��������ֻ���Լ��ͺ����ܿ��������қ]������֪���l�l���ġ�", x = 0, y = 214, font = 47, multi = true, w = 290, h = 50 })
		_HM_Secret.eFrame = frm
	end
	if _HM_Secret.vFrame then
		_HM_Secret.vFrame:Toggle(false)
	end
	Wnd.CloseWindow("EmotionPanel")
	frm:Toggle(true)
	frm:Fetch("Btn_Submit"):Enable(true)
	Station.SetFocusWindow(frm:Fetch("Edit_Content"):Raw())
end

-- emotion hook
HM.BreatheCall("HM_Secret_Emotion", function()
	local frame = Station.Lookup("Normal/EmotionPanel")
	if frame and frame.bSecret then
		local hL = frame:Lookup("WndContainer_Page/Wnd_EM", "Handle_Image")
		local hI = hL:Lookup(0)
		if hI and hI.bFace and not hI.bSecret then
			hI.bSecret = true
			for i = 0, hL:GetItemCount() - 1, 1 do
				local hI = hL:Lookup(i)
				hI.OnItemLButtonClick = function()
					if _HM_Secret.eFrame and Station.Lookup("Normal/HM_Secret_Post"):IsVisible() then
						local edit = _HM_Secret.eFrame:Fetch("Edit_Content"):Raw()
						edit:InsertText(this.szCmd)
					elseif _HM_Secret.vFrame and Station.Lookup("Normal/HM_Secret_View"):IsVisible() and not _HM_Secret.vFrame.bForward then
						local edit = _HM_Secret.vFrame:Fetch("Edit_Comment"):Raw()
						if edit:GetText() == _HM_Secret.vFrame.ctip then
							edit:SetText(this.szCmd)
							edit:SetFontScheme(162)
						else
							edit:InsertText(this.szCmd)
						end
					else
						Wnd.CloseWindow(this:GetRoot())
					end
				end
			end
		end
	end
end)

-- set all child text node font
_HM_Secret.SetChildrenFont = function(h, nFont)
	for i = 0, h:GetItemCount() - 1, 1 do
		local t = h:Lookup(i)
		if t:GetType() == "Text" then
			t:SetFontScheme(nFont)
		end
	end
	h:FormatAllItemPos()
end

-- append rich text to handle
_HM_Secret.AppendRichText = function(h, szText, nFont, tColor)
	local t = HM.ParseFaceIcon({{ type = "text", text = szText }})
	local szXml, szDeco = "", " font=" .. (nFont or 41)
	if type(tColor) == "table" then
		szDeco = szDeco .. " r=" .. tColor[1] .. " g=" .. tColor[2] .. " b=" .. tColor[3]
	end
	local nS = 20, 20
	if Station.GetUIScale() < 0.8 then
		nS = math.floor(Station.GetUIScale()  / 0.8 * 20)
	end
	for _, v in ipairs(t) do
		if v.type == "text" then
			szXml = szXml .. "<text>text=" .. EncodeComponentsString(v.text) .. szDeco .. " </text>"
		elseif v.type == "emotion" then
			local r = g_tTable.FaceIcon:GetRow(v.id + 1)
			if not r then
				szXml = szXml .. "<text>text=" .. EncodeComponentsString(v.text) ..  szDeco .. " </text>"
			elseif r.szType == "animate" then
				szXml = szXml .. "<animate>path=" .. EncodeComponentsString(r.szImageFile) .. " disablescale=1 group=" .. r.nFrame .. " w=" .. nS .. " h=" .. nS .. " </animate>"
			else
				szXml = szXml .. "<image>path=" .. EncodeComponentsString(r.szImageFile) .. " disablescale=1 frame=" .. r.nFrame .. " w=" .. nS .. " h=" .. nS .. " </image>"
			end
		end
	end
	h:AppendItemFromString(szXml)
	h:FormatAllItemPos()
end

-- set rich text
_HM_Secret.SetRichText = function(h, ...)
	h:Clear()
	_HM_Secret.AppendRichText(h, ...)
end

-- update comment scroll (nH = 31)
_HM_Secret.UpdateListScroll = function(scroll, handle, nH, nPos)
	local w, h = handle:GetSize()
	local wA, hA = handle:GetAllItemSize()
	local nStep = math.ceil((hA - h) / nH)
	scroll:SetStepCount(nStep)
	if nStep > 0 then
		scroll:Show()
	else
		scroll:Hide()
	end
	if nPos then
		scroll:SetScrollPos(nPos)
	end
	if scroll:GetScrollPos() > nStep then
		scroll:SetScrollPos(nStep)
	end
end

-- show one
_HM_Secret.ShowOne = function(data)
	if not data then
		return
	end
	Wnd.CloseWindow("EmotionPanel")
	local frm = _HM_Secret.vFrame
	local hC = frm:Fetch("Handle_Content"):Raw()
	_HM_Secret.SetRichText(hC, string.gsub(data.content, "[\r\n]", ""), 201, { 255, 160, 255 })
	local nW, nH = hC:GetAllItemSize()
	hC:SetRelPos((680 - nW) / 2, (100 - nH) / 2)
	hC:GetParent():FormatAllItemPos()
	frm:Fetch("Text_Time"):Text(_HM_Secret.FormatTime(data.time_post) .. "��" .. data.cnum .. "�l�uՓ"):Toggle(true)
	frm.bForward = data.forward
	if data.forward then
		frm:Fetch("Edit_Comment"):Text("�D�l�����ܲ����uՓ"):Enable(false):Toggle(true)
	else
		frm:Fetch("Edit_Comment"):Text(frm.ctip):Enable(true):Font(108):Toggle(true)
	end
	frm:Fetch("Btn_Comment"):Enable(data.forward == false):Toggle(true)
	frm:Fetch("Btn_Laud"):Text("ٝ(" .. data.znum .. ")"):Enable(data.lauded == false):Toggle(true)
	frm:Fetch("Btn_Hiss"):Text("�u(" .. data.xnum .. ")"):Enable(data.hiss == false):Toggle(true)
	-- show comments
	local hnd =frm:Fetch("Handle_Comment")
	hnd:Raw():Clear()
	for _, v in ipairs(data.comments) do
		local h = hnd:Append("Handle3", { w = 665, h = 25 }):Raw()
		h:AppendItemFromString("<text>text=" .. EncodeComponentsString((v.owner or _L["<OUTER GUEST>"]) .. "��") .. " font=27 </text>")
		_HM_Secret.AppendRichText(h, v.content, 162)
		h:AppendItemFromString("<text>text=" .. EncodeComponentsString("  " .. _HM_Secret.FormatTime(v.time_post)) .. " font=108 </text>")
		h:FormatAllItemPos()
	end
	hnd:Raw():FormatAllItemPos()
	-- update coments scrollbar
	_HM_Secret.UpdateListScroll(frm:Fetch("Scroll_List"):Raw(), hnd:Raw(), 25, 0)
	frm.bLoading = false
end

-- read one
_HM_Secret.ReadOne = function(dwID)
	local frm = _HM_Secret.vFrame
	if not frm then
		local me = GetClientPlayer()
		frm = HM.UI.CreateFrame("HM_Secret_View", { close = false, w = 770, h = 430, title = "��x����", drag = true })
		frm.name = me.szName .. "-" .. me.dwID
		frm:Append("Image", { x = 0, y = 130, w = 680, h = 3 }):File("ui\\Image\\Minimap\\MapMark.UITex", 65)
		frm:Append("Handle3", "Handle_Content", { x = 0, y = 0, w = 680, h = 100 })
		frm:Append("Text", "Text_Time", { x = 0, y = 100 })
		frm:Append("WndEdit", "Edit_Comment", { x = 160, y = 100, w = 296, h = 25, limit = 60 })
		frm:Append("WndButton", "Btn_Comment", { txt = "�l��", x = 480, y = 100, w = 70, h = 26 }):Click(function()
			local szContent = frm:Fetch("Edit_Comment"):Text()
			if szContent == frm.ctip then
				return
			end
			local szRealName = nil
			if string.sub(szContent, 1, 1) == "@" then
				szRealName = "1"
				szContent = string.sub(szContent, 2)
			end
			_HM_Secret.RemoteCall("comment", { d = frm.id, o = frm.name, c = szContent, r = szRealName }, _HM_Secret.ShowOne)
		end)
		frm:Append("WndButton", "Btn_Laud", { txt = "ٝ(99)", x = 550, y = 100, w = 70, h = 26 }):Click(function()
			_HM_Secret.RemoteCall("laud", { d = frm.id, o = frm.name }, function(data)
				_HM_Secret.ShowOne(data)
				_HM_Secret.PostNotify(frm.id, nil, true)
			end)
		end)
		frm:Append("WndButton", "Btn_Hiss", { txt = "�u(0)", x = 620, y = 100, w = 60, h = 26, font = 166 }):Click(function()
			_HM_Secret.RemoteCall("hiss", { d = frm.id, o = frm.name }, function(data)
				if type(data) == "table" then
					-- refresh
					_HM_Secret.ShowOne(data)
				else
					-- deleted
					frm:Toggle(false)
					_HM_Secret.LoadList()
				end
			end)
		end)
		-- add btn_face
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local btn = dummy:Lookup("Btn_Face")
		btn:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		btn:SetRelPos(454, 100)
		btn:SetSize(20, 25)
		btn:Show()
		btn.OnLButtonClick = function()
			local frame = Wnd.OpenWindow("EmotionPanel")
			local _, nH = frame:GetSize()
			local nX, nY = this:GetAbsPos()
			frame:SetAbsPos(nX, nY - nH)
			frame.bSecret = true
		end
		-- comments: 25*8
		frm:Append("Handle3", "Handle_Comment", { x= 0, y = 140, w = 665, h = 200 }):Raw():RegisterEvent(2048)
		local dummy = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		local scroll = dummy:Lookup("Wnd_Result/Scroll_List")
		scroll:ChangeRelation(frm.wnd, true, true)
		Wnd.CloseWindow(dummy)
		scroll:SetRelPos(665, 140)
		scroll:SetSize(15, 200)
		scroll.OnScrollBarPosChanged = function()
			local nPos = this:GetScrollPos()
			local handle =frm.handle:Lookup("Handle_Comment")
			handle:SetItemStartRelPos(0, - nPos * 25)
		end
		frm.handle:Lookup("Handle_Comment").OnItemMouseWheel = function()
			if scroll:IsVisible() then
				scroll:ScrollNext(Station.GetMessageWheelDelta())
				return true
			end
		end
		frm.ctip = "��@�_�^���uՓ�t������ -_-"
		frm:Fetch("Edit_Comment"):Raw().OnSetFocus = function()
			if this:GetText() == frm.ctip then
				this:SetText("")
				this:SetFontScheme(162)
			end
		end
		frm:Fetch("Edit_Comment"):Raw().OnKillFocus = function()
			if this:GetText() == "" then
				this:SetText(frm.ctip)
				this:SetFontScheme(108)
			end
		end
		_HM_Secret.vFrame = frm
	end
	if frm.bLoading then
		return
	end
	frm.bLoading = true
	if _HM_Secret.eFrame then
		_HM_Secret.eFrame:Toggle(false)
	end
	-- hide all things
	frm:Fetch("Handle_Content"):Raw():Clear()
	frm:Fetch("Handle_Content"):Append("Text", { txt = "Loading...", x = 20, y = 20 })
	frm:Fetch("Handle_Content"):Raw():FormatAllItemPos()
	frm:Fetch("Text_Time"):Toggle(false)
	frm:Fetch("Edit_Comment"):Toggle(false)
	frm:Fetch("Btn_Comment"):Toggle(false)
	frm:Fetch("Btn_Laud"):Toggle(false)
	frm:Toggle(true)
	frm.id = dwID
	-- remote call
	_HM_Secret.RemoteCall("read", { d = dwID, o = frm.name }, _HM_Secret.ShowOne)
end

-- draw one item
_HM_Secret.AddTableRow = function(data)
	local hI = _HM_Secret.handle:AppendItemFromIni(_HM_Secret.szIniFile, "Handle_Item")
	hI.id = data.id
	hI.new = data.new
	hI:Lookup("Text_Time"):SetText(_HM_Secret.FormatTime(data.time_update))
	_HM_Secret.SetRichText(hI:Lookup("Handle_Content"), data.content, (hI.new and 40) or 41)
	if hI.new then
		hI:Lookup("Text_Time"):SetFontScheme(40)
	end
	hI.OnItemMouseEnter = function() this:Lookup("Image_Light"):Show() end
	hI.OnItemMouseLeave = function() this:Lookup("Image_Light"):Hide() end
	hI.OnItemLButtonDown = function()
		_HM_Secret.ReadOne(this.id)
		if this.new then
			_HM_Secret.SetChildrenFont(this:Lookup("Handle_Content"), 41)
			this:Lookup("Text_Time"):SetFontScheme(41)
			this.new = false
		end
	end
	hI:Show()
end

-- draw list
_HM_Secret.DrawTable = function(data_all)
	_HM_Secret.loading:Hide()
	_HM_Secret.handle:Clear()
	for _, v in ipairs(data_all) do
		_HM_Secret.AddTableRow(v)
	end
	_HM_Secret.handle:FormatAllItemPos()
	_HM_Secret.UpdateListScroll(_HM_Secret.win:Lookup("Scroll_List"), _HM_Secret.handle, 31, 0)
end

-- load lsit
_HM_Secret.LoadList = function()
	local me = GetClientPlayer()
	_HM_Secret.handle:Clear()
	_HM_Secret.loading:Show()
	if IsRemotePlayer(me.dwID) then
		return HM.Alert("����У�����֧��ԓ���ܣ�")
	end
	_HM_Secret.RemoteCall("list", { o = me.szName .. "-" .. me.dwID }, _HM_Secret.DrawTable)
end
--]]
-------------------------------------
-- �¼�̎��
-------------------------------------

-------------------------------------
-- �O�ý���
-------------------------------------
_HM_Secret.PS = {}

-- init
_HM_Secret.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- buttons
	--nX = ui:Append("WndButton", { x = 0, y = 0, txt = "ˢ���б�" }):Click(_HM_Secret.LoadList):Pos_()
	--nX = ui:Append("WndButton", { x = nX, y = 0, txt = "�l������" }):Click(_HM_Secret.PostNew):Pos_()
	-- Tips
	ui:Append("Text", { x = nX + 10, y = 0, txt = "�@���ǘ䶴�����ܾ́�������߅�����ѡ�", font = 27 })
	ui:Append("Text", { x = 0, y = 378, txt = "С��ʾ��������������ڃ��κ��˶��o��֪�����ܵā�Դ��Ո���İl����", font = 47 })
	-- tips
	ui:Append("Text", { x = 10, y = 28, w = 486, h = 50, multi = true, txt = "����/Secret �������D�Ƶ�΢�Ź��\̖�������D�Ķ��S�a��΢��������������������Pע���ɡ�", font = 207 })
	ui:Append("Image", { x = 0, y = 82, w = 532, h = 168 }):File("interface\\HM\\HM_0Base\\image.UITEX", 0)
	do return end
	--[[
	-- table frame
	local fx = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret")
	local win = fx:Lookup("Wnd_Result")
	win:ChangeRelation(frame, true, true)
	Wnd.CloseWindow(fx)
	win:SetRelPos(0, 32)
	win:Lookup("", "Text_TimeTitle"):SetText("�l��/����")
	win:Lookup("", "Text_ContentTitle"):SetText("����ժҪ")
	_HM_Secret.win = win
	_HM_Secret.handle = win:Lookup("", "Handle_List")
	_HM_Secret.loading = win:Lookup("", "Text_Loading")
	-- add checkbox
	ui:Append("WndCheckBox", { x = 206, y = 32, font = 47, txt = "��С�؈D�@ʾδ�x֪ͨ", checked = HM_Secret.bShowButton }):Click(function(bChecked)
		HM_Secret.bShowButton = bChecked
		local btn = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over/Btn_Secret")
		if btn then
			if bChecked then
				btn:Show()
			else
				btn:Hide()
			end
		end
	end)
	-- scroll
	win:Lookup("Scroll_List").OnScrollBarPosChanged = function()
		local nPos = this:GetScrollPos()
		_HM_Secret.handle:SetItemStartRelPos(0, - nPos * 31)
	end
	_HM_Secret.handle.OnItemMouseWheel = function()
		local scroll = win:Lookup("Scroll_List")
		if scroll:IsVisible() then
			scroll:ScrollNext(Station.GetMessageWheelDelta())
			return true
		end
	end
	_HM_Secret.LoadList()
	--]]
end

--[[
-- deinit
_HM_Secret.PS.OnPanelDeactive = function(frame)
	_HM_Secret.handle =nil
	_HM_Secret.loading = nil
	_HM_Secret.win = nil
	if _HM_Secret.eFrame then
		_HM_Secret.eFrame:Toggle(false)
	end
	if _HM_Secret.vFrame then
		_HM_Secret.vFrame:Toggle(false)
	end
end

---------------------------------------------------------------------
-- ע���¼�����ʼ��
---------------------------------------------------------------------
HM.RegisterEvent("LOADING_END", function()
	-- attach button
	local win = Station.Lookup("Normal/Minimap/Wnd_Minimap/Wnd_Over")
	local btn = win:Lookup("Btn_Secret")
	if not btn then
		local frame = Wnd.OpenWindow(_HM_Secret.szIniFile, "HM_Secret_Dummy")
		btn = frame:Lookup("Btn_Secret")
		btn:ChangeRelation(win, true, true)
		Wnd.CloseWindow(frame)
		btn:SetRelPos(28, 178)
		btn:Show()
		btn.OnLButtonClick = function()
			this:Lookup("", ""):Hide()
			HM.OpenPanel(_HM_Secret.szName)
		end
	end
	if not HM_Secret.bShowButton then
		return btn:Hide()
	else
		btn:Show()
	end
	-- get unread
	local me = GetClientPlayer()
	if IsRemotePlayer(me.dwID) then
		return
	end
	_HM_Secret.RemoteCall("unread", { o = me.szName .. "-" .. me.dwID }, function(nNum)
		local h = btn:Lookup("", "")
		if not nNum or nNum == 0 then
			h:Hide()
		else
			if nNum > 9 then
				nNum = 9
			end
			h:Lookup("Text_News"):SetText(tostring(nNum))
			h:Show()
		end
	end)
end)
--]]

-- add to HM collector
HM.RegisterPanel(_HM_Secret.szName, 2, _L["Recreation"], _HM_Secret.PS)

