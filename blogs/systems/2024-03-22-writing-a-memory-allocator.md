---
title: Writing a Memory Allocator in C
date: 2024-03-22
tags: [c, memory, systems]
---

# Writing a Memory Allocator in C

Every C program leans on `malloc` and `free` without much thought.
In this post we rip out the guts of a simple allocator and build one from scratch.

## The Core Problem

The OS hands your process raw pages via `sbrk()` or `mmap()`.
Your allocator's job is to **carve that slab into chunks** and hand them out on request.

```c
typedef struct block {
    size_t        size;
    int           free;
    struct block *next;
} block_t;

#define BLOCK_SIZE sizeof(block_t)
```

## Free List Strategy

We keep a linked list of every allocated block. On `malloc`:

1. Walk the list for a free block that fits (first-fit / best-fit)
2. If none found — extend the heap with `sbrk(size)`
3. Mark the block as used and return a pointer past the header

```c
void *my_malloc(size_t size) {
    block_t *cur = head;

    while (cur) {
        if (cur->free && cur->size >= size) {
            cur->free = 0;
            return (void *)(cur + 1);   /* skip header */
        }
        cur = cur->next;
    }

    /* grow heap */
    block_t *blk = sbrk(BLOCK_SIZE + size);
    blk->size = size;
    blk->free = 0;
    blk->next = NULL;
    /* ... append to list */
    return (void *)(blk + 1);
}
```

## Why Alignment Matters

`sbrk` doesn't guarantee alignment. Unaligned access on x86 is slow;
on ARM it's a bus fault. Always round up to `sizeof(max_align_t)`:

```c
#define ALIGN(n) (((n) + sizeof(max_align_t) - 1) & ~(sizeof(max_align_t) - 1))
```

## Coalescing Free Blocks

Naive `free` causes **fragmentation** — lots of small gaps that can't
satisfy a large request even if total free memory is sufficient.
Fix it by merging adjacent free blocks during `free()`.

## Next Steps

- Implement best-fit vs first-fit and benchmark them
- Add a slab layer for fixed-size objects
- Use `mmap` instead of `sbrk` for large allocations
