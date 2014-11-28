  http = require("socket.http")
  https = require("ssl.https")
  URL = require("socket.url")
  json = (loadfile "./bot/JSON.lua")()

  VERSION = 'v0.7.5'
  
  -- taken from http://stackoverflow.com/a/11130774/3163199
  function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    for filename in popen('ls -a "'..directory..'"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
  end
  
  function on_msg_receive (msg)
    vardump(msg)

    if msg_valid(msg) == false then
      return
    end

    update_user_stats(msg)
    do_action(msg)

    mark_read(get_receiver(msg), ok_cb, false)
  end

  function ok_cb(extra, success, result)
  end

  -- Callback to remove tmp files
  function rmtmp_cb(file_path, success, result)
     os.remove(file_path)
  end

  function msg_valid(msg)
    local allowedchat=false
    for v,chat in pairs(config.allowed_chats) do 
        if chat == msg.to.id then 
          allowedchat=true
        end
    end
    if not allowedchat then
      print("add "..msg.to.id.." to config.allowed_chats")
      return false
    end 
    if msg.text == nil then
      return false
    end
    --if msg.from.id == our_id then
    --  return false
    --end
    if msg.out then
      return false
    end
    if msg.date < now then
      return false
    end
    if msg.text == nil then
      return false
    end
    if msg.unread == 0 then
      return false
    end
  end

  -- Where magic happens
  function do_action(msg)
    local receiver = get_receiver(msg)
    local text = msg.text
    -- print("Received msg", text)
    for name, desc in pairs(plugins) do
      -- print("Trying module", name)
      for k, pattern in pairs(desc.patterns) do
        -- print("Trying", text, "against", pattern)
        matches = { string.match(text, pattern) }
        if matches[1] then
          print("  matches",pattern)
          result = desc.run(msg, matches)
          print("  sending", result)
          if (result) then
            send_msg(receiver, result, ok_cb, false)
            return
          end
        end
      end
    end
  end

function string.starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
  return End=='' or string.sub(String,-string.len(End))==End
end

  function load_config()
     local f = assert(io.open('./bot/config.json', "r"))
     local c = f:read "*a"
     local config = json:decode(c)
     if config.sh_enabled then 
        print ("!sh command is enabled")
        for v,user in pairs(config.sudo_users) do
           print("Allowed user: " .. user)
        end
     end
     -- print("Torrent path: " .. config.torrent_path)
     f:close()
     return config
  end

  function is_sudo(msg)
     local var = false
     -- Check users id in config 
     for v,user in pairs(config.sudo_users) do 
        if user == msg.from.id then 
           var = true 
        end
     end
     return var
  end

  function get_name(msg)
     local name = msg.from.first_name
     if name == nil then
        name = msg.from.id
     end
     return name
  end

  function run_sh(msg)
     name = get_name(msg)
     text = ''
     if config.sh_enabled == false then 
        text = '!sh command is disabled'
     else
        if is_sudo(msg) then
           bash = msg.text:sub(4,-1)
           text = run_bash(bash)
        else
           text = name .. ' you have no power here!'
        end
     end
     return text
  end

  function run_bash(str)
    local cmd = io.popen(str)
    local result = cmd:read('*all')
    cmd:close()
    return result
  end

  function download_to_file( url , noremove )
    print("url to download: "..url)
    req, c, h = http.request(url)
    htype = h["content-type"]
    vardump(c)
    print("content-type: "..htype)
    if htype == "image/jpeg" then
      file_name = string.random(5)..".jpg"
      file_path = "/tmp/"..file_name
    else
      if htype == "image/gif" then
        file_name = string.random(5)..".gif"
        file_path = "/tmp/"..file_name
      else
        if htype == "image/png" then
          file_name = string.random(5)..".png"
          file_path = "/tmp/"..file_name
        else
          file_name = url:match("([^/]+)$")
          file_path = "/tmp/"..file_name
        end
      end
    end
    file = io.open(file_path, "w+")
    file:write(req)
    file:close()

    if noremove == nil then
       postpone(rmtmp_cb, file_path, config.rmtmp_delay)
    end

    return file_path
  end

  function string.random(length)
     math.randomseed(os.time())
     local str = "";
     for i = 1, length do
        math.random(97, 122)
        str = str..string.char(math.random(97, 122));
     end
     return str;
  end

  function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
  end

  function vardump(value, depth, key)
    local linePrefix = ""
    local spaces = ""
    
    if key ~= nil then
      linePrefix = "["..key.."] = "
    end
    
    if depth == nil then
      depth = 0
    else
      depth = depth + 1
      for i=1, depth do spaces = spaces .. "  " end
    end
    
    if type(value) == 'table' then
      mTable = getmetatable(value)
      if mTable == nil then
        print(spaces ..linePrefix.."(table) ")
      else
        print(spaces .."(metatable) ")
          value = mTable
      end		
      for tableKey, tableValue in pairs(value) do
        vardump(tableValue, depth, tableKey)
      end
    elseif type(value)	== 'function' or 
        type(value)	== 'thread' or 
        type(value)	== 'userdata' or
        value		== nil
    then
      print(spaces..tostring(value))
    else
      print(spaces..linePrefix.."("..type(value)..") "..tostring(value))
    end
  end

  function update_user_stats(msg)
     -- Save user to _users table
    local from_id = tostring(msg.from.id)
    local user_name = get_name(msg)
    -- If last name is nil dont save last_name.
    local user_last_name = msg.from.last_name
    local user_print_name = msg.from.print_name
    print ("user_last_name", user_last_name)
    if _users[from_id] == nil then
      _users[from_id] = {
        name = user_name,
        last_name = user_last_name,
        print_name = user_print_name,
        msg_num = 1
      }
    else
      local actual_num = _users[from_id].msg_num
      _users[from_id].msg_num = actual_num + 1
      -- And update last_name
      _users[from_id].last_name = user_last_name
    end
  end

  function load_user_stats()
    local f = io.open('res/users.json', "r+")
    -- If file doesn't exists
    if f == nil then
      f = io.open('res/users.json', "w+")
      f:write("{}") -- Write empty table
      f:close()
      return {}
    else
      local c = f:read "*a"
      f:close()
      return json:decode(c)
    end
  end

  function get_receiver(msg)
    if msg.to.type == 'user' then
      return 'user#id'..msg.from.id
    end
    if msg.to.type == 'chat' then
      return 'chat#id'..msg.to.id
    end
  end

  function on_our_id (id)
    our_id = id
  end

  function on_user_update (user, what)
    --vardump (user)
  end

  function on_chat_update (chat, what)
    --vardump (chat)
  end

  function on_secret_chat_update (schat, what)
    --vardump (schat)
  end

  function on_get_difference_end ()
  end

  function on_binlog_replay_end ()
    started = 1
  end

  -- Start and load values
  config = load_config()
  _users = load_user_stats()
  our_id = 0
  now = os.time()

  -- load plugins
  plugins = {}

  -- load all plugins in the plugins/ directory
  for k, v in pairs(scandir("plugins")) do 
    if not (v:sub(0, 1) == ".") then
        print("Loading plugin", v)
        t = loadfile("plugins/" .. v)()
        table.insert(plugins, t)
    end 
  end

