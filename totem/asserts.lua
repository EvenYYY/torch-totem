--[[ Test for tensor equality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number) maximum pointwise difference between `a` and `b`

Returns two values:
success (boolean), failure_message (string or nil)

Tests whether the maximum pointwise difference between `a` and `b` is less than
or equal to `condition`.

]]
function totem.areTensorsEq(ta, tb, condition, _negate)
  -- If _negate is true, we invert success and failure
  if _negate == nil then
    _negate = false
  end
  assert(torch.isTensor(ta), "First argument should be a Tensor")
  assert(torch.isTensor(tb), "Second argument should be a Tensor")
  assert(type(condition) == 'number',
         "Third argument should be a number describing a tolerance for"
         .. " equality for a single element")

  if ta:dim() ~= tb:dim() then
    return false, 'The tensors have different dimensions'
  end
  local sizea = torch.DoubleTensor(ta:size():totable())
  local sizeb = torch.DoubleTensor(tb:size():totable())
  local sizediff = sizea:clone():add(-1, sizeb)
  local sizeerr = sizediff:abs():max()
  if sizeerr ~= 0 then
    return false, 'The tensors have different sizes'
  end

  local function ensureHasAbs(t)
  -- Byte, Char and Short Tensors don't have abs
    if not t.abs then
      return t:double()
    else
      return t
    end
  end

  ta = ensureHasAbs(ta)
  tb = ensureHasAbs(tb)

  local diff = ta:clone():add(-1, tb)
  local err = diff:abs():max()
  local violation = _negate and 'TensorNE(==)' or ' TensorEQ(==)'
  local errMessage = string.format('%s violation: val=%s, condition=%s',
                                   violation,
                                   tostring(err),
                                   tostring(condition))

  local success = err <= condition
  if _negate then
    success = not success
  end
  return success, (not success) and errMessage or nil
end

--[[ Assert tensor equality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number) maximum pointwise difference between `a` and `b`

Asserts that the maximum pointwise difference between `a` and `b` is less than
or equal to `condition`.

]]
function totem.assertTensorEq(ta, tb, condition)
  return assert(totem.areTensorsEq(ta, tb, condition))
end


--[[ Test for tensor inequality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number)

Returns two values:
success (boolean), failure_message (string or nil)

The tensors are considered unequal if the maximum pointwise difference >= condition.

]]
function totem.areTensorsNe(ta, tb, condition)
  return totem.areTensorsEq(ta, tb, condition, true)
end

--[[ Assert tensor inequality

Parameters:

- `ta` (tensor)
- `tb` (tensor)
- `condition` (number)

The tensors are considered unequal if the maximum pointwise difference >= condition.

]]
function totem.assertTensorNe(ta, tb, condition)
  assert(totem.areTensorsNe(ta, tb, condition))
end


local function isIncludedIn(ta, tb)
    if type(ta) ~= 'table' or type(tb) ~= 'table' then
        return ta == tb
    end
    for k, v in pairs(tb) do
        if not totem.assertTableEq(ta[k], v) then return false end
    end
    return true
end

--[[ Assert that two tables are equal (comparing values, recursively)

Parameters:

- `actual` (table)
- `expected` (table)

]]
function totem.assertTableEq(ta, tb)
    return isIncludedIn(ta, tb) and isIncludedIn(tb, ta)
end

--[[ Assert that two tables are *not* equal (comparing values, recursively)

Parameters:

- `actual` (table)
- `expected` (table)

]]
function totem.assertTableNe(ta, tb)
    return not totem.assertTableEq(ta, tb)
end
