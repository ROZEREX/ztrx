// The fixer stage (`crate::pipeline::host::mesh_fixer`): ahead of an
// indirect call of a mesh pipeline too big for the launcher, it reads the
// title's record, bounds it as the argument clamp does, and writes it to a
// slot the call then reads; it launches no mesh groups. It runs on the
// drawing pipe: no switch to compute and back for each call.
struct Payload { uint unused; };
cbuffer Fix : register(b0, space91) { uint src_offset; uint dst_offset; };
ByteAddressBuffer src : register(t0, space91);
RWByteAddressBuffer dst : register(u0, space91);
groupshared Payload payload;
[numthreads(1, 1, 1)]
void main() {
    uint3 g = src.Load3(src_offset);
    // The console's mesh dispatches are one-dimensional; the record's other
    // two words are not counts.
    dst.Store3(dst_offset, uint3(min(g.x, 65535u), min(g.y, 1u), min(g.z, 1u)));
    DispatchMesh(0, 0, 0, payload);
}
