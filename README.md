# .SR - SmallRead

Clear Text Data Storage format with the following goals:
* human readable
* minimal symbol overhead
    * Less Disk Space
    * Less characters to type
    * Less noise while reading
* efficient decode + encode


#### Demo
Online demo of current version: [here](https://omnesia.org/flutter_showcase/srx/)

And a small example right here:
```
** Small SR example
name:README.md
type:markdown
modified:2021-12-12 13:00** can use colons only after first char of value
** incomplete
sections::3** object
.syntax:::2** list
..:Reserved Symbols
..:Components
```

# Syntax
## Reserverd symbols
`SR` only reserves
* `:` anywhere
* `.` as line prefix
* `**` as comment initiators
    * (enabled iff file starts with `**`)

If you want to store these symbols, you will have to encode them as different symbols yourself.
Character escaping is not supported.

## Components
`SR` structures its data through the use of the following components:
* `element`
* `scope`
* `scope-size`
* `value`
* `name`
* `object-head`
* `list-head`

### Element
Each line in `SR` represents an `element`.
Multi-line `elements` are not supported.

`Elements` in `SR` are (`named`) `values` or (`named`) `object-`/`list-heads`.

### Scope
Similar to `yaml`, `SR` uses a kind of indentation to hierarchically group data.
Instead of using whitespace, which can lead to confusion (e.g. `\s\s` vs `\t`),
`SR` uses leading dots:
```
// This is not SR yet
<element-1>
.<e-2>
.<e-3>
..<e-4>
<e-5>
```
Here `<element-1>` is in the global `scope` of the `SR` file.
`<e-2>` and `<e-3>` are in the `scope` of `<element-1>`.
`<e-4>` is in the `scope` of `<e-3>` (transitively, also in `<element-1>`).

The entire file defines one global `scope`.
Inside, `Scopes` are started via `object-` or `list-heads`.
`Values` never have a `scope` beyond their own line.

### Scope-Size
To make decoding single-pass and fast,
`scopes` must state the number of lines that are nested within them:
```
// This is not SR yet
<element-1>   3
.<e-2>       (0)
.<e-3>        1
..<e-4>      (0)
<e-5>        (0)
```

Note that requiring `scope-size` as part of the headers,
results in memory overhead during encoding.

*`TODO: consider adding .SRD for dynamic without size (-> generate SR in pre-processing step => once for user generated input, not for every read cycle)`


### Value
All values in `SR` are interpreted as `String` and go from single `:` to the end of the line (`\n`).
```
:value with whitespace trail    \n
:10\n
:.2\n
```
Would be decoded as
```
"value with whitespace trail    "
"10"
".2"
```

`Values` must _not start_ with `:`.
They are allowed to contain `.` or any other characters (even at the start).
They must _not contain any_ `**`, iff comments are allowed.

### Name
`Values` (and `Objects` and `Lists`) can be `named` if their `scope` allows it.
They go from the start of the line to the first `:` and are also always interpreted as `String`.

```
myName:myValue\n
 my name : my value \n
my.Name:.my.Value
```
Would be decoded as
```
"myName"    -> " myValue"
" my name " -> " my value "
"my.Name"   -> ".my.Value"
```

`Names` must _not contain any_ `:`.
They must _not start_ with `.`.
They must _not contain any_ `**`, iff comments are allowed

## Object: Head and Scope
`Objects` are `scopes` that allow only `named` `elements`.

`Object-heads` start with double colon `::`, followed by their `scope-size`.
Each element in the `objects` `scope` gets one `.` added to the start of the line.
The `scope` ends when the number of leading `.` returns to the same number as before the `object-head`.

`Objects` are `named` inside `object-scope` and `un-named` in `list-scope`.
```
**                  start of global scope
name:value
myObj::2**          start of myObj scope
.myNestedObj::1**   start of myNestedObj scope inside myObj
..name:value
**                  end of myNestedObj scope
.name:value
**                  end of myObj and global scope
```

## List: Head and Scope
`Lists` are `scopes` that allow only `un-named` `elements`.

`List-heads` start with tripple colon `:::`, followed by their `scope-size`.
Each element in the `lists` `scope` gets one `.` added to the start of the line.
The `scope` ends when the number of leading `.` returns to the same number as before the `list-head`.

`Lists` are `named` inside `object-scope` and `un-named` in `list-scope`.
```
**                  start of global scope
name:value
myList:::2**        start of myList scope
.::1**              start of unnamed object scope inside myList
..name:value
**                  end of unnamed object scope
.:value
**                  end of myList and global scope
```


# SR <-> JSON
### Values
`Named` `Values` are basically just key-value pairs:
```
field:value
```
```json
{
    "field":"value"
}
```

`Un-named` `Values` (only in lists) are just values:
```
myList:::1
.:value
```
```json
{
    "myList": ["value"]
}
```
Note that `SR` does not allow for top-level lists.

### Objects
`SR` `objects` are single key json maps:

##### top-level object
```
field-1:value-1
field-2:value-2
```
```json
{
    "field-1": "value-1",
    "field-2": "value-2"  
}
```

##### named object (only in objects)
```
object::2
.field-1:value-1
.field-2:value-2
```
```json
{
    "object": {
        "field-1": "value-1",
        "field-2": "value-2"
    }
}
```

##### un-named object (only in lists)
```
myList:::3
.::2
..field-1:value-1
..field-2:value-2
```
```json
{
    "myList": [
        {
            "field-1": "value-1",
            "field-2": "value-2"
        }
    ]
}
```

### Lists
`SR` `lists` are just json lists:

##### named list (only in objects)
```
myList::2
.:value-1
.:value-2
```
```json
{
    "myList": [
        "value-1",
        "value-2"
    ]
}
```

##### un-named lists (only in lists)
```
myList:::3
.:::2
..value-1
..value-2
```
```json
{
    "myList": [
        [
            "value-1",
            "value-2"
        ]
    ]
}
```

# Caveats

## Valid JSON might not have a valid SR mapping
```json
{".:":"::"}
```
is valid json, but has no valid `SR` counterpart.

Less obvious, the same holds true for
```json
[
    {
        "a":1,
        "b":2
    },
    {
        "a":4,
        "b":3
    },
    ...
]
```
since `SR` can not have top level lists!

## JSON -> SR -> JSON may change value types
Since all values in `SR` are interpreted as `String`, the default mapping from `SR` back to `JSON` may not result in the original file:
```
{"a":true} -> a:true -> {"a":"true"}
```
You may parse numbers and booleans back manually.

## Validation
The current implementation of `SmallReadConverter` does not check for valid form of an input `SR` file.
If the `SR` file is malformed, the conversion behaviour is undefined and might throw or return incorrect data without failing.

`TODO: add utility to validate SR files`

### Correct behaviour is guaranteed only if:

#### - `:` is not part of `name`s nor `value`s
`(my:name):(my:value)` is illegal.
Currently there is no way to escape these special characters.
If you need to store `:` consider encoding/decoding it yourself via non-reserved symbols. 

#### - `names` do not start with `.`
```
obj::1
..n:v
```
would currently result in
```json
{"obj":{".n":"v"}}
```
but this is not guaranteed by the spec.

Values that start with `.` are compliant:
```
obj::1
.n:.2
```
is guaranteed to result in:
```json
{"obj":{"n":".2"}}
```

#### - headers have the correct `SIZE`
```
obj::1
.n1:v1
.n2:v2
```
Will result in an error, since the decoder processes only the first line in the correct scope.
The second line will start decoding in an unexpected state.

*`TODO: add utility to clean up SIZE for SR files`

#### - names are unique per level
```
obj::2
.n1:v1
.n1:v2
```
will currently result in:
```json
{"obj":{"n1":"v2"}}
```
but that behaviour is undefined and might change


# Comments
Iff the `SR` file starts with `**`, then `**` are used to start comments.
```
**
name:value** this is my comment
name:value ** comment
```
```
"name"->"value"
"name"->"value "
```

Without that first line, `**` is not reserved:
```
name:value** this is my comment
name:value ** comment
```
```
"name"->"value** this is my comment"
"name"->"value ** comment"
```

Note that comments will be lost on decode.

# Experiment
```
:value
name:value
obj::1
.name:value
list:::9
.name:value
.:value
.obj::1
..name:value
.::1
..name:value      ** is this just the same as .name:value in list?
.list:::0
.:::1
..:value
.::2
..name1:value
..name2:value
```
```json
{
    ** value                 ** cant have unnamed values in object scope
    name: value,
    obj: {
        name: value,
    },
    list: [
        {name: value},        ** named value
        value,                ** value             ** only inside lists
        {obj: {name: value}}  ** named object
        {name: value},        ** unnamed object
        {list: []},           ** named list
        [value]               ** unnamed list      ** only inside lists
        {                     ** unnamed object
            name1: value,     ** _ w multiple fields
            name2: value,
        },        
    ],
}
```

## Alternative: Only named in object, only unnamed in lists
```
name:value
obj::1
.name:value
list:::9
.::1            ** unnamed obj with one field instead of named fields in lists
..name:value
.:value         ** unnamed value is fine
.::2            ** named object must be wrapped in unnamed object
..obj::1
...name:value
.::1            ** unnamed object with single field (just like above, but now without ambiguity)
..name:value
.::1
..list:::0      ** named empty list must be explicitly wrapped in unnamed object
.:::1           ** unnamed list is fine
..:value
.::2            ** unnamed object is fine
..name1:value
..name2:value
```
```json
{
    name: value,
    obj: {
        name: value,
    },
    list: [
        {name: value},        ** named value; here in explicit unnamed object
        value,                ** value             ** only inside lists
        {obj: {name: value}}  ** named object; here in explicit unnamed object
        {name: value},        ** unnamed object
        {list: []},           ** named list; here in explixit unnamed object
        [value]               ** unnamed list      ** only inside lists
        {                     ** unnamed object
            name1: value,     ** _ w multiple fields
            name2: value,
        },        
    ],
}
```