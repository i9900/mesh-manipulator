include("shared.lua")

for _, v in pairs( player.GetAll() ) do
  v:SendLua( [[RunConsoleCommand("say", 1/FrameTime()) ]] )
end

print("SV: MESH")


include("pac3/libraries/caching/cache.lua")
include("pac3/libraries/urlobj/urlobj.lua")

util.AddNetworkString("mesh_create_recv")
util.AddNetworkString("mesh_create_update")
util.AddNetworkString("mesh_transform_recv")
util.AddNetworkString("mesh_transform_update")
util.AddNetworkString("mesh_paint_recv")
util.AddNetworkString("mesh_paint_update")

util.AddNetworkString("mesh_sync_recv")   --Sync mesh verts
util.AddNetworkString("mesh_sync_update")

util.AddNetworkString("mesh_collisions_recv")

local function GetMeanPosition( vec_tbl )
  local tbl_pos = {}
  for k, v in pairs(vec_tbl) do
    if type(v) == "Vector" then
--      v.x = math.floor(v.x)
--      v.y = math.floor(v.y)
--      v.z = math.floor(v.z)
      table.insert(tbl_pos, v)
    end
  end

  return ( tbl_pos[1] + tbl_pos[2] + tbl_pos[3] + tbl_pos[4] ) / 4
end

local function GetMeanAngle( vec_tbl )
  local tbl_pos = {}

  for k, v in pairs(vec_tbl) do
    if type(v) == "Vector" then
      table.insert(tbl_pos, v)
    end
  end


  table.sort( tbl_pos, function(a, b) return a.z > b.z end )


  local ang_a = (tbl_pos[1]-tbl_pos[2]):Angle()
  local ang_b = (tbl_pos[3]-tbl_pos[4]):Angle()

  local ang_e = Angle(0,0,0) --dang

  --ang_c.p = math.Clamp(ang_c.p, 0, 180)
  --ang_c.y = math.Clamp(ang_c.y, 0, 180)
  --ang_c.r = math.Clamp(ang_c.r, 0, 180)

  return ang_e
end

net.Receive( "mesh_collisions_recv", function( len, ply)
  local mesh_ent = net.ReadEntity()
  local convex = net.ReadTable()

  if ( IsValid(mesh_ent) and mesh_ent:GetClass() == "sent_mesh" ) then

    if not (mesh_ent.Convex) then

      mesh_ent.Convex = convex

      for node_ind, node_tbl in pairs( mesh_ent.Convex ) do
        local mean_pos = GetMeanPosition( node_tbl )

        local prop = ents.Create( "prop_physics" )
        prop:SetModel( "models/hunter/plates/plate1x1.mdl" )
        --prop:SetParent( mesh_ent )
        prop:SetPos( mean_pos )
        prop:Spawn()
        local phys = prop:GetPhysicsObject()
        phys:EnableMotion( false )
        prop:SetMaterial( "gm_construct/grass1" )
        prop:SetColor( Color( 145, 255, 145, 0 ) )
        prop:SetRenderMode( RENDERMODE_TRANSALPHA )
        prop:SetMoveType( MOVETYPE_VPHYSICS )
        prop:SetSolid( SOLID_VPHYSICS )
        prop:EnableCustomCollisions(true)

        mesh_ent.Convex[ node_ind ].prop = {
          pos = mean_pos,
          ent = prop,
        }
      end


    else

  --[[      for node_ind, node_tbl in pairs( mesh_ent.Convex ) do
          local mean_pos = GetMeanPosition( node_tbl )
          node_tbl.prop.ent:SetPos( mean_pos )
        end]]

    end
  end
end )


concommand.Add( "MeshManip_panic", function(pl, cmd, args, argstr)

  for _, v in pairs(MESH_MANIPULATOR) do
    if (v:GetOwner() == pl) and (Entity(args[1]) == v) then v:Remove() end
  end

end )


net.Receive( "mesh_sync_recv", function( len, ply )

  local mesh_ent = net.ReadEntity()
  local mesh_ind_pos = net.ReadTable()

  if ( IsValid( mesh_ent ) and mesh_ent:GetClass() == "sent_mesh" ) then

    if ( mesh_ent.Convex ) then

      for node_ind, node_tbl in pairs( mesh_ent.Convex ) do
        for k, v in pairs( node_tbl ) do
          if mesh_ind_pos[k] and mesh_ind_pos[k] ~= v  then
            node_tbl[k] = mesh_ind_pos[k]
          end
        end

        local mean_pos = GetMeanPosition( node_tbl )
        node_tbl.prop.pos = mean_pos
        node_tbl.prop.ent:SetPos( mean_pos )


        local tbl_pos = {}
        for k, v in pairs(node_tbl) do
          if type(v) == "Vector" then
            local LeVector = node_tbl.prop.ent:WorldToLocal( v )
            LeVector.x = math.floor( LeVector.x )
            LeVector.y = math.floor( LeVector.y )
            LeVector.z = math.floor( LeVector.z )
            table.insert( tbl_pos, LeVector )
          end
        end

        node_tbl.prop.ent:PhysicsInitConvex({
          tbl_pos[1]+Vector(0, 0, 1),
          tbl_pos[1]+Vector(0, 0, 1),
          tbl_pos[2],
          tbl_pos[2],
          tbl_pos[3],
          tbl_pos[3],
          tbl_pos[4],
          tbl_pos[4],
        })

        local phys = node_tbl.prop.ent:GetPhysicsObject()
        phys:EnableMotion( false )

        node_tbl.prop.ent:SetSolid( SOLID_VPHYSICS )
        node_tbl.prop.ent:SetMoveType( MOVETYPE_VPHYSICS )
        node_tbl.prop.ent:EnableCustomCollisions(true)

      end
    end

    net.Start( "mesh_sync_update" )
      net.WriteEntity( mesh_ent )
      net.WriteTable( mesh_ind_pos )
    net.Broadcast()

    print( string.format( "MeshManipulator -> Received Sync: %u indices, from %s, (%u)", #mesh_ind_pos, ply:Nick(), mesh_ent:EntIndex() ) )
  else
    print( string.format( "MeshManipulator -> Received INVALID sync: %u indices, from %s", #mesh_ind_pos, ply:Nick() ) )
  end

end )

net.Receive( "mesh_create_recv", function( len, ply )
  local mesh_ent = net.ReadEntity()
  local url = net.ReadString()

  if ( IsValid( mesh_ent ) ) then

    --mesh_ent:SetPos(Vector(0,0,-12000))

    if ( url == "remove" ) then
      print( string.format( "MeshManipulator -> Received Create URL: %s, from %s, (%u)", url, ply:Nick(), mesh_ent:EntIndex() ) )
      mesh_ent:Remove()
      return
    end --User cancelled

    if ( url == "offline" ) then
      return --boop
    end


    url = string.Replace( url, "dropbox.com", "dl.dropboxusercontent.com" )

    MESH_MANIPULATOR[ mesh_ent:EntIndex() ] = mesh_ent

    net.Start( "mesh_create_update" )
      net.WriteEntity( mesh_ent )
      net.WriteString( url )
    net.Broadcast()


    print( string.format( "MeshManipulator -> Received Create URL: %s, from %s, (%u)", url, ply:Nick(), mesh_ent:EntIndex() ) )

  else
    print( string.format( "MeshManipulator -> Received INVALID Create URL: %s, from %s, (%u)", url, ply:Nick(), mesh_ent:EntIndex() ) )
  end
end )


net.Receive( "mesh_transform_recv", function( len, ply )
  local mesh_ent = net.ReadEntity()
  local offset = net.ReadVector()
  local verts = net.ReadTable()

  if ( IsValid( mesh_ent ) and mesh_ent:GetClass() == "sent_mesh" ) then
    net.Start( "mesh_transform_update" )
      net.WriteEntity( mesh_ent )
      net.WriteVector( offset )
      net.WriteTable( verts )
    net.Broadcast()

    print( string.format( "MeshManipulator -> Received Transform: Index=%u, %u indices, %u bits, from %s, (%u)", mesh_ent:EntIndex(), #verts, len, ply:Nick(), mesh_ent:EntIndex() ) )
  else
    print( string.format( "MeshManipulator -> Received INVALID transform: %u indices, from %s", #verts, ply:Nick() ) )
  end
end )

net.Receive( "mesh_paint_recv", function(len, ply)
  local mesh_ent = net.ReadEntity()
  local color = net.ReadColor()
  local verts = net.ReadTable()

  if ( IsValid( mesh_ent ) and mesh_ent:GetClass() == "sent_mesh" ) then
    net.Start( "mesh_paint_update" )
      net.WriteEntity( mesh_ent )
      net.WriteColor( color )
      net.WriteTable( verts )
    net.Broadcast()

    print( string.format( "MeshManipulator -> Received Paint: Index=%u, %u indices, %u bits, from %s", mesh_ent:EntIndex(), #verts, len, ply:Nick() ) )
  else
    print( string.format( "MeshManipulator -> Received INVALID paint: %u indices, from %s", #verts, ply:Nick() ) )
  end
end )
