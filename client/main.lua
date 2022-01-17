local QBCore = exports['qb-core']:GetCoreObject()

-- Functions

local function SetupItems(shop)
    local products = Config.Locations[shop].products
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    local items = {}
    for i = 1, #products do
        if not products[i].requiredJob then
            items[#items+1] = products[i]
        else
            for i2 = 1, #products[i].requiredJob do
                if playerJob == products[i].requiredJob[i2] then
                    items[#items+1] = products[i]
                end
            end
        end
    end
    return items
end

local function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Events

RegisterNetEvent('qb-shops:client:UpdateShop', function(shop, itemData, amount)
    TriggerServerEvent('qb-shops:server:UpdateShopItems', shop, itemData, amount)
end)

RegisterNetEvent('qb-shops:client:SetShopItems', function(shop, shopProducts)
    Config.Locations[shop]["products"] = shopProducts
end)

RegisterNetEvent('qb-shops:client:RestockShopItems', function(shop, amount)
    if Config.Locations[shop]["products"] ~= nil then
        for k, v in pairs(Config.Locations[shop]["products"]) do
            Config.Locations[shop]["products"][k].amount = Config.Locations[shop]["products"][k].amount + amount
        end
    end
end)

-- Threads

RegisterNetEvent('qb-shops:marketshop', function()
            for shop, data in pairs(Config.Locations) do
                local position = data["coords"]
                local products = data["products"]
                for _, loc in pairs(position) do
                    local dist = #(GetEntityCoords(PlayerPedId()) - vector3(loc["x"], loc["y"], loc["z"]))
                    if dist < 3 then
                        local ShopItems = {}
                        ShopItems.items = {}
                        local callback = promise.new()
                        QBCore.Functions.TriggerCallback('qb-shops:server:getLicenseStatus', function(result)
                            ShopItems.label = Config.Locations[shop]["label"]
                            if Config.Locations[shop].type == "weapon" then
                                if result then
                                    ShopItems.items = SetupItems(shop)
                                else
                                    for i = 1, #products do
                                        if not products[i].requiredJob then
                                            if not products[i].requiresLicense then
                                                table.insert(ShopItems.items, products[i])
                                            end
                                        else
                                            for i2 = 1, #products[i].requiredJob do
                                                if QBCore.Functions.GetPlayerData().job.name == products[i].requiredJob[i2] and not products[i].requiresLicense then
                                                    table.insert(ShopItems.items, products[i])
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                ShopItems.items = SetupItems(shop)
                            end
                            for k, v in pairs(ShopItems.items) do
                                ShopItems.items[k].slot = k
                            end
                            ShopItems.slots = 30
                            TriggerServerEvent("inventory:server:OpenInventory", "shop", "Itemshop_"..shop, ShopItems)
                            callback:resolve(true)
                        end)
        
                        Citizen.Await(callback)
                        break
                    end
                end
            end
        end)

CreateThread(function()
    for store, _ in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            for i = 1, #Config.Locations[store]["coords"] do
                StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"][i]["x"], Config.Locations[store]["coords"][i]["y"], Config.Locations[store]["coords"][i]["z"])
                SetBlipColour(StoreBlip, 0)
                SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
                SetBlipScale(StoreBlip, 0.6)
                SetBlipDisplay(StoreBlip, 4)
                SetBlipAsShortRange(StoreBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
                EndTextCommandSetBlipName(StoreBlip)
            end
        end
    end
end)
