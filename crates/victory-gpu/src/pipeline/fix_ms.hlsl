// The fixer's mesh stage: never launched (the fixer stage asks for no
// groups); a pipeline needs one.
struct Payload { uint unused; };
struct Vertex { float4 position : SV_Position; };
[outputtopology("triangle")]
[numthreads(1, 1, 1)]
void main(in payload Payload p, out vertices Vertex verts[1], out indices uint3 tris[1]) {
    SetMeshOutputCounts(0, 0);
    // (written for the validator; with no vertices nothing reads it)
    if (p.unused == 0xFFFFFFFFu) {
        verts[0].position = float4(0, 0, 0, 1);
        tris[0] = uint3(0, 0, 0);
    }
}
