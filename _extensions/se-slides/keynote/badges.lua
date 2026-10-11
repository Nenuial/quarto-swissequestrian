-- Licence and AI declaration badges on the title slide, as on the GeoDoc documents (GeoDoc
-- badges extension). Metadata, e.g. in the project's _quarto.yml:
--
--   cc: by-nc-sa        Creative Commons licence (icon available: by-nc-sa)
--   ai: cyborg          Me & My Machine label (https://mmmlabel.tech/):
--                       manmade | handyman | cyborg | piggybacker | lazyprompter
--   licence-url: https://df.geoviews.ch/licence.html
--                       page that explains both; the badges link to #licence and #ia
--
-- Nothing without cc or ai. The badges go after the slides (.title-badges); theme.html moves them
-- next to the logo and shows them on the title slide only, not inside an iframe.

local AI_LABELS = {
  manmade = { fr = "Réalisé sans IA générative", en = "Made without generative AI" },
  handyman = { fr = "Assisté par l'IA générative", en = "Assisted by generative AI" },
  cyborg = { fr = "Réalisé avec l'IA générative", en = "Made together with generative AI" },
  piggybacker = { fr = "Principalement réalisé par l'IA générative", en = "Mostly made by generative AI" },
  lazyprompter = { fr = "Réalisé par l'IA générative", en = "Made by generative AI" },
}

local CC_LABELS = {
  ["by-nc-sa"] = "CC BY-NC-SA 4.0",
}

local function setting(meta, key)
  return meta[key] and pandoc.utils.stringify(meta[key]) or nil
end

local function dataUri(name)
  local file = assert(io.open(quarto.utils.resolve_path("badges/" .. name .. ".svg"), "rb"))
  local content = file:read("a")
  file:close()
  return "data:image/svg+xml;base64," .. quarto.base64.encode(content)
end

local function escape(s)
  return (s:gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"))
end

local function Meta(meta)
  if not quarto.doc.is_format("revealjs") then
    return nil
  end
  local cc, ai = setting(meta, "cc"), setting(meta, "ai")
  if cc and not CC_LABELS[cc] then
    quarto.log.warning("badges: no icon for licence '" .. cc .. "'")
    cc = nil
  end
  if ai and not AI_LABELS[ai] then
    quarto.log.warning("badges: unknown AI label '" .. ai .. "'")
    ai = nil
  end
  if not cc and not ai then
    return nil
  end

  local lang = (setting(meta, "lang") or "fr"):sub(1, 2) == "en" and "en" or "fr"
  local url = setting(meta, "licence-url")
  local items = {}
  if cc then
    table.insert(items, { icon = "cc-" .. cc, anchor = "#licence", class = "cc",
      text = (lang == "fr" and "Licence " or "License ") .. CC_LABELS[cc] })
  end
  if ai then
    table.insert(items, { icon = "mmm-" .. ai, anchor = "#ia", class = "ai", text = AI_LABELS[ai][lang] })
  end

  local html = { '<div class="title-badges">' }
  for _, item in ipairs(items) do
    local img = '<img class="' .. item.class .. '" src="' .. dataUri(item.icon) .. '" alt="' .. escape(item.text)
      .. '" title="' .. escape(item.text) .. '">'
    if url then
      img = '<a href="' .. escape(url .. item.anchor) .. '" target="_blank" rel="noopener">' .. img .. "</a>"
    end
    table.insert(html, img)
  end
  table.insert(html, "</div>")
  quarto.doc.include_text("after-body", table.concat(html))
  return nil
end

return { { Meta = Meta } }
