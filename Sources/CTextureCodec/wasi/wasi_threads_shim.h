// Force-included (-include) into every CTextureCodec source in WebAssembly builds only
// (ENGINE_WASM=1, see Package.swift). Single-threaded WASI (wasm32-unknown-wasip1) libc++ has no
// std::mutex or std::condition_variable (_LIBCPP_HAS_THREADS is 0), which astc-encoder's context
// (vendor/astcenc/astcenc_internal_entry.h) and codec.cpp use. With one thread nothing is ever
// contended, so the no-op types below stand in and the vendored sources compile unmodified.
// std::lock_guard and std::unique_lock are templates libc++ still provides; they lock these.
#pragma once

#if defined(__cplusplus) && defined(__wasi__)
#include <mutex>
#include <condition_variable>

#if !_LIBCPP_HAS_THREADS
#include <cstdlib>

namespace std {

class mutex {
public:
    constexpr mutex() noexcept = default;
    mutex(const mutex &) = delete;
    mutex &operator=(const mutex &) = delete;
    void lock() {}
    bool try_lock() { return true; }
    void unlock() noexcept {}
};

// astc-encoder waits only for work other threads are finishing (after the calling thread has
// already done all of it alone), so a wait whose predicate is false could never end.
class condition_variable {
public:
    condition_variable() = default;
    condition_variable(const condition_variable &) = delete;
    condition_variable &operator=(const condition_variable &) = delete;
    void notify_one() noexcept {}
    void notify_all() noexcept {}
    void wait(unique_lock<mutex> &) { abort(); }
    template <class Predicate> void wait(unique_lock<mutex> &, Predicate pred) {
        if (!pred()) abort();
    }
};

} // namespace std
#endif // !_LIBCPP_HAS_THREADS
#endif // __cplusplus && __wasi__
