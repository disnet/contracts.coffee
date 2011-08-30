---
layout: default
---

Contracts.coffee is a dialect of CoffeeScript with built-in
support for contracts.

Contracts let you clearly&mdash;even beautifully&mdash;express how
your code behaves, and free you from writing tons of boilerplate,
defensive code.

You can think of contracts as `assert` on
steroids.

<span id="basics"></span>
Basics
------

Here's a simple example of a contract on a function:

{% highlight coffeescript %}
id :: (Num) -> Num
id = (x) -> x
{% endhighlight %}

This says that the `id` function should always be called with a number
and will always return a number. It looks a lot like types (in fact
the syntax looks a *lot* like Haskell) but unlike types,
contracts are enforced at runtime in pure JavaScript.

If we try to use `id` incorrectly: 

{% highlight coffeescript %}
id "foo"
{% endhighlight %}

The program throws an error, which displays lots of nice information
telling us what we did wrong:

<pre style="color: red">
Error: Contract violation: expected &lt;Num&gt;,
actual: "foo"
Value guarded in: id_module:42
  -- blame is on: client_code:104
Parent contracts:
(Num) -> Num
</pre>

You can also put contracts on objects.

{% highlight coffeescript %}
person ::
    name: Str
    age: Num
person =
    name: "Bertrand Meyer"
    age: 42
{% endhighlight %}

And arrays.

{% highlight coffeescript %}
loc :: [...Num]
loc = [99332, 23452, 123, 2, 5000]
{% endhighlight %}

And in various combinations.

{% highlight coffeescript %}
average :: ({name: Str, age: Num}, [...Num]) -> Str
average = (person, loc) ->
    sum = loc.reduce (s1, s2) -> s1 + s2
    "#{person.name} wrote on average 
     #{sum / loc.length} lines of code."
{% endhighlight %}

Under the covers, contracts are really just normal functions that
return `true` or `false`, so it's really easy to roll your own by
using the `!` operator to define new contracts.

{% highlight coffeescript %}
isEven = (x) -> x % 2 is 0
isOdd = (x) -> x % 2 isnt 0

addEvens :: (!isEven) -> !isOdd
addEvens = (x) -> x + 1
{% endhighlight %}

In fact, since contracts are checked at runtime, they can enforce
properties that static type systems can only dream of.

{% highlight coffeescript %}
isPrime = (x) -> # ...

f :: (!isPrime) -> !isPrime
f = (x) -> x
{% endhighlight %}

Eat your heart out, Haskell :)

<span id="quickstart"></span>
Quick Start
-----------

Here's what you need to actually start working with contracts.coffee.

First, grab the source from github.

{% highlight bash %}
git clone git://github.com/disnet/contracts.coffee.git
cd contracts.coffee
git submodule init
git submodule update
{% endhighlight %}

Install [Node.js](https://github.com/joyent/node/wiki/Installation)
and then contracts.coffee.

{% highlight bash %}
sudo bin/cake install
{% endhighlight %}

Now, compile some coffee with contracts!

{% highlight bash %}
coffee -cC MyContractedScript.coffee
{% endhighlight %}

Note the `-cC` flag. The `-c` says to compile to JavaScript and `-C`
enables contracts in the compiled JavaScript. If you don't want
contracts enabled (say in production) simply don't include the `-C`
flag.

You will also need to include `loadContracts.js`, which is found in the
root of contracts.coffee. So the header of your HTML file will look
something like:

{% highlight html %}
...
<script src="loadContracts.js"
    type="application/javascript"></script>
<script src="MyContractedScript.js"
    type="application/javascript"></script>
...
{% endhighlight %}

Note that if you have an existing install of CoffeeScript,
installing contracts.coffee will replace it. If you don't want to give
up the old CoffeeScript compiler you can just run contracts.coffee
from its own directory:

{% highlight bash %}
bin/coffee -cC MyContractedScript.coffee
{% endhighlight %}

And finally, note that contracts.coffee requires some pretty new
features of JavaScript to get its job done (in particular
[Proxies](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Proxy))
so it currently only works on Firefox 4+. Support for other JavaScript
engines is coming soon.

This means that if you attempt to run your contracted CoffeeScript
under node/V8:

{% highlight bash %}
# note the -c flag is missing
coffee -C MyContractedScript.coffee
# Compile error!!!
{% endhighlight %}

You will get a bunch of errors. So just compile to JavaScript and run
it in Firefox for now.

Note that since leaving off the `-C` flag will generate JavaScript
code with absolutely no trace of contracts (the code is exactly what
vanilla CoffeeScript would generate), you can easily set up a
production build with contracts disabled that can run in any browser
or JavaScript environment and a development/testing build with
contracts enabled that you run in Firefox to help track down bugs.

<span id="use"></span>
How to Use
-----------------

In order to provide good error messages when things go wrong,
contracts.coffee needs to know where contracted values are 
used in your code. What this means practically is that before you can
use a value that has a contract on it, you must first `use()` it:

{% highlight coffeescript %}
# Library.coffee
window.id :: (Num) -> Num
window.id = (x) -> x
{% endhighlight %}

{% highlight coffeescript %}
# Main.coffee
id = window.id.use()

id 4     # ok
id "foo" # Contract Violation...
{% endhighlight %}

<pre style="color: red">
Contract violation: expected &lt;Num&gt;, actual: "foo"
Value guarded in: Library:3
  -- blame is on: Main:2
Parent contracts:
(Num) -> Num 
</pre>

The `use()` function does the work of dynamically setting up the right
file names to display in error messages.

This is an unfortunate bit of syntax that we hope to do implicitly in
the future with better compiler and module support.

In general it is advisable to only put contracts on
module exports but if you want to use them in the same module
simply call `use()` immediately.

Admittedly, in the example above finding the right file name is pretty trivial
(we could have just inspected the stacktrace). To see the real power
of recording the right names with `use()` consider the following
example:

{% highlight coffeescript linenos %}
# CheckingLibrary.coffee
window.checkAge :: (Num) -> Bool
window.checkAge = (age) ->
  # make sure the age makes sense
  age > 0 && age < 150 
{% endhighlight %}

{% highlight coffeescript linenos %}
# Validator.coffee
window.validateForm :: ((Str) -> Bool, Str) -> Bool
window.validateForm = (checker, fieldName) ->
  checker $(fieldName).val()   # failure is here 
{% endhighlight %}

{% highlight coffeescript linenos %}
# Main.coffee
checkAge = window.checkAge.use()
validateForm = window.validateForm.use()

$("form").submit ->
  # checkAge takes Num but validateForm passes Str!
  validateForm checkAge, "#age"
{% endhighlight %}

We get this contract violation:

<pre style="color: red">
Contract violation: expected &lt;Num&gt;, actual: "42"
Value guarded in: CheckingLibrary:2
  -- blame is on: Main:3
Parent contracts:
(Num) -> Bool
</pre>

Here we have a library that does some simple form validation.
The `checkAge` library function checks ages to be within a reasonable
range for humans and the `validateForm` function takes a field name
and a checker function and checks the field's value with the supplied
checker.

The problem happens when `Main.coffee` sets up the form submit handler to call
`validateForm` (which expects a checker that takes strings) with
`checkAge` (which takes numbers).

Notice that the violation happens at `Validator.coffee:4` when the
checker is called with a string but the module at fault is actually
`Main.coffee` (since it was responsible for providing
`Validator.coffee` with the right checker). In this case it is pretty
much impossible to correctly assign blame by just inspecting the
stacktrace since the the point of failure is in a different location
than the file actually at fault.


But the error message gets it right!

It gets it right because `use()` records the module name where the
contracted values were `used()` and we correctly track all the module
names through all the subsequent contract checks.


<span id="simple"></span>
Simple Contracts
----------------

In addition to the `Num` contract that checks for numbers, we
also have `Str`, `Bool`, `Null`, `Undefined`, `Nat`, `Pos`, `Neg`,
`Any` (everything is ok), and `None` (nothing is ok).

<span id="functions"></span>
Functions
---------

Basic functions:

{% highlight coffeescript %}
f :: (Num) -> Num
f = (x) -> x
{% endhighlight %}

Multiple arguments:

{% highlight coffeescript %}
f :: (Num, Str, Bool) -> Num
f = (n, s, b) -> # ...
{% endhighlight %}

Optional arguments:

{% highlight coffeescript %}
f :: (Num, Str, Bool?) -> Num
f = (n, s, b) -> # ...
{% endhighlight %}

All optional arguments must come at the end of the arguments list.

Higher order functions:

{% highlight coffeescript %}
f :: ((Num) -> Bool, Num) -> Bool
f = (g, n) -> # ...
{% endhighlight %}

Functions that *cannot* be called with the `new` keyword:

{% highlight coffeescript %}
f :: (Num) --> Num
f = (n) -> # ...
#...

g = f 42      # ok
g = new f 42  # error!
{% endhighlight %}

Functions that can *only* be called with the `new` keyword:

{% highlight coffeescript %}
f :: (Num) ==> Num
f = (n) -> # ...
#...

g = f 42      # error!
g = new f 42  # ok
{% endhighlight %}

Functions that get `new` inserted automatically if it was left out.

{% highlight coffeescript %}
f :: (Num) -=> Num
f = (n) -> # ...
#...

g = f 42      # ok: converted to g = new f 42
g = new f 42  # ok
{% endhighlight %}

Dependent functions:

{% highlight coffeescript %}
inc :: (Num) -> !(result) -> result > $1
inc = (n) -> n + 1
{% endhighlight %}

The variable `$1` is the first argument passed to the function (`$2`
would be the second argument, `$3` the third, and so on). This allows
us to compare the result of the function to its arguments. Note that
the test is run after the function has completed so if any of the
arguments were mutated during the function's execution the test could
give spurious results.

The `this` contract:

{% highlight coffeescript %}
f :: (Str, @{name: Str}) -> Str
f = (s) -> #...

o = { name: "foo", f: f}
o.f()
{% endhighlight %}

Checks that `this` matches the given object contract.

<span id="objects"></span>
Objects
-------

Simple properties:

{% highlight coffeescript %}
o ::
  a: Str
  b: Num
  f: (Num) -> Num
o =
  a: "foo"
  b: 42
  f: (x) -> x
{% endhighlight %}

Optional properties:

{% highlight coffeescript %}
o ::
  a: Str
  b: Num?
  f: (Num) -> Num
o =
  a: "foo"
  f: (x) -> x
{% endhighlight %}

Nested objects:

{% highlight coffeescript %}
o ::
  oo: { a: Str }
  b: Num
o =
  oo: { a: "foo" }
  b: 42
{% endhighlight %}

Recursive objects:

{% highlight coffeescript %}
o ::
  a: Num
  b: Self
  c: (Num) -> Self
  inner: { y: Bool, z: Self }
o = #...
{% endhighlight %}

`Self` binds to the closest object contract. So in this example,
`Self` in `b` and `c` points to `o` and `Self` in `inner.z` points to
`inner`.

Objects with functions that have pre and post conditions:

{% highlight coffeescript %}
o ::
  a: Num
  f: (Num) -> Num |
      pre: (o) -> o.a > 10
      post: (o) -> o.a > 20
o =
  a: 12
  f: (x) -> @.a = @.a + x
{% endhighlight %}

The pre and post condition functions are called with the object that
`f` is a member of. As their names imply, `pre` is called before the
function `f` is invoked and `post` is called after.

Object invariants:

{% highlight coffeescript %}
o ::
  a: Num
  f: (Num) -> Num |
      pre: (o) -> o.a > 10
      post: (o) -> o.a > 20
  | invariant: ->
    @.a > 0 and @.a < 100
o =
  a: 12
  f: (x) -> @.a = @.a + x
{% endhighlight %}

The invariant is checked whenever there is a possibility of `o`
mutating (on property sets, delete, etc.).

<span id="arrays"></span>
Arrays
------

Basic arrays:

{% highlight coffeescript %}
a :: [Num, Str, [Bool, Num]]
a = [42, "foo", [true, 24]
{% endhighlight %}

This says the array must have three elements, the first being a `Num`,
the second being a `Str`, and the third being another array.

Multiple elements:

{% highlight coffeescript %}
a :: [...Num]
a = [42, 24, 432, 854, 21]
{% endhighlight %}

The `...` operator says that the array will only contain `Num`s.

Mixing arrays

{% highlight coffeescript %}
a :: [Bool, Str, ...Num]
a = [false, "foo", 432, 854, 21]
{% endhighlight %}

The `...` operator can be mixed with single contracts. This says that
the array's first and second positions must pass the first two
contracts and the remaining array positions must pass `Num`. The
`...` operator must be in the last position of the array contract.

<span id="operators"></span>
Contract Operators
------

The `or` contract:

{% highlight coffeescript %}
o :: { a: Num or Str }
o = { a: 42 }
{% endhighlight %}

Here, the `a` property must pass either the `Num` or `Str` contract. Note
that since contracts like function and object have
deferred checking, they cannot be used with the `or` contract. Or to be
more precise only *one* function/object contract can be used with
`or`. So you could have `Num or (Num) -> Num` but not
`((Num) -> Num) or ((Str) -> Str)`. If you combine normal contracts and
function/object contracts with `or` all the normal contracts will be
checked first and then the function/object contract will be applied.

The `and` contract:

{% highlight coffeescript %}
o :: { a: Num and Even }
o = { a: 42 }
{% endhighlight %}

The `a` property must pass both the `Num` and `Even`
contracts. Just like `or` you cannot use multiple function/object
contracts with `and`.


<span id="naming"></span>
Naming your own contracts
-------------------------

You can bind a contract to a variable just like normal expressions:

{% highlight coffeescript %}
NumId = ?(Num) -> Num

f :: NumId
f = (x) -> x
{% endhighlight %}

The `?` operator allows you to escape out of the normal expression
language and into the contract language.

You can also escape from the contract language to the normal
expression language:

{% highlight coffeescript %}
takesEvens :: (!(x) -> x % 2 is 0) -> Num
takesEvens = (x) -> x
{% endhighlight %}

The result of the expression in the `!` escape must be a function that
returns a boolean. It is converted to a contract that checks its value
against the function.

The standard `Num` and `Str` contracts you have seen are
implemented as:

{% highlight coffeescript %}
Num = ?!(x) -> typeof x is 'number'
Str = ?!(x) -> typeof x is 'string'
{% endhighlight %}

The syntax may look a little strange at first, but it can be read as
"assign to `Num` the contract generated from the function `(x) ->
...`

It could also be written:

{% highlight coffeescript %}
Num = (x) -> typeof x is 'number'
Str = (x) -> typeof x is 'string'

f = (!Num) -> !Str
{% endhighlight %}
