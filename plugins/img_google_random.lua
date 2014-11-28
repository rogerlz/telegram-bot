  
function getGoogleImage(text)
  text = URL.escape(text)
  for i = 1, 5, 1 do -- Try 5 times
    local api = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&q="
    b = http.request(api..text)
    local google = json:decode(b)

    if (google.responseStatus == 200) then -- OK
      math.randomseed(os.time())
      i = math.random(#google.responseData.results) -- Random image from results
      return google.responseData.results[i].url
    end
  end
end

function run(msg, matches)
  local receiver = get_receiver(msg)
  local text = msg.text:sub(6,-1)
  local url = getGoogleImage(text)
  local file_path = download_to_file(url)
  print(file_path)
  send_photo(receiver, file_path, ok_cb, false)
  return nil
end

return {
    description = "random image search by Google API", 
    usage = "!img_random [topic]",
    patterns = {"^!img_random (.*)$"}, 
    run = run 
}

