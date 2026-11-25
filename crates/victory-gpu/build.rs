//! The shader cache's key names the translator, not the whole executable
//! (`src/shader_cache.rs`, `build`): a hash of the shader translator's
//! sources, the lock file and the cache's own encoding. A change elsewhere
//! (the renderer, the runtime) keeps the cached translations; keyed by the
//! executable's bytes, every build translated all of the game's shaders
//! again on its first run (minutes of slow frames and late walls).

use std::path::{Path, PathBuf};

fn files(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else { return };
    for e in entries.flatten() {
        let path = e.path();
        if path.is_dir() {
            files(&path, out);
        } else {
            out.push(path);
        }
    }
}

/// FNV-1a, 64 bits: the same answer from every toolchain.
fn fnv(hash: &mut u64, bytes: &[u8]) {
    for &b in bytes {
        *hash ^= u64::from(b);
        *hash = hash.wrapping_mul(0x0100_0000_01b3);
    }
}

fn main() {
    let here = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").expect("cargo sets it"));
    let shader = here.join("../victory-shader");
    let mut inputs = Vec::new();
    files(&shader.join("src"), &mut inputs);
    inputs.push(shader.join("Cargo.toml"));
    inputs.push(here.join("../../Cargo.lock"));
    inputs.push(here.join("src/shader_cache.rs"));
    inputs.sort();
    let mut hash = 0xcbf2_9ce4_8422_2325u64;
    for path in &inputs {
        let name = path.strip_prefix(&here).unwrap_or(path).to_string_lossy().replace('\\', "/");
        fnv(&mut hash, name.as_bytes());
        if let Ok(bytes) = std::fs::read(path) {
            fnv(&mut hash, &bytes);
        }
    }
    // The translator's own features change what it emits.
    for feature in ["DIAGNOSTICS"] {
        fnv(&mut hash, format!("{feature}={}", std::env::var_os(format!("CARGO_FEATURE_{feature}")).is_some()).as_bytes());
    }
    println!("cargo:rustc-env=VICTORY_TRANSLATOR_HASH={hash:016x}");
    println!("cargo:rerun-if-changed={}", shader.join("src").display());
    println!("cargo:rerun-if-changed={}", shader.join("Cargo.toml").display());
    println!("cargo:rerun-if-changed={}", here.join("../../Cargo.lock").display());
    println!("cargo:rerun-if-changed={}", here.join("src/shader_cache.rs").display());
}
