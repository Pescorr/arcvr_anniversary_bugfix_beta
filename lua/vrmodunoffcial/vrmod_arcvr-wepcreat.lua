-- Required libraries
-- Custom weapon class using ArcVR weapon base
local CUSTOM_WEAPON_CLASS = "weapon_arcvr_custom"
-- Define Custom Weapon
weapons.Register(
    {
        Base = "weapon_arcvr_base", -- Replace with the actual ArcVR base class
        PrintName = "Custom ArcVR Weapon",
        ViewModel = "", -- Default view model, can be changed
        WorldModel = "", -- Default world model, can be changed
        Primary = {
            Ammo = "",
            ClipSize = 30,
        },
    }, CUSTOM_WEAPON_CLASS
)

-- Add other primary fire settings
-- Add other weapon settings
-- VGUI Panel for Weapon Customization
local function createCustomWeaponPanel()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Custom ArcVR Weapon Configuration")
    frame:SetSize(500, 700)
    frame:Center()
    frame:MakePopup()
    -- Example: Text Entry for ViewModel
    local viewModelEntry = vgui.Create("DTextEntry", frame)
    viewModelEntry:SetPos(10, 30)
    viewModelEntry:SetSize(200, 20)
    viewModelEntry:SetText("Model/ViewModel.mdl")
    -- Add other VGUI controls for each parameter (text entries, dropdowns, sliders, etc.)
    -- Example: Dropdown for selecting weapon model
    -- Button to create weapon
    local createWeaponButton = vgui.Create("DButton", frame)
    createWeaponButton:SetText("Create Weapon")
    createWeaponButton:SetPos(10, 60)
    createWeaponButton:SetSize(200, 30)
    createWeaponButton.DoClick = function()
        -- Function to create weapon with the specified parameters
        createCustomWeapon(viewModelEntry:GetValue())
    end
end

-- Function to Create the Custom Weapon
local function createCustomWeapon(viewModel)
    local weaponData = weapons.GetStored(CUSTOM_WEAPON_CLASS)
    if weaponData then
        weaponData.ViewModel = viewModel
        -- Set other customized parameters
        weapons.Register(weaponData, CUSTOM_WEAPON_CLASS)
        print("Custom ArcVR Weapon Created with ViewModel: " .. viewModel)
    else
        print("Error: Custom weapon class not found")
    end
end

-- Optionally, bind the VGUI panel creation to a console command or key
concommand.Add("open_custom_arcvr_weapon_config", createCustomWeaponPanel)
-- Example usage:
-- Run "open_custom_arcvr_weapon_config" in the console to open the customization panel