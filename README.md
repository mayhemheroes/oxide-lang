# Oxide Programming Language
Interpreted C-like language with a Rust influenced syntax. [Latest release][latest-releases]

## Example programs

```rust
/// recursive function calls to compute n-th
/// fibonacci sequence number

fn fib(n: int) -> int {
    if n <= 1 {
        return n;
    }

    return fib(n - 2) + fib(n - 1);
}

let nums = vec<int>[];
for let mut i = 0; i < 30; i += 1 {
    nums.push(fib(i));
}
```

```rust
/// sorting a vector using
/// insertion sort

fn insertion_sort(input: vec<int>) {
    for let mut i = 1; i < input.len(); i += 1 {
        let cur = input[i];
        let mut j = i - 1;
    
        while input[j] > cur {
            let temp = input[j + 1];
            input[j + 1] = input[j];
            input[j] = temp;
      
            if j == 0 {
              break;
            }
    
            j -= 1;
        }
    }
}

let input: vec<int> = vec[4, 13, 0, 3, -3, 4, 19, 1];

insertion_sort(input);

println(input); // [vec] [-3, 0, 1, 3, 4, 4, 13, 19]
```

```rust
/// first-class functions

let make_adder = fn (x: num) -> func {
    return fn (y: num) -> num {
        return x + y;
    };
};

let add5 = make_adder(5);
let add7 = make_adder(7);

println(add5(2)); // 7
println(add7(2)); // 9
```

```rust
/// structs

struct Circle {
    radius: float,
    center: Point,
    tangents: vec<Tangent>,   // vector of structs
}

struct Point {
    x: int,
    y: int,
}

struct Tangent {
    p: Point,
}

const PI = 3.14159;

let circle = Circle {                       // struct instantiation
    radius: 103.5,
    center: Point { x: 1, y: 5 }            // inner structs instantiation
    tangents: vec[                          // inner vector of structs instantiation
        Tangent { Point { x: 4, y: 3 } }    
        Tangent { Point { x: 1, y: 0 } }
    ],
};

fn calc_area(c: Circle) -> float {
    return PI * c.radius * c.radius;
}

let area = calc_area(circle); // 33653.4974775
```

```rust
/// compute the greatest common divisor 
/// of two integers using Euclid’s algorithm

fn gcd(mut n: int, mut m: int) -> int {
    while m != 0 {
        if m < n {
            let t = m;
            m = n;
            n = t;
        }
        m = m % n;
    }

    return n;
}

gcd(15, 5); // 5
```

[More examples][examples]

## Usage
### Interpret a file
```shell
oxide [script.ox]
```

### REPL

There is also a simplistic REPL mode available. 
```shell
oxide
```

# Quick Overview

* [Variables and Type System](#variables)
    * [Mutable Variables vs Immutable ones](#mutable-variables-vs-immutable-ones)
    * [Shadowing](#shadowing)
* [Control Flow and Loops](#control-flow-and-loops)
    * [If](#if)
    * [Match](#match)
    * [While](#while)
    * [Loop](#loop)
    * [For](#for)
* [Functions](#functions)
    * [Closures and Lambdas](#closures-and-lambdas)
    * [Declared functions](#declared-functions)
* [Structs](#structs)
* [Vectors](#vectors)
* [Constants](#constants)
* [Type System](#type-system)
* [Operators](#operators)
    * [Unary](#unary)
    * [Binary](#binary)
* [Comments](#comments)
* [Standard library](#standard-library)


## Variables and Type System

There are ten types embodied in the language: `nil`, `num`, `int`, `float`, `bool`, `str`, `func`, `vec`, `any` and user-defined types (via structs). See [type system][type-system]

Each variable has a type associated with it, either explicitly declared with the variable itself:

```rust
let x: int;

let mut y: str = "hello" + " world";

let double: func = fn (x: num) -> num {
    return x * 2;
};

let human: Person = Person { name: "Jane" };

let names: vec<str> = vec["Josh", "Carol", "Steven"];
```

or implicitly inferred by the interpreter the first time it is being assigned:

```rust
let x = true || false; // inferred as "bool";

let mut y;
y = vec<bool>[]; // inferred as "vec<bool>";

let dog;
dog = Dog { name: "Good Boy"}; // inferred as "Dog";
```

Mutable variables cannot be assigned to a value of another type, unless they are of type `any`:

```rust
let mut s: str = "string";
s = vec[]; //! type error

let mut a: any = Rectangle { height: 10, width: 10 };
a.height = "string"; //! type error
a = 45.34; // valid
```

### Mutable Variables vs Immutable ones

There are two possible ways of declaring a variable: immutable and mutable. Immutable ones cannot be reassigned after having been assigned to a value.

```rust
let x: str = "string";

let y: num;
y = 100;
```

However, mutable ones behave like you would expect a variable to behave in most other languages:

```rust
let mut x: str = "hello";
x += " world";
x += "another string";
```

### Shadowing

One important thing is that variables can be redeclared in other words, shadowed. Each variable declaration "shadows" the previous one and ignores its type and mutability. Consider:

```rust
let x: int = 100;
let x: str = "This was x value before: " + x;
let x: vec<any> = vec[];
```

## Control Flow and Loops

### If

`if` statement is pretty classic. It supports `else if` and `else` branches. Parentheses are not needed around conditions. Each branch must be enclosed in curly braces.

```rust
if x >= 100 {
    println("x is more than 100");
} else if x <= 100 && x > 0 {
    println("x is less than 100, but positive");
} else {
    println("x a non-positive number");
}
```

### Match

`match` expression returns the first matching arm evaluated value. Unlike other control flow statements, `match` is an expression and therefore must be terminated with semicolon. It can be used in any place an expression is expected.

```rust
let result = match get_direction() {
    "north" => 0,
    "east" => 90,
    "south" => 180,
    "west" => 270,
};
```

`match true` can be used to make more generalised comparisons.
```rust
let age = 40;

let description: str = match true {
    age > 19 => "adult",
    age >= 13 && x <= 19 => "teenager",
    age < 13 => "kid",
};
```

### While

There are three loops in Oxide: `while`, `loop` and `for`. All loops support `break` and `continue` statements. Loop body must be enclosed in curly braces.

`while` statement is rather usual.

```rust
while x != 100 {
    x += 1;
}
```

### Loop

`loop` looks like Rust's `loop`. Basically it is `while true {}` with some nice looking syntax.

```rust
loop {
    i -= 1;
    x[i] *= 2;
    if x.len() == 0 {
        break;
    }
}
```

### For

`for` loop is a ~~good~~ old C-like `for` statement, which comprises three parts. You should be familiar with it.
```rust
for let mut i = v.len(); i >= 0; i -= 1 {
    println(v[i]);
}

// the first or the last parts can be omitted
let mut i = v.len();

for ; i >= 0; {
    println(v[i]);
    i -= 1;
}

// or all three of them
// this is basically "while true" or "loop"
let mut i = v.len();

for ;; {
    println(v[i]);
    i -= 1;

    if i < 0 {
        break;
    }
}
```

## Functions

### Declared functions

Functions are declared with a `fn` keyword. Function signature must explicitly list all argument types as well as a return type. Functions that do not have a return value always return `nil` and the explicit return type can be omitted (same as declaring it with `-> nil`)

```rust
fn add(x: num, y: num) -> num {
    return x + y;
}

let sum = add(1, 100); // 101

fn clone(c: Circle) -> Circle {
    return Circle {
        radius: c.radius,
        center: c.center,
        tangents: vec<Tangent>[],
    };
}

let cloned = clone(circle);

// since this function returns nothing, the return type can be omitted
fn log(level: str, msg: str) {
    println("Level: " + level + ", message: " + msg);
}
```

Redeclaring a function will result in a runtime error.

### Closures and Lambdas

Functions can also be assigned to variables of type `func`. As with other types, it can be inferred and therefore omitted when declaring a variable.

```rust
/// function returns closure
/// which captures the internal value i
/// each call to the closure increments the captured value
fn create_counter() -> func {
    let mut i = 0;

    return fn () {
        i += 1;
        println(i);
    };
}

let counter: func = create_counter();

counter(); // 1
counter(); // 2
counter(); // 3
```

Functions are first-class citizens of the language, they can be stored in a variable, passed or/and returned from another function.

```rust
fn vec_concat(prefix: str, suffix: str) -> str {
    return prefix + suffix;
}

fn str_transform(callable: func, a: str, b: str) -> any {
    return callable(s1, s2);
}

str_transform(str_concat, "hello", " world");
```

Defining a function argument as `mut` lets you mutate it in the function body. By default, it is immutable.

```rust
fn inc(mut x: int) -> int {
    x += 1;
    return x;
}

// same as with shadowing
fn inc(x: int) -> int {
    let mut x = x;
    x += 1;
    return x;
}
```

Immediately Invoked Function Expressions, short IIFE, are also supported for whatever reason.

```rust
(fn (names: vec<str>) {
    for let mut i = 0; i <= names.len(); i += 1 {
        println(names[i]);
    }
})(vec["Rob", "Sansa", "Arya", "Jon"]);
```

## Structs

Structs represent the user-defined types. The struct declaration starts with `struct` keyword.

All struct properties are mutable and public by default.

```rust
struct Person {
    name: str,          // property of type str
    country: Country,   // property of type struct Country
    alive: bool,
    pets: vec<Animal>,  // property of type vector of structs Animal
}

struct Animal {
    kind: str,
    alive: bool,
}

struct Country {
    name: str,
}
```

You instantiate a struct creating it with curly braces and initializing all its properties `Animal { prop: value[, prop: value ...] }`.

```rust
let cat = Animal {
    kind: "cat",
    alive: true
};

let john: Person = Person {
    name: "John",
    alive: true,
    pets: vec[cat],                    // via variable
    country: Country { name: "UK" }    // via inlined struct instantiation
};
```

Dot syntax is used to access structs fields

```rust
// set new value
john.country = Country { name: "USA" };
john.pets.push( Animal {
    kind: "dog",
    alive: true
});

// get value
println(john.pet[0].kind); // cat
```

Immutable variable will still let you change the struct's fields, but it will prevent you from overwriting the variable itself. Similar to Javascript `const` that holds an object.

```rust
john.name = "Steven";    // valid, John is not a John anymore
john.pet.kind = "dog"    // also valid, john's pet is changed
john = Person { .. };    // invalid, "john" cannot point to another struct
```

Structs are always passed by reference, consider:

```rust
fn kill(person: Person) {
    person.alive = false;     // oh, john is dead
    person.pet.alive = false; // as well as its pet. RIP
}

kill(john);
```

## Vectors

Vectors, values of type `vec<type>`, represent arrays of values and can be created using `vec<type>[]` syntax, where `type` is any Oxide type.

Vectors support following methods:
* `vec.push(val: any)` push value to the end of the vector


* `vec.pop() -> any` remove value from the end of the vector and return it


* `vec.len() -> int` get vectors length

```rust
let planets = vec<str>["Mercury", "Venus", "Earth", "Mars"];

let mars = planets[3];

planents.push("Jupiter");     // "Jupiter" is now the last value in a vector

let jupiter = planets.pop(); // "Jupiter" is no longer in a vector.

planets[2] = "Uranus";       // "Earth" is gone. "Uranus" is on its place now

planets.len();               // 3

typeof(planets);             // vec<str>
```

When type is omitted it is inferred as `any` on type declaration, but on vector instantiation it is inferred as proper type **when possible**.
Consider:
```rust
let v: vec = vec[];                     // typeof(v) = vec<any>
let v = vec[];                          // typeof(v) = vec<any>

let v: vec<int> = vec[1, 2, 3];         // typeof(v) = vec<int>
let v = vec<int>[1, 2, 3];              // typeof(v) = vec<int>
let v = vec[1, 2, 3];                   // typeof(v) = vec<int>, because all the initial values are of type "int"

let v = vec<bool>[true];                // typeof(v) = vec<bool>

let v: vec<Dog> = vec[                  // typeof(v) = vec<Dog>, type declaration can actually be omitted
    Dog { name: "dog1" },
    Dog { name: "dog2" },
];

let v = vec[                            // typeof(v) = vec<vec<Point>,
    vec[                                // inferred by the initial values, despite the type being omitted
        Point { x: 1, y: 1 }, 
        Point { x: 0, y: 3 } 
    ],
    vec[ 
        Point { x: 5, y: 2 }, 
        Point { x: 3, y: 4 } 
    ],
];


let matrix = vec[                       // typeof(v) = vec<vec<int>>
    vec[1, 2, 3, 4, 5],
    vec[3, 4, 5, 6, 7],
    vec[3, 4, 5, 6, 7],
];

let things = vec[nil, false, Dog {}];   // typeof(v) = vec<any>
```

Like structs vectors are passed by reference. Consider this example of an in place sorting algorithm, selection sort, that accepts a vector and sorts it in place, without allocating memory for a new one.

<details>
  <summary>Selection sort</summary>

```rust
fn selection_sort(input: vec<int>) {
    if input.len() == 0 {
        return;
    }

    let mut min: int;
    for let mut i = 0; i < input.len() - 1; i += 1 {
        min = i;

        for let mut j = i; j < input.len(); j += 1 {
            if input[j] < input[min] {
                min = j;
            }
        }

        if min != i {
            let temp = input[i];
            input[i] = input[min];
            input[min] = temp;
        }
    }
}
```
</details>

Vectors can hold any values and be used inside structs.
```rust
let animals: vec = vec[
    Elephant { name: "Samuel" },
    Zebra { name: "Robert" },
    WolfPack { 
        wolves: vec<Wolf>[
            Wolf { name: "Joe" },
            Wolf { name: "Mag" },
        ]
    }
]

let mag = animals[2].wolves[1]; // Mag
```

Trying to read from a non-existent vector index will result in a `uninit` value returned. Trying to write to it will result in an error.

## Constants

Constants unlike variables need not be declared with a type since it can always be inferred. Constants also cannot be redeclared, and it will result in a runtime error. Constants **must** hold only a scalar value: `str`, `int`, `float`, `bool`.

```rust
const MESSAGE = "hello world";

const PI = 3.14159;

const E = 2.71828;
```

## Operators

### Unary
- `!` negates boolean value
- `-` negates number 

### Binary
- `&&`, `||` logic, operate on `bool` values
- `<`, `>`, `<=`, `>=`, comparison, operate on `int`, `float` values
- `==`, `!=` equality, operate on values of the **same** type
- `-`, `/`, `+`, `*`, `%` math operations on numbers
- `+` string concatenation, also casts any other value in the same expression to `str`
- `=`, `+=`, `-=`, `/=`, `%=`, `*=` various corresponding assignment operators

## Comments

Classic comments that exist in most other languages.
```rust
// inline comments

/*
    multiline comment
 */

let x = 100; /* inlined multiline comment */ let y = x;
```

## Standard library

A small set of built-in functionality is available anywhere in the code.

- `print(msg: str)` prints `msg` to the standard output stream (stdout).
  

- `println(msg: str)` same as `print`, but inserts a newline at the end of the string.
  

- `eprint(err: str)` prints `err` to the standard error (stderr).
  

- `eprintln(err: str)` you got the idea.
  

- `timestamp() -> int` returns current Unix Epoch timestamp in seconds
  

- `read_line() -> str` reads user input from standard input (stdin) and returns it as a `str`
  

- `file_write(file: str, content: str) -> str` write `content` to a file, creating it first, should it not exist
  

- `typeof(val: any) -> str` returns type of a given value or variable



[latest-releases]: https://github.com/tuqqu/oxide-lang/releases/latest
[examples]: https://github.com/tuqqu/oxide-lang/tree/master/examples
[type-system]: /doc/type_system.md