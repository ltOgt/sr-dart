# .SR - SmallRead

`TODO: Lists not yet implemented`

Clear Text Data Storage format with the following goals:
* human readable
* minimal symbol overhead
    * Less Disk Space
    * Less characters to type
    * Less noise while reading
* efficient decode + encode

Online demo of current version: [here](https://omnesia.org/flutter_showcase/srx/)

_______

## Reserverd symbols
`SR` only reserves
* `:` anywhere
* `.` as line prefix

### Types
`SR` defines three types that are identified by `:`:
* `<name>:<value>` for _key-value_ pairs
* `<name>::<SIZE>` for _object_ headers
* `<name>:::<SIZE>` for _list_ headers
* `<value>` for unnamed values (only inside _list_ scopes)

Both `<name>` and `<value>` are always interpreted as `String`, while `<SIZE>` is always cast to `int`.

### Depth
Similar to `yaml`, `SR` uses a kind of indentation to hierarchically group data.
Instead of using whitespace, which can lead to confusion (e.g. `\s\s` vs `\t`),
`SR` uses leading dots.
```
<level-1>
.<level-2>
.<level-2>
..<level-3>
<level-1>
```

### Decode with `<SIZE>`
To make decoding single-pass and fast,
headers (`object::<S>` or `list:::<S>`) state the number of other lines that are
part of their scope as their `SIZE`.

```
<level-1>      3
.<level-2>    (0)
.<level-2>     1
..<level-3>   (0)
<level-1>     (0)
```

Note that requiring `SIZE` as part of the headers, results in memory overhead during encoding.
Because we must know the number of lines in a scope before writing the line belonging to the scope, we have to keep the scope content in memory before writing it.

## Type details and JSON equivalents
### Fields
Fields behave as expected inside objects (where the top level of the file is the root object).
They are basically just key-value pairs:
```
field:value
```
```json
{
    "field":"value"
}
```

### Objects
Objects are basically named maps:
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

### Lists
List behave a little unexpected.
Lists must always be named, but can have unnamed values.
At the same time, they can still inline fields and objects:
```
list:::2
.value-1
.value-2
```
```json
{
    "list": [
        "value-1",
        "value-2",
    ]
}
```

#### Objects and Fields in Lists
```
field:value
list:::5
.value-1
.value-2
.field:value
.object::2
..field-1:value-1
..field-2:value-2
```
```json
{
    "field": "value",
    "list": [
        "value-1",
        "value-2",
        {
            "field": "value"
        },
        {
            "object": {
                "field-1": "value-1",
                "field-2": "value-2"
            }
        }
    ]
}
```

_______

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
`SR` can not have top level lists, nor unnamed objects inside a list!

## Validation
The current implementation of `SmallReadConverter` does not check for valid form of an input `SR` file.
If the `SR` file is malformed, the conversion behaviour is undefined and might throw or return incorrect data without failing.

`TODO: add utility to validate SR files`

### Correct behaviour is guaranteed only if:

#### - `:` is not part of `name`s nor `value`s
`(my:name):(my:value)` is illegal.
Currently there is no way to escape these special characters.
If you need to store `:` consider encoding/decoding it yourself. 

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

*`TODO: consider adding SRD for dynamic without size (would generate SR in pre-processing step, so rather used for user generated input once, not for every read cycle)`

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