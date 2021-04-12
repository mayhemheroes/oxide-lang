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
/// structs

struct Circle {                 // struct declaration
    pub radius: float,          // public field
    center: Point,              // private field
    tangents: vec<Tangent>,     
}

impl Circle {                   // struct implementation
    const PI = 3.14159;         // private associated constant

    pub fn new(radius: float, center: Point) -> Self {    // public static method
        return Self {
            radius: radius,
            center: center,
            tangents: vec[],
        }
    }
  
    pub fn calc_area(self) -> float {                     // public method
        return Self::PI * self.radius * self.radius;
    }
  
    pub fn add_tangent(self, t: Tangent) {      
        self.tangents.push(t);
    }
}

struct Point {
    pub x: int,
    pub y: int,
}

struct Tangent {
    p: Point,
}

// instantiation via static constructor
let circle_a = Circle::new(200, Point { x: 1, y: 5 });

// direct instantiation
let circle_b = Circle {      
    radius: 103.5,
    center: Point { x: 1, y: 5 } ,             // inner structs instantiation
    tangents: vec[                             // inner vector of structs instantiation
        Tangent { p: Point { x: 4, y: 3 } },
        Tangent { p: Point { x: 1, y: 0 } },
    ],
};

let area = circle_a.calc_area();  // 33653.4974775
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

let make_adder = fn (x: num) -> fn {
    return fn (y: num) -> num {
        return x + y;
    };
};

let add5: fn = make_adder(5);
let add7: fn = make_adder(7);

println(add5(2)); // 7
println(add7(2)); // 9
```

```rust
/// enums

enum Ordering {
    Less,
    Equal,
    Greater
}

fn compare(a: int, b: int) -> Ordering {
    return match true {
        a < b => Ordering::Less,
        a == b => Ordering::Equal,
        a > b => Ordering::Greater,
    };
}

let order: Ordering = compare(10, 5); // Ordering::Greater
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

To print current Oxide version
```shell
oxide version
```

## Building from source
If your architecture is not supported by the pre-built binaries you can build the interpreter from the source code yourself. Make sure you have Rust installed.

```shell
git clone https://github.com/tuqqu/oxide-lang.git
cd oxide-lang
cargo install --path . # copies binary to /.cargo/bin/

# you can now run it with
oxide script.ox

# to uninstall run
cargo uninstall
```

# Quick Overview

* [Variables and Type System](#variables-and-type-system)
    * [Mutability](#mutability)
    * [Shadowing](#shadowing)
* [Control Flow and Loops](#control-flow-and-loops)
    * [If](#if)
    * [Match](#match)
    * [While](#while)
    * [Loop](#loop)
    * [For](#for)
* [Functions](#functions)
    * [Declared functions](#declared-functions)
    * [Closures and Lambdas](#closures-and-lambdas)
* [Structs](#structs)
* [Enums](#enums)
* [Vectors](#vectors)
* [Constants](#constants)
* [Operators](#operators)
    * [Unary](#unary)
    * [Binary](#binary)
* [Comments](#comments)
* [Standard library](#standard-library)


## Variables and Type System

There are eleven types embodied in the language: `nil`, `num`, `int`, `float`, `bool`, `str`, `fn`, `vec`, `any` and user-defined types (via [`structs`](#structs) and [`enums`](#enums)). See [type system][type-system]

Each variable has a type associated with it, either explicitly declared with the variable itself:

```rust
let x: int;

let mut y: str = "hello" + " world";

let double: fn = fn (x: num) -> num { return x * 2; };

let human: Person = Person { name: "Jane" };

let names: vec<str> = vec["Josh", "Carol", "Steven"];
```

or implicitly inferred by the interpreter the first time it is being assigned:

```rust
let x;
x = true || false;              // inferred as "bool"

let y = vec<bool>[];            // inferred as "vec<bool>"

let dog;
dog = Dog::new("Good Boy");     // inferred as "Dog"

let ordering = Ordering::Less; // inferred as "Ordering"
```

Mutable variables cannot be assigned to a value of another type, unless they are of type `any`:

```rust
let mut s: str = "string";
s = vec[];                      //! type error

let mut a: any = Rectangle { 
    height: 10,                 // height is of type int
    width: 10 
};
a.height = "string";            //! type error
a = 45.34;                      // valid
```

### Mutability

Variables can be immutable and mutable. Immutable ones cannot be reassigned after having been assigned to a value.

```rust
let x = "a";
x = "b"; //! error, x is immutable
```

However, mutable ones behave like you would expect a variable to behave in most other languages:

```rust
let mut x: str = "hello";
x += " world";
x += "another string"; // ok
```

### Shadowing

One important thing is that variables can be redeclared in other words, shadowed. Each variable declaration "shadows" the previous one and ignores its type and mutability. Consider:

```rust
let x: int = 100;
let x: Circle = Circle::new(10, Point { x: x, y: 5 });
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
let direction = match get_direction() {
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

`match` can be used with [enums](#enums)

```rust
enum HttpStatus {
    NotFound,
    NotModified,
    Ok
}

fn code(status: HttpStatus) -> int {
    return match status {
        HttpStatus::NotFound => 404,
        HttpStatus::NotModified => 304,
        HttpStatus::Ok => 200,
    };
}

let status = code(HttpStatus::Ok); // 200
```

### While

There are three loops in Oxide: `while`, `loop` and `for`. 

Loops support `break` and `continue` statements. Loop body must be enclosed in curly braces.

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
for let mut i = 0; i < v.len(); i += 1 {
    println(v[i]);
}

// the first or the last parts can be omitted
let mut i = 0;

for ; i < v.len(); {
    println(v[i]);
    i += 0;
}

// or all three of them
// this is basically "while true" or "loop"
let mut i = 0;

for ;; {
    println(v[i]);
    i -= 1;

    if i < v.len() {
        break;
    }
}
```

## Functions

### Declared functions

Functions are declared with a `fn` keyword. 

Function signature must explicitly list all argument types as well as a return type.

Functions that do not have a `return` statement implicitly return `nil` and the explicit return type can be omitted (same as declaring it with `-> nil`)

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

Defining a function argument as `mut` lets you mutate it in the function body. By default, it is immutable.

```rust
/// compute the greatest common divisor 
/// of two integers using Euclids algorithm

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

Redeclaring a function results in a runtime error.

### Closures and Lambdas

Functions are first-class citizens of the language, they can be stored in a variable of type `fn`, passed to or/and returned from another function.

```rust
/// function returns closure
/// which captures the internal value i
/// each call to the closure increments the captured value
fn create_counter() -> fn {
    let mut i = 0;

    return fn () {                  // returns closure
        i += 1;
        println(i);
    };
}

let counter = create_counter();     // inferred as "fn"

counter(); // 1
counter(); // 2
counter(); // 3
```

Declared functions can be passed by their name directly

```rust
fn str_concat(prefix: str, suffix: str) -> str {
    return prefix + suffix;
}

fn str_transform(callable: fn, a: str, b: str) -> any {
    return callable(a, b);
}

str_transform(str_concat, "hello", " world");
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

Structs represent the user-defined types. Struct declaration starts with `struct` keyword.
All struct properties are mutable by default.

You can make property public with a `pub` keyword. Public fields can be accessed from outside scope.

```rust
struct StellarSystem {           
    pub name: str,               // public field
    pub planets: vec<Planet>,    // public vector of structs
    pub star: Star,         
    age: int                     // private field
}

struct Star { 
    pub name: str,
    mass: int,                  
}

struct Planet {
    pub name: str,
    mass: int,
    belt: bool,
}
```

Struct implementation starts with `impl` keyword.
While struct declaration defines its properties, struct implementation defines its methods, static methods and constants.

* `self` keyword can be used inside methods and points to the current struct instance. i.e `self.field`
* `Self` (capitalised) keyword can be used inside methods to point to the current struct name, i.e. `Self::CONSTANT` or `Self::static_method(x)`, it can be used as a type as well `let p: Self = Self { .. };`

You can make methods and constants public with a `pub` keyword. Public methods and constants can be accessed from outside scope.

Methods with `self` as the first argument are instance methods. Methods without it are static methods. 

```rust
impl Star {                      
    pub const WHITE_DWARF = 123.3;     // public associated constants
    pub const NEUTRON_STAR = 335.2;    // lets pretend those values are real
    pub const BLACK_HOLE = 9349.02;  
  
    const MAX_AGE = 99999;             // private constant
  
    pub fn new(name: str, mass: int) -> Self {  // public static method
        return Self {
            name: name,
            mass: mass,
        }
    }
    
    pub fn get_description(self) -> str {  // public instance method
        return match true {
            self.mass <= Self::WHITE_DWARF => "white dwarf",
            self.mass > Self::WHITE_DWARF && self.mass <= Self::BLACK_HOLE => "neutron star",
            self.mass >= Self::BLACK_HOLE => "black hole",
        };
    }
}

impl Planet {
    pub fn set_new_mass(self, mass: int) {
        self.mass = mass;
    }

    fn is_heavier(self, p: Self) -> bool {      // private method
        return self.mass > p.mass;
    }
}
```

You need to initialize all structs properties on instantiation.

```rust
let planet_mars: Planet = Planet {                   
    name: "Mars",
    mass: 100,
    belt: false,
};

let system = StellarSystem {
    name: "Solar System",
    star: Star { name: "Sun", mass: 9999 },
    planets: vec[
        planet_mars,                                        // via variable
        Planet { name: "Earth", belt: false, mass: 120 }    // via inlined struct instantiation
    ],    
    age: 8934,
};

let arcturus = Planet::new("Arcturus", 4444);  // creating instance via static method
```

Dot syntax `.` is used to access structs fields and call its methods.

```rust
// set new value
system.name = "new name";
system.planets.push( Planet {
    name: "Venus",
    belt: false,
    mass: 90,
});

// get value
let mars_name: str = system.planets[0].name;

// call method
let star_descr: str = system.star.get_description();
system.planets[0].set_new_mass(200);
```

`::` is used to access constants
```rust
let dwarf_mass: int = Star::WHITE_DWARF;

impl Star {
    const MAX_AGE = 99999; 
    
    // inside methods Self:: can be used instead
    pub fn get_max_age() -> int {
        return Self::MAX_AGE;
    }
}
```

Immutable variable will still let you change the struct's fields, but it will prevent you from overwriting the variable itself. Similar to Javascript `const` that holds an object.

```rust
system.name = "new name";              // valid
system.planets[0].name = "new name";   // also valid
system = StellarSystem { ... };         //! error, "system" cannot point to another struct
```

Structs are always passed by reference, consider:

```rust
fn remove_planets(s: StellarSystem) {
    s.planets = vec<Planet>[];  // oh, all planets are removed
}

remove_planets(system);
```
### Public and Private

Only public properties, methods and constants can be accessed from outside code.

```rust
system.age = 100;                //! access error, "age" is private
system.planets[0].mass;          //! access error, "mass" is private
system.planets[0].is_heavier(p); //! access error, "is_heavier()" is private
Star::MAX_AGE;                   //! access error, "Star::MAX_AGE" is private
```

## Enums

Same as structs, enums represent user-defined types. Enums are quite simple and similar to C-style enums.

```rust
enum TimeUnit {
    Seconds,
    Minutes,
    Hours,
    Days,
    Months,
    Years,
}

let days = TimeUnit::Days; // inferred type as "TimeUnit"
```

Equality of enum values can be checked with `==` and `!=`

```rust
days == TimeUnit::Days;             // true
TimeUnit::Years == TimeUnit::Hours; // false
```

Or better with `match`

```rust
fn plural(time: TimeUnit) -> str {
    return match time {
        TimeUnit::Seconds => "seconds",
        TimeUnit::Minutes => "minutes",
        TimeUnit::Hours => "hours",
        TimeUnit::Days => "days",
        TimeUnit::Months => "months",
        TimeUnit::Years => "years"
    };
}
```

Different types of enum values are not compatible and comparing them will trigger an error

```rust
enum Ordering {
    Less,
    Equal,
    Greater
}

Ordering::Less == TimeUnit::Days; //! type error
```

## Vectors

Vectors, values of type `vec<type>`, represent arrays of values and can be created using `vec<type>[]` syntax, where `type` is any Oxide type.

Vectors have built-in methods:
* `vec.push(val: any)` push value to the end of the vector
* `vec.pop() -> any` remove value from the end of the vector and return it
* `vec.len() -> int` get vectors length

```rust
let planets = vec<str>["Mercury", "Venus", "Earth", "Mars"];

planents.push("Jupiter");    // "Jupiter" is now the last value in a vector
let jupiter = planets.pop(); // "Jupiter" is no longer in a vector.

let mars = planets[3];       // mars = "Mars"
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

Like structs vectors are passed by reference. 

Consider this example of an in place sorting algorithm, selection sort, that accepts a vector and sorts it in place, without allocating memory for a new one.

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

const SOME_THRESHOLD = 100;

const EPSILON = 0.004;
```

Struct implementations (`impl` blocks) can also define constants. Those constants can be either public or private.
```rust
struct Math {};

impl Math {
    pub const PI = 3.14159265;  // public const
    const E = 2.71828182846;    // private const
  
    pub fn get_e() -> float {
        return Self::E;         // Self:: is the same as Math:: inside methods
    }
}
```

Accessing private consts from outer scope will result in an error.

```rust
let pi = Math::PI;     // ok
let e = Math::E;       //! access error
let e = Math::get_e(); // ok
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
- `typeof(val: any) -> str` returns type of given value or variable



[latest-releases]: https://github.com/tuqqu/oxide-lang/releases/latest
[examples]: https://github.com/tuqqu/oxide-lang/tree/master/examples
[type-system]: /doc/type_system.md