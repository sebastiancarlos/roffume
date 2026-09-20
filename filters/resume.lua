-- resume.lua — pandoc filter: markdown -> resume.ms (groff ms via resume.tmac)
--
-- Design: a single `Pandoc` filter that (1) groups top-level `#` headings
-- and their following blocks into native section Divs, then (2) walks the
-- resulting tree with `traverse = "topdown"`, so each section `Div` is
-- visited before its children and collapses into one `RawBlock` in a single
-- pass.
--
-- The `#` section heading is the container that gives semantic meaning to
-- its content:
--   * `# SKILLS {#skills}` -> the skills layout: each `## Category` heading
--     plus the one comma-separated paragraph that follows it becomes a
--     `.item "Category" "\&" "\&"` followed by `.LP`/`.ps 11`/`.vs 15`.
--   * any other section -> the jobs layout: each `##` heading — `Company | Role`
--     (or just `Company`) — opens an entry, the indented two-line block right
--     after it is the place/dates dateline, and the bullets that follow
--     become `\.list` lines.
--   * The section heading itself becomes `\.section NAME`.
--
-- Other content:
--   * Top-level paragraphs (summary etc.) -> `.PP`.
--   * Empty div class "pagebreak" -> `.bp`.
--   * YAML front matter (name, title, location, email, phone, github,
--     linkedin, hm, fm) feeds the custom ms template.

-- Escape literal characters groff would interpret (e.g. `@` for email).
local function esctxt(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub("@", "\\(at")
  return s
end

local function inlines_to_ms(inls)
  local out = {}
  for _, el in ipairs(inls) do
    if el.t == "Str" then
      out[#out + 1] = esctxt(pandoc.utils.stringify(el))
    elseif el.t == "Space" then
      out[#out + 1] = " "
    elseif el.t == "SoftBreak" then
      out[#out + 1] = " "
    elseif el.t == "Strong" then
      out[#out + 1] = "\\f[B]" .. inlines_to_ms(el.content) .. "\\f[R]"
    elseif el.t == "Emph" then
      out[#out + 1] = "\\f[I]" .. inlines_to_ms(el.content) .. "\\f[R]"
    elseif el.t == "Code" then
      out[#out + 1] = "\\f[CR]" .. el.text .. "\\f[R]"
    elseif el.t == "Link" then
      out[#out + 1] = inlines_to_ms(el.content)
    else
      local s = pandoc.utils.stringify(el)
      if s ~= "" then out[#out + 1] = s end
    end
  end
  return table.concat(out)
end

-- Render a list of blocks; BulletList -> `.list` lines.
local function blocks_to_ms(blocks)
  local out = {}
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      out[#out + 1] = inlines_to_ms(block.content)
    elseif block.t == "BulletList" then
      for _, item in ipairs(block.content) do
        out[#out + 1] = ".list " .. blocks_to_ms(item)
      end
    end
  end
  return table.concat(out, "\n")
end

-- Group top-level H1 headings + following blocks into section Divs. The div
-- inherits the heading's identifier, classes and attributes; the heading is
-- kept as the div's first child.
local function group_into_sections(blocks)
  local out, i, n = {}, 1, #blocks
  while i <= n do
    local b = blocks[i]
    if b.t == "Header" and b.level == 1 then
      local kids, j = { b }, i + 1
      while j <= n and not (blocks[j].t == "Header" and blocks[j].level == 1) do
        kids[#kids + 1] = blocks[j]
        j = j + 1
      end
      local attr = pandoc.Attr(b.identifier, b.classes, b.attributes)
      out[#out + 1] = pandoc.Div(kids, attr)
      i = j
    else
      out[#out + 1] = b
      i = i + 1
    end
  end
  return out
end

-- Any non-skills section -> `.section NAME` + job entries. A `##` heading
-- may pair a company and role with a pipe — `Company | Role` — otherwise the
-- heading is the company alone. The indented two-line code block right after
-- a heading is the dateline (place, then dates); the bullets that follow are
-- `.list` lines.
local function jobs_to_ms(el)
  local out = {}
  local i, n = 1, #el.content
  while i <= n do
    local b = el.content[i]
    if i == 1 then -- the preserved H1 section heading
      out[#out + 1] = ".section " .. inlines_to_ms(b.content)
      i = i + 1
    elseif b.t == "Header" and b.level == 2 then
      local head = pandoc.utils.stringify(b.content)
      local company, role = head:match("^%s*(.-)%s*|%s*(.-)%s*$")
      company = (company or head):gsub("^%s+", ""):gsub("%s+$", "")
      role = role and role:gsub("^%s+", ""):gsub("%s+$", "") or ""
      local place, dates = "", ""
      local has_dateline = el.content[i + 1]
        and el.content[i + 1].t == "CodeBlock"
      if has_dateline then
        place, dates = el.content[i + 1].text:match("^%s*(.-)%s*\n%s*(.-)%s*$")
        place, dates = (place or ""), (dates or "")
      end
      out[#out + 1] = '.item "' .. company .. '" "'
        .. role
        .. (role ~= "" and " \\- " or "")
        .. place .. '" "' .. dates .. '"'
      -- Advance past the dateline only if we actually consumed it; otherwise
      -- the following block (typically the bullet list) must still be visited.
      i = i + (has_dateline and 2 or 1)
    elseif b.t == "BulletList" then
      for _, item in ipairs(b.content) do
        out[#out + 1] = ".list " .. blocks_to_ms(item)
      end
      i = i + 1
    elseif b.t == "Div" and b.classes[1] == "pagebreak" then
      out[#out + 1] = ".bp"
      i = i + 1
    else
      i = i + 1
    end
  end
  return table.concat(out, "\n")
end

-- The skills section (id="skills") -> `.item "Category" "\&" "\&"` +
-- `.LP`/`.ps 11`/`.vs 15` + the comma-separated paragraph per category.
local function skills_to_ms(el)
  local out = {}
  for idx, b in ipairs(el.content) do
    if idx == 1 then -- the preserved H1 heading
      out[#out + 1] = ".section " .. inlines_to_ms(b.content)
    elseif b.t == "Header" then
      out[#out + 1] = '.item "' .. inlines_to_ms(b.content) .. '" "\\&" "\\&"'
    elseif b.t == "Para" or b.t == "Plain" then
      out[#out + 1] = ".LP\n.ps 11\n.vs 15\n" .. inlines_to_ms(b.content)
    end
  end
  return table.concat(out, "\n")
end

local filter = {
  traverse = "topdown",

  Para = function(el)
    return pandoc.RawBlock("ms", ".PP\n" .. inlines_to_ms(el.content))
  end,

  Div = function(el)
    if el.classes[1] == "pagebreak" then
      return pandoc.RawBlock("ms", ".bp"), false
    elseif el.content[1] and el.content[1].t == "Header" and el.content[1].level == 1 then
      if el.identifier == "skills" then
        return pandoc.RawBlock("ms", skills_to_ms(el)), false
      end
      return pandoc.RawBlock("ms", jobs_to_ms(el)), false
    end
  end,
}

return {
  Pandoc = function(doc)
    doc.blocks = group_into_sections(doc.blocks)
    return doc:walk(filter)
  end,
}