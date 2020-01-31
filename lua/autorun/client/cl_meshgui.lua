list.Set(
	"DesktopWindows",
	"MeshManipulator",
	{
		title = "Mesh Editor",
		icon = "icon64/tool.png",
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()

      if (MeshManager) then
        MeshManager.Enabled = not MeshManager.Enabled
        MeshManager.ToggleContext()
      end
		end
	}
)
