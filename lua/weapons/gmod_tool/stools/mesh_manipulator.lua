TOOL.Category		= "!FubuDuckie"
TOOL.Name			= "Mesh Editor"
TOOL.Command		= nil
TOOL.ConfigName		= ""


function TOOL:LeftClick( tr )
	print("LeftClick")
end

function TOOL:RightClick( tr )
	print("RightClick")
end

function TOOL.BuildCPanel( CPanel )

	local draw_hud = vgui.Create( "DCheckBoxLabel", CPanel )
	draw_hud:SetPos( 10, 25 )
	draw_hud:SetText("Draw HUD")
	draw_hud:SetConVar("MrMesh_drawhud")
	draw_hud:SetValue( true )
	draw_hud:SizeToContents()	


	local color_mixer = vgui.Create( "DColorMixer", CPanel )
    color_mixer:SetPos( 10, 35)
    color_mixer:SetSize( 190, 240 )
    color_mixer:SetConVarR( "MrMesh_paint_r" )
    color_mixer:SetConVarG( "MrMesh_paint_g" )
    color_mixer:SetConVarB( "MrMesh_paint_b" )
    color_mixer:SetConVarA( "MrMesh_paint_a" )
    color_mixer:SizeToContents()

    local slider_radius = vgui.Create( "DNumSlider", CPanel )
    slider_radius:SetPos( 10, 270)
    slider_radius:SetSize( 190, 35 )
    slider_radius:SetText( "Select Radius" )
    slider_radius:SetMin( 5 )
    slider_radius:SetMax( 5000 )
    slider_radius:SetDecimals( 0 )
    slider_radius:SetConVar( "MrMesh_select_radius" )

    local slider_offset = vgui.Create( "DNumSlider", CPanel )
    slider_offset:SetPos( 10, 295)
    slider_offset:SetSize( 190, 35 )
    slider_offset:SetText( "Offset" )
    slider_offset:SetMin( 0 )
    slider_offset:SetMax( 500 )
    slider_offset:SetDecimals( 0 )
    slider_offset:SetConVar( "MrMesh_offset" )

    local btn_transformup = vgui.Create( "DButton", CPanel )
    btn_transformup:SetFont( "DermaLarge" )
    btn_transformup:SetSize( 190, 25 )
    btn_transformup:SetPos( 10, 330 )
    btn_transformup:SetText( "Transform Up" )
    btn_transformup.DoClick = function( self )
      --MeshSendTransform( Vector( 0, 0, slider_offset:GetValue() ) )
      MeshManager.TransformSelected( Vector( 0, 0, slider_offset:GetValue() ) )
    end

    local btn_transformdown = vgui.Create( "DButton", CPanel )
    btn_transformdown:SetFont( "DermaLarge" )
    btn_transformdown:SetSize( 190, 25 )
    btn_transformdown:SetPos( 10, 360 )
    btn_transformdown:SetText( "Transform Down" )
    btn_transformdown.DoClick = function( self )
      --MeshSendTransform( Vector( 0, 0, -slider_offset:GetValue() ) )
      MeshManager.TransformSelected( Vector( 0, 0, -slider_offset:GetValue() ) )
    end

     local btn_clearselect = vgui.Create( "DButton", CPanel )
    btn_clearselect:SetFont( "DermaLarge" )
    btn_clearselect:SetSize( 190, 25 )
    btn_clearselect:SetPos( 10, 390 )
    btn_clearselect:SetText( "Clear Selection" )
    btn_clearselect.DoClick = function( self )
      for _, v in pairs( MESH_MANIPULATOR ) do
        v.Mesh.Primary = false
        for _, v in pairs( v.Mesh.PAC ) do
          v.sel = false
        end
      end
    end

    local btn_resetmesh = vgui.Create( "DButton", CPanel )
    btn_resetmesh:SetFont( "DermaLarge" )
    btn_resetmesh:SetSize( 190, 25 )
    btn_resetmesh:SetPos( 10, 420 )
    btn_resetmesh:SetText( "Reset" )
    btn_resetmesh.DoClick = function( self )
      --http.Fetch( "https://www.dl.dropboxusercontent.com/s/umuhv8586ldzlb0/map.obj?dl=0", OnSuccess, OnFailure )

      for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
        if ( mesh_ent:GetOwner() == LocalPlayer() ) then
          MeshManipulatorURLCallback( mesh_ent, mesh_ent.Mesh.URL )
        end
      end
    end

    local btn_setcolor = vgui.Create( "DButton", CPanel )
    btn_setcolor:SetFont( "DermaLarge" )
    btn_setcolor:SetSize( 190, 25 )
    btn_setcolor:SetPos( 10, 450 )
    btn_setcolor:SetText( "Apply Color" )
    btn_setcolor.DoClick = function( self )
      --MeshSendPaint( Color( GetConVar("MrMesh_paint_r"):GetInt(), GetConVar("MrMesh_paint_g"):GetInt(), GetConVar("MrMesh_paint_b"):GetInt(), GetConVar("MrMesh_paint_a"):GetInt() ) )
      MeshManager.PaintSelected( Color( GetConVar("MrMesh_paint_r"):GetInt(), GetConVar("MrMesh_paint_g"):GetInt(), GetConVar("MrMesh_paint_b"):GetInt(), GetConVar("MrMesh_paint_a"):GetInt() ) )
    end

    local btn_sync = vgui.Create( "DButton", CPanel )
    btn_sync:SetFont( "DermaLarge" )
    btn_sync:SetSize( 190, 25 )
    btn_sync:SetPos( 10, 480 )
    btn_sync:SetText( "Sync Collisions" )
    btn_sync.DoClick = function( self )
      for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
        print(mesh_ent:GetOwner())
        if ( mesh_ent:GetOwner() == LocalPlayer() ) then
          print(mesh_ent)
          mesh_ent:Synchronize()
        end
      end
    end

end

function TOOL:Think()
	print("think")
end


