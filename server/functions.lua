logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end