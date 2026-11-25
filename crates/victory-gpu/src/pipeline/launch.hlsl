struct Payload { uint unused; };
// mode 0: a direct dispatch of `direct_x` groups; 1: one record at
// `args_offset`; 2: records `stride` apart, as many as the count buffer
// says, at most `most`; 3: `most` records. One launcher group a record.
cbuffer Launch : register(b0, space90) {
    uint args_offset; uint direct_x; uint mode; uint stride; uint count_offset; uint most; uint pad0; uint pad1;
};
ByteAddressBuffer args : register(t0, space90);
ByteAddressBuffer count_buf : register(t1, space90);
groupshared Payload payload;
[numthreads(1, 1, 1)]
void main(uint3 group : SV_GroupID) {
    uint3 g = uint3(direct_x, 1, 1);
    if (mode == 1) {
        g = args.Load3(args_offset);
    } else if (mode >= 2) {
        uint n = mode == 2 ? min(most, count_buf.Load(count_offset)) : most;
        g = group.x < n ? args.Load3(args_offset + group.x * stride) : uint3(0, 0, 0);
    }
    // As the argument clamp bounds a mesh record: the console's mesh
    // dispatches are one-dimensional, and the record's other two words
    // are not counts (taken whole, a large one emptied the draw).
    g = uint3(min(g.x, 65535u), min(g.y, 1u), min(g.z, 1u));
    DispatchMesh(g.x, g.y, g.z, payload);
}
