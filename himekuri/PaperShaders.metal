//
//  PaperShaders.metal
//  himekuri
//
//  Paper deformation. The pull uses the classic e-book curl model — a virtual
//  cylinder the sheet rolls over (arc length s = r·asin(d/r)) — combined with
//  a progressive tear front: fibers release from the grabbed side first.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The pull is a layer effect (not just a distortion) so the rolled-over BACK
// of the sheet can be painted: blank paper stock, lit as a cylinder — the
// classic e-book page-curl model (θ = asin(d/r); front arc θ·r, back (π−θ)·r).
[[ stitchable ]] half4 paperSheet(float2 position,
                                  SwiftUI::Layer layer,
                                  float2 size,
                                  float2 grab,   // grab point in layer coords
                                  float2 pull,   // drag translation in points
                                  float tearY,   // layer y of the tear line
                                  float hold,    // 0..1 fingers pressing the sheet
                                  float2 torn,   // persistent seam: (center x, parted half-width)
                                  half4 paper) { // blank stock color for the back
    float pullLen = length(pull);
    if (pullLen < 0.5 && hold < 0.01 && torn.y < 1.0) { return layer.sample(position); }

    float span = max(size.y - tearY, 1.0);
    float sBelow = position.y - tearY;
    if (sBelow <= 0.0) { return layer.sample(position); } // held fast under the staples
    float v = clamp(sBelow / span, 0.0, 1.0);

    float mag = clamp(pullLen / 110.0, 0.0, 1.0);
    // Downward/sideways tension bows the sheet; upward drag folds it over.
    float tens = clamp(length(float2(pull.x, max(pull.y, 0.0))) / 110.0, 0.0, 1.0);
    float L = -min(pull.y, 0.0); // upward hand travel in points

    // Tear front: fibers let go at the grabbed side first, racing across
    // the sheet as the pull deepens. Columns past the front stay attached.
    float dGrab = abs(position.x - grab.x);
    float frontX = mix(size.x * 0.4, size.x * 1.6, mag);
    float release = 0.15 + 0.85 * smoothstep(frontX + 55.0, frontX - 55.0, dGrab);

    // Fibers already parted on earlier pulls stay parted: those columns
    // hang free no matter where the fingers are now.
    float relOld = torn.y < 1.0 ? 0.0
        : smoothstep(torn.y + 45.0, torn.y - 45.0, abs(position.x - torn.x));
    release = max(release, relOld);

    float2 toGrab = position - grab;
    float r2 = dot(toGrab, toGrab);
    float dimple = exp(-r2 / (2.0 * 85.0 * 85.0));
    float core = exp(-r2 / (2.0 * 38.0 * 38.0));
    // Half-torn at rest: the released side hangs a few points lower off the
    // remaining fibers, opening the seam just below the staples.
    float sag = 8.0 * relOld * smoothstep(0.0, 0.22, v);
    // D-CONE: paper is stiff in-plane, so a point grab does NOT gather into
    // radial folds like cloth — it forms one smooth developable cone whose
    // crescent-shaped buckle sits OFF the load point, on the slack side
    // below the fingers (the staple side above is taut).
    float2 toCone = position - (grab + float2(0.0, 16.0));
    float coneFall = exp(-(toCone.x * toCone.x) / (2.0 * 58.0 * 58.0)
                         - (toCone.y * toCone.y) / (2.0 * 95.0 * 95.0));

    if (L > 0.5) {
        // ---- LIFT: a MIRROR FOLD, the way a wall-calendar page really flips.
        // The crease sits between the staples and the fingers, advancing at
        // about half the hand's travel (a touch ahead on the torn side), and
        // the flipped-over part — blank back showing — climbs the page.
        float pageBottom = size.y - 210.0; // Metrics.shaderPadBottom
        float upSpan = max(0.8 * (grab.y - tearY), 90.0);
        float lr = clamp(L / upSpan, 0.0, 1.0);
        float r = mix(58.0, 36.0, lr); // the roll tightens as tension builds
        float adv = L * (0.42 + 0.18 * release);
        float yc = max(grab.y - adv, tearY + 6.0);
        float sx = position.x - pull.x * v * 0.5;
        float len = pageBottom - yc;       // sheet length folded past the crease
        float tail = len - 3.14159 * r;    // flat flipped-over part above it
        float d = position.y - yc;

        if (d >= r) { return half4(0.0); } // the sheet has left; the pad shows

        if (d >= 0.0) {
            // On the roll of the fold.
            float phi = asin(clamp(d / r, 0.0, 1.0));
            float sBack = r * (3.14159 - phi);
            if (len >= sBack) {
                // Rolled-over back: blank stock on a lit cylinder, brightest
                // at the crest, shading into the crease.
                half a = layer.sample(float2(sx, yc + sBack)).a;
                half shade = half(0.72 + 0.28 * (d / r));
                return half4(paper.rgb * shade * a, a);
            }
            float sFront = r * phi;
            if (len >= sFront) {
                half4 c = layer.sample(float2(sx, yc + sFront));
                return half4(c.rgb * half(1.0 - 0.20 * (d / r)), c.a);
            }
            return half4(0.0);
        }

        // Above the crease: the flipped tail lies on top, blank side out,
        // its free edge chasing the hand up the page.
        if (tail > 0.0 && position.y > yc - tail) {
            float srcY = yc + 3.14159 * r + (yc - position.y);
            half a = layer.sample(float2(sx, srcY)).a;
            return half4(paper.rgb * half(0.965) * a, a);
        }

        // Bare front, still flat on the pad: light tension pinch.
        float press = clamp(hold * 0.35 + lr * 0.5, 0.0, 1.0);
        float2 pinch = toGrab * (0.03 * press) * coneFall;
        return layer.sample(float2(sx + pinch.x, position.y + pinch.y - sag));
    }

    // ---- PULL DOWN / AT REST: inextensible bow + d-cone pinch. ----
    // Paper cannot elongate: pulling bows the sheet toward the viewer, so
    // its projection gets shorter; pressing lifts it a hair too.
    float shorten = 0.085 * tens * release + 0.006 * hold;
    float srcY = tearY + sBelow / max(1.0 - shorten, 0.4);
    srcY = min(srcY, min(size.y - 2.0, position.y + 250.0));

    // The only real downward travel: slack at the staples and the pinch of
    // the fingers dragging the paper locally near the grab point. A tight
    // core tracks the fingers closely so the sheet feels truly held.
    float give = 12.0 * tanh(pull.y / 70.0) * pow(v, 1.4) * release;
    give += max(pull.y, 0.0) * (0.18 * dimple + 0.30 * core);
    give += sag;

    // Sideways pull rotates/shears the sheet — no stretch involved. The
    // grabbed spot follows the fingers more tightly than the body.
    float shear = pull.x * v * release * 0.7
        + pull.x * (0.15 * dimple + 0.25 * core);

    // Subtle bow across the width.
    float acrossBow = 4.0 * v * tens * release
        * sin(3.14159 * clamp(position.x / size.x, 0.0, 1.0));

    float press = clamp(hold * 0.35 + tens * 0.80, 0.0, 1.0);
    float2 pinch = toGrab * (0.035 * press) * coneFall;

    return layer.sample(float2(position.x - shear + pinch.x,
                               srcY - give - acrossBow + pinch.y));
}

// A falling sheet is not rigid: it ripples softly as it planes on the air.
[[ stitchable ]] float2 paperFlex(float2 position,
                                  float2 size,
                                  float time,
                                  float amp) {
    float u = clamp(position.x / size.x, 0.0, 1.0);
    float v = clamp(position.y / size.y, 0.0, 1.0);
    float bend = sin(u * 3.14159 + time * 2.4) * amp * (0.35 + 0.65 * v);
    return position - float2(0.0, bend);
}
