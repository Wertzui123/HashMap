# HashMap
This is a hashmap/hashtable implementation written in V.
<br>Since the standard `map` type in V does not allow for arbitrary key types, you can use this library when you need keys of different types than `string`, `integer`, `float`, `rune`, `enum` or `voidptr` ([which are allowed in the default map](https://github.com/vlang/v/blob/a0e7a46be4d468ecf61b0e6cd7c81f11ddbd4233/vlib/v/parser/parse_type.v#L131)).
<br>Note that your keys must define both an `equals` and a `hash` method.

## Example
```v
import hashmap

struct String {
	str string
}

pub fn (s1 String) equals(s2 String) bool {
	return s1.str == s2.str
}

pub fn (s String) hash() int {
	return s.str.hash()
}

fn main() {
	mut m := hashmap.new_hashmap<String, String>()
	m.set(String{'Hello'}, String{'World'})
	assert m.contains_key(String{'Hello'})
	assert m.contains_value(String{'World'})
	assert m.get_value(String{'Hello'}) ? == String{'World'}
	assert m.get_key(String{'World'}) ? == String{'Hello'}
	m.remove(String{'Hello'})
	assert m.len == 0
}
```

## Performance
Since this is my first attempt at writing a hashmap, the performance is probably pretty poor; in particular, removing elements is really slow.
<br>Furthermore, the array under the hoods is scaled by only one element each time it is enlarged, which is very bad if many elements are added (you can provide an `initial_capacity` when creating a hashmap though).
<br>Of course the performance also depends a lot on what hashing algorithm you use for your keys.

## License
This library is licensed under the MIT license (see [LICENSE](LICENSE)).