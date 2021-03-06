  
function getGoogleImage(text)
  text = URL.escape(text)
  for i = 1, 5, 1 do -- Try 5 times
    local api = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=1&q="
    b = http.request(api..text)
    local google = json:decode(b)

    if (google.responseStatus == 200) then -- OK
      return google.responseData.results[1].url
    end
  end
end

function run(msg, matches)
  local receiver = get_receiver(msg)
  local text = msg.text:sub(6,-1)
  local url = getGoogleImage(text)
  local file_path = download_to_file(url)
  print(file_path)
  search = "search query: " .. text
  send_photo(receiver, file_path, send_title, {receiver, search})
  -- send_photo(receiver, file_path, ok_cb, false)
  return nil
end

return {
    description = "image search by Google API", 
    usage = "!img [topic]",
    patterns = {"^!img (.*)$"}, 
    run = run 
}

