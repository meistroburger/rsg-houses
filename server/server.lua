local RSGCore = exports['rsg-core']:GetCoreObject()

-- get house keys
RSGCore.Functions.CreateCallback('rsg-houses:server:GetHouseKeys', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local housekeys = MySQL.query.await('SELECT * FROM player_housekeys WHERE citizenid=@citizenid',
    {
        ['@citizenid'] = citizenid
    })

    if housekeys[1] == nil then return end

    cb(housekeys)
end)

-- get house keys (guests)
RSGCore.Functions.CreateCallback('rsg-houses:server:GetGuestHouseKeys', function(source, cb)
    local guestinfo = MySQL.query.await('SELECT * FROM player_housekeys WHERE guest=@guest', {['@guest'] = 1})

    if guestinfo[1] == nil then return end

    cb(guestinfo)
end)

-- get house info
RSGCore.Functions.CreateCallback('rsg-houses:server:GetHouseInfo', function(source, cb)
    local houseinfo = MySQL.query.await('SELECT * FROM player_houses', {})

    if houseinfo[1] == nil then return end

    cb(houseinfo)
end)

-- get owned house info
RSGCore.Functions.CreateCallback('rsg-houses:server:GetOwnedHouseInfo', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local houseinfo = MySQL.query.await('SELECT * FROM player_houses WHERE citizenid=@citizenid AND owned=@owned',
    {
        ['@citizenid']  = citizenid,
        ['@owned']      = 1
    })

    if houseinfo[1] == nil then return end

    cb(houseinfo)
end)

-- buy house
RegisterServerEvent('rsg-houses:server:buyhouse', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    local fullname = (firstname..' '..lastname)
    local housecount = MySQL.prepare.await('SELECT COUNT(*) FROM player_houses WHERE citizenid = ?', {citizenid})

    if housecount >= 1 then
        RSGCore.Functions.Notify(src, Lang:t('lang_52'), 'error')
        return
    end

    --if (Player.PlayerData.money.cash < data.price) then
    --    RSGCore.Functions.Notify(src, 'You don\'t have enough cash!', 'error')
    --    return
    --end

    MySQL.update('UPDATE player_houses SET citizenid = ?, fullname = ?, owned = ?, credit = ? WHERE houseid = ?',
    {
        citizenid,
        fullname,
        1,
        Config.StartCredit,
        data.house
    })

    MySQL.insert('INSERT INTO player_housekeys(citizenid, houseid) VALUES(@citizenid, @houseid)',
    {
        ['@citizenid']  = citizenid,
        ['@houseid']    = data.house
    })

    Player.Functions.RemoveMoney('cash', data.price)

    RSGCore.Functions.Notify(src, Lang:t('lang_53'), 'success')

    TriggerClientEvent('rsg-houses:client:BlipsOnSpawn', src, data.blip)
end)

-- sell house
RegisterServerEvent('rsg-houses:server:sellhouse', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    MySQL.update('UPDATE player_houses SET citizenid = 0, fullname = 0, credit = 0, owned = 0 WHERE houseid = ?', {data.house})

    MySQL.update('DELETE FROM player_housekeys WHERE houseid = ?', {data.house})

    Player.Functions.AddMoney('cash', data.price)

    RSGCore.Functions.Notify(src, Lang:t('lang_54'), 'success')

    TriggerClientEvent('rsg-houses:client:BlipsOnSpawn', src, data.blip)
end)
-----------------------------
-- NEW parte TEST NOT FINISH
-----------------------------
-- 
--[[ RSGCore.Functions.CreateCallback('rsg-houses:server:houseshopS', function(source, cb, currenthouseshop)
    MySQL.query('SELECT * FROM player_houses WHERE houseid = ?', {currenthouseshop}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('rsg-houses:server:houseshopWithdraw')
AddEventHandler('rsg-houses:server:houseshopWithdraw', function(location, smoney)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM player_houses WHERE houseid = ?',{location} , function(result)
        if result[1] ~= nil then
            if result[1].money >= tonumber(smoney) then
                local nmoney = result[1].money - smoney
                MySQL.update('UPDATE player_houses SET money = ? WHERE houseid = ?',{nmoney, location})
                Player.Functions.AddMoney('cash', smoney)
            else
                --Notif
            end
        end
    end)
end) ]]
-----------------------

-- add house credit
RegisterNetEvent('rsg-houses:server:addcredit', function(newcredit, removemoney, houseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    --local cashBalance = Player.PlayerData.money["cash"]
    --if cashBalance >= removemoney then
    local cashItem = Player.Functions.GetItemByName("cash")
    if cashItem and cashItem.amount >= removemoney then
        Player.Functions.RemoveItem("cash", removemoney, "land-tax-credit")

        MySQL.update('UPDATE player_houses SET credit = ? WHERE houseid = ?', {newcredit, houseid})

        RSGCore.Functions.Notify(src, Lang:t('lang_55')..houseid, 'success')
        Wait(3000)
        RSGCore.Functions.Notify(src, Lang:t('lang_56')..newcredit, 'primary')
    else
        RSGCore.Functions.Notify(src,  Lang:t('lang_57'), 'error')
    end
end)

-- remove house credit
RegisterNetEvent('rsg-houses:server:removecredit', function(newcredit, removemoney, houseid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local cashItem = Player.Functions.GetItemByName("cash")

    if cashItem and cashItem.amount >= removemoney then
        local updatedCredit = newcredit - removemoney

        if updatedCredit < 0 then
            RSGCore.Functions.Notify(src, Lang:t('lang_58'), 'error')
            return
        end

        Player.Functions.AddItem("cash", removemoney, "land-tax-credit")

        MySQL.update('UPDATE player_houses SET credit = ? WHERE houseid = ?', {updatedCredit, houseid})

        RSGCore.Functions.Notify(src, Lang:t('lang_59')..houseid, 'success')
        Wait(3000)
        RSGCore.Functions.Notify(src, Lang:t('lang_56')..updatedCredit, 'primary')
    else
        RSGCore.Functions.Notify(src, Lang:t('lang_57'), 'error')
    end
end)
--------------------------------------------------------------------------------------------------

-- get all door states
RSGCore.Functions.CreateCallback('rsg-houses:server:GetDoorState', function(source, cb)
    local doorstate = MySQL.query.await('SELECT * FROM doors', {})

    if doorstate[1] == nil then return end

    cb(doorstate)
end)

-- get current door state
RSGCore.Functions.CreateCallback('rsg-houses:server:GetCurrentDoorState', function(source, cb, door)
    local result = MySQL.query.await('SELECT doorstate FROM doors WHERE doorid = ?', {door})

    if result[1] == nil then return end

    cb(result[1].doorstate)
end)

-- get specific door state
RegisterNetEvent('rsg-houses:server:GetSpecificDoorState', function(door)
    local src = source
    local result = MySQL.query.await('SELECT * FROM doors WHERE doorid = ?', {door})

    if result[1] == nil then return end

    local doorid = result[1].doorid
    local doorstate = result[1].doorstate

    if Config.Debug then
        print("")
        print("Door ID: "..doorid)
        print("Door State: "..doorstate)
        print("")
    end

    TriggerClientEvent('rsg-houses:client:GetSpecificDoorState', src, doorid, doorstate)
end)

-- update door state
--[[ RegisterNetEvent('rsg-houses:server:UpdateDoorState', function(doorid, doorstate)
    local src = source

    MySQL.update('UPDATE doors SET doorstate = ? WHERE doorid = ?', {doorstate, doorid})

    TriggerClientEvent('rsg-houses:client:GetSpecificDoorState', src, doorid, doorstate)
end) ]]

RegisterNetEvent('rsg-houses:server:UpdateDoorStateRestart', function()
    local result = MySQL.query.await('SELECT * FROM doors WHERE doorstate=@doorstate', {['@doorstate'] = 1})
    
    if not result then
        MySQL.update('UPDATE doors SET doorstate = 1')
    end
end)

--------------------------------------------------------------------------------------------------

-- land tax billing loop
BillingInterval = function()
    local result = MySQL.query.await('SELECT * FROM player_houses WHERE owned=@owned', {['@owned'] = 1})

    if not result then goto continue end

    for i = 1, #result do
        local row = result[i]

        if Config.Debug then
            print(row.agent, row.houseid, row.citizenid, row.fullname, row.owned, row.price, row.credit)
        end

        if row.credit >= Config.LandTaxPerCycle then
            local creditadjust = (row.credit - Config.LandTaxPerCycle)

            MySQL.update('UPDATE player_houses SET credit = ? WHERE houseid = ? AND citizenid = ?',
            {
                creditadjust,
                row.houseid,
                row.citizenid
            })

            local creditwarning = (Config.LandTaxPerCycle * Config.CreditWarning)

            if row.credit < creditwarning then
                MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
                {
                    row.citizenid,
                    row.fullname,
                    '22222222',
                    'Land Tax Office',
                    'Land Tax Credit Due to Run Out!',
                    os.date("%x"),
                    'Your land tax credit for your house is due to run out!',
                })
            end
        else
            MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {
                row.citizenid,
                row.fullname,
                '22222222',
                'Land Tax Office',
                'Land Tax Credit Ran Out!',
                os.date("%x"),
                'Due to lack of tax credit, your house has been repossessed!',
            })

            Wait(1000)

            MySQL.update('UPDATE player_houses SET citizenid = 0, fullname = 0, owned = 0 WHERE houseid = ?', {row.houseid})

            MySQL.update('DELETE FROM player_housekeys WHERE houseid = ?', {row.houseid})

            if Config.PurgeStorage then
                MySQL.update('DELETE FROM stashitems WHERE stash = ?', {row.houseid})
            end

            TriggerEvent('rsg-log:server:CreateLog', 'estateagent', 'House Lost', 'red', row.fullname..' house '..row.houseid..' has been lost!')
        end

        if row.agent == 'newhanover' then
           exports['rsg-bossmenu']:AddMoney('govenor1', Config.LandTaxPerCycle)
        end

        if row.agent == 'westelizabeth' then
            exports['rsg-bossmenu']:AddMoney('govenor2', Config.LandTaxPerCycle)
        end

        if row.agent == 'newaustin' then
            exports['rsg-bossmenu']:AddMoney('govenor3', Config.LandTaxPerCycle)
        end

        if row.agent == 'ambarino' then
            exports['rsg-bossmenu']:AddMoney('govenor4', Config.LandTaxPerCycle)
        end

        if row.agent == 'lemoyne' then
            exports['rsg-bossmenu']:AddMoney('govenor5', Config.LandTaxPerCycle)
        end
    end

    ::continue::

    print('Land Tax Billing Cycle Complete')

    SetTimeout(Config.BillingCycle * (60 * 60 * 1000), BillingInterval) -- hours
    -- SetTimeout(Config.BillingCycle * (60 * 1000), BillingInterval) -- mins (for testing)
end

SetTimeout(Config.BillingCycle * (60 * 60 * 1000), BillingInterval) -- hours
-- SetTimeout(Config.BillingCycle * (60 * 1000), BillingInterval) -- mins (for testing)

--------------------------------------------------------------------------------------------------

-- add house guest
RegisterNetEvent('rsg-houses:server:addguest', function(cid, houseid)
    local src = source
    local keycount = MySQL.prepare.await('SELECT COUNT(*) FROM player_housekeys WHERE citizenid = ? AND houseid = ?', {cid, houseid})

    if keycount >= 1 then
        RSGCore.Functions.Notify(src, Lang:t('lang_60'), 'error')
        return
    end

    MySQL.insert('INSERT INTO player_housekeys(citizenid, houseid, guest) VALUES(@citizenid, @houseid, @guest)',
    {
        ['@citizenid']  = cid,
        ['@houseid']    = houseid,
        ['@guest']      = 1,
    })

    RSGCore.Functions.Notify(src, cid..Lang:t('lang_61'), 'success')
end)

-- remove house guest
RegisterNetEvent('rsg-houses:server:removeguest', function(data)
    local src = source

    MySQL.update('DELETE FROM player_housekeys WHERE houseid = ? AND citizenid = ?', {data.houseid, data.guestcid})

    RSGCore.Functions.Notify(src, data.guestcid..Lang:t('lang_62'), 'success')
end)
