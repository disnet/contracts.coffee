---
layout: default
---

Contracts.coffee is a dialect of [CoffeeScript](http://jashkenas.github.com/coffee-script/) with built-in
support for contracts. It is inspired by the contract system found in [Racket](http://racket-lang.org/).

Contracts let you clearly&mdash;even beautifully&mdash;express how
your code behaves, and free you from writing tons of boilerplate,
defensive code.

You can think of contracts as `assert` on
steroids.

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
(Num) -&gt; Num
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
Even = (x) -> x % 2 is 0
Odd = (x) -> x % 2 isnt 0

addEvens :: (!Even) -> !Odd
addEvens = (x) -> x + 1
{% endhighlight %}

In fact, since contracts are checked at runtime, they can enforce
properties that static type systems can only dream of.

{% highlight coffeescript %}
Prime = (x) -> # ...

f :: (!Prime) -> !Prime
f = (x) -> x
{% endhighlight %}

Eat your heart out, Haskell :)

<span id="quickstart"></span>
Quick Start
-----------

Here's what you need to actually start working with contracts.coffee.

First, if you don't already have them, install [Node.js](https://github.com/joyent/node/wiki/Installation)
and [npm](http://npmjs.org/). Then install contracts.coffee using npm:

{% highlight bash %}
npm install -g contracts.coffee
{% endhighlight %}

Now, compile some coffee with contracts!

{% highlight bash %}
coffee -c --contracts MyContractedScript.coffee
{% endhighlight %}

Note the `-c` and `--contracts` flags. The `-c` flag says to compile to JavaScript 
and `--contracts` enables contracts in the compiled JavaScript. If you don't want
contracts enabled (say in production) simply don't include the `--contracts`
flag.

If you are planning to run your code in the browser 
you will need to include the `contracts.js` library (which can be found [here](https://github.com/disnet/contracts.coffee/blob/master/lib/contracts/contracts.js)).
So the header of your HTML file will look something like:

{% highlight html %}
...
<script src="lib/contracts.js"
    type="application/javascript"></script>
<script src="MyContractedScript.js"
    type="application/javascript"></script>
...
{% endhighlight %}


Contracts.coffee also has experimental support for
[require.js](http://requirejs.org/). Just load the "contracts" module
first in `main.js`. So your `main.js` will look something like:

{% highlight javascript %}
require(["contracts", "MyModule"], function(c, myMod) {
    // ...
});
{% endhighlight %}

If you are planning to run your code on node.js then you simply
need to install `contracts.js` via npm:

{% highlight bash %}
npm install contracts.js
{% endhighlight %}

Note that if you have an existing install of CoffeeScript,
installing contracts.coffee will replace it. If you don't want to give
up the old CoffeeScript compiler you can grab the source from 
[github](https://github.com/disnet/contracts.coffee) and 
just run contracts.coffee from its own directory:

{% highlight bash %}
bin/coffee -c --contracts MyContractedScript.coffee
{% endhighlight %}

And finally, note that contracts.coffee requires some pretty new
features of JavaScript to get its job done (in particular
[Proxies](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Proxy))
so it currently only works on Firefox 4+, Node.js 0.8.0+,
and recent versions of Chrome (though at the moment you'll need to enable the
experimental JavaScript flag in about:flags).

When using node you will need to supply two command line flags to enable
Proxies (`--harmony_proxies`) and WeakMaps (`--harmony-collections`). 
If you use the
`coffee` or `cake` scripts these flags will be enabled automatically for you, otherwise
the full process looks like:

{% highlight bash %}
coffee -c --contracts script.coffee
node --harmony_proxies --harmony-collections script.js
{% endhighlight %}

Note that since leaving off the `--contracts` flag will generate JavaScript
code with absolutely no trace of contracts (the code is exactly what
vanilla CoffeeScript would generate), you can easily set up a
production build with contracts disabled that can run in any browser
or JavaScript environment and a development/testing build with
contracts enabled that you run in Firefox to help track down bugs.

Resources
---------

*  [Issue Tracker](https://github.com/disnet/contracts.coffee/issues?sort=created&direction=desc&state=open)
   <br />
   For filing bugs, requesting features and changes.
*  [Google Group](https://groups.google.com/forum/?hl=en#!forum/contractscoffee)
   <br />
   For general discussion about contracts.coffee.
*  [disnet's blog](http://disnetdev.com/blog/)
   <br />
   Will sometimes post about contracts.coffee.

<span id="use"></span>
How to Use
-----------------

In order to provide good error messages when things go wrong,
contracts.coffee needs to know where contracted values are 
created and used in your code. 
It does this by enforcing a kind of module discipline and
keeping track of which module a value was in
when it was first wrapped up in a contract and which module
uses the contracted value.

Since JavaScript doesn't (yet) have modules, contracts.coffee must
enforce a notion of modules on its own. The good news is that for the
common cases you'll never have to deal with this.

* If you are running in node.js the appropriate module wiring is done
  automatically. You just need to use `require` and the `exports` 
  object like normal.
  
* If you are running in the browser and using
  [require.js](http://requirejs.org/), then the wiring is also
  automatically handled for you. Just be sure to include "contracts"
  as your first loaded module. (Here is an [example](https://github.com/disnet/contracts.coffee/tree/master/test/webtest) of this in action)
  
* If you have some other situation then you will need to do the module
  wiring by hand. This is documented over [here](https://github.com/disnet/contracts.coffee/wiki/Manual-Modules).

<span id="simple"></span>
Simple Contracts
----------------

In addition to the `Num` contract that checks for numbers, we
also have `Str`, `Bool`, `Null`, `Undefined`, `Nat`, `Pos`, `Neg`,
`Any` (everything is ok), and `None` (nothing is ok).

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

Dependent functions:

{% highlight coffeescript %}
inc :: (Num) -> !(result, args) -> result > args[0]
inc = (n) -> n + 1
{% endhighlight %}

The variable `args[0]` is the first argument passed to the function (`args[1]`
would be the second argument, `args[2]` the third, and so on). This allows
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

**Note:** Putting an object contract on a primitive will always fail.
  This might seem obvious at first but since many primitives have
  methods, the following contract would seem reasonable:
  
{% highlight coffeescript %}
f :: ({toString: (Any) -> Str}) -> Str
f = (s) -> s.toString()

f "a string"   # Contract violation
f {}           # ok
{% endhighlight %}

Even though "a string" has a `toString` method the contract will
always signal a violation. This is because JavaScript proxies can wrap
objects but not primitives. 

In addition due to a limitation in the current JavaScript engines implementations
of proxies, you cannot put a contract on the `Date` object. This is
expected to be fixed in future implementations. 
See [this issue](https://github.com/disnet/contracts.coffee/issues/44) to
track progress on this.

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
  f: (Num) -> Num -|
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
  f: (Num) -> Num -|
      pre: (o) -> o.a > 10
      post: (o) -> o.a > 20
  -| invariant: ->
    @.a > 0 and @.a < 100
o =
  a: 12
  f: (x) -> @.a = @.a + x
{% endhighlight %}

The invariant is checked at contract application and whenever there is a possibility of `o`
mutating (on property sets and delete).

Arrays
------

**Note: due to a proxy bug in all the current JavaScript engines, arrays are not currently being wrapped in a contract. This won't cause code to fail, it just means that contracts will not be checked for arrays. See this github [issue](https://github.com/disnet/contracts.coffee/issues/54) for more info.**

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


<span id="checking"></span>
## Check-Time of Contracts

The actual point in time when a contract is checked depends
on the kind of contract. 

* Simple contracts (*e.g.* `Num`, `Str`, and contracts created via
  `!`) are checked immediately.
* Function contracts are checked when the function is called. 
* Object contracts are immediately checked to make sure all their 
  properties exist. The individual property contracts are
  checked each time the property is accessed.
* Array contracts are checked in the same way as object contracts.

For example, this means that if a function `f` takes another function 
`g` as an argument,
it will delay checking of `g` until `g` is actually invoked.

{% highlight coffeescript %}
f :: ((Num) -> Num, (Str) -> Str) -> Num
f = (g, h) -> g 42

str = (x) -> "string"
num = (x) -> 42

f str, num  # fails when g is called inside f
f num, num  # since h is never called it never fails
            # even though it would violate its contract
{% endhighlight %}

A function returning an object will immediately check for the
existence of properties but delay checking that they match their
contract until accessed. 

{% highlight coffeescript %}
f :: (Num) -> {a: Str, b: Num}
f = (x) -> {a: "foo"}

# fails as soon as f returns since b is missing
f 42

g :: (Num) -> {a: Str, b: Num}
g = (x) -> {a: x, b: x}

o = g 42         # does not fail yet
console.log o.a  # now fails because o.a does not satisfy Str
{% endhighlight %}

<span id="naming"></span>
Naming your own contracts
---------

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

     
<span id="duck"></span>
Duck-Typing Invariants
----------------------
  
A full write-up on this topic is covered [here](http://disnetdev.com/blog/2011/09/05/Duck-Typing-Invariants-In-contracts.coffee/) but to whet your appetite: you can "duck-type" object invariants. Code can now say, "give me whatever object you want so long as it has *these* properties and satisfies *these* invariants".

Consider a binary search tree:

{% highlight coffeescript %}
# A binary search tree is a binary tree 
# where each node is  greater than the 
# left child but less than the right child
BinarySearchTree = ?(Null or {
  node: Num
  left: Self or Null
  right: Self or Null
  -| invariant: ->
    (@.node > @.left.node) and (@.node < @.right.node)
})
{% endhighlight %}

And a [red-black tree](http://en.wikipedia.org/wiki/Red-black_tree):

{% highlight coffeescript %}
# A red-black tree is a binary search tree 
# that keeps its balance
RedBlackTree = ?(Null or {
  node: Num
  color: Str
  left: Self or Null
  right: Self or Null
  -| invariant: ->
    (@.color is "red" or @.color is "black") and
    (if @.color is "red"
      (@.left.color is "black" and 
       @.right.color is "black") 
    else 
      true
    ) and
    (@.node >= @.left.node) and 
    (@.node >= @.right.node) and
})
{% endhighlight %}

The red-black tree is exactly the same as a binary search tree with some additional invariants. This means we have a kind of subtyping going on here: code that expects a binary search tree will also work with a red-black tree but *not* vica versa.

{% highlight coffeescript %}
takesBST :: (BinarySearchTree) -> Any
takesBST = (bst) -> ...

takesRedBlack :: (RedBlackTree) -> Any
takesRedBlack = (rbTree) -> ...

bst = makeBinarySearchTree()  
rb = makeRedBlackTree()

takesBST bst # works fine
takesBST rb  # works fine

takesRedBlack rb  # works fine
takesRedBlack bst # might fail if the full 
                  # red-black invariants don't hold!
{% endhighlight %}

In duck-typing, functions work when given *any* object that has the properties the function needs (though the object might have other properties too). Contracts allow us to extend that to object invariants: functions work when given *any* object that has the required properties *and* satisfies the required invariants (though the object might satisfy other invariants too).


<span id="log"></span>
Change Log
----------

* [0.3.2](https://github.com/disnet/contracts.coffee/tree/c0.3.1) (September 5, 2012)
  * disabling contracts for arrays (see issue [54](https://github.com/disnet/contracts.coffee/issues/54))
  * various bug fixes
* [0.3.1](https://github.com/disnet/contracts.coffee/tree/c0.3.1) (July 15th, 2012)
  * support for stable node.js (v0.8.0+)
  * some bug fixes
* [0.3.0](https://github.com/disnet/contracts.coffee/tree/c0.3.0) (March 15th, 2012)
  * [change](https://github.com/disnet/contracts.coffee/issues/8) to dependent function contracts
  * various contracts.coffee bug fixes: [#27](https://github.com/disnet/contracts.coffee/issues/27), [#41](https://github.com/disnet/contracts.coffee/issues/41), [#33](https://github.com/disnet/contracts.coffee/issues/33), [#31](https://github.com/disnet/contracts.coffee/issues/31),
  * various contracts.js bug fixes: [#9](https://github.com/disnet/contracts.js/pull/9), [#8](https://github.com/disnet/contracts.js/pull/8), [#7](https://github.com/disnet/contracts.js/pull/7), [#6](https://github.com/disnet/contracts.js/pull/6), [#5](https://github.com/disnet/contracts.js/pull/5), [#4](https://github.com/disnet/contracts.js/pull/4)
  * experimental support for require.js (see [here](https://github.com/disnet/contracts.coffee/tree/master/test/webtest) for example use)
  * based off CoffeeScript 1.3.1
* [0.2.0](https://github.com/disnet/contracts.coffee/tree/c0.2.0) (January 4th, 2012)
  * removed `.use()`, now using `Contracts.exports` and `Contracts.use`
  * various bug fixes
  * based off CoffeeScript 1.2.0
* [0.1.0](https://github.com/disnet/contracts.coffee/tree/c0.1.0) (August 29th, 2011) 
  * initial release
  * based off CoffeeScript 1.1.2



