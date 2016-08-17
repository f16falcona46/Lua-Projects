function create_closure(f, data)
	return function(...)
		return f(data, ...)
	end
end

function initialize_threads(context)
	context.threadpool = {}
	context.currentthread = 1
	
	for i=1,10 do
		context.threadpool[i] = coroutine.create(function ()
				for j=1,i + 5 do
					coroutine.yield()
				end
				context.progressbar:SetValue(context.progressbar:GetValue() + 1)
			end)
	end
	
	context.mainpanel:Connect(wx.wxID_ANY, wx.wxEVT_IDLE,
		function (event)
			for i=#context.threadpool,1,-1 do
				if coroutine.status(context.threadpool[i]) == "dead" then
					table.remove(context.threadpool, i)
				end
			end
			if context.currentthread > #context.threadpool then
				context.currentthread = 1
			end
			if #context.threadpool > 0 then
				coroutine.resume(context.threadpool[context.currentthread])
				context.currentthread = context.currentthread + 1
			end
		end)
end

function create_window()
	local context = {}
	ID = {
		Button1 = 1,
		Button2 = 2,
		Button3 = 3,
		Button4 = 4,
		Button5 = 5,
		Timer1 = 6
	}
	context.frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Test", wx.wxDefaultPosition, wx.wxSize(600, 480), wx.wxDEFAULT_FRAME_STYLE)
	context.frame:SetMinSize(wx.wxSize(400, 300))
	context.mainpanel = wx.wxPanel(context.frame, wx.wxID_ANY)
	--context.frame:SetBackgroundColour(wx.wxSystemSettings.GetColour(wx.wxSYS_COLOUR_WINDOW))
	
	context.timer = wx.wxTimer(context.mainpanel, ID.Timer1)
	
	context.sizer = wx.wxGridBagSizer()
	context.sizer:Add(wx.wxButton(context.mainpanel, ID.Button1, "Test1", wx.wxDefaultPosition, wx.wxDefaultSize, 0), wx.wxGBPosition(0, 0), wx.wxGBSpan(), wx.wxALL + wx.wxEXPAND, 5)
	context.sizer:Add(wx.wxButton(context.mainpanel, ID.Button2, "Test2", wx.wxDefaultPosition, wx.wxDefaultSize, 0), wx.wxGBPosition(0, 1), wx.wxGBSpan(), wx.wxALL + wx.wxEXPAND, 5)
	context.sizer:Add(wx.wxButton(context.mainpanel, ID.Button3, "Test3", wx.wxDefaultPosition, wx.wxDefaultSize, 0), wx.wxGBPosition(1, 0), wx.wxGBSpan(), wx.wxALL + wx.wxEXPAND, 5)
	context.sizer:Add(wx.wxButton(context.mainpanel, ID.Button4, "Increment", wx.wxDefaultPosition, wx.wxDefaultSize, 0), wx.wxGBPosition(1, 1), wx.wxGBSpan(), wx.wxALL + wx.wxALIGN_CENTER, 5)
	context.timercounter = wx.wxStaticText(context.mainpanel, -1, "Timer events: 0")
	context.sizer:Add(context.timercounter, wx.wxGBPosition(0, 2), wx.wxGBSpan(), wx.wxALL + wx.wxALIGN_CENTER, 5)
	context.buttoncounter = wx.wxStaticText(context.mainpanel, -1, "Button clicks: 0")
	context.sizer:Add(context.buttoncounter, wx.wxGBPosition(1, 2), wx.wxGBSpan(), wx.wxALL + wx.wxALIGN_CENTER, 5)
	context.sizer:Add(wx.wxButton(context.mainpanel, ID.Button5, "MultiSpan", wx.wxDefaultPosition, wx.wxDefaultSize, 0), wx.wxGBPosition(0, 3), wx.wxGBSpan(3, 1), wx.wxALL + wx.wxEXPAND, 5)
	context.threadindicator = wx.wxStaticText(context.mainpanel, -1, "Current thread: NONE")
	context.sizer:Add(context.threadindicator, wx.wxGBPosition(2, 0), wx.wxGBSpan(1, 3), wx.wxALL + wx.wxEXPAND, 5)
	context.progressbar = wx.wxGauge(context.mainpanel, wx.wxID_ANY, 10)
	context.sizer:Add(context.progressbar, wx.wxGBPosition(3, 0), wx.wxGBSpan(1, 4), wx.wxALL + wx.wxEXPAND, 5)
	
	
	context.sizer:AddGrowableRow(0)
	context.sizer:AddGrowableRow(1)
	context.sizer:AddGrowableCol(0)
	context.sizer:AddGrowableCol(1)
	context.sizer:AddGrowableCol(3)
	
	context.mainpanel:Connect(ID.Button1, wx.wxEVT_COMMAND_BUTTON_CLICKED, function (event) wx.wxMessageBox("Test1 clicked", "Title", wx.wxOK + wx.wxICON_INFORMATION) end)
	context.mainpanel:Connect(ID.Button2, wx.wxEVT_COMMAND_BUTTON_CLICKED, function (event) wx.wxMessageBox("Test2 clicked", "Title", wx.wxOK + wx.wxICON_ERROR) end)
	context.mainpanel:Connect(ID.Button3, wx.wxEVT_COMMAND_BUTTON_CLICKED, function (event) wx.wxMessageBox("Test3 clicked", "Title", wx.wxOK) end)
	context.mainpanel:Connect(ID.Button4, wx.wxEVT_COMMAND_BUTTON_CLICKED,
		create_closure(function (data, event)
			data.i = data.i + 1
			context.buttoncounter:SetLabel("Button clicks: "..tostring(data.i))
			context.sizer:Layout()
		end, {i = 0}))
	context.mainpanel:Connect(ID.Timer1, wx.wxEVT_TIMER,
		create_closure(function (data, event)
			data.i = data.i + 1
			context.timercounter:SetLabel("Timer events: "..tostring(data.i))
			context.sizer:Layout()
		end, {i = 0}))
	context.mainpanel:Connect(ID.Button5, wx.wxEVT_COMMAND_BUTTON_CLICKED, function (event) wx.wxMessageBox("Multispan clicked", "Title", wx.wxOK + wx.wxICON_INFORMATION) end)
	
	initialize_threads(context)
	
	context.timer:Start(1000)
	context.mainpanel:SetSizer(context.sizer)
	context.frame:Show(true)
end

create_window()

wx.wxGetApp():MainLoop()