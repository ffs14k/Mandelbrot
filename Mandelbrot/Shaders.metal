#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct ColorStop {
    float position;
    float3 color;
};

struct Uniforms {
    float2 center;
    float zoom;
    float aspectRatio;
    int maxIterations;
    int colorStopCount;
    float powerCurve;
    bool reversed;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.position;
    return out;
}

float3 getColorFromStops(float t, constant ColorStop* stops, int count, float powerCurve, bool reversed) {
    if (reversed) {
        t = 1.0 - t;
    }
    t = pow(t, powerCurve);
    
    if (count < 2) {
        return stops[0].color;
    }
    
    if (t <= stops[0].position) {
        return stops[0].color;
    }
    if (t >= stops[count - 1].position) {
        return stops[count - 1].color;
    }
    
    for (int i = 0; i < count - 1; i++) {
        ColorStop start = stops[i];
        ColorStop end = stops[i + 1];
        
        if (t >= start.position && t <= end.position) {
            float factor = (t - start.position) / (end.position - start.position);
            return start.color + (end.color - start.color) * factor;
        }
    }
    
    return stops[count - 1].color;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(0)]],
                              constant ColorStop* colorStops [[buffer(1)]]) {
    float2 c;
    c.x = in.texCoord.x * uniforms.aspectRatio / uniforms.zoom + uniforms.center.x;
    c.y = in.texCoord.y / uniforms.zoom + uniforms.center.y;
    
    float2 z = float2(0.0, 0.0);
    int iterations = 0;
    float smoothValue = 0.0;
    
    for (int i = 0; i < uniforms.maxIterations; i++) {
        float x = (z.x * z.x - z.y * z.y) + c.x;
        float y = (2.0 * z.x * z.y) + c.y;
        
        z = float2(x, y);
        iterations = i;
        
        if (length(z) > 4.0) {
            smoothValue = float(i) + 1.0 - log2(log2(dot(z, z)));
            break;
        }
    }
    
    if (iterations == uniforms.maxIterations - 1) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    
    float t = smoothValue / float(uniforms.maxIterations);
    float3 color = getColorFromStops(t, colorStops, uniforms.colorStopCount, uniforms.powerCurve, uniforms.reversed);
    
    return float4(color, 1.0);
}

