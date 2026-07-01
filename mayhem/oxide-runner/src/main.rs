//! Additive file-input runner for Mayhem — the sanitized successor to the original
//! `/oxide @@` target. It reads a source file, then drives the FULL Oxide pipeline
//! (lex -> parse -> interpret) exactly like the upstream `oxide` CLI, using the
//! library's public `Engine`. We do NOT edit the upstream oxide-cli crate; this is
//! a standalone additive binary so we can (a) always allow top-level statements
//! (more interpreter coverage) and (b) bake in ASan options.
//!
//! `__asan_default_options` disables LeakSanitizer: the interpreter intentionally
//! keeps the global stdlib env / Rc-graph alive to program exit (the OS reclaims
//! it), so LSan-at-exit would flag every run as a leak and mask real UAF/OOB/
//! overflow faults. Baking it into the binary keeps the target self-contained
//! (no Mayhemfile env dependency).

use std::os::raw::c_char;
use std::{env, fs, process};

use oxide_interpreter::Engine;

#[no_mangle]
pub extern "C" fn __asan_default_options() -> *const c_char {
    b"detect_leaks=0\0".as_ptr() as *const c_char
}

fn on_error(errs: &[Box<dyn std::error::Error>]) -> ! {
    for err in errs {
        eprintln!("{}", err);
    }
    process::exit(1);
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: oxide <file>");
        process::exit(1);
    }
    let path = &args[1];
    let contents = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(_) => process::exit(1), // unreadable input is not a target defect
    };

    let engine = Engine::new(on_error);
    let ast = engine.ast(contents);
    // Always allow top-level instructions so scripts without a main() are still
    // interpreted (maximizes coverage of the interpreter, not just the parser).
    let _ = engine.run(&ast, &args[1..], None);
}
