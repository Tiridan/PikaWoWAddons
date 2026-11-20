function PikaImportArkLing()
    local source=ArkInventoryLingDB;
    if type(source)~="table" then return; end
    PikaBankViewerDB=PikaBankViewerDB or {};
    local target=PikaBankViewerDB;
    if target.importedArkLing then return; end
    local function copy(value,seen)
        if type(value)~="table" then return value; end
        seen=seen or {}; if seen[value] then return seen[value]; end
        local result={}; seen[value]=result;
        for key,child in pairs(value) do result[key]=copy(child,seen); end
        return result;
    end
    local function stamp(value)
        return math.max(tonumber(value and value.updatedAt) or 0,tonumber(value and value.scannedAt) or 0,tonumber(value and value.viewerUpdatedAt) or 0);
    end
    for key,value in pairs(source) do if target[key]==nil then target[key]=copy(value); end end
    target.reagentSearchBanks=target.reagentSearchBanks or {};
    for key,bank in pairs(source.reagentSearchBanks or {}) do
        if not target.reagentSearchBanks[key] or stamp(bank)>=stamp(target.reagentSearchBanks[key]) then
            target.reagentSearchBanks[key]=copy(bank);
        end
    end
    target.characters=target.characters or {};
    for key,character in pairs(source.characters or {}) do
        target.characters[key]=target.characters[key] or {};
        local current=target.characters[key];
        for field,value in pairs(character) do if current[field]==nil then current[field]=copy(value); end end
        if character.bank and stamp(character.bank)>=stamp(current.bank) then current.bank=copy(character.bank); end
    end
    target.importedArkLing=true;
end
