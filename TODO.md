TODO: SciFi Demo

 - Add delta-time updates per frame
 - Add Material type:
    - Sortable to minimize texture switches
    - Bound (potentially) to Texture or cloned Texture (region)
    - Add repeat flags
 - Use frame buffers
    - Main FBO where we redirect all rendering
    - Draw main FBO with aspect ratio fixing
 - Find way to bind entities to the scene (load/unload)
 - Add Animations (frame-based)
 - Allow ignoring camera for background/UI elements
 - Add flip support to renderer
 - Add a player.
 - Add keyboard control
 - Add enemies


Reorganise the batcher:

 - Transient vertex buffer is technically more expensive.
 - Allocate large dynamic index/vertex buffer pair per batch
   and submit them all. Respect upper caps and all will work fine
   with large maps.


Make Life Easier:

Try to get `autoformat`, `dfmt` and `misspell` packaged up for
Solus to simplify `update_format.sh` usage.
