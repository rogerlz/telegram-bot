local f = io.open('./res/quotes.json', "r+")
if f == nil then
  f = io.open('./res/quotes.json', "w+")
  f:write("{}") -- Write empty table
  f:close()
  _quotes = {}
else
  local c = f:read "*a"
  f:close()
  _quotes = json:decode(c)
end

function get_quote()
  print(_quotes[1])
  quote = _quotes[math.random(1,#_quotes)]
  print(quote)
  return quote
end

function run(msg, matches)
  return get_quote()
end

return {
    description = "retrieves random quotes",
    usage = "!quote",
    patterns = {
      "^!quote$"},
    run = run
}
