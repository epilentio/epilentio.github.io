-- i18n.lua
-- Sets lang attribute and adds hreflang tags

site_url = soupault_config["custom_options"]["site_url"]
languages = config["languages"]
default_lang = config["default_lang"]

-- Extract the current language from the URL
current_lang = default_lang
idx = 1
while languages[idx] do
  lang = languages[idx]
  if lang ~= default_lang then
    pattern = "^/" .. lang .. "(/|$)"
    if Regex.match(page_url, pattern) then
      current_lang = lang
    end
  end
  idx = idx + 1
end

-- Set the lang attribute in the <html> element
html_element = HTML.select_one(page, "html")
if html_element then
  HTML.set_attribute(html_element, "lang", current_lang)
end

-- Build regex pattern for removing language prefix from the configured languages
-- Needed to construct the default language's hreflang link
lang_pattern_inner = ""
idx = 1
while languages[idx] do
  if languages[idx] ~= default_lang then
    if lang_pattern_inner ~= "" then
      lang_pattern_inner = lang_pattern_inner .. "|"
    end
    lang_pattern_inner = lang_pattern_inner .. languages[idx]
  end
  idx = idx + 1
end
lang_pattern = "^/(" .. lang_pattern_inner .. ")(/|$)"
relative_path = Regex.replace(page_url, lang_pattern, "/")

-- Build hreflang links
head = HTML.select_one(page, "head")
if head then
  idx = 1
  while languages[idx] do
    lang = languages[idx]
    link = HTML.create_element("link")
    HTML.set_attribute(link, "rel", "alternate")
    HTML.set_attribute(link, "hreflang", lang)
    if lang == default_lang then
      HTML.set_attribute(link, "href", site_url .. relative_path)
    else
      HTML.set_attribute(link, "href", site_url .. "/" .. lang .. relative_path)
    end
    HTML.append_child(head, link)
    idx = idx + 1
  end

  default_link = HTML.create_element("link")
  HTML.set_attribute(default_link, "rel", "alternate")
  HTML.set_attribute(default_link, "hreflang", "x-default")
  HTML.set_attribute(default_link, "href", site_url .. relative_path)
  HTML.append_child(head, default_link)
end
