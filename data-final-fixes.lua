---------------------------------------------------------------------------------------------------
---[ data-final-fixes.lua ]---
---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Cargar dependencias ]---
---------------------------------------------------------------------------------------------------

local d12b = GMOD.d12b
if not d12b then return end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Información del MOD ]---
---------------------------------------------------------------------------------------------------

local This_MOD = GMOD.get_id_and_name()
if not This_MOD then return end
GMOD[This_MOD.id] = This_MOD

---------------------------------------------------------------------------------------------------

function This_MOD.start()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Iniciar el MOD dependiente
    d12b.start()

    --- Valores de la referencia
    This_MOD.reference_values()

    --- Obtener los elementos
    This_MOD.get_elements()

    --- Modificar los elementos
    for _, spaces in pairs(This_MOD.to_be_processed) do
        for _, space in pairs(spaces) do
            --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

            --- Crear los elementos
            This_MOD.create_item(space)
            This_MOD.create_tile(space)
            This_MOD.create_equipment(space)
            This_MOD.create_entity(space)
            This_MOD.update_recipe(space)
            This_MOD.update_tech(space)

            --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        end
        for _, space in pairs(spaces) do
            --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

            --- Corregir resultado de combustion
            This_MOD.update___burnt_result(space)

            --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        end
    end

    --- Implementar otros MODs
    if GMOD.d01b then GMOD.d01b.start() end
    if GMOD.d03b then GMOD.d03b.start() end
    if GMOD.d04b then GMOD.d04b.start() end

    --- Fijar las posiciones actual
    GMOD.d00b.change_orders()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.reference_values()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Contenedor de los elementos que el MOD modoficará
    This_MOD.to_be_processed = {}

    --- Validar si se cargó antes
    if This_MOD.setting then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Valores de la referencia en todos los MODs
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Cargar la configuración
    This_MOD.setting = GMOD.setting[This_MOD.id] or {}

    --- Indicador del mod
    This_MOD.indicator = {
        icon  = GMOD.signal["star"],
        shift = { 14, -14 }
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Valores de la referencia en este MOD
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Lista de entidades a ignorar
    This_MOD.ignore_to_name = {
        --- Space Exploration
        ["se-space-pipe-long-j-3"] = true,
        ["se-space-pipe-long-j-5"] = true,
        ["se-space-pipe-long-j-7"] = true,
        ["se-space-pipe-long-s-9"] = true,
        ["se-space-pipe-long-s-15"] = true,

        ["se-condenser-turbine"] = true,
        ["se-energy-transmitter-emitter"] = true,
        ["se-energy-transmitter-injector"] = true,
        ["se-core-miner-drill"] = true,
        ["se-energy-transmitter-chamber"] = true,
        ["se-energy-receiver"] = true,

        ["se-delivery-cannon"] = true,
        ["se-spaceship-rocket-engine"] = true,
        ["se-spaceship-ion-engine"] = true,
        ["se-spaceship-antimatter-engine"] = true,

        ["se-meteor-point-defence-container"] = true,
        ["se-meteor-defence-container"] = true,
        ["se-delivery-cannon-weapon"] = true,
        ["shield-projector"] = true
    }

    --- Efectos por tipo
    This_MOD.effect_to_type = {
        --- Entities
        ["accumulator"] = function(space, entity)
            if not entity.energy_source then return end
            local Energy = entity.energy_source
            for _, propiety in pairs({
                "buffer_capacity",
                "input_flow_limit",
                "output_flow_limit"
            }) do
                local Value, Unit = GMOD.number_unit(Energy[propiety])
                Energy[propiety] = (space.amount * Value) .. Unit
            end
        end,

        ["assembling-machine"] = function(space, entity)
            --- Renombrar
            local Table = entity.energy_source

            --- Usar menos combustible
            if Table.type == "burner" then
                Table.effectivity = space.amount * (Table.effectivity or 1)
            end

            --- Aumnetar la velocidad de fabricación
            entity.crafting_speed = space.amount * entity.crafting_speed
        end,

        ["artillery-wagon"] = function(space, entity)
            entity.max_speed = space.amount * entity.max_speed
        end,

        ["beacon"] = function(space, entity)
            entity.distribution_effectivity = space.amount * entity.distribution_effectivity
        end,

        ["boiler"] = function(space, entity)
            --- Renombrar
            local Energy = entity.energy_source

            --- Para los que usan combustible
            if Energy.type == "burner" then
                Energy.effectivity = space.amount * (Energy.effectivity or 1)
            end

            --- Velocidad de calentamiento
            local Value, Unit = GMOD.number_unit(entity.energy_consumption)
            entity.energy_consumption = (space.amount * Value) .. Unit
        end,

        ["cargo-wagon"] = function(space, entity)
            entity.max_speed = space.amount * entity.max_speed

            if entity.inventory_size then
                entity.inventory_size = space.amount * entity.inventory_size
                if entity.inventory_size > 65535 then
                    entity.inventory_size = 65535
                end
            end
        end,

        ["construction-robot"] = function(space, entity)
            entity.speed = space.amount * entity.speed
            entity.max_payload_size = space.amount * entity.max_payload_size
            entity.next_upgrade = nil
        end,

        ["electric-turret"] = function(space, entity)
            --- Velocidad de respues
            entity.rotation_speed = space.amount * entity.rotation_speed
            entity.preparing_speed = space.amount * entity.preparing_speed

            --- Daño directo
            local Damages = GMOD.get_tables(entity.attack_parameters, "type", "damage")
            for _, element in pairs(Damages or {}) do
                if element.damage.amount then
                    element.damage.amount = space.amount * element.damage.amount
                end
            end

            --- Daño indirecto
            local Action = entity.attack_parameters.ammo_type.action
            for _, type in pairs({
                "beam",
                "projectile"
            }) do
                for _, Table in pairs(
                    GMOD.get_tables(Action, "type", type) or {}
                ) do
                    repeat
                        --- Validación
                        if GMOD.has_id(Table[type], This_MOD.id) then break end
                        local Effecto = data.raw[type][Table[type]]
                        if not Effecto then break end

                        --- Duplicar el efecto
                        Effecto = GMOD.copy(Effecto)

                        --- Actualizar el nombre
                        local That_MOD =
                            GMOD.get_id_and_name(Effecto.name) or
                            { ids = "-", name = Effecto.name }

                        Effecto.name =
                            GMOD.name .. That_MOD.ids ..
                            This_MOD.id .. "-" ..
                            That_MOD.name .. "-" ..
                            space.amount .. "x"

                        Table[type] = Effecto.name

                        --- Aumentar el daño
                        for _, element in pairs(
                            GMOD.get_tables(Effecto, "type", "damage") or {}
                        ) do
                            if element.damage.amount then
                                element.damage.amount = space.amount * element.damage.amount
                            end
                        end

                        --- Crear y devolver el effecto
                        GMOD.extend(Effecto)
                    until true
                end
            end
        end,

        ["fluid-wagon"] = function(space, entity)
            entity.max_speed = space.amount * entity.max_speed

            if entity.capacity then
                entity.capacity = space.amount * entity.capacity
            end
        end,

        ["furnace"] = function(space, entity)
            --- Renombrar
            local Energy = entity.energy_source

            --- Usar menos combustible
            if Energy.type == "burner" then
                Energy.effectivity = space.amount * (Energy.effectivity or 1)
            end

            --- Aumnetar la velocidad de fabricación
            entity.crafting_speed = space.amount * entity.crafting_speed
        end,

        ["gate"] = function(space, entity)
            entity.max_health = space.amount * entity.max_health
        end,

        ["generator"] = function(space, entity)
            entity.effectivity = space.amount * (entity.effectivity or 1)
        end,

        ["inserter"] = function(space, entity)
            entity.extension_speed = space.amount * entity.extension_speed
            entity.rotation_speed  = space.amount * entity.rotation_speed
        end,

        ["lab"] = function(space, entity)
            entity.researching_speed = space.amount * (entity.researching_speed or 1)
        end,

        ["lane-splitter"] = function(space, entity)
            --- Velocidad de la cintas
            entity.speed = (space.belt or space.amount) * entity.speed

            --- Velocidad de la animación
            local Fact = entity.speed / space.entity.speed
            entity.animation_speed_coefficient = entity.animation_speed_coefficient / Fact
        end,

        ["loader-1x1"] = function(space, entity)
            --- Velocidad de la cintas
            entity.speed = (space.belt or space.amount) * entity.speed

            --- Velocidad de la animación
            local Fact = entity.speed / space.entity.speed
            entity.animation_speed_coefficient = entity.animation_speed_coefficient / Fact
        end,

        ["locomotive"] = function(space, entity)
            entity.max_speed = space.amount * entity.max_speed

            local Energy = entity.energy_source
            if Energy and Energy.type == "burner" then
                Energy.effectivity = space.amount * (Energy.effectivity or 1)
            end

            if entity.max_power then
                local Value, Unit = GMOD.number_unit(entity.max_power)
                entity.max_power = (space.amount * Value) .. Unit
            end
        end,

        ["logistic-robot"] = function(space, entity)
            entity.speed = space.amount * entity.speed
            entity.max_payload_size = space.amount * entity.max_payload_size
            entity.next_upgrade = nil
        end,

        ["mining-drill"] = function(space, entity)
            if not entity.energy_source then return end
            local Energy = entity.energy_source
            if Energy.type == "burner" then
                Energy.effectivity = space.amount * (Energy.effectivity or 1)
            end
            entity.mining_speed = space.amount * entity.mining_speed
        end,

        ["offshore-pump"] = function(space, entity)
            repeat
                if not entity.fluid_box then break end
                if not entity.fluid_box.volume then break end
                entity.fluid_box.volume = space.amount * entity.fluid_box.volume
            until true
            if entity.pumping_speed then
                entity.pumping_speed = space.amount * entity.pumping_speed
            end
        end,

        ["pipe-to-ground"] = function(space, entity)
            if not entity.fluid_box then return end
            if not entity.fluid_box.pipe_connections then return end
            local Pipe_connections = entity.fluid_box.pipe_connections
            for _, value in pairs(Pipe_connections) do
                if value.max_underground_distance then
                    value.max_underground_distance =
                        space.amount * value.max_underground_distance
                    if value.max_underground_distance > 255 then
                        value.max_underground_distance = 255
                    end
                end
            end
        end,

        ["pump"] = function(space, entity)
            repeat
                if not entity.fluid_box then break end
                if not entity.fluid_box.volume then break end
                entity.fluid_box.volume = space.amount * entity.fluid_box.volume
            until true
            if entity.pumping_speed then
                entity.pumping_speed = space.amount * entity.pumping_speed
            end
        end,

        ["reactor"] = function(space, entity)
            local Energy = entity.energy_source
            if Energy.type ~= "burner" then return end
            Energy.effectivity = space.amount * (Energy.effectivity or 1)
        end,

        ["solar-panel"] = function(space, entity)
            local Value, Unit = GMOD.number_unit(entity.production)
            entity.production = (space.amount * Value) .. Unit
        end,

        ["splitter"] = function(space, entity)
            --- Velocidad de la cintas
            entity.speed = space.amount * entity.speed

            --- Velocidad de la animación
            local Fact = entity.speed / space.entity.speed
            entity.animation_speed_coefficient = entity.animation_speed_coefficient / Fact
        end,

        ["storage-tank"] = function(space, entity)
            entity.fluid_box.volume = space.amount * entity.fluid_box.volume
        end,

        ["transport-belt"] = function(space, entity)
            --- Velocidad de la cintas
            entity.speed = space.amount * entity.speed

            --- Velocidad de la animación
            local Fact = entity.speed / space.entity.speed
            entity.animation_speed_coefficient = entity.animation_speed_coefficient / Fact

            --- Cinta subterranea a usar
            if not entity.related_underground_belt then return end
            local Item = GMOD.items[entity.related_underground_belt]
            entity.related_underground_belt =
                GMOD.name .. (
                    GMOD.get_id_and_name(entity.name) or
                    { ids = "-" .. This_MOD.id .. "-" }
                ).ids .. (
                    d12b.setting.stack_size and
                    Item.stack_size .. "x" .. d12b.setting.amount or
                    space.amount
                ) .. "u-" .. (
                    GMOD.get_id_and_name(entity.related_underground_belt) or
                    { name = entity.related_underground_belt }
                ).name
        end,

        ["underground-belt"] = function(space, entity)
            --- Velocidad de la cintas
            entity.speed = (space.belt or space.amount) * entity.speed

            --- Velocidad de la animación
            local Fact = entity.speed / space.entity.speed
            entity.animation_speed_coefficient = entity.animation_speed_coefficient / Fact

            --- Distancia
            if not entity.max_distance then return end
            if entity.max_distance == 0 then return end
            entity.max_distance = entity.max_distance + 2 * ((space.belt or space.amount) - 1)
            if entity.max_distance > 255 then entity.max_distance = 255 end
        end,

        ["wall"] = function(space, entity)
            entity.max_health = space.amount * entity.max_health
        end,

        --- Items
        ["ammo"] = function(space, item)
            --- Actualizar las propiedades
            if item.magazine_size then
                item.magazine_size = space.amount * item.magazine_size
            end

            --- Actualizar el daño directo en el objeto
            for _, element in pairs(
                GMOD.get_tables(item.ammo_type, "type", "damage") or {}
            ) do
                element.damage.amount = space.amount * element.damage.amount
            end

            local function duplicate(effect)
                if not effect then return end

                --- Duplicar el efecto
                effect = GMOD.copy(effect)

                --- Actualizar el nombre
                local That_MOD =
                    GMOD.get_id_and_name(effect.name) or
                    { ids = "-", name = effect.name }

                effect.name =
                    GMOD.name .. That_MOD.ids ..
                    This_MOD.id .. "-" ..
                    That_MOD.name .. "-" ..
                    space.amount .. "x"

                --- Verificar si ya existe
                if data.raw[effect.type][effect.name] then
                    return effect.name
                end

                --- Aumentar el daño
                for _, element in pairs(
                    GMOD.get_tables(effect, "damage") or {}
                ) do
                    if element.damage.amount then
                        element.damage.amount = space.amount * element.damage.amount
                    end
                end

                --- Crear y devolver el effecto
                GMOD.extend(effect)
                return effect.name
            end

            --- Bucar los daños indirectos
            for _, find in pairs({
                "damage",
                "stream",
                "artillery",
                "projectile"
            }) do
                for _, effect in pairs(
                    GMOD.get_tables(item.ammo_type, "type", find) or {}
                ) do
                    --- Duplicar el projectile
                    repeat
                        if effect.type ~= "projectile" then break end
                        if GMOD.has_id(effect.projectile, This_MOD.id) then break end
                        effect.projectile = duplicate(data.raw[effect.type][effect.projectile])
                    until true

                    --- Duplicar el artillery-projectile
                    repeat
                        if effect.type ~= "artillery" then break end
                        if GMOD.has_id(effect.projectile, This_MOD.id) then break end
                        effect.projectile = duplicate(data.raw["artillery-projectile"][effect.projectile])
                    until true

                    --- Duplicar el stream
                    repeat
                        if effect.type ~= "stream" then break end
                        if GMOD.has_id(effect.stream, This_MOD.id) then break end
                        effect.stream = duplicate(data.raw[effect.type][effect.stream])
                    until true
                end
            end
        end,

        ["module"] = function(space, item)
            local Validate = {
                ["productivity"] = function(value) return value > 0 end,
                ["consumption"] = function(value) return value < 0 end,
                ["pollution"] = function(value) return value < 0 end,
                ["quality"] = function(value) return value > 0 end,
                ["speed"] = function(value) return value > 0 end
            }
            for effect, _ in pairs(item.effect) do
                if Validate[effect](item.effect[effect]) then
                    item.effect[effect] = space.amount * item.effect[effect]
                    if item.effect[effect] > 327 then item.effect[effect] = 327 end
                    if item.effect[effect] < -327 then item.effect[effect] = -327 end
                end
            end
        end,

        ["repair-tool"] = function(space, item)
            item.speed = space.amount * item.speed
            item.durability = space.amount * item.durability
        end,

        --- Tile
        ["tile"] = function(space, tile)
            local Pollution = 0
            local Spores = 0

            tile.absorptions_per_second = tile.absorptions_per_second or {}
            Pollution = tile.absorptions_per_second.pollution or 0.0000025
            Pollution = Pollution ~= 0 and Pollution or 0.0000025
            if mods["space-age"] then
                Spores = tile.absorptions_per_second.spores or 0.0000025
            end

            tile.absorptions_per_second = {
                spores = Spores > 0 and (Spores * (space.amount - 1)) or nil,
                pollution = Pollution * (space.amount - 1),
            }
        end,

        --- Equipment
        ["active-defense-equipment"] = function(space, equipment)
            local Action = equipment.attack_parameters.ammo_type.action
            for _, type in pairs({
                "beam",
                "projectile"
            }) do
                for _, Table in pairs(
                    GMOD.get_tables(Action, "type", type) or {}
                ) do
                    repeat
                        --- Validación
                        if GMOD.has_id(Table[type], This_MOD.id) then break end
                        local Effecto = data.raw[type][Table[type]]
                        if not Effecto then break end

                        --- Duplicar el efecto
                        Effecto = GMOD.copy(Effecto)

                        --- Actualizar el nombre
                        local That_MOD =
                            GMOD.get_id_and_name(Effecto.name) or
                            { ids = "-", name = Effecto.name }

                        Effecto.name =
                            GMOD.name .. That_MOD.ids ..
                            This_MOD.id .. "-" ..
                            That_MOD.name .. "-" ..
                            space.amount .. "x"

                        Table[type] = Effecto.name

                        --- Aumentar el daño
                        for _, element in pairs(
                            GMOD.get_tables(Effecto, "type", "damage") or {}
                        ) do
                            if element.damage.amount then
                                element.damage.amount = space.amount * element.damage.amount
                            end
                        end

                        --- Crear y devolver el effecto
                        GMOD.extend(Effecto)
                    until true
                end
            end
        end,

        ["battery-equipment"] = function(space, equipment)
            local Value, Unit = GMOD.number_unit(equipment.energy_source.buffer_capacity)
            equipment.energy_source.buffer_capacity = (space.amount * Value) .. Unit
        end,

        ["roboport-equipment"] = function(space, equipment)
            equipment.robot_limit = space.amount * equipment.robot_limit
        end,

        ["generator-equipment"] = function(space, equipment)
            local Value, Unit = GMOD.number_unit(equipment.power)
            equipment.power = (space.amount * Value) .. Unit
        end,

        ["solar-panel-equipment"] = function(space, equipment)
            local Value, Unit = GMOD.number_unit(equipment.power)
            equipment.power = (space.amount * Value) .. Unit
        end,

        ["energy-shield-equipment"] = function(space, equipment)
            equipment.max_shield_value = space.amount * equipment.max_shield_value
        end
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Cambios del MOD ]---
---------------------------------------------------------------------------------------------------

function This_MOD.get_elements()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Función para analizar cada entidad
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function validate_recipe(recipe)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Validación
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validar el tipo
        if recipe.type ~= "recipe" then return end
        if not GMOD.has_id(recipe.name, d12b.id) then return end
        if not GMOD.has_id(recipe.name, d12b.category_do) then return end

        --- Validar contenido
        if #recipe.ingredients ~= 1 then return end
        if #recipe.results ~= 1 then return end

        --- Renombrar
        local Item = GMOD.items[recipe.ingredients[1].name]
        local Item_do = GMOD.items[recipe.results[1].name]

        --- Calcular la cantidad
        local Amount = d12b.setting.amount
        if d12b.setting.stack_size then
            Amount = Amount * Item.stack_size
            if Amount > 65000 then
                Amount = 65000
            end
        end

        --- Validar si ya fue procesado
        if GMOD.has_id(Item_do.name, This_MOD.id) then return end

        local That_MOD =
            GMOD.get_id_and_name(Item_do.name) or
            { ids = "-", name = Item_do.name }

        local Name =
            GMOD.name .. That_MOD.ids ..
            This_MOD.id .. "-" ..
            That_MOD.name

        if GMOD.items[Name] then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Valores para el proceso
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        local Space = {}

        Space.name = Name

        Space.item = Item
        Space.amount = Amount
        Space.item_do = Item_do

        Space.recipe_do = recipe
        Space.recipe_undo = recipe.name:gsub(
            d12b.category_do .. "%-",
            d12b.category_undo .. "-"
        )
        Space.recipe_undo = data.raw.recipe[Space.recipe_undo]

        Space.tech = GMOD.get_technology({ Space.recipe_undo }, true)

        Space.localised_name = Item.localised_name
        Space.localised_description = Item.localised_description

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Validar el elemento a afectar
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        if Item.place_result then
            Space.entity = GMOD.entities[Item.place_result]
            if not Space.entity then return end
            if This_MOD.ignore_to_name[Space.entity.name] then return end
            if not Space.entity.minable then return end
            if not Space.entity.minable.results then return end

            if Space.entity.type == "accumulator" then
                if not Space.entity.energy_source then return end
                if not Space.entity.energy_source.output_flow_limit then return end
                local Energy = Space.entity.energy_source.output_flow_limit
                Energy = GMOD.number_unit(Energy)
                if not Energy then return end
            else
                if not This_MOD.effect_to_type[Space.entity.type] then return end
            end
        end

        if Item.place_as_tile then
            Space.tiles = GMOD.tiles[Item.name]
            if not Space.tiles then return end
            if not Space.tiles.minable then return end
            if not Space.tiles.minable.results then return end
        end

        if Item.place_as_equipment_result then
            for _, equipment in pairs(GMOD.equipments) do
                repeat
                    if Item.place_as_equipment_result ~= equipment.name then break end
                    if not This_MOD.effect_to_type[equipment.type] then break end
                    if not equipment.power then
                        local Energy = equipment.energy_source
                        if Energy and not Energy.buffer_capacity then
                            break
                        end
                    end

                    Space.equipment = equipment
                until true
                if Space.equipment then break end
            end
            if not Space.equipment then return end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if This_MOD.effect_to_type[Item.type] then break end
            if Item.fuel_value then break end
            if Item.place_as_equipment_result then break end
            if Item.place_as_tile then break end
            if Item.place_result then break end
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        local Belts = {
            ["underground-belt"] = true,
            ["lane-splitter"] = true,
            ["loader-1x1"] = true
        }

        repeat
            if not Space.entity then break end
            if not Belts[Space.entity.type] then break end

            local Find = Space.entity.type:gsub("%-", "%%-")
            local Belt = Space.item.name:gsub(Find, "transport-belt")
            Belt = GMOD.items[Belt]
            if not Belt then break end

            Space.belt = d12b.setting.amount
            if d12b.setting.stack_size then
                Space.belt = Space.belt * Belt.stack_size
                if Space.belt > 65000 then
                    Space.belt = 65000
                end
            end
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Guardar la información
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        This_MOD.to_be_processed[recipe.type] = This_MOD.to_be_processed[recipe.type] or {}
        This_MOD.to_be_processed[recipe.type][Name] = Space

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Preparar los datos a usar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, recipe in pairs(data.raw.recipe) do
        validate_recipe(recipe)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

function This_MOD.create_item(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.item then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Duplicar el elemento
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Item = GMOD.copy(space.item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Nombre
    Item.name = space.name

    --- Apodo y descripción
    Item.localised_name = GMOD.copy(space.localised_name)
    Item.localised_description = GMOD.copy(space.localised_description)

    --- Agregar indicador del MOD
    Item.icons = GMOD.copy(space.item_do.icons)
    local Icon = GMOD.get_tables(Item.icons, "icon", d12b.indicator.icon)[1]
    Icon.icon = This_MOD.indicator.icon

    --- Actualizar subgroup y order
    Item.subgroup = space.item_do.subgroup
    Item.order = space.item_do.order

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---- Modificar los objetos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if Item.place_result then
        Item.place_result = space.name
    end

    if Item.place_as_tile then
        Item.place_as_tile.result = space.name .. "-1"
    end

    if Item.place_as_equipment_result then
        Item.place_as_equipment_result = space.name
    end

    if This_MOD.effect_to_type[Item.type] then
        This_MOD.effect_to_type[Item.type](space, Item)
    end

    if Item.fuel_value then
        local Value, Unit = GMOD.number_unit(Item.fuel_value)
        Item.fuel_value = Value * space.amount .. Unit
        space.burnt_result = Item.burnt_result
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---- Eliminar el objeto anterior
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.items[space.item_do.name] = nil
    data.raw.item[space.item_do.name] = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---- Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.extend(Item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.create_tile(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.tiles then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Duplicar el elemento
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for i, Tile in pairs(space.tiles) do
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Duplicar el suelo
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        Tile = GMOD.copy(Tile)

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Cambiar algunas propiedades
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Nombre
        Tile.name = space.name .. "-" .. i

        --- Apodo y descripción
        Tile.localised_name = GMOD.copy(space.localised_name)
        Tile.localised_description = GMOD.copy(space.localised_description)

        --- Agregar indicador del MOD
        Tile.icons = GMOD.copy(GMOD.items[space.name].icons)

        --- Objeto a minar
        Tile.minable.results = { {
            type = "item",
            name = space.name,
            amount = 1
        } }

        --- Siguiente tile
        if Tile.next_direction then
            local Next = i + 1
            if Next > #space.tiles then
                Next = 1
            end
            Tile.next_direction = space.name .. "-" .. Next
        end

        --- Actualizar subgroup y order
        Tile.subgroup = space.item_do.subgroup
        Tile.order = space.item_do.order

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        ---- Modificar los objetos
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        if This_MOD.effect_to_type[Tile.type] then
            This_MOD.effect_to_type[Tile.type](space, Tile)
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        ---- Crear el prototipo
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        GMOD.extend(Tile)

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.create_equipment(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.equipment then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Duplicar el elemento
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Equipment = GMOD.copy(space.equipment)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Nombre
    Equipment.name = space.name

    --- Apodo y descripción
    Equipment.localised_name = GMOD.copy(space.localised_name)
    Equipment.localised_description = GMOD.copy(space.localised_description)

    --- Agregar indicador del MOD
    Equipment.icons = GMOD.copy(space.item_do.icons)
    local Icon = GMOD.get_tables(Equipment.icons, "icon", d12b.indicator.icon)[1]
    Icon.icon = This_MOD.indicator.icon

    --- Actualizar subgroup y order
    Equipment.subgroup = space.item_do.subgroup
    Equipment.order = space.item_do.order

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---- Modificar los equipment
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if This_MOD.effect_to_type[Equipment.type] then
        This_MOD.effect_to_type[Equipment.type](space, Equipment)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---- Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.extend(Equipment)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.create_entity(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.entity then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Duplicar el elemento
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Entity = GMOD.copy(space.entity)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Nombre
    Entity.name = space.name

    --- Apodo y descripción
    Entity.localised_name = GMOD.copy(space.localised_name)
    Entity.localised_description = GMOD.copy(space.localised_description)

    --- Elimnar propiedades inecesarias
    Entity.factoriopedia_simulation = nil

    --- Cambiar icono
    Entity.icons = GMOD.items[space.name].icons

    --- Actualizar el nuevo subgrupo
    Entity.subgroup = GMOD.items[space.name].subgroup

    --- Objeto a minar
    Entity.minable.results = { {
        type = "item",
        name = space.name,
        amount = 1
    } }

    --- Siguiente tier
    Entity.next_upgrade = (function(entity)
        --- Validación
        if not entity then return end

        --- Cargar el objeto de referencia
        local Item = GMOD.items[entity]
        if not Item then return end

        --- Nombre despues del aplicar el MOD
        local Name =
            GMOD.name .. (
                GMOD.get_id_and_name(space.name) or
                { ids = "-" }
            ).ids .. (
                d12b.setting.stack_size and
                Item.stack_size .. "x" .. d12b.setting.amount or
                space.amount
            ) .. "u-" .. (
                GMOD.get_id_and_name(entity) or
                { name = entity }
            ).name

        --- La entidad ya existe
        if GMOD.entities[Name] then return Name end

        --- La entidad existirá
        for _, Spaces in pairs(This_MOD.to_be_processed) do
            for _, Space in pairs(Spaces) do
                if Space.entity and Space.entity.name == entity then
                    return Name
                end
            end
        end
    end)(Entity.next_upgrade)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Aplicar el efecto apropiado
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    This_MOD.effect_to_type[Entity.type](space, Entity)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.extend(Entity)

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.update_recipe(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.recipe_do then return end
    if not space.recipe_undo then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    space.recipe_do.results[1].name = space.name
    space.recipe_undo.ingredients[1].name = space.name

    GMOD.recipes[space.name] = GMOD.recipes[space.item_do.name]
    GMOD.recipes[space.item_do.name] = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.update_tech(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.tech then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    space.tech.research_trigger.item = space.name

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

function This_MOD.update___burnt_result(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not space.burnt_result then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cambiar algunas propiedades
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Item = GMOD.items[space.name]
    for _, recipe in pairs(GMOD.recipes[Item.burnt_result]) do
        if GMOD.has_id(recipe.name, d12b.category_undo) then
            Item.burnt_result = recipe.ingredients[1].name
            break
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Iniciar el MOD ]---
---------------------------------------------------------------------------------------------------

This_MOD.start()

---------------------------------------------------------------------------------------------------
