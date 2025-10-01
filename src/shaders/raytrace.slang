import "./include/uv.slang";
import "./include/rand.slang";
import "./include/util.slang";
import "./include/ray.slang";
import "./include/objects.slang";
import "./include/material.slang";

struct Params {
    float2 resolution;
};

layout(location = 0) ConstantBuffer<Params> params;

struct VOut {
    float4 position : SV_Position;
    float2 uv;
    float2 ndc;
    nointerpolation float aspect;
    nointerpolation float2 pixelDelta;
};


[shader("vertex")]
VOut vert(BasicVIn i) {
    BasicVOut o = basicVertex(i);
    VOut v;
    v.position = o.position;
    v.uv = o.uv;

    v.ndc = (v.uv * 2.0) - 1.0;

    v.aspect = params.resolution.x / params.resolution.y;

    v.pixelDelta = 1.0 / params.resolution;

    return v;
}

struct World<H: Hittable, let size: int> {
    H[size] objects;

    __init(H[size] objects) {
        this.objects = objects;
    }

    Optional<Hit> hit(in Ray ray, Interval interval) {
        Optional<Hit> closestHit = none;
        for (int i = 0; i < size; i++) {
            let hit = objects[i].hit(ray, interval);
            if (hit.hasValue) {
                let h = hit.value;
                if (closestHit.hasValue) {
                    if (h.t < closestHit.value.t) {
                        closestHit = h;
                    }
                } else {
                  closestHit = h;
                }
            }
        }
        return closestHit;
    }

    float4 color(Ray ray, Interval interval, float2 ndc) {
        bool hitSomething = false;
        float3 color = float3(1, 1, 1);

        var r = ray;
        var inter = interval;
        for (int i = 0; i < 50; i++) {
            if (let hitConst = this.hit(r, inter)) {
                hitSomething = true;
                var hit = hitConst;
                if (let pair = hit.mat.scatter(r, hit)) {
                    r = pair.scattered;
                    color *= float3(pair.attenuation);
                } else {
                    color = float3(0, 0, 0);
                    break;
                }
            } else {
                if (hitSomething) {
                    color *= lerp(float3(0.3, 0.5, 1.0), float3(1.0), 1.0 - ndc.y);
                }
                break;
            }
        }

        if (hitSomething) {
            return float4(color, 1.0);
        }
      
        return lerp(float4(0.3, 0.5, 1.0, 1.0), float4(1.0), 1.0 - ndc.y);
    }
}

[shader("fragment")]
float4 frag(VOut i) : SV_Target {
    float4 hitColor = float4(0, 0, 0, 1);

    float2 adjNdc = i.ndc;
    adjNdc.x *= i.aspect;

    Ray ray;
    ray.origin = float3(0, 0, 0);
    ray.dir = float3(adjNdc, -1.0);

    Interval tInterval = Interval(0.001, 1.#INF);

    Material groundMat = Lambertian(float3(0.8, 0.8, 0.0));
    Material centerMat = Lambertian(float3(0.1, 0.2, 0.5));
    Material leftMat = Dielectric(1. / 1.33);
    Material rightMat = Metal(float3(0.8, 0.6, 0.2), 0.2);

    Sphere ground = Sphere(float3(0, -100.5, -1), 100.0, groundMat);
    Sphere middle = Sphere(float3(0, 0, -1.2), 0.5, centerMat);
    Sphere left = Sphere(float3(-1.0, 0, -1), 0.5, leftMat);
    Sphere right = Sphere(float3(1.0, 0, -1), 0.5, rightMat);

    let world = World<Sphere, 4>({ground, middle, left, right});

    let finalColor = world.color(ray, tInterval, i.uv);

    // linear to sRGB
    return float4(finalColor.rgb, finalColor.a);
}