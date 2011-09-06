# note that these tests are really just checking
# the grammar. Can't actually test that the contracts are working
# beause we depend on Proxy which node (aka V8) doesn't have yet.
# Actual contract functionality tests are found in webtests/.

# test "function, simple first order", ->
#   id :: (Num) -> Num
#   id = (x) -> x
#   eq (id 4), 4

# test "function, higher order in params", ->
#   id :: ( ((Num) -> Str), Bool ) -> Num
#   id = (x) -> x
#   eq (id 4), 4

# # test "function, higher order in params, implicit parens", ->
# #   id :: ( (Num) -> Str, Bool ) -> Num
# #   id = (x) -> x
# #   eq (id 4), 4

# test "function, higher order in range", ->
#   id :: (Num) -> (Str) -> Bool
#   id = (x) -> x
#   eq (id 4), 4

# test "object, simple props", ->
#   id :: { a: Num, b: Str }
#   id =
#     a: 42
#     b: "foo"
#   eq id.a, 42

# test "object, function props", ->
#   id :: { a: ( (Num) -> Num ), b: Str }
#   id =
#     a: (x) -> x
#     b: "foo"
#   eq (id.a 42), 42

# test "array, simple props", ->
#   id :: [Num, Str]
#   id = [42, "foo"]
#   eq id[0], 42

# test "array, function props", ->
#   id :: [ ((Num) -> Num), Str]
#   id = [(x) -> x, "foo"]
#   eq (id[0] 42), 42

# todo make a test that catches
# a :: C
# b = C
# idents need to match up


test "contracts can be embedded in comments", ->
  # Make sure that compiling code with contracts embedded in the comments
  # generates the same JavaScript as code with just regular contracts.

  js_with_contract = CoffeeScript.compile '''
    id :: (Num) -> Num
    id = (x) -> x
  ''', { contracts : true }

  js_without_contract = CoffeeScript.compile '''
    id = (x) -> x
  '''

  # These snippets must have contracts when compiled
  positive_tests = [
    '''
      #? id :: (Num) -> Num
      id = (x) -> x
    ''',
    '''
      #?id :: (Num) -> Num
      id = (x) -> x
    '''
  ]

  # These snippets must not have contracts when compiled
  negative_tests = [
    '''
      # id :: (Num) -> Num
      id = (x) -> x
    ''',
    '''
      ##? id :: (Num) -> Num
      id = (x) -> x
    ''',
    '''
      #? ::
      id = (x) -> x
    ''',
    '''
      #? id::prototype_method
      id = (x) -> x
    ''',
    '''
      #::
      id = (x) -> x
    ''',
    '''
      #? somerandomtext
      #? :: double colons on the next line
      id = (x) -> x
    '''
  ]

  for test in positive_tests
    compiled_test = CoffeeScript.compile test, { contracts: true }
    eq compiled_test, js_with_contract

    compiled_test = CoffeeScript.compile test, { contracts: false }
    eq compiled_test, js_without_contract

  for test in negative_tests
    compiled_test = CoffeeScript.compile test, { contracts: true }
    eq compiled_test, js_without_contract
