site_url = soupault_config["custom_options"]["site_url"]
languages = config["languages"]
default_lang = config["default_lang"]
routes = config["routes"]

function normalized_path(path)
  if path == "/" then
    return path
  end
  return Regex.replace(path, "/$", "")
end

function required_route(page_id, lang)
  route = routes[page_id]
  if route == nil then
    Plugin.fail("Unknown localized page: " .. page_id)
  end

  path = route[lang]
  if path == nil then
    Plugin.fail("Page " .. page_id .. " has no route for language " .. lang)
  end
  return path
end

current_page_id = nil
current_lang = nil
seen_paths = {}

page_ids = Table.keys(routes)
page_idx = 1
while page_ids[page_idx] do
  page_id = page_ids[page_idx]
  route = routes[page_id]
  idx = 1
  while languages[idx] do
    lang = languages[idx]
    path = required_route(page_id, lang)
    normalized = normalized_path(path)
    if seen_paths[normalized] ~= nil then
      Plugin.fail("Localized route " .. path .. " is assigned to both " .. seen_paths[normalized] .. " and " .. page_id)
    end
    seen_paths[normalized] = page_id

    if normalized == normalized_path(page_url) then
      current_page_id = page_id
      current_lang = lang
    end
    idx = idx + 1
  end
  page_idx = page_idx + 1
end

if current_page_id == nil then
  Plugin.fail("Page URL is missing from the localized route table: " .. page_url)
end

html_element = HTML.select_one(page, "html")
HTML.set_attribute(html_element, "lang", current_lang)

localized_copy = HTML.select(page, "[data-language-copy]")
idx = 1
while localized_copy[idx] do
  element = localized_copy[idx]
  lang = HTML.get_attribute(element, "data-language-copy")
  if lang == current_lang then
    HTML.delete_attribute(element, "data-language-copy")
  else
    HTML.delete(element)
  end
  idx = idx + 1
end

localized_attributes = {
  { source = "data-i18n-aria-label", target = "aria-label" },
  { source = "data-i18n-data-tip", target = "data-tip" },
  { source = "data-i18n-copy-label", target = "data-copy-label" },
  { source = "data-i18n-copied-label", target = "data-copied-label" }
}

idx = 1
while localized_attributes[idx] do
  attribute = localized_attributes[idx]
  selector = "[" .. attribute.source .. "-" .. default_lang .. "]"
  elements = HTML.select(page, selector)
  element_idx = 1
  while elements[element_idx] do
    element = elements[element_idx]
    value = HTML.get_attribute(element, attribute.source .. "-" .. current_lang)
    if value == nil then
      Plugin.fail("Missing " .. current_lang .. " value for " .. attribute.source)
    end
    HTML.set_attribute(element, attribute.target, value)

    lang_idx = 1
    while languages[lang_idx] do
      HTML.delete_attribute(element, attribute.source .. "-" .. languages[lang_idx])
      lang_idx = lang_idx + 1
    end
    element_idx = element_idx + 1
  end
  idx = idx + 1
end

route_links = HTML.select(page, "[data-i18n-route]")
idx = 1
while route_links[idx] do
  link = route_links[idx]
  page_id = HTML.get_attribute(link, "data-i18n-route")
  HTML.set_attribute(link, "href", required_route(page_id, current_lang))
  HTML.delete_attribute(link, "data-i18n-route")
  idx = idx + 1
end

language_links = HTML.select(page, "[data-i18n-language]")
idx = 1
while language_links[idx] do
  link = language_links[idx]
  lang = HTML.get_attribute(link, "data-i18n-language")
  HTML.set_attribute(link, "href", required_route(current_page_id, lang))
  HTML.delete_attribute(link, "data-i18n-language")
  if lang == current_lang then
    HTML.set_attribute(link, "aria-current", "page")
  end
  idx = idx + 1
end

head = HTML.select_one(page, "head")
idx = 1
while languages[idx] do
  lang = languages[idx]
  link = HTML.create_element("link")
  HTML.set_attribute(link, "rel", "alternate")
  HTML.set_attribute(link, "hreflang", lang)
  HTML.set_attribute(link, "href", site_url .. required_route(current_page_id, lang))
  HTML.append_child(head, link)
  idx = idx + 1
end

default_link = HTML.create_element("link")
HTML.set_attribute(default_link, "rel", "alternate")
HTML.set_attribute(default_link, "hreflang", "x-default")
HTML.set_attribute(default_link, "href", site_url .. required_route(current_page_id, default_lang))
HTML.append_child(head, default_link)
