module hashmap

const (
	initial_capacity = 4
)

struct HashMap[K, V] {
mut:
	pair_index int
	pairs      []&Pair[K, V] // used in the iterator to keep the order of the pairs
	buckets    []&Bucket[K, V] @[required]
pub mut:
	len int
}

struct Pair[K, V] {
pub:
	key K
pub mut:
	value V
}

@[heap]
struct Bucket[K, V] {
pub mut:
	pairs []&Pair[K, V]
}

@[params]
pub struct HashMapConfig {
pub:
	initial_capacity int = hashmap.initial_capacity
}

pub fn new_hashmap[K, V](config HashMapConfig) !HashMap[K, V] {
	if config.initial_capacity <= 0 {
		error('initial_capacity of hashmap must be greater than 0')
	}
	mut buckets := unsafe { []&Bucket[K, V]{len: config.initial_capacity, init: &Bucket[K, V]{}} }
	return HashMap[K, V]{
		buckets: buckets
	}
}

pub fn (m HashMap[K, V]) contains_key(key K) bool {
	if m.buckets.len == 0 {
		return false
	}
	key_hash := key.hash()
	bucket := m.buckets[modulo(key_hash, m.buckets.len)] or { return false }
	for pair in bucket.pairs {
		if pair.key.equals(key) {
			return true
		}
	}
	return false
}

pub fn (m HashMap[K, V]) contains_value(value V) bool {
	if m.buckets.len == 0 {
		return false
	}
	for bucket in m.buckets {
		for pair in bucket.pairs {
			if pair.value.equals(value) {
				return true
			}
		}
	}
	return false
}

pub fn (m HashMap[K, V]) get_value[K](key K) ?V {
	if m.buckets.len == 0 {
		return none
	}
	bucket := m.buckets[modulo(key.hash(), m.buckets.len)] or { return none }
	for pair in bucket.pairs {
		if pair.key.equals(key) {
			return pair.value
		}
	}
	return none
}

pub fn (m HashMap[K, V]) get_key[K](value V) ?K {
	if m.buckets.len == 0 {
		return none
	}
	for bucket in m.buckets {
		for pair in bucket.pairs {
			if pair.value.equals(value) {
				return pair.key
			}
		}
	}
	return none
}

pub fn (mut m HashMap[K, V]) set[K, V](key K, value V) {
	key_hash := key.hash()
	mut index := modulo(key_hash, m.buckets.len)
	assert index >= 0
	if index >= m.buckets.len {
		pair := Pair[K, V]{
			key: key
			value: value
		}
		m.buckets << &Bucket[K, V]{
			pairs: [&pair]
		}
		m.pairs << &pair
		m.rehash()
	}
	mut bucket := m.buckets[index]
	assert voidptr(bucket) != 0
	for mut pair in bucket.pairs {
		if pair.key.equals(key) {
			pair.value = value
			return
		}
	}
	pair := Pair[K, V]{
		key: key
		value: value
	}
	bucket.pairs << &pair
	m.pairs << &pair
	m.len++
}

pub fn (mut m HashMap[K, V]) remove(key K) bool {
	key_hash := key.hash()
	mut bucket := m.buckets[modulo(key_hash, m.buckets.len)] or { return false }
	for mut pair in bucket.pairs {
		if pair.key.hash() == key_hash {
			bucket_pair_index := bucket.pairs.index(pair)
			assert bucket_pair_index != -1
			bucket.pairs.delete(bucket_pair_index)
			pair_index := m.pairs.index(pair)
			assert pair_index != -1
			m.pairs.delete(pair_index)
			m.len--
			if bucket.pairs.len == 0 {
				if m.buckets.len > 1 { // ensure the array never shrinks to 0 (which would break the hash % size calculation)
					m.buckets.delete(m.buckets.index(bucket))
					m.rehash()
				}
			}
			return true
		}
	}
	return false
}

fn (mut m HashMap[K, V]) rehash() {
	old_buckets := m.buckets.clone()
	m.pairs = []&Pair[K, V]{}
	m.buckets = unsafe { []&Bucket[K, V]{len: old_buckets.len, init: &Bucket[K, V]{}} }
	m.len = 0
	for bucket in old_buckets {
		for pair in bucket.pairs {
			m.set(pair.key, pair.value)
		}
	}
}

pub fn (m HashMap[K, V]) hash() int {
	// TODO: Implement a better hash function
	mut i := 0
	for bucket in m.buckets {
		for pair in bucket.pairs {
			i += i * 31 + pair.key.hash()
			i += i * 31 + pair.value.hash()
		}
	}
	return i
}

pub fn (a HashMap[K, V]) equals(b HashMap[K, V]) bool {
	if a.len != b.len {
		return false
	}
	for bucket in a.buckets {
		for pair in bucket.pairs {
			if !b.contains_key(pair.key) {
				return false
			}
			if b.get_value(pair.key) or { return false } != pair.value {
				return false
			}
		}
	}
	return true
}

pub fn (mut m HashMap[K, V]) reverse() HashMap[K, V] {
	mut reverse := HashMap[K, V]{
		buckets: unsafe { []&Bucket[K, V]{len: m.buckets.len, init: &Bucket[K, V]{}} }
		pairs: []&Pair[K, V]{}
		len: 0
		pair_index: 0
	}
	for pair in m.pairs.reverse() {
		reverse.set(pair.key, pair.value)
	}
	return reverse
}

pub fn (mut m HashMap[K, V]) next() ?Pair[K, V] {
	if m.len == 0 {
		return none
	}
	if m.pair_index == m.pairs.len {
		return none
	}
	defer {
		m.pair_index++
	}
	return *m.pairs[m.pair_index]
}
