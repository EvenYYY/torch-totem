-- Defines a totem.Tester class. This is the main object of the totem tester.

local lapp = require 'pl.lapp'

local c = {} -- dummy colour list

local NCOLS = 80
--[[ totem Tester class.

This class defines all the basic testing utilities provided by the totem
package.

Arguments: No arguments.
]]
local Tester = torch.class('totem.Tester')

function Tester:__init()
    self.errors = {}
    self.tests = {}
    self.curtestname = ''
end


-- Add a success to the test
function Tester:_success()
    self.countasserts = self.countasserts + 1
    local name = self.curtestname
    self.assertionPass[name] = self.assertionPass[name] + 1
    return true
end


-- Add a failure to the test
function Tester:_failure(message)
    self.countasserts = self.countasserts + 1
    local name = self.curtestname
    self.assertionFail[name] = self.assertionFail[name] + 1
    local ss = debug.traceback('tester',2) or ''
    ss = ss:match('.-\n([^\n]+\n[^\n]+)\n[^\n]+xpcall') or ''
    if type(message) == 'function' then
        message = message()
    end
    if message then
        self.errors[#self.errors+1] = self.curtestname .. '\n' .. message .. '\n' .. ss .. '\n'
    else
        self.errors[#self.errors+1] = self.curtestname .. '\n' .. ss .. '\n'
    end
    return false
end


--[[

Arguments:

- `condition` (boolean)
- `message` (string or function : nil → string)

]]
function Tester:_assert_sub (condition, message)
    if condition then
        return self:_success(message)
    else
        return self:_failure(message)
    end
end


--[[ Asserts that a condition holds true.

Arguments:

* `condition` (boolean) the condition to be evaluated.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assert(condition, message)
    return self:_assert_sub(condition,
            string.format('%s\n%s  condition=%s', message, ' BOOL violation ',
                tostring(condition)))
end


--[[ Asserts that the value of a variable is less than a threshold.

Arguments:

* `val` (number) the variable to be evaluated.
* `condition` (number) the threshold that `val` is compared against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertlt(val, condition, message)
    return self:_assert_sub(val < condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' LT(<) violation ',
                tostring(val), tostring(condition)))
end


--[[ Asserts that the value of a variable is greater than a threshold.

Arguments:

* `val` (number) the variable to be evaluated.
* `condition` (number) the threshold that `val` is compared against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertgt(val, condition, message)
   return self:_assert_sub(val > condition,
        string.format('%s\n%s  val=%s, condition=%s',message,' GT(>) violation ',
            tostring(val), tostring(condition)))
end


--[[ Asserts that the value of a variable is less than or equal to a threshold.

Arguments:

* `val` (number) the variable to be evaluated.
* `condition` (number) the threshold that `val` is compared against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertle(val, condition, message)
    return self:_assert_sub(val <= condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' LE(<=) violation ',
                tostring(val), tostring(condition)))
end


--[[ Asserts that the value of a variable is greater than or equal to a
threshold.

Arguments:

* `val` (number) the variable to be evaluated.
* `condition` (number) the threshold that `val` is compared against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertge(val, condition, message)
    return self:_assert_sub(val >= condition,
            string.format('%s\n%s  val=%s, condition=%s', message, ' GE(>=) violation ',
                tostring(val), tostring(condition)))
end


--[[ Asserts that the value of a variable is equal to an expected value.

Arguments:

* `val` (number) the variable to be evaluated.
* `expected` (number) the expected value that `val` is compared against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:asserteq(actual, expected, message)
    return self:_assert_sub(actual == expected,
            string.format('%s\n%s  actual=%s, expected=%s', message, ' EQ(==) violation ',
                tostring(actual), tostring(expected)))
end

--[[ Asserts that two variables are almost equal.

Arguments:

* `a` (number) first variable.
* `b` (number) second variable.
* `tolerance` (optional number, default 1e-16) the maximum acceptable
    difference of `a` and `b`.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertalmosteq(a, b, tolerance, message)
    tolerance = tolerance or 1e-16
    local err = math.abs(a-b)
    return self:_assert_sub(err < tolerance,
            string.format('%s\n%s  val=%s, tolerance=%s', message, ' ALMOST_EQ(==) violation ',
                tostring(err), tostring(tolerance)))
end

--[[ Asserts that the value of a variable is not equal to a given value.

Arguments:

* `val` (number) the variable to be evaluated.
* `condition` (number) a value to compare `val` against.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertne (val, condition, message)
    return self:_assert_sub(val ~= condition,
            function ()
                return string.format('%s\n%s  val=%s, condition=%s', message, ' NE(~=) violation ',
                    tostring(val), tostring(condition))
            end)
end



--[[ Asserts that two tensors are equal.

The two tensors provided should be of the same type.

Arguments:

* `ta` (tensor) first tensor.
* `tb` (tensor) second tensor.
* `tolerance` (number) the maximum acceptable difference of ta and tb.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertTensorEq(ta, tb, tolerance, message)
    local success, subMessage = totem.areTensorsEq(ta, tb, tolerance)
    return self:_assert_sub(success, string.format("%s\n%s", message, subMessage))
end



--[[ Asserts that two tensors are unequal.

The tensors are considered unequal if the maximum elementwise
difference >= tolerance. The two tensors provided should be of the same type.

Arguments:

* `ta` (tensor) first tensor.
* `tb` (tensor) second tensor.
* `tolerance` (number) the minimum acceptable difference of ta and tb.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertTensorNe(ta, tb, tolerance, message)
    local success, subMessage = totem.areTensorsNe(ta, tb, tolerance)
    return self:_assert_sub(success, string.format("%s\n%s", message, subMessage))
end


--[[ Asserts that two tables are equal by recursively comparing their values.

This function recursively traverses the two tables and asserts the equality of
their non-table elements. Note that this method simply uses the `==` operator
to assess the equality of two non-table elements.

Arguments:

* `actual` (table) the first table.
* `expected` (table) the second table.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertTableEq(actual, expected, message)
    return self:_assert_sub(totem.assertTableEq(actual, expected),
            string.format('%s\n%s actual=%s, expected=%s', message, ' TableEQ(==) violation ',
                tostring(actual), tostring(expected)))
end


--[[ Asserts that two tables are not equal.

The values of the two tables are being compared recursively.

Arguments:

* `ta` (table) the first table.
* `expected` (table) the second table.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertTableNe(ta, tb, message)
    return self:_assert_sub(totem.assertTableNe(ta, tb),
            string.format('%s\n%s ta=%s, tb=%s', message, ' TableNE(~=) violation ',
                tostring(ta), tostring(tb)))
end


--[[ Asserts that an error is raised by `f`

Arguments:

* `f` (function) function to be tested.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertError(f, message)
    return self:assertErrorObj(f, function(err) return true end, message)
end


--[[ Asserts that no error is raised by `f`

Arguments:

* `f` (function) function to be tested.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertNoError(f, message)
    return self:assertErrorObj(f, function(err) return true end, message, true)
end


--[[ Asserts that an error is raised by `f` with a specific message

Arguments:

* `f` (function) function to be tested.
* `errmsg` (string) error message that should be generated by `f`.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertErrorMsg(f, errmsg, message)
    return self:assertErrorObj(f, function(err) return err == errmsg end, message)
end


--[[ Asserts that an error is raised by `f` containing a specific pattern.

Arguments:

* `f` (function) function to be tested.
* `errPattern` (string) pattern that should be present in the error object.
* `message` (string) the error message to be displayed in case of failure.

Returns (boolean) whether the test succeeded.
]]
function Tester:assertErrorPattern(f, errPattern, message)
    return self:assertErrorObj(f, function(err) return string.find(err, errPattern) ~= nil end, message)
end


--[[ Asserts that an error is raised by `f` which satisfies some condition.

Arguments:

* `f`, (function) function to be tested.
* `errcomp`, (function : obj → bool) function that compares the error object
    to its expected value.
* `message`, (string) the error message to be displayed in case of failure.
* `condition`, (boolean) assert condition on status of pcall
    (defaults to false).

Returns (boolean) whether the test succeeded.
]]
function Tester:assertErrorObj(f, errcomp, message, condition)
    local status, err = pcall(f)
    return self:_assert_sub(status == (condition or false) and errcomp(err),
            string.format('%s\n%s  err=%s', message,' ERROR violation ', tostring(err)))
end



--[[ General assert on equality with a supplied precision (number, table,
user data).

In case of tables the comparison is carried out recursively with precision
being passed down to sub-objects.

Arguments:

* `got`, (number, table, userData, string) the value computed during the test
    execution.
* `expected`, (number, table, userData) the expected value.
* `label`, (string) used for output labelling.
* `precision`, (number) the maximum allowed difference for numbers or tensors.
* `ret`, (boolean) whether to return a value instead of running an assertion
    (default is false).

Returns (boolean) whether the test succeeded.
]]
function Tester:eq(got, expected, label, precision, ret)

    ret = ret or false
    label = label or "eq"
    precision = precision or 0

    local ok = false
    local diff = 0
    if type(got) ~= type(expected) then
        if not ret then
            self:_failure(string.format("%s inconsistent types: %s and %s",label,type(got),type(expected)))
        end
        return false
    elseif type(expected) == "table" then
        return self:_eqTable(got, expected, label, precision)
    elseif type(expected) == "userdata" then
        if torch.isTensor(got) then
            self:_eqSize(got, expected, label)
            diff = got:clone():add(-1, expected:type(got:type())):abs():max()
            ok = diff <= precision
        else
            return self:_eqStorage(got, expected, label, precision)
        end
    else
        if precision == 0 then
            ok = (got == expected)
        else
            diff = math.abs(got - expected)
            ok = (diff <= precision)
        end
    end

    if not ret then
        self:_assert_sub(ok,
            function ()
                return string.format("%s violation at precision %g (max diff=%g): %s != %s",
                        tostring(label), precision, diff, tostring(got), tostring(expected))
            end)
    end
    return ok
end


function Tester:_eqSize(ta, tb, label)
    local ok = true
    if ta:nDimension() ~= tb:nDimension() then
        ok = false
    else
        for i = 1, ta:nDimension() do
            if ta:size(i) ~= tb:size(i) then
                ok = false
                break
            end
        end
    end

    self:_assert_sub(ok,
        function ()
            return string.format("%s inconsistent size: %s != %s", tostring(label), tostring(ta), tostring(tb))
        end)
end


function Tester:_eqStorage(got, expected, label, precision)
    self:_assert_sub(#got == #expected,
        string.format("%s inconsistent storage size: %s != %s", label, #got, #expected))
    for i = 1, #expected do
        if not self:eq(got[i], expected[i], label, precision, true) then
            self:_failure(string.format("%s inconsistent values: %s != %s at position %d",
                          label, tostring(got[i]), tostring(expected[i]), i))
            return false
        end
    end

    self:_success()
    return true
end


function Tester:_eqTable(got, expected, label, precision)
    local failure = function(value1, value2, position)
        if type(value1) == 'table' then
            value1 = 'table1'
        end
        if type(value2) == 'table' then
            value2 = 'table2'
        end
        self:_failure(string.format("%s inconsistent values: %s != %s at position %d",
                      label, tostring(value1), tostring(value2), position))
    end

    if #got ~= #expected then
        self:_failure(string.format("%s inconsistent table size: %s != %s", label, #got, #expected))
        return false
    end

    for k, v in pairs(expected) do
        if not self:eq(got[k], v, label, precision, true) then
            failure(got[k], v, k)
            return false
        end
    end

    for k, v in pairs(got) do
        if not self:eq(v, expected[k], label, precision, true) then
            failure(v, expected[k], k)
            return false
        end
    end

    self:_success()
    return true
end


function Tester:_pcall(f)
    local nerr = #self.errors
    local stat, result = xpcall(f, debug.traceback)
    if not stat then
        self.errors[#self.errors+1] = self.curtestname .. '\n Function call failed \n' .. result .. '\n'
    end
    return stat, result, stat and (nerr == #self.errors)
end


local function unwords(...)
    return table.concat({...}, ' ')
end


local function pluralize(num, str)
    local stem = num .. ' ' .. str
    if num == 1 then
        return stem
    else
        return stem .. 's'
    end
end


-- dummy function
local function coloured(str)
    return str
end


local function bracket(str)
    return '[' .. str .. ']'
end


function Tester:_nfailures(tests)
    local nfailures = 0
    for name,_ in pairs(tests) do
        if self.assertionFail[name] > 0 then
            nfailures = nfailures + 1
        end
    end
    return nfailures
end


function Tester:_nerrors(tests)
    local nerrors = 0
    for name,_ in pairs(tests) do
        if self.testError[name] > 0 then
            nerrors = nerrors + 1
        end
    end
    return nerrors
end


function Tester:_report(tests, ntests, nfailures, nerrors, summary)
    io.write('Completed ' .. pluralize(self.countasserts, 'assert'))
    io.write(' in ' .. pluralize(ntests, 'test') .. ' with ')

    io.write(coloured(pluralize(nfailures, 'failure'), nfailures == 0 and c.green or c.red))
    io.write(' and ')
    io.write(coloured(pluralize(nerrors, 'error'), nerrors == 0 and c.green or c.magenta))
    io.write('\n')

    if #self.errors ~= 0 and not summary then
        io.write(string.rep('-', NCOLS))
        io.write('\n')
        for i,v in ipairs(self.errors) do
            if type(v) == 'string' then
                io.write(v)
                io.write('\n')
                io.write(string.rep('-', NCOLS))
                io.write('\n')
            end
        end
    end
end


function Tester:_logOutput(f, tests)
    local npasses, nfails, nerrors = 0, 0, 0
    for name,_ in pairs(tests) do
        npasses = npasses + self.assertionPass[name]
        nfails = nfails + self.assertionFail[name]
        nerrors = nerrors + self.testError[name]
        f:write(unwords(name, self.assertionPass[name], self.assertionFail[name], self.testError[name]))
        f:write('\n')
    end
    f:write(unwords('[total]', npasses, nfails, nerrors))
    f:write('\n')
    f:close()
end


function Tester:_listTests(tests)
    for name,_ in pairs(tests) do
        print(name)
    end
end

Tester.CLoptions = [[
    --list print the names of the available tests instead of running them.
    --log-output (optional file-out) redirect compact test results to file.
        This contains one line per test in the following format:
        name #passed-assertions #failed-assertions #exceptions
    --no-colour suppress colour output
    --summary print only pass/fail status rather than full error messages.
    --full-tensors when printing tensors, always print in full even if large.
        Otherwise just print a summary for large tensors.
    --early-abort (optional boolean) abort execution on first error.
    --rethrow (optional boolean) errors make the program crash and propagate up
        the stack.
    ]]

function Tester:_runCL(candidates)

    local args = lapp([[Run tests

Usage:

  ]] .. arg[0] .. [[ [options] [test1 [test2...] ]

Options:

]]
..Tester.CLoptions..
[[

If any test names are specified only the named tests are run. Otherwise
all the tests are run.

]])
    if #args > 0 then
        candidates = args
    end

    if not args.no_colour then
        require 'sys'
        c = sys.COLORS
        coloured = function(str, colour)
            return colour .. str .. c.none
        end
    end

    if not args.full_tensors then
        local _tostring = tostring
        tostring = function(x)
            if torch.isTensor(x) and x:nElement() > 256 then
                local sz = _tostring(x:size(1))
                for i = 2,x:nDimension() do
                    sz = sz .. 'x' .. _tostring(x:size(i))
                end
                return string.format('Tensor of size %s, min=%g, max=%g', sz, x:min(), x:max())
            else
                return _tostring(x)
            end
        end
    end

    local tests = self:_getTests(candidates)
    if args.list then
        self:_listTests(tests)
        return 0
    else
        local status = self:_run(tests, args.summary, args.early_abort, args.rethrow)
        if args.log_output then
            self:_logOutput(args.log_output, tests)
        end
        return status
    end
end


--[[ Runs tests.

Arguments:

* `tests` (optional string or table of strings) names of tests to run (if not
     running from the command-line).
]]
function Tester:run(tests)
    local status = 0
    if arg then
        status = self:_runCL()
    else
        status = self:_run(self:_getTests(tests))
    end
    -- Detect whether we're running directly from a top-level script. This
    -- will not work for e.g. th which is an interpreter defined in lua
    if debug.getinfo(3) then
        return status
    else
        os.exit(status, true)
    end
end


function Tester:_getTests(candidates)
    local tests = self.tests

    local function getMatchingNames(pattern)
        local matchingNames = {}
        for name,_ in pairs(self.tests) do
            if string.match(name, pattern) then table.insert(matchingNames, name) end
        end
        if next(matchingNames) == nil then
            lapp.error(string.format("Invalid test case '%s'", pattern), true)
        end
        return matchingNames
    end

    if type(candidates) == 'string' then
        candidates = getMatchingNames(candidates)
    end

    if type(candidates) == 'table' then
        tests = {}
        for _,name in ipairs(candidates) do
            local curNames = getMatchingNames(name)
            for _,name in pairs(curNames) do
                tests[name] = self.tests[name]
            end
        end
    end

    return tests
end


local function countFormat(n)
    local total = string.format('%u', n)
    return string.format('%%%uu/%u ', total:len(), total), total:len() * 2 + 2
end


function Tester:_run(tests, summary, earlyAbort, rethrow)

    self.countasserts = 0

    self.assertionPass = {}
    self.assertionFail = {}
    self.testError = {}
    local ntests = 0
    for name,_ in pairs(tests) do
        self.assertionPass[name] = 0
        self.assertionFail[name] = 0
        self.testError[name] = 0
        ntests = ntests + 1
    end

    local cfmt, cfmtlen = countFormat(ntests)

    io.write('Running ' .. pluralize(ntests, 'test') .. '\n')
    local i = 1
    for name,fn in pairs(tests) do
        self.curtestname = name

        -- TODO: compute max length of name and cut it down to size if needed
        local strinit = coloured(string.format(cfmt,i), c.cyan)
                      .. self.curtestname .. ' '
                      .. string.rep('.', NCOLS-6-2-cfmtlen-self.curtestname:len()) .. ' '
        io.write(strinit .. bracket(coloured('WAIT', c.cyan)))
        io.flush()

        local stat, message, pass
        if rethrow then
            stat = true
            local nerr = #self.errors
            message = fn()
            pass = nerr==#self.errors
        else
            stat, message, pass = self:_pcall(fn)
        end

        io.write('\r')
        io.write(strinit)

        if not stat then
            self.testError[name] = 1
            io.write(bracket(coloured('ERROR', c.magenta)))
        elseif pass then
            io.write(bracket(coloured('PASS', c.green)))
        else
            io.write(bracket(coloured('FAIL', c.red)))
        end
        io.write('\n')
        io.flush()

        if earlyAbort and (i<ntests) and (not stat or not pass) then
            io.write('Aborting on first error, not all tests have been executed\n')
            break
        end

        i = i + 1

        collectgarbage()
    end
    local nfailures = self:_nfailures(tests)
    local nerrors = self:_nerrors(tests)
    self:_report(tests, ntests, nfailures, nerrors, summary)
    return nfailures + nerrors == 0 and 0 or 1
end


--[[ Adds one or more test cases to a totem.Tester instance.

Arguments:

* `test`, (function, table, number, string)
    * A function is a test case that makes assertions.
    * A table should contain a number of functions. These are added
        individually.
    * A number is assumed to be a return code from a tester run, for use in
        nested tests. 0 means no errors, while any other value indicate error.
    * A string is assumed to be a filename which when loaded returns a test
        return code as described above.
* `name` (optional string) name of test. If the test is a filename, the `name`
    parameter is ignored.

Returns the totem.Tester instance.
]]
function Tester:add(f, name)
    name = name or 'unknown'
    if type(f) == "table" then
        for i,v in pairs(f) do
            self:add(v,i)
        end
    elseif type(f) == "function" then
        self.tests[name] = f
    elseif type(f) == "number" then
        -- a test that has already been run
        self.tests[name] = function() self:_assert_sub(f == 0) end
    elseif type(f) == "string" then
        -- a file containing tests
        self:add(dofile(f), f)
    else
        error('Tester:add(f) expects a function, a table of functions, a pre-computed test result, or a filename.\nFound' .. tostring(f) .. ' instead for the test ' .. name)
    end
    return self
end

local paths = require 'paths'
local file = require 'learning.lua.file'
local logging = require 'learning.lua.logging'
