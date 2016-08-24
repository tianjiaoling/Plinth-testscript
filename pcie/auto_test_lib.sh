#!/bin/bash
#
function fail_test()
{
local reason="$1"
echo "${TEST}: FAIL - ${reason}"
}
#
function pass_test()
{
echo "${TEST}: PASS"
}
#
