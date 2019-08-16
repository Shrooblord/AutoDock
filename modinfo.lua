
meta =
{
    id = "Shrooblord_Auto-Dock",
    name = "Auto-Dock",
    title = "Auto-Dock",
    description = "Auto-Dock allows you to dock with Stations while flying at them at speeds of up to 2 km/s. To use Auto-Dock, use the new interaction when talking to the Station you would wish to dock with. Then fly towards the Beacon that gets spawned for that Station in order to initiate the automatic docking procedure.",
    authors = {"Shrooblord"},
    version = "2.0.0",

    -- If your mod requires dependencies, enter them here. The game will check that all dependencies given here are met.
    -- Possible attributes:
    -- id: The ID of the other mod as stated in its modinfo.lua
    -- min, max, exact: version strings that will determine minimum, maximum or exact version required (exact is only syntactic sugar for min == max)
    -- optional: set to true if this mod is only an optional dependency (will only influence load order, not requirement checks)
    -- incompatible: set to true if your mod is incompatible with the other one
    -- Example:
    -- dependencies = {
    --      {id = "Avorion", min = "0.17", max = "0.21"}, -- we can only work with Avorion between versions 0.17 and 0.21
    --      {id = "SomeModLoader", min = "1.0", max = "2.0"}, -- we require SomeModLoader, and we need its version to be between 1.0 and 2.0
    --      {id = "AnotherMod", max = "2.0"}, -- we require AnotherMod, and we need its version to be 2.0 or lower
    --      {id = "IncompatibleMod", incompatible = true}, -- we're incompatible with IncompatibleMod, regardless of its version
    --      {id = "IncompatibleModB", exact = "2.0", incompatible = true}, -- we're incompatible with IncompatibleModB, but only exactly version 2.0
    --      {id = "OptionalMod", min = "0.2", optional = true}, -- we support OptionalMod optionally, starting at version 0.2
    -- },
    dependencies = {
        {id = "Avorion", min = "0.25", max = "0.26"},
        {id = "ShrooblordMothership", min = "1.0.0"},
    },

    serverSideOnly = false,
    clientSideOnly = false,
    saveGameAltering = true,

    contact = "avorion@shrooblord.com",
}
