local function customCallouts(div)
  if div.attr.classes:find_if(function (c)
    local baseCallouts = pandoc.List({"note", "warning", "important","tip", "caution"})
    local calloutClass = string.match(c, "callout[-](.*)")
    if calloutClass == nil then
      return false
    elseif baseCallouts:includes(calloutClass) then
      return false
    else
      return true
    end
  end) then
    local calloutClass = ""
    div.attr.classes:find_if(function (c)
      calloutClass = string.match(c, "callout[-](.*)")
    end)
    
    local title = markdownToInlines(div.attr.attributes["title"])
    if not title or #title == 0 then
      title = resolveHeadingCaption(div)
    end
    local calloutDiv = {}
    calloutDiv["type"] = calloutClass
    calloutDiv["icon"] = true
    calloutDiv["title"] = title
    calloutDiv["content"] = div.content
    
    calloutOut = quarto.Callout(calloutDiv)
    
    return calloutOut
  end
end

function resolveHeadingCaption(div) 
  local capEl = div.content[1]
  if capEl ~= nil and capEl.t == 'Header' then
    div.content:remove(1)
    return capEl.content
  else 
    return nil
  end
end

function markdownToInlines(str)
  if str then
    local doc = pandoc.read(str)
    if #doc.blocks == 0 then
      return pandoc.List({})
    else
      return doc.blocks[1].content
    end
  else
    return pandoc.List()
  end
end

return {
  {Div = customCallouts}
}