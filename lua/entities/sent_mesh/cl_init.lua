include( "shared.lua" )

MeshManager = MeshManager or {}

CreateClientConVar("MeshManipulator_URL", "https://www.dl.dropboxusercontent.com/s/qrmi3oq9t6g0qo8/plane.obj?dl=0", true, false)
CreateClientConVar("MrMesh_offset", "25", true, false)
CreateClientConVar("MrMesh_paint_r", "0", true, false)
CreateClientConVar("MrMesh_paint_g", "255", true, false)
CreateClientConVar("MrMesh_paint_b", "0", true, false)
CreateClientConVar("MrMesh_paint_a", "255", true, false)
CreateClientConVar("MrMesh_select_radius", "15", true, false)
CreateClientConVar("MrMesh_select_snap", "0", true, false)

MeshManager.Enabled = false
MeshManager.OffsetX = 100
MeshManager.OffsetY = 30
MeshManager.Width = 300
MeshManager.Height = 600
MeshManager.Panels = {}
MeshManager.SelectRadius = GetConVar("MrMesh_select_radius"):GetInt()
MeshManager.Material = Material( "editor/wireframe" )

local MESH_MANIPULATOR_CONTEXT = false
local MESH_MANIPULATOR_MOUSE = false
local MESH_MANIPULATOR_HOVERED = false
local MESH_MANIPULATOR_FRAME = nil


function MeshManager.TransformSelected( offset, smooth )
  for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
    local selected = mesh_ent:GetSelectedIndices()

    if ( #selected >= 1 ) then
      mesh_ent:SendTransform( offset )
    end
  end
end

function MeshManager.PaintSelected( color )
  for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
    local selected = mesh_ent:GetSelectedIndices()

    if ( #selected >= 1 ) then
      mesh_ent:SendPaint( color )
    end
  end
end



hook.Add( "Think", "MeshManip-ThinkAll", function()
  MESH_MANIPULATOR_MOUSE = input.IsMouseDown( MOUSE_FIRST ) --Instead of calling per-entity
  MESH_MANIPULATOR_HOVERED = vgui.GetHoveredPanel()

  if ( MESH_MANIPULATOR_MOUSE and not table.HasValue( MeshManager.Panels, MESH_MANIPULATOR_HOVERED ) ) then

    MeshManager.SelectRadius = GetConVar("MrMesh_select_radius"):GetInt()
    MESH_MANIPULATOR_SNAP = GetConVar("MrMesh_select_snap"):GetBool()


    local mX, mY = gui.MousePos()
    local result = false

    for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
      for i = 1, #mesh_ent.Mesh.Nodes do

          local dist = Vector( mesh_ent.Mesh.Nodes[i].screenpos.x, mesh_ent.Mesh.Nodes[i].screenpos.y, 0 ):Distance( Vector( mX, mY, 0 ) )

          if ( dist <= 5 ) then
            mesh_ent.Mesh.Primary = mesh_ent.Mesh.Nodes[i]
          end

          if ( mesh_ent.Mesh.Primary ) then
            mesh_ent.Mesh.Nodes[i].sel = false

            local primary_dist = mesh_ent.Mesh.Primary.pos:Distance( mesh_ent.Mesh.Nodes[i].pos )

            if (primary_dist <= MeshManager.SelectRadius) then
              mesh_ent.Mesh.Nodes[i].sel = primary_dist/MeshManager.SelectRadius
            end
          end

      end
    end
  end
end )

--CONTEXT MENU

function MeshManager.ToggleContext()
  if not ( MeshManager.Enabled ) then
    if ( IsValid( MESH_MANIPULATOR_FRAME ) ) then
      MESH_MANIPULATOR_FRAME:Remove()
    end
  else
    if not ( IsValid( MESH_MANIPULATOR_FRAME ) ) then
      MESH_MANIPULATOR_FRAME = vgui.Create( "DFrame" )
      MESH_MANIPULATOR_FRAME:SetTitle( "" )
      MESH_MANIPULATOR_FRAME:SetSize( ScrW() - MeshManager.OffsetX, ScrH() - MeshManager.OffsetY )
      MESH_MANIPULATOR_FRAME:SetPos( MeshManager.OffsetX, MeshManager.OffsetY )
      MESH_MANIPULATOR_FRAME:MakePopup()
      MESH_MANIPULATOR_FRAME:SetDeleteOnClose( false )
      MESH_MANIPULATOR_FRAME.Paint = function( self )
        local w, h = self:GetWide(), self:GetTall()

        surface.SetDrawColor( 255, 255, 255, 0 )
        surface.DrawRect( 0, 0, w, h)

        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawOutlinedRect( 0, 0, w, h)

      end
    else
      MESH_MANIPULATOR_FRAME:MakePopup()
    end

    local color_mixer = vgui.Create( "DColorMixer", MESH_MANIPULATOR_FRAME )
    color_mixer:SetPos( 10, 25)
    color_mixer:SetSize( 190, 240 )
    color_mixer:SetConVarR( "MrMesh_paint_r" )
    color_mixer:SetConVarG( "MrMesh_paint_g" )
    color_mixer:SetConVarB( "MrMesh_paint_b" )
    color_mixer:SetConVarA( "MrMesh_paint_a" )

    local slider_radius = vgui.Create( "DNumSlider", MESH_MANIPULATOR_FRAME )
    slider_radius:SetPos( 10, 260)
    slider_radius:SetSize( 190, 35 )
    slider_radius:SetText( "Select Radius" )
    slider_radius:SetMin( 5 )
    slider_radius:SetMax( 5000 )
    slider_radius:SetDecimals( 0 )
    slider_radius:SetConVar( "MrMesh_select_radius" )

    local slider_offset = vgui.Create( "DNumSlider", MESH_MANIPULATOR_FRAME )
    slider_offset:SetPos( 10, 285)
    slider_offset:SetSize( 190, 35 )
    slider_offset:SetText( "Offset" )
    slider_offset:SetMin( 0 )
    slider_offset:SetMax( 500 )
    slider_offset:SetDecimals( 0 )
    slider_offset:SetConVar( "MrMesh_offset" )

    local btn_transformup = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_transformup:SetFont( "DermaLarge" )
    btn_transformup:SetSize( 190, 25 )
    btn_transformup:SetPos( 10, 320 )
    btn_transformup:SetText( "Transform Up" )
    btn_transformup.DoClick = function( self )
      --MeshSendTransform( Vector( 0, 0, slider_offset:GetValue() ) )
      MeshManager.TransformSelected( Vector( 0, 0, slider_offset:GetValue() ) )
    end

    local btn_transformdown = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_transformdown:SetFont( "DermaLarge" )
    btn_transformdown:SetSize( 190, 25 )
    btn_transformdown:SetPos( 10, 350 )
    btn_transformdown:SetText( "Transform Down" )
    btn_transformdown.DoClick = function( self )
      --MeshSendTransform( Vector( 0, 0, -slider_offset:GetValue() ) )
      MeshManager.TransformSelected( Vector( 0, 0, -slider_offset:GetValue() ) )
    end

    local btn_clearselect = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_clearselect:SetFont( "DermaLarge" )
    btn_clearselect:SetSize( 190, 25 )
    btn_clearselect:SetPos( 10, 380 )
    btn_clearselect:SetText( "Clear Selection" )
    btn_clearselect.DoClick = function( self )
      for _, v in pairs( MESH_MANIPULATOR ) do
        v.Mesh.Primary = false
        for _, v in pairs( v.Mesh.PAC ) do
          v.sel = false
        end
      end
    end

    local btn_resetmesh = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_resetmesh:SetFont( "DermaLarge" )
    btn_resetmesh:SetSize( 190, 25 )
    btn_resetmesh:SetPos( 10, 410 )
    btn_resetmesh:SetText( "Reset" )
    btn_resetmesh.DoClick = function( self )
      --http.Fetch( "https://www.dl.dropboxusercontent.com/s/umuhv8586ldzlb0/map.obj?dl=0", OnSuccess, OnFailure )

      for _, mesh_ent in pairs( MESH_MANIPULATOR ) do
        if ( mesh_ent:GetOwner() == LocalPlayer() ) then
          MeshManipulatorURLCallback( mesh_ent, mesh_ent.Mesh.URL )
        end
      end
    end

    local btn_setcolor = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_setcolor:SetFont( "DermaLarge" )
    btn_setcolor:SetSize( 190, 25 )
    btn_setcolor:SetPos( 10, 440 )
    btn_setcolor:SetText( "Apply Color" )
    btn_setcolor.DoClick = function( self )
      --MeshSendPaint( Color( GetConVar("MrMesh_paint_r"):GetInt(), GetConVar("MrMesh_paint_g"):GetInt(), GetConVar("MrMesh_paint_b"):GetInt(), GetConVar("MrMesh_paint_a"):GetInt() ) )
      MeshManager.PaintSelected( Color( GetConVar("MrMesh_paint_r"):GetInt(), GetConVar("MrMesh_paint_g"):GetInt(), GetConVar("MrMesh_paint_b"):GetInt(), GetConVar("MrMesh_paint_a"):GetInt() ) )
    end

    local btn_sync = vgui.Create( "DButton", MESH_MANIPULATOR_FRAME )
    btn_sync:SetFont( "DermaLarge" )
    btn_sync:SetSize( 190, 25 )
    btn_sync:SetPos( 10, 470 )
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

      MeshManager.Panels = {}
      table.insert(MeshManager.Panels, color_mixer)
      table.insert(MeshManager.Panels, slider_radius)
      table.insert(MeshManager.Panels, slider_offset)
      table.insert(MeshManager.Panels, btn_transformup)
      table.insert(MeshManager.Panels, btn_transformdown)
      table.insert(MeshManager.Panels, btn_clearselect)
      table.insert(MeshManager.Panels, btn_resetmesh)
      table.insert(MeshManager.Panels, btn_setcolor)
  end

end

hook.Add( "OnContextMenuOpen", "MeshManip-ContextOpen", function()
  MESH_MANIPULATOR_CONTEXT = true
  MeshManager.ToggleContext()
end )

hook.Add( "OnContextMenuClose", "MeshManip-ContextClose", function()
  MESH_MANIPULATOR_CONTEXT = false

  if ( IsValid( MESH_MANIPULATOR_FRAME ) ) then
    MESH_MANIPULATOR_FRAME:Remove()
  end
end )

hook.Add( "HUDPaint", "MeshManip-DrawHUD", function()

  local num = 0

  for k, v in pairs( MESH_MANIPULATOR ) do
    num = num + 1
    draw.DrawText( string.format( "Mesh-> %u: %s, %s", v:EntIndex(), v:GetOwner(), v.Mesh.URL ), "DermaLarge", 10, 10*num, Color( 255, 0, 0 ) )
    v:DrawHUD() --Maybe ill fix this
  end

  for _, v in pairs(ents.FindByClass("prop_physics")) do
      local pos = v:LocalToWorld( v:OBBCenter() ):ToScreen()
      --local pos = v:GetPos():ToScreen()
      local ang = v:GetAngles()

      --draw.DrawText( string.format( "[%i, %i, %i]", ang.p, ang.y, ang.r ), "BudgetLabel", pos.x, pos.y, Color( 255, 255, 255, 180 ), 1 )
  end
end )




hook.Add( "PostDrawOpaqueRenderables", "MeshManip-Draw", function()



  for _, ent in pairs( MESH_MANIPULATOR ) do



    render.SetMaterial( MeshManager.Material )

    mesh.Begin( 2, #ent.Mesh.PAC / 3 )
      for i = 1, #ent.Mesh.PAC do

        mesh.Position( ent.Mesh.PAC[i].pos )
        --mesh.Normal( ent.Mesh.PAC[i].normal )
        if ( ent.Mesh.PAC[i].color ) then
          mesh.Color( ent.Mesh.PAC[i].color.r, ent.Mesh.PAC[i].color.g, ent.Mesh.PAC[i].color.b, ent.Mesh.PAC[i].color.a )
        end
        mesh.AdvanceVertex()
      end
    mesh.End()

    for i = 1, #ent.Mesh.Nodes do

      if ( ent.Mesh.Nodes[i].sel ) then
        local col = Color(255 * ent.Mesh.Nodes[i].sel, 255 * (1 - ent.Mesh.Nodes[i].sel), 0, 255)
        render.DrawSphere( ent.Mesh.Nodes[i].pos, 10, 8, 8, col )
      end

    end


    if ( ent.Mesh.Primary ) then
      render.DrawSphere( ent.Mesh.Primary.pos, MeshManager.SelectRadius, 42, 42  , Color(0, 255, 0, 1) )
    end

  end
end )

local function MeshManipulatorFailureCallback( ent, err )
  print( string.format( "MeshManipulator-> Error: %s", err ) )
end

--""
local function MeshManipulatorURLCallback( ent, text )
  net.Start( "mesh_create_recv" )
    net.WriteEntity( ent )
    net.WriteString( text )
  net.SendToServer()
end

function ENT:OnRemove()
  MESH_MANIPULATOR[ self:EntIndex() ] = nil
end

function ENT:Initialize()
  if ( CLIENT and self:GetOwner() == LocalPlayer() ) then
    Derma_StringRequest( "Enter a .obj URL",
    "Include http:// in your url, direct links only",
    "https://www.dl.dropboxusercontent.com/s/qrmi3oq9t6g0qo8/plane.obj?dl=0",
    function( text ) MeshManipulatorURLCallback( self, text ) end,
    function( text ) RunConsoleCommand( "MeshManip_panic", self:EntIndex() ) end )
  end
end


function ENT:Think()
  if not ( MeshManager.Enabled ) then return end

  if ( MESH_MANIPULATOR_CONTEXT and self.Mesh and self.Mesh.Nodes ) then
    for i = 1, #self.Mesh.Nodes do
      self.Mesh.Nodes[i].screenpos = self.Mesh.Nodes[i].pos:ToScreen()
    end
  end
end


function ENT:DrawHUD()
  if not ( MeshManager.Enabled ) then return end

  if ( MESH_MANIPULATOR_CONTEXT and self.Mesh ) then
    for i = 1, #self.Mesh.Nodes do
      if ( self.Mesh.Nodes[i].screenpos ) then
          surface.SetDrawColor( 0, 0, 0, 255 )
          surface.DrawRect( self.Mesh.Nodes[i].screenpos.x-2, self.Mesh.Nodes[i].screenpos.y-2, 6, 6 )

          if ( self.Mesh.Nodes[i].sel ) then
            surface.SetDrawColor( 0, 255, 0, 255 )
            --draw.DrawText( string.format( "%f", self.Mesh.Nodes[i].sel + 1 ), "DermaDefault", self.Mesh.Nodes[i].screenpos.x, self.Mesh.Nodes[i].screenpos.y+6, Color( 0, 0, 0 ) )
          else
            surface.SetDrawColor( 255, 0, 0, 255 )
          end

          surface.DrawRect( self.Mesh.Nodes[i].screenpos.x-1, self.Mesh.Nodes[i].screenpos.y-1, 4, 4 )

          draw.DrawText( string.format( "Mesh: %i", self:EntIndex() ), "DermaDefault", self.Mesh.PAC[i].screenpos.x, self.Mesh.PAC[i].screenpos.y+6, Color( 0, 0, 0 ) )


          --draw.DrawText( string.format( "%u", self.Mesh.Nodes[i].pos_index ), "BudgetLabel", self.Mesh.Nodes[i].screenpos.x, self.Mesh.Nodes[i].screenpos.y, Color( 255, 255, 255 ) )
          --draw.DrawText( string.format( "(%i, %i, %i)", self.Mesh.Nodes[i].pos.x, self.Mesh.Nodes[i].pos.y, self.Mesh.Nodes[i].pos.z ), "BudgetLabel", self.Mesh.Nodes[i].screenpos.x, self.Mesh.Nodes[i].screenpos.y+16, Color( 255, 255, 255 ) )

      end
    end
  end
end


function ENT:IndexToPosition( index )
  local pos = false

  index = tonumber(index)

  for _, node in pairs( self.Mesh.Nodes ) do
    if ( node.pos_index == index ) then
      pos = node.pos
    end
  end

  return pos
end


function ENT:GetSelectedIndices()
  local indices = {}

  for k, vertex in pairs( self.Mesh.Nodes ) do
    if ( vertex.sel ) then
      table.insert(indices, vertex.pos_index)
    end
  end

  return indices
end


function ENT:Synchronize()
  local indices = {}

  for k, v in pairs( self.Mesh.PAC ) do
    if not ( indices[ v.pos_index ] ) then
      indices[ v.pos_index ] = v.pos
    end
  end

  --PrintTable( indices )

  net.Start( "mesh_sync_recv" )
    net.WriteEntity( self )
    net.WriteTable( indices )
  net.SendToServer()
end

function ENT:SendTransform( offset )
  local indices = self:GetSelectedIndices()

  net.Start( "mesh_transform_recv" )
    net.WriteEntity( self )
    net.WriteVector( offset )
    net.WriteTable( indices )
  net.SendToServer()

end

function ENT:SendPaint( color )
  local indices = self:GetSelectedIndices()

    net.Start( "mesh_paint_recv" )
      net.WriteEntity( self )
      net.WriteColor( color )
      net.WriteTable( indices )
    net.SendToServer()
end


net.Receive( "mesh_create_update", function( len )
  local mesh_ent = net.ReadEntity()
  local url = net.ReadString()


  if ( MESH_MANIPULATOR[ mesh_ent:EntIndex() ] ) then MESH_MANIPULATOR[ mesh_ent:EntIndex() ] = nil end

  mesh_ent.Mesh = {}
  mesh_ent.Mesh.URL = url


--  local backup = file.Read( "plane2.txt", "DATA" )
--  MeshManipulatorSuccessCallback( mesh_ent, backup ) --Internet outage, must improvise
--  return

  http.Fetch( url, function( body )
    MeshManipulatorSuccessCallback( mesh_ent, body )
  end, function( err )
    MeshManipulatorFailureCallback( mesh_ent, err )
  end )
end )

print( "CL: MESH" )
