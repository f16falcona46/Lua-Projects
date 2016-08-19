require("wx")

function create_closure(f, data)
	return function(...)
		return f(data, ...)
	end
end

function initialize_threads(context)
	context.threadpool = {}
	context.currentthread = 1
	
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

function create_task(context, functions, done_callback)
	local num_threads = #context.threadpool
	local num_new_threads = #functions
	local tasks = {}
	for i=1,num_new_threads do
		local c = coroutine.create(functions[i])
		table.insert(context.threadpool, c)
		table.insert(tasks, c)
	end
	if done_callback ~= nil then
		table.insert(context.threadpool, coroutine.create(function ()
				local i = 1
				while i <= #tasks do
					if (coroutine.status(tasks[i]) ~= "dead") then
						coroutine.yield()
					else
						i = i + 1
					end
				end
				done_callback()
			end))
	end
end

function create_window()
	local context = {}
	ID = {
		Button1 = 1,
		Button2 = 2,
		Button3 = 3,
		Button4 = 4,
		Button5 = 5,
		Timer1 = 6,
		Panel1 = 7
	}
	context.frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Test", wx.wxDefaultPosition, wx.wxSize(600, 480), wx.wxDEFAULT_FRAME_STYLE)
	context.frame:SetMinSize(wx.wxSize(500, 300))
	context.mainpanel = wx.wxPanel(context.frame, wx.wxID_ANY)
	
	initialize_threads(context)
	
	local funcs = {}
	for i=1,10 do
		funcs[i] = function ()
				for j=1,3*i*i do
					for k=1,1000000 do end
					coroutine.yield()
				end
				context.progressbar:SetValue(context.progressbar:GetValue() + 1)
			end
	end
	funcs[11] = function ()
			local width = 500
			local height = 500
			local scale = 40
			local bitmap = wx.wxBitmap(width, height)
			local dc = wx.wxMemoryDC()
			dc:SelectObject(bitmap)
			dc:SetBackground(wx.wxBLACK_BRUSH)
			dc:Clear()
			dc:SetPen(wx.wxGREEN_PEN)
			for i=0,width,40 do
				dc:DrawLine(0, i, width, i)
				dc:DrawLine(i, 0, i, height)
			end
			dc:SetPen(wx.wxWHITE_PEN)
			for i=0,width - 5,5 do
				dc:DrawLine(i, -scale * math.sin(i / scale) + height / 2, i + 5, -scale * math.sin((i + 5) / scale) + height / 2)
			end
			dc:SelectObject(wx.wxNullBitmap)
			dc:delete()
			wx.wxImage.AddHandler(wx.wxPNGHandler())
			--local image = bitmap:ConvertToImage()
			bitmap:SaveFile("garbage.png", wx.wxBITMAP_TYPE_PNG, wx.NULL)
			bitmap:delete()
			context.progressbar:SetValue(context.progressbar:GetValue() + 1)
		end
	
	create_task(context, funcs, function ()
			context.threadindicator:SetLabel("Threads stopped")
			wx.wxMessageBox("Done!", "title", wx.wxOK + wx.wxICON_INFORMATION)
		end)
	
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
	context.drawpanel = wx.wxPanel(context.mainpanel, ID.Panel1, wx.wxDefaultPosition, wx.wxSize(100, 100))
	context.sizer:Add(context.drawpanel, wx.wxGBPosition(0, 4), wx.wxGBSpan(), wx.wxALL + wx.wxEXPAND, 5)
	context.threadindicator = wx.wxStaticText(context.mainpanel, -1, "Threads running")
	context.sizer:Add(context.threadindicator, wx.wxGBPosition(2, 0), wx.wxGBSpan(1, 3), wx.wxALL + wx.wxEXPAND, 5)
	context.progressbar = wx.wxGauge(context.mainpanel, wx.wxID_ANY, #funcs)
	context.sizer:Add(context.progressbar, wx.wxGBPosition(3, 0), wx.wxGBSpan(1, 5), wx.wxALL + wx.wxEXPAND, 5)
	
	
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
	context.drawpanel:Connect(ID.Panel1, wx.wxEVT_PAINT,
		create_closure(function (data, event)
			local dc = wx.wxPaintDC(data.drawpanel)
			dc:DrawLine(0, 0, 100, 100)
			dc:delete()
		end, { drawpanel = context.drawpanel }))
	
	context.timer:Start(1000)
	context.mainpanel:SetSizer(context.sizer)
	context.frame:Show(true)
end

create_window()

wx.wxGetApp():MainLoop()