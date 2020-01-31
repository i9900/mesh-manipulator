AddCSLuaFile()

MESH_MANIPULATOR = MESH_MANIPULATOR or {}

ENT.Base = "base_entity"
ENT.Type = "point"

ENT.Printname = "Mesh Manipulator"
ENT.Author = "h0lz"
ENT.Information = "A portable multi-user mesh manipulator"
ENT.Category = "h0lz"

ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.RenderGroup = RENDERGROUP_OPAQUE


function MeshManipulatorSuccessCallback( ent, body )
  ent.Mesh = {} --Is now created before success
  ent.Mesh.Material = Material( "hunter/myplastic" )
  ent.Mesh.Position = ent:GetPos()
  ent.Mesh.PAC = false

  if ( SERVER ) then return end  --TO DO: Incude PAC.urlobj library on server for better networking

  ent.Mesh.PAC = pac.urlobj.ParseObj( body, true )
  ent.Mesh.Nodes = {} --The key to optimizing this, ~3x the speed!, ALSO USED FOR FACE CONVEX!


  for k, v in pairs( ent.Mesh.PAC ) do
      v.color = Color( 255, 255, 255 )
      v.pos = v.pos + ent.Mesh.Position

      if ( SERVER ) then return end

      local screenpos = v.pos:ToScreen()
      screenpos.x = math.floor( screenpos.x )
      screenpos.y = math.floor( screenpos.y )
      v.screenpos = screenpos

      if not ent.Mesh.Nodes[ v.pos_index ] then
        ent.Mesh.Nodes[ v.pos_index ] = v
      end
  end

  local multi_convex = {}

  local splitStr = string.Explode( "\n", body ) --Need to
  for i = 1, #splitStr do
    if string.Left( splitStr[i], 1 ) ~= "f" then
      splitStr[i] = nil
    else
      splitStr[i] = string.Replace( splitStr[i], "//1", "" )
      splitStr[i] = string.Replace( splitStr[i], "f ", "" )
      local face_points = string.Explode( " ", splitStr[i] )
      local convex = {  [ tonumber( face_points[ 1 ] ) ] = ent.Mesh.Nodes[ tonumber( face_points[ 1 ] ) ].pos,
                        [ tonumber( face_points[ 2 ] ) ] = ent.Mesh.Nodes[ tonumber( face_points[ 2 ] ) ].pos,
                        [ tonumber( face_points[ 3 ] ) ] = ent.Mesh.Nodes[ tonumber( face_points[ 3 ] ) ].pos,
                        [ tonumber( face_points[ 4 ] ) ] = ent.Mesh.Nodes[ tonumber( face_points[ 4 ] ) ].pos }
      multi_convex[ face_points[1] ] = convex
    end
  end

  --PrintTable( multi_convex )

  net.Start( "mesh_collisions_recv" )
    net.WriteEntity( ent )
    net.WriteTable( multi_convex )
  net.SendToServer()


  MESH_MANIPULATOR[ ent:EntIndex() ] = ent
end


--################################### MESHMAN

net.Receive( "mesh_sync_update", function( len )
  local mesh_ent = net.ReadEntity()
  local indices = net.ReadTable()

  print( string.format( "MeshManipulator -> Received Sync: Index=%u, %u indices, %u bits", mesh_ent:EntIndex(), #indices, len ) )

  for _, v in pairs( mesh_ent.Mesh.PAC ) do
    if ( indices[ v.pos_index ] ) then
      v.pos = indices[ v.pos_index ]
    end
  end

end )

net.Receive( "mesh_transform_update", function( len )
    local mesh_ent = net.ReadEntity()
    local offset = net.ReadVector()
    local indices = net.ReadTable()

    print( string.format( "MeshManipulator -> Received Transform: Index=%u, %u indices, %u bits", mesh_ent:EntIndex(), #indices, len) )

    for _, v in pairs( mesh_ent.Mesh.PAC ) do
      if ( table.HasValue( indices, v.pos_index ) ) then
        v.pos = v.pos + offset
      end
    end
end )

net.Receive( "mesh_paint_update", function( len )
    local mesh_ent = net.ReadEntity()
    local color = net.ReadColor()
    local indices = net.ReadTable()

    print( string.format( "MeshManipulator -> Received Paint: Index=%u, %u indices, %u bits", mesh_ent:EntIndex(), #indices, len ) )

    for _, v in pairs( mesh_ent.Mesh.PAC ) do
      if ( table.HasValue( indices, v.pos_index ) ) then
        v.color = color
      end
    end
end )


concommand.Add( "MeshManip_debug", function(pl, cmd, args, argstr)
  for k, v in pairs( MESH_MANIPULATOR ) do
    PrintTable( v.Mesh.Nodes  )
  end
end )

concommand.Add( "MeshManip_collision", function(pl, cmd, args, argstr)
  local mesh_ent = Entity(tonumber(args[1]))

  net.Start( "mesh_collisions_recv" )
    net.WriteEntity( mesh_ent )

  net.SendToServer()
end )

concommand.Add( "MeshManip_debug_selected", function(pl, cmd, args, argstr)
  for k, mesh_ent in pairs( MESH_MANIPULATOR ) do
    local selected = mesh_ent:GetSelectedIndices()[1]
    print(selected)
  end
end )
