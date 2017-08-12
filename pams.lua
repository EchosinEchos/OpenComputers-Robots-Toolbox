local move = require('common.movement')
local utilitie = require('common.utilities')
local energy = require('common.energy')
local chest = require('common.chest')
local inventory = require('common.inventory')
local environement = require('common.environement')
local crafting = require('common.crafting')

local component = require('component')
local robot = require('robot')
local side = require('sides')

local PASTE_ID = 'KzP5EAya'
local SCRIPT_NAME = 'foody'
local FIELD_X_SIZE = 9
local FIELD_Y_SIZE = 9
local FIELD_DIRECTION = 'right'
local MAIN_LOOP_MINUTES_SLEEP = 2
local MAIN_LOOP_SECONDS_SLEEP = MAIN_LOOP_MINUTES_SLEEP * 60
local SALT_PRODUCTION_STACK_AMOUNT = 2
local WATER_PRODUCTION_STACK_AMOUNT = 2
local args = {... }

local CHEST_MAP = {}
local FIELD_MAP = {}
local need_list = {}

-- Will be harverst one time every FREQUENCY loop.
local FREQUENCY_CHEST_DROP = 5
local FREQUENCY_APPLE = 10

local last_field

function init()
    local tmp

    tmp = {}
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.up] = "harvestcraft:saltItem"
    tmp[#tmp][side.down] = "harvestcraft:freshwaterItem"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.up] = "harvestcraft:soybeanItem"
    tmp[#tmp][side.down] = "harvestcraft:lettuceItem"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.up] = "harvestcraft:silkentofuItem"
    tmp[#tmp][side.down] = "harvestcraft:soymilkItem"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.up] = "harvestcraft:firmtofuItem"
    tmp[#tmp][side.down] = "minecraft:wheat_seeds"
    CHEST_MAP[#CHEST_MAP + 1] = tmp

    tmp = {}
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.down] = "TConstruct:oreBerries"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.down] = "minecraft:wheat"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.down] = "minecraft:apple"
    tmp[#tmp + 1] = {}
    tmp[#tmp][side.down] = "harvestcraft:tomatoItem"
    CHEST_MAP[#CHEST_MAP + 1] = tmp

    FIELD_MAP[#FIELD_MAP + 1] = "harvestcraft:lettuceItem"
    FIELD_MAP[#FIELD_MAP + 1] = "harvestcraft:soybeanItem"
    FIELD_MAP[#FIELD_MAP + 1] = "harvestcraft:tomatoItem"
    FIELD_MAP[#FIELD_MAP + 1] = "minecraft:wheat"
    FIELD_MAP[#FIELD_MAP + 1] = "TConstruct:oreBerries"
    last_field = #FIELD_MAP
end

function update()
    os.execute('rm ' .. SCRIPT_NAME)
    utilitie.download_file(PASTE_ID, SCRIPT_NAME, true)
end

--[[
----    APPLES PRODUCTION
--]]

function harvest_apples()
    if not utilitie.is_elem_in_list(need_list, 'minecraft:apple') then
        return false
    end
    move.move(4, side.right)
    move.move(5, side.back)
    robot.useUp()
    move.move(2, side.back)
    move.move(4, side.right)
    robot.useUp()
    move.move(2, side.front)
    robot.useUp()
    move.move(1, side.front)
    robot.useUp()
    move.move(1, side.front)
    robot.useUp()
    move.move(1, side.left)
    move.move(1, side.back)
    robot.useUp()
    move.move(1, side.left)
    move.move(1, side.front)
    robot.useUp()
    move.move(1, side.left)
    move.move(1, side.back)
    robot.useUp()
    move.move(1, side.left)
    move.move(4, side.front)
    move.move(4, side.left)
    return true
end

--[[
----    SALT AND WATER PRODUCTION
--]]

function go_base_to_salt()
    move.move(4, side.front)
    move.move(2, side.right)
    move.move(1, side.down)
    move.move(1, side.right)
end

function go_salt_to_base()
    move.move(1, side.left)
    move.move(1, side.up)
    move.move(2, side.left)
    move.move(4, side.back)
end

function extract_water()
    chest.get_item_from_chest('minecraft:bucket', false, false, side.up)
    while environement.fill_bucket() do
        if inventory.is_full() then
            chest.drop_item_to_chest('minecraft:water_bucket', false, side.down)
        end
    end
    chest.drop_item_to_chest('minecraft:water_bucket', false, side.down)
end

function draw_water(amount)
    if not chest.get_item_from_chest('minecraft:bucket', nil, nil, side.up) then
        print('Bucket not found, can\'t craft water.')
        return false
    end
    if amount / 64 > robot.inventorySize() - 10 then
        amount = (robot.inventorySize() - 10) * 64
    end
    crafting.free_crafting_table()
    while amount > 0 do
        environement.fill_bucket(robot.front, true, true)
        component.crafting.craft()
        crafting.move_item_out_of_crafting_table('harvestcraft:freshwaterItem')
        amount = amount - 1
    end
    chest.drop_item_to_chest('minecraft:bucket', nil, nil, side.up)
    return true
end

function craft_salt()
    if not draw_water(SALT_PRODUCTION_STACK_AMOUNT * 64) or not chest.get_item_from_chest('harvestcraft:potItem', false, false, side.up) then
        return false
    end
    crafting.free_crafting_table()
    crafting.place_item_for_craft('harvestcraft:potItem', 1)
    while crafting.place_item_for_craft('harvestcraft:freshwaterItem', 2) do
        component.crafting.craft()
        crafting.move_item_out_of_crafting_table('harvestcraft:saltItem')
    end
    chest.drop_item_to_chest('harvestcraft:potItem', nil, nil, side.up)
    return true
end

function make_salt()
    if not utilitie.is_elem_in_list(need_list, 'harvestcraft:saltItem') then
        return false
    end
    go_base_to_salt()
    if not craft_salt() then
        go_salt_to_base()
        return false
    end
    go_salt_to_base()
    return true
end

function make_water()
    if not utilitie.is_elem_in_list(need_list, 'harvestcraft:freshwaterItem') then
        return false
    end
    go_base_to_salt()
    if not draw_water(WATER_PRODUCTION_STACK_AMOUNT * 64) then
        go_salt_to_base()
        return false
    end
    go_salt_to_base()
    return true
end

--[[
----    FIELDS HARVEST
--]]

function harvest_plant(plant)
    if plant and plant == "minecraft:wheat" then
        local data

        if environement.get_bloc_meta(side.down) == 7 then
            robot.swingDown()
        end
        if inventory.select_item('minecraft:wheat_seeds') then
            robot.placeDown()
        end
    else
        robot.useDown()
    end
end

function check_seeds(plant)
    if plant and plant == 'minecraft:wheat' then
        robot.turnLeft()
        chest.get_item_from_chest('minecraft:wheat_seeds')
        robot.turnRight()
    end
    return true
end

function place_seeds(plant)
    if plant and plant == 'minecraft:wheat' then
        robot.turnLeft()
        if not chest.drop_item_to_chest('minecraft:wheat_seeds') then
            inventory.repack_item('minecraft:wheat_seeds')
        end
        robot.turnRight()
    end
    return true
end

function harvest_field(maxx, maxy, direction, plant)
    local sav = {}
    local bool

    bool = false
    if direction and direction == "left" then
        bool = true
    end
    sav['bool'] = bool
    sav['x'] = maxx
    sav['y'] = maxy
    check_seeds(plant)
    harvest_plant(plant)
    while maxy > 0 do
        move.forward()
        maxx = maxx - 1
        harvest_plant(plant)
        if maxx <= 1 then
            maxy = maxy - 1
            maxx = sav['x']
            if maxy > 0 then
                move.turn_bool(bool)
                move.forward()
                harvest_plant(plant)
                move.turn_bool(bool)
                bool = not bool
            else
                if sav['bool'] == bool then
                    move.turn_bool(bool)
                    move.turn_bool(bool)
                    move.forward(sav['x'] - 1)
                    bool = not bool
                end
                move.turn_bool(not bool)
                move.forward(sav['y'] - 1)
                move.turn_bool(not bool)
            end
        end
    end
    place_seeds(plant)
end

function go_base_to_fields()
    move.move(1, side.up)
    move.move(6, side.front)
end

function go_fields_to_base()
    move.move(6, side.back)
    move.down()
end

function get_next_field()
    local tmp

    tmp = last_field + 1
    while tmp ~= last_field do
        if tmp > #FIELD_MAP then
            tmp = 1
        end
        if utilitie.is_elem_in_list(need_list, FIELD_MAP[tmp]) then
            last_field = tmp
            return tmp
        end
        tmp = tmp + 1
    end
    if utilitie.is_elem_in_list(need_list, FIELD_MAP[tmp]) then
        last_field = tmp
        return tmp
    end
    return false
end

function harvest_next_field()
    local next_field

    next_field = get_next_field()
    if not next_field then
        return false
    end
    go_base_to_fields()
    move.move(4 * (next_field - 1), side.up)
    move.move(2, side.front)
    harvest_field(FIELD_X_SIZE, FIELD_Y_SIZE, FIELD_DIRECTION, FIELD_MAP[next_field])
    move.move(2, side.back)
    move.move(4 * (next_field - 1), side.down)
    go_fields_to_base()
    return true
end

--[[
----    INVENTORY CONTROLL
--]]

function inventory_controll_chest(item, chest_side, drop, repack, update_need)
    if drop then
        chest.drop_item_to_chest(item, nil, nil, chest_side)
    end
    if repack then
        chest.repack_chest(chest_side)
    end
    if update_need then
        if not utilitie.is_elem_in_list(need_list, item) and not chest.is_full(chest_side) then
            need_list[#need_list + 1] = item
        elseif utilitie.is_elem_in_list(need_list, item) and chest.is_full(chest_side) then
           table.remove(need_list, item)
        end
    end
end

function inventory_controll_case(case, drop, repack, update_need)
    if case[side.up] then
        inventory_controll_chest(case[side.up], side.up, drop, repack, update_need)
    end
    if case[side.down] then
        inventory_controll_chest(case[side.down], side.down, drop, repack, update_need)
    end
end

function inventory_controll_line(line, drop, repack, update_need)
    local i

    i = 1
    while i <= #line do
        inventory_controll_case(line[i], drop, repack, update_need)
        i = i + 1
        if i <= #line then
            move.move(1)
        end
    end
    move.move(#line - 1, side.back)
end

function inventory_controll(drop, repack, update_need)
    local i

    i = 1
    move.move(1, side.up)
    move.move(6, side.front)
    move.move(2, side.left)
    move.move(1, side.front)
    while i <= #CHEST_MAP do
        inventory_controll_line(CHEST_MAP[i], drop, repack, update_need)
        i = i + 1
        if i <= #CHEST_MAP then
            move.move(2, side.left)
        end
    end
    move.move(2 * (i - 2), side.right)
    move.move(1, side.back)
    move.move(2, side.right)
    move.move(6, side.back)
    move.move(1, side.down)
end

function garbage_all()
    local slot

    move.move(1, side.up)
    move.move(1, side.right)
    slot = robot.inventorySize()
    while slot >= 1 do
        robot.select(slot)
        robot.dropDown()
        slot = slot - 1
    end
    move.move(1, side.left)
    move.move(1, side.down)
end

function core()
    local frequency_iter

    frequency_iter = 0
    while true do
        if frequency_iter % FREQUENCY_CHEST_DROP == 0 then
            energy.wait_charging()
            inventory_controll(true, false, true)
            print('Needed ressources: ' .. utilitie.var_dump(need_list))
            garbage_all()
        end
        energy.wait_charging()
        make_salt()
        inventory_controll(true, false, false)
        garbage_all()
        energy.wait_charging()
        make_water()
        inventory_controll(true, false, false)
        garbage_all()
        energy.wait_charging()
        harvest_next_field()
        if frequency_iter % FREQUENCY_APPLE == 0 then
            energy.wait_charging()
            harvest_apples()
        end
        os.sleep(MAIN_LOOP_SECONDS_SLEEP)
        frequency_iter = frequency_iter + 1
        if frequency_iter > 2000000000 then --in case of scipt running non-stop 63 years.
            frequency_iter = 0
        end
    end
end

if args[1] == '-u' or args[1] == '--update' then
    update()
    return true
end

init()
core()
