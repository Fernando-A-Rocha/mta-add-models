-- Used in https://github.com/Fernando-A-Rocha/mta-add-models
-- https://github.com/inlife/mta-lua-async

local function loadClass()
    ---------
    -- Start of slither.lua dependency
    ---------

    local _LICENSE = -- zlib / libpng
    [[
    Copyright (c) 2011-2014 Bart van Strien

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

      1. The origin of this software must not be misrepresented; you must not
      claim that you wrote the original software. If you use this software
      in a product, an acknowledgment in the product documentation would be
      appreciated but is not required.

      2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original software.

      3. This notice may not be removed or altered from any source
      distribution.
    ]]

    local class =
    {
        _VERSION = "Slither 20140904",
        -- I have no better versioning scheme, deal with it
        _DESCRIPTION = "Slither is a pythonic class library for lua",
        _URL = "http://bitbucket.org/bartbes/slither",
        _LICENSE = _LICENSE,
    }

    local function stringtotable(path)
        local t = _G
        local name

        for part in path:gmatch("[^%.]+") do
            t = name and t[name] or t
            name = part
        end

        return t, name
    end

    local function class_generator(name, b, t)
        local parents = {}
        for _, v in ipairs(b) do
            parents[v] = true
            for _, v in ipairs(v.__parents__) do
                parents[v] = true
            end
        end

        local temp = { __parents__ = {} }
        for i, v in pairs(parents) do
            table.insert(temp.__parents__, i)
        end

        local class = setmetatable(temp, {
            __index = function(self, key)
                if key == "__class__" then return temp end
                if key == "__name__" then return name end
                if t[key] ~= nil then return t[key] end
                for i, v in ipairs(b) do
                    if v[key] ~= nil then return v[key] end
                end
                if tostring(key):match("^__.+__$") then return end
                if self.__getattr__ then
                    return self:__getattr__(key)
                end
            end,

            __newindex = function(self, key, value)
                t[key] = value
            end,

            allocate = function(instance)
                local smt = getmetatable(temp)
                local mt = {__index = smt.__index}

                function mt:__newindex(key, value)
                    if self.__setattr__ then
                        return self:__setattr__(key, value)
                    else
                        return rawset(self, key, value)
                    end
                end

                if temp.__cmp__ then
                    if not smt.eq or not smt.lt then
                        function smt.eq(a, b)
                            return a.__cmp__(a, b) == 0
                        end
                        function smt.lt(a, b)
                            return a.__cmp__(a, b) < 0
                        end
                    end
                    mt.__eq = smt.eq
                    mt.__lt = smt.lt
                end

                for i, v in pairs{
                    __call__ = "__call", __len__ = "__len",
                    __add__ = "__add", __sub__ = "__sub",
                    __mul__ = "__mul", __div__ = "__div",
                    __mod__ = "__mod", __pow__ = "__pow",
                    __neg__ = "__unm", __concat__ = "__concat",
                    __str__ = "__tostring",
                    } do
                    if temp[i] then mt[v] = temp[i] end
                end

                return setmetatable(instance or {}, mt)
            end,

            __call = function(self, ...)
                local instance = getmetatable(self).allocate()
                if instance.__init__ then instance:__init__(...) end
                return instance
            end
            })

        for i, v in ipairs(t.__attributes__ or {}) do
            class = v(class) or class
        end

        return class
    end

    local function inheritance_handler(set, name, ...)
        local args = {...}

        for i = 1, select("#", ...) do
            if args[i] == nil then
                error("nil passed to class, check the parents")
            end
        end

        local t = nil
        if #args == 1 and type(args[1]) == "table" and not args[1].__class__ then
            t = args[1]
            args = {}
        end

        for i, v in ipairs(args) do
            if type(v) == "string" then
                local t, name = stringtotable(v)
                args[i] = t[name]
            end
        end

        local func = function(t)
            local class = class_generator(name, args, t)
            if set then
                local root_table, name = stringtotable(name)
                root_table[name] = class
            end
            return class
        end

        if t then
            return func(t)
        else
            return func
        end
    end

    function class.private(name)
        return function(...)
            return inheritance_handler(false, name, ...)
        end
    end

    class = setmetatable(class, {
        __call = function(self, name)
            return function(...)
                return inheritance_handler(true, name, ...)
            end
        end,
    })


    function class.issubclass(class, parents)
        if parents.__class__ then parents = {parents} end
        for i, v in ipairs(parents) do
            local found = true
            if v ~= class then
                found = false
                for _, p in ipairs(class.__parents__) do
                    if v == p then
                        found = true
                        break
                    end
                end
            end
            if not found then return false end
        end
        return true
    end

    function class.isinstance(obj, parents)
        return type(obj) == "table" and obj.__class__ and class.issubclass(obj.__class__, parents)
    end

    -- Export a Class Commons interface
    -- to allow interoperability between
    -- class libraries.
    -- See https://github.com/bartbes/Class-Commons
    --
    -- NOTE: Implicitly global, as per specification, unfortunately there's no nice
    -- way to both provide this extra interface, and use locals.
    if common_class ~= false then
        common = {}
        function common.class(name, prototype, superclass)
            prototype.__init__ = prototype.init
            return class_generator(name, {superclass}, prototype)
        end

        function common.instance(class, ...)
            return class(...)
        end
    end

    ---------
    -- End of slither.lua dependency
    ---------

    return class;
end

local class = loadClass();

--- GTA:MTA Lua async thread scheduler.
-- @author Inlife
-- @license MIT
-- @url https://github.com/Inlife/mta-lua-async
-- @dependency slither.lua https://bitbucket.org/bartbes/slither

class "_Async" {
    
    -- Constructor mehtod
    -- Starts timer to manage scheduler
    -- @access public
    -- @usage local asyncmanager = async();
    __init__ = function(self)

        self.threads = {};
        self.resting = 50; -- in ms (resting time)
        self.maxtime = 200; -- in ms (max thread iteration time)
        self.current = 0;  -- starting frame (resting)
        self.state = "suspended"; -- current scheduler executor state
        self.debug = false;
        self.priority = {
            low = {500, 50},     -- better fps
            normal = {200, 200}, -- medium
            high = {50, 500}     -- better perfomance
        };

        self:setPriority("normal");
    end,


    -- Switch scheduler state
    -- @access private
    -- @param boolean [istimer] Identifies whether or not 
        -- switcher was called from main loop
    switch = function(self, istimer)
        self.state = "running";

        if (self.current + 1  <= #self.threads) then
            self.current = self.current + 1;
            self:execute(self.current);
        else
            self.current = 0;

            if (#self.threads <= 0) then
                self.state = "suspended";
                return;
            end

            -- setTimer(function theFunction, int timeInterval, int timesToExecute) 
            -- (GTA:MTA server scripting function)
            -- For other environments use alternatives.
            setTimer(function() 
                self:switch();
            end, self.resting, 1);
        end
    end,


    -- Managing thread (resuming, removing)
    -- In case of "dead" thread, removing, and skipping to the next (recursive)
    -- @access private
    -- @param int id Thread id (in table async.threads)
    execute = function(self, id)
        local thread = self.threads[id];

        if (thread == nil or coroutine.status(thread) == "dead") then
            table.remove(self.threads, id);
            self:switch();
        else
            coroutine.resume(thread);
            self:switch();
        end
    end,


    -- Adding thread
    -- @access private
    -- @param function func Function to operate with
    add = function(self, func)
        local thread = coroutine.create(func);
        table.insert(self.threads, thread);
    end,


    -- Set priority for executor
    -- Use before you call 'iterate' or 'foreach' 
    -- @access public
    -- @param string|int param1 "low"|"normal"|"high" or number to set 'resting' time
    -- @param int|void param2 number to set 'maxtime' of thread
    -- @usage async:setPriority("normal");
    -- @usage async:setPriority(50, 200);
    setPriority = function(self, param1, param2)
        if (type(param1) == "string") then
            if (self.priority[param1] ~= nil) then
                self.resting = self.priority[param1][1];
                self.maxtime = self.priority[param1][2];
            end
        else
            self.resting = param1;
            self.maxtime = param2;
        end
    end,

    -- Set debug mode enabled/disabled
    -- @access public
    -- @param boolean value true - enabled, false - disabled
    -- @usage async:setDebug(true);
    setDebug = function(self, value)
        self.debug = value;
    end,


    -- Iterate on interval (for cycle)
    -- @access public
    -- @param int from Iterate from
    -- @param int to Iterate to
    -- @param function func Iterate using func
        -- Function func params:
        -- @param int [i] Iteration index
    -- @param function [callback] Callback function, called when execution finished
    -- Usage:
        -- @usage async:iterate(1, 10000, function(i)
        --     outputDebugString(i);
        -- end);
    iterate = function(self, from, to, func, callback)
        self:add(function()
            local a = getTickCount();
            local lastresume = getTickCount();
            for i = from, to do
                func(i); 

                -- int getTickCount() 
                -- (GTA:MTA server scripting function)
                -- For other environments use alternatives.
                if getTickCount() > lastresume + self.maxtime then
                    coroutine.yield()
                    lastresume = getTickCount()
                end
            end
            if (self.debug) then
                outputDebugString("[DEBUG]Async iterate: " .. (getTickCount() - a) .. "ms");
            end
            if (callback) then
                callback();
            end
        end);

        self:switch();
    end,

    -- Iterate over array (foreach cycle)
    -- @access public
    -- @param table array Input array
    -- @param function func Iterate using func
        -- Function func params:
        -- @param int [v] Iteration value
        -- @param int [k] Iteration key
    -- @param function [callback] Callback function, called when execution finished
    -- Usage:
        -- @usage async:foreach(vehicles, function(vehicle, id)
        --     outputDebugString(vehicle.title);
        -- end);
    foreach = function(self, array, func, callback)
        self:add(function()
            local a = getTickCount();
            local lastresume = getTickCount();
            for k,v in ipairs(array) do
                func(v,k);

                -- int getTickCount() 
                -- (GTA:MTA server scripting function)
                -- For other environments use alternatives.
                if getTickCount() > lastresume + self.maxtime then
                    coroutine.yield()
                    lastresume = getTickCount()
                end
            end
            if (self.debug) then
                outputDebugString("[DEBUG]Async foreach: " .. (getTickCount() - a) .. "ms");
            end
            if (callback) then
                callback();
            end
        end);

        self:switch();
    end,
}

-- Async Singleton wrapper
Async = {
    instance = nil,
};

-- After first call, creates an instance and stores it
local function getInstance()
    if Async.instance == nil then
        Async.instance = _Async();
    end

    return Async.instance; 
end

-- proxy methods for public members
function Async:setDebug(...)
    getInstance():setDebug(...);
end

function Async:setPriority(...)
    getInstance():setPriority(...);
end

function Async:iterate(...)
    getInstance():iterate(...);
end

function Async:foreach(...)
    getInstance():foreach(...);
end
