function getDDG(text)
  local topic = string.match(text, "!ddg (.+)")
  topic = url_encode(topic)
  b = http.request("http://api.duckduckgo.com/?format=json&q=" .. topic)
  res = json:decode(b)
  local definition = nil
  if #res.RelatedTopics > 0 then
    definition = res.Heading..": "..res.RelatedTopics[1].Text.."\n".. res.RelatedTopics[1].FirstURL
  else
    definition = nil
  end
  return definition
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

function run(msg, matches)
  local text = getDDG(msg.text)
  if (text == nil) then
    return "Zzzzz..."
  else
    return text
  end
end

return {
    description = "get duck duck go instant result",
    usage = "!ddg [topic]",
    patterns = {"^!ddg (.*)$"},
    run = run
}

