--[[
   This service provides an api for updating entity's stats from the roster customization screen.
--]]

local validator = radiant.validator

local StatsCustomizationService = class()

function StatsCustomizationService:initialize()
end

function StatsCustomizationService:get_max_stats_command(session, response)
   local pop = stonehearth.population:get_population(session.player_id)
   response:resolve({ attribute_distribution = pop:get_role_data().attribute_distribution })
end

-- Set the entity's stat using the given stat type 
function StatsCustomizationService:change_stat_by_type_command(session, response, entity, statType, value)
   validator.expect_argument_types({'Entity', 'string', 'number'}, entity, statType, value)
   validator.expect.num.positive(value)
   validator.expect.string.max_length(statType)

   local attributes = entity:get_component('stonehearth:attributes')
   attributes:set_attribute(statType, value)
   response:resolve({ citizen = entity })
end

function StatsCustomizationService:get_all_traits_command(session, response, entity)
   validator.expect_argument_types({'Entity'}, entity)
   local pop = stonehearth.population:get_population(session.player_id)
   local all_traits = {}
   for group_name, group in pairs(pop._traits.groups) do
        for trait_uri, trait in pairs(group) do
            trait = radiant.resources.load_json(trait_uri, true, true) 
            trait['i18n_data'] = {}
            trait['i18n_data']['entity_custom_name'] = radiant.entities.get_custom_name(entity) 
            trait['i18n_data']['entity_display_name'] = radiant.entities.get_display_name(entity)
            if group_name == 'passion_jobs' and trait.data.job_uri then
                local job = radiant.resources.load_json(trait.data.job_uri, true, true)
                trait['i18n_data']['passion_job'] = job.display_name
            end
            trait['uri'] = trait_uri
            table.insert(all_traits, trait)
        end
   end
   for trait_uri, trait in pairs(pop._traits.traits) do
        trait = radiant.resources.load_json(trait_uri, true, true)
        trait['i18n_data'] = {}
        trait['i18n_data']['entity_custom_name'] = radiant.entities.get_custom_name(entity) 
        trait['i18n_data']['entity_display_name'] = radiant.entities.get_display_name(entity)
        if trait_uri == 'stonehearth:traits:animal_companion' then
            local species = radiant.entities.get_entity_data(entity, 'stonehearth:species', false)
            trait['i18n_data']['maybe_determiner'] = 'i18n(stonehearth:ui.game.common.the)'
            trait['i18n_data']['maybe_savior_species'] = '%random_species%'
            trait['i18n_data']['savee_custom_name'] = trait['i18n_data']['entity_custom_name']
            trait['i18n_data']['savee_display_name'] = trait['i18n_data']['entity_display_name']
            trait['i18n_data']['savee_species'] = species and species.display_name or trait.data.default_species
            trait['i18n_data']['savior_custom_name'] = '%random_name%'
            trait['i18n_data']['savior_display_name'] = 'i18n(stonehearth:ui.game.entities.custom_name)'
        end
        trait['uri'] = trait_uri
        table.insert(all_traits, trait)
   end
   response:resolve({ all_traits = all_traits })
end

function StatsCustomizationService:add_trait_command(session, response, entity, trait_uri)
    local traits = entity:get_component('stonehearth:traits')
    traits:add_trait(trait_uri)
    response:resolve({ citizen = entity })
end

function StatsCustomizationService:remove_trait_command(session, response, entity, trait_uri)
    local traits = entity:get_component('stonehearth:traits')
    traits:remove_trait(trait_uri)
    response:resolve({ citizen = entity })
end

return StatsCustomizationService
