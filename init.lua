local TEXTURES = 43
local MOD_NAME = core.get_current_modname()

local palette = {}

minetest.register_on_leaveplayer(function(player)
	palette[player:get_player_name()] = nil
end)

function get_shape_name(num)
    return num < 10 and "0"..num or num
end

local formspec_cols = 8
local formspec_rows = math.ceil(TEXTURES/formspec_cols)
local formspec = "size[".. formspec_cols ..",".. formspec_rows .."]"

for i=0,TEXTURES-1,1 do
    local name = get_shape_name(i)
    local row = math.floor(i / formspec_cols)
    local col = i - math.floor(i/formspec_cols)*formspec_cols
    formspec = formspec .. "image_button_exit[".. col ..",".. row ..";1,1;".. name ..".png;".. name ..";]"
end

function show_palette(painter)
    minetest.show_formspec(painter:get_player_name(), MOD_NAME ..":palette", formspec)
end

minetest.register_on_player_receive_fields(function(painter, formname, fields)
	if formname ~= MOD_NAME ..":palette" then return end
    
    for k,v in pairs(fields) do
        local num = tonumber(k)
        if num ~= nil then
            palette[painter:get_player_name()] = get_shape_name(num)
            return
        end
    end
end)

for i=0,TEXTURES-1,1 do
    local shape_name = get_shape_name(i)
    minetest.register_node(MOD_NAME..":".. shape_name, {
        description = "Shape ".. shape_name,
        inventory_image = shape_name .. ".png",
        drawtype = "nodebox",
		tiles = {
            shape_name .. ".png",
        },
		paramtype = "light",
		paramtype2 = "wallmounted",
		is_ground_content = false,
        groups = {cracky=1, attached_node=1, not_in_creative_inventory=1},
        buildable_to = true,
        walkable = false,
        node_box = {
			type = "wallmounted",
			wall_top    = {-0.5, 0.49, -0.5, 0.5, 0.5, 0.5},
			wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.49, 0.5},
			wall_side   = {-0.5, -0.5, -0.5, -0.49, 0.5, 0.5},
        },
        pointable = false,
        legacy_wallmounted = true,
        drop = {},
    })
end

minetest.register_tool(MOD_NAME..":brush", {
    description = "Brush",
    inventory_image = "brush.png",
    wield_image = "brush.png^[transformR270",
	
    on_place = function(itemstack, placer, pointed_thing)
        show_palette(placer)
    end,
	
    on_secondary_use = function(itemstack, user, pointed_thing)
        show_palette(user)
    end,
	
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        
        if pointed_thing.type == "nothing" or not palette[player_name] then
            show_palette(user)
            return nil
        end
        
        if pointed_thing.type ~= "node" then
            return nil
        end
        
        if minetest.is_protected(pointed_thing.above, player_name)
        or minetest.is_protected(pointed_thing.under, player_name)
        then
            return nil
        end
        
        local node_under = minetest.get_node(pointed_thing.under)
        local node_under_def = core.registered_items[node_under.name]
        if node_under_def and node_under_def.buildable_to then
            return nil
        end
        
        local node_above = minetest.get_node(pointed_thing.above)
        local node_above_def = core.registered_items[node_above.name]
        if node_above_def and not node_above_def.buildable_to then
            return nil
        end
        
        local shape = MOD_NAME ..":".. palette[player_name]
        local dir = vector.direction(pointed_thing.above, pointed_thing.under)
        local wallmounted = minetest.dir_to_wallmounted(dir)
        minetest.swap_node(pointed_thing.above, {name = shape, param2=wallmounted})
        
        return nil
    end
})

minetest.register_craft({
	output = MOD_NAME ..":brush",
	recipe = {
		{'default:stick'},
		{'default:steel_ingot'},
		{'dye:white'},
	}
})
