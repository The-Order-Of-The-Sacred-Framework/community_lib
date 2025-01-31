Logs = Logs or {}

local WebhookURL = ""
local LogoForEmbed = ""

Logs.Send = function(src, message)
    if not src or not message then return end
    if BridgeServerConfig.LogSystem == "builtin" then
        PerformHttpRequest(WebhookURL, function(err, text, headers) end, 'POST', json.encode(
        {
            username = "Community_Bridge's Logger",
            avatar_url = 'https://cdn.discordapp.com/avatars/299410129982455808/31ce635662206e8bd0132c34ce9ce683?size=1024',
            embeds = {
                {
                    color = "15769093",
                    title = GetCurrentResourceName(),
                    url = 'https://discord.gg/wsPAK5mEPg',
                    --description = message,
                    thumbnail = { url = LogoForEmbed },
                    fields = {
                        {
                            name = '**Player ID**',
                            value = src,
                            inline = true,
                        },
                        {
                            name = '**Player Identifier**',
                            value = Framework.GetPlayerIdentifier(src),
                            inline = true,
                        },
                        {
                            name = 'Log Message',
                            value = "```"..message.."```",
                            inline = false,
                        },
                    },
                    timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
                    footer = {
                        text = "Community_Bridge | "..GetCurrentResourceName(),
                        icon_url = 'https://cdn.discordapp.com/avatars/299410129982455808/31ce635662206e8bd0132c34ce9ce683?size=1024',
                    },
                }
            }
        }), { ['Content-Type']= 'application/json' })
    elseif BridgeServerConfig.LogSystem == "qb" then
        return TriggerEvent('qb-log:server:CreateLog', GetCurrentResourceName(), GetCurrentResourceName(), 'green', message)
    elseif BridgeServerConfig.LogSystem == "ox" then
        return exports.ox_lib:logger(src, GetCurrentResourceName(), message)
    end
end

exports('Logs', Logs)
return Logs