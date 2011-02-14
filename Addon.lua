local addonName, ns = ...
local buffsize = 12 -- # items to show in the tooltip
	
local debugf = nil -- tekDebug and tekDebug:GetFrame(addonName)
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end

---------------------------------------------------------------------------
-- Addon event frame
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, addon)
	if addon ~= addonName then return end
	LibStub("tekKonfig-AboutPanel").new(nil, addonName)
	self:UnregisterEvent("ADDON_LOADED")
end)
f:RegisterEvent("ADDON_LOADED")

---------------------------------------------------------------------------
-- Fixed size queue to hold the messages for the tooltip --
---------------------------------------------------------------------------
local lastGuid
local messages = {}
local function LogMessage(sender, msg, guid)
	if guid == lastGuid then return else lastGuid = guid end
	table.insert(messages, {time(), sender, msg})
	while #messages > buffsize do
		table.remove(messages, 1)
	end
end

---------------------------------------------------------------------------
-- Chat filter for Trade channel
---------------------------------------------------------------------------
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(self, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
	if string.find(channelName, "Trade") then
		Debug("Trade message found: " ..message)
		if string.find(message, "|%x+|Hitem:.-|h.-|h|r") then
			LogMessage(sender, message, guid)
			return false
		else
			-- no match, kick it
			return true
		end
	else
		Debug("Non-trade message found: " .. message)
		return false
	end
end)

---------------------------------------------------------------------------
-- LDB Provider
---------------------------------------------------------------------------
local ldb = LibStub("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName(addonName) or ldb:NewDataObject(addonName, {
	type = "data source",
	text = "Trade Links",
	icon = [[Interface\Icons\INV_Misc_Coin_04]],
})

dataobj.OnTooltipShow = function(tooltip)
	tooltip:AddLine("SimpleTradeLinks")

	for idx, message in ipairs(messages) do
		tooltip:AddLine(string.format("%s[%s]: %s", date("%H:%M ", message[1]), message[2], message[3]), 0.9, 0.9, 0.9)
	end

	if #messages <= 0 then
		tooltip:AddLine("No links found")
	end
end

