//
//  PaperShaders.metal
//  himekuri
//
//  A falling sheet is not rigid: it ripples softly as it planes on the air.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] float2 paperFlex(float2 position,
                                  float2 size,
                                  float time,
                                  float amp) {
    float u = clamp(position.x / size.x, 0.0, 1.0);
    float v = clamp(position.y / size.y, 0.0, 1.0);
    float bend = sin(u * 3.14159 + time * 2.4) * amp * (0.35 + 0.65 * v);
    return position - float2(0.0, bend);
}
