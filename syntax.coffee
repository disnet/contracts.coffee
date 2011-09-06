# basic functions
id :: (Num) -> Num
id = (x) -> x

# multi args
adder :: (Num, Str, Bool) -> Str
adder = (a, b, c) ->
  a + b + c

# simple flat combinators
or :: (Num or Str) -> Bool
and :: (Num and Str) -> Bool # not a very accepting contract :)
# want not but this conflicts with contract expression escape operator: !(x) -> x > 4
not :: (not Num) -> Num
not :: (!Num) -> Num # conflict!

# optional args
opt :: (Num, Str, Str?) -> Str

# higher order
app :: ((Num) -> Bool, Bool) -> Bool

# call only
f :: (Num) --> Num # can't be used with 'new'

# new only
f :: (Num) ==> Any # can't be used without 'new'

# dependent
inc :: (Num, Num) -> !(result) -> result > $1 and $1 > $2

# this contract
f :: (Str, @{name: Str}) -> Str

# objects
o :: { a : Num, b: Str, f: (Any) -> Any }

# implicit curlies
o ::
  a: Num
  b: Str?
  f: (Any) -> Any
  oo:
    z: Num
    y: Str

# this contract
o ::
  a: Num,
  b: Str,
  f: (Any, @{a: Num, b: Str}) -> Any

# pre/post/invariant
o ::
  a: Num,
  b: Str,
  f: (Any, @{name: Str, age: Num}) -> Any |
      pre: (obj) -> obj.a > 42
      post: (obj) -> obj.b is not "bad"
  | invariant: ->
      @.a > 0 and @.b is "foo"

# recursive contracts
o ::
  a: Num
  b: Str
  f: (Num) -> Self

# arrays
arr :: [Str, Num, Bool, [Bool, Bool]]
arr :: [...Bool]
arr :: [Str, Num, ...Bool]

# naming contracts
NumId  = ?(Num) -> Num
NumObj = ?{a: Num, b: Num}
NumArr = ?[Num, Num]

# escaping from a contract expression
f :: (!(x) -> typeof x is 'number') -> Num

retPrim :: (Num) -> !isPrime
f :: (Num, !(x) -> isPrime x) -> Bool

NumId = ?(Num) -> Num
id :: NumId

MyEven = ?!(x) -> x % 2 is 0
idEven :: (MyEven) -> MyEven

MyEven = (x) -> x % 2 is 0
idEven :: (!MyEven) -> !MyEven


# note on combinators...racket provides a bunch of flat contracts
# like >, <, between, etc. The only one we're providing are 'and' and 'or'.
# I think the escape syntax is sufficient and potentially less confusing (also less
# work for me :-). So where racket would use the flat combinators we have:
f :: (Num and (!(x) -> x > 4)) -> (Num and (!(x) -> x < 10) and x > 1)

# modules for browser

# server.coffee
obj ::
  a: Str
  b: Num
obj = {a: "foo", b: 42}

# client-browser.coffee
obj.a # ERROR
o = obj.use()

o.a = "bar" # works fine
o.a = 42 # contract failure

# client-node.coffee (not implemented...no node with proxies yet)
s = require "server"
o = s.obj

# some example blame messages
# (note that a cleaned up  stack trace (contract library frames removed) is available on
# the error object that gets thrown when a contract is violated

id :: (Num) -> Num
id "foo"
# Error: Contract violation: expected <Number>, actual: "foo"
# Value guarded in: blametest.js:31 -- blame is on: blametest.js:32
# Parent contracts:
# (Number) -> Number

f :: ( (Str) -> Str ) -> Num
f = (fun) ->
  fun "foo"
  42
f (s) -> s
# Error: Contract violation: expected <String>, actual: 42
# Value guarded in: blametest.js:108 (server) -- blame is on: blametest.js:108 (client)
# Parent contracts:
# (String) -> String
# ((String) -> String ) -> Number

o :: {a: Num, b: Str}
o = {a: 42}
# Error: Contract violation: expected <{a : Number, b : String}>, actual: "[missing property: b]"
# Value guarded in: blametest.js:164 (server) -- blame is on: blametest.js:164 (server)
# Parent contracts:
# {a : Number, b : String}

o ::
  a: Num
  f: (Num) -> Num |
      pre: (obj) -> obj.a > 0
o =
  a: -1
  f: ...
o.f 42
# Error: Contract violation: expected <precondition: function (obj) {
#     return obj.a > 0;
# }>, actual: "[failed precondition]"
# Value guarded in: blametest.js:282 (server) -- blame is on: blametest.js:282 (client)
# Parent contracts:
# (Number) -> Number
# {f : (Number) -> Number , a : Number}
