
function run(msg, matches)
  return 'Telegram Bot '.. VERSION .. [[ by roge
  Github http://git.io/o7priw ]] 
end

return {
    description = "Shows bot version", 
    usage = "!version",
    patterns = {"^!version$"}, 
    run = run 
}

