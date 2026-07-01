#![no_main]

//! Fuzz the Oxide lexer + recursive-descent parser via the crate's public API.
//!
//! This drives the *real* front-end the `oxide` CLI used to exercise via `/oxide @@`
//! (lex the source, then parse the token stream into an AST), but through the
//! library's non-diverging public entry points — `Lexer::tokenize` returns
//! `(tokens, errors)` and `Parser::parse` returns a `Result`, so malformed input
//! is reported as data, never as a crash. Any panic / memory-safety fault the
//! sanitizer catches here is a genuine defect in the lexer or parser.

use libfuzzer_sys::fuzz_target;
use oxide_parser::{Lexer, Parser};

fuzz_target!(|data: &[u8]| {
    // Oxide source is text; only feed the lexer valid UTF-8 (the CLI reads the
    // script with fs::read_to_string, which is UTF-8). Non-UTF-8 is not a
    // parser input, so skip it rather than reject it as a "crash".
    let src = match std::str::from_utf8(data) {
        Ok(s) => s.to_owned(),
        Err(_) => return,
    };

    let mut lexer = Lexer::new(src);
    let (tokens, _errors) = lexer.tokenize();

    // Parse whatever tokens the lexer produced (even on lex errors, tokens are
    // still emitted up to that point), matching Engine::ast's flow.
    let mut parser = Parser::new(tokens.to_vec());
    let _ = parser.parse();
});
