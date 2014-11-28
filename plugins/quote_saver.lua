function save_quote( text )
  quote = string.match(text, "!addquote (.+)")
  if (quote == nil) then
    return "Usage: !addquote quote"
  end
  table.insert(_quotes, quote)

  local json_text = json:encode_pretty(_quotes)
  file = io.open ("./res/quotes.json", "w+")
  file:write(json_text)
  file:close()

  return "Quote Saved: "..quote
end

function run(msg, matches)
  local text = save_quote(msg.text)
  return text
end

return {
    description = "Save quote",
    usage = "!addquote (quote)",
    patterns = {"^!addquote (.+)$"},
    run = run
}

