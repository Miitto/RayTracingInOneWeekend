import "./include/uv.slang";
import "./include/rand.slang";
import "./include/util.slang";
import "./include/ray.slang";
import "./include/objects.slang";
import "./include/material.slang";

struct Params {
    float2 resolution;
    float vFov;
    float focalLength;
    float backgroundBrightness;
    uint raysPerPixel;
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

float4 background(float2 ndc) {
    return lerp(float4(0.3, 0.5, 1.0, 1.0), float4(1.0), 1.0 - ndc.y) * params.backgroundBrightness;
}

struct World<let size: int> {
    Hittable[size] objects;

    __init(Hittable[size] objects) {
        this.objects = objects;
    }

    Optional<Hit> hit(in Ray ray, Interval interval) {
        Optional<Hit> closestHit = none;
        for (int i = 0; i < size; i++) {
            if (let hit = objects[i].hit(ray, interval)) {
                if (closestHit.hasValue) {
                    if (hit.t <= closestHit.value.t) {
                        closestHit = hit;
                    }
                } else {
                  closestHit = hit;
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

                // TODO: Get proper UV
                let emmission = hit.mat.emitted(float2(0, 0));

                if (let pair = hit.mat.scatter(r, hit, ndc)) {
                    r = pair.scattered;
                    color *= emmission + float3(pair.attenuation);
                } else {
                    color *= emmission;
                    break;
                }
            } else {
                if (hitSomething) {
                    color *= background(ndc).rgb;
                }
                break;
            }
        }

        if (hitSomething) {
            return float4(color, 1.0);
        }
      
        return background(ndc);
    }
}

World<6> sphereScene() {
 Material groundMat = Lambertian(float3(0.8, 0.8, 0.0));
    Material centerMat = Lambertian(float3(0.1, 0.2, 0.5));
    Material leftMat = Dielectric(1.5);
    Material leftInnerMat = Dielectric(1. / 1.5);
    Material rightMat = Metal(float3(0.8, 0.6, 0.2), 0.2);
    Material lightMat = DiffuseLight(float3(4, 4, 4));

    Sphere ground = Sphere(float3(0, -100.5, -1), 100.0, groundMat);
    Sphere middle = Sphere(float3(0, 0, -1.2), 0.5, centerMat);
    Sphere left = Sphere(float3(-1.0, 0, -1), 0.5, leftMat);
    Sphere leftInner = Sphere(float3(-1.0, 0, -1), 0.4, leftInnerMat);
    Sphere right = Sphere(float3(1.0, 0, -1), 0.5, rightMat);
    let light = Quad(float3(-5, 3, -5), float3(10, 0, 0), float3(0, 0, 10), lightMat);

    let world = World<6>({ground, middle, left, leftInner, right, light});

    return world;
}

World<8> cornellScene() {
    Material red = Lambertian(float3(0.65, 0.05, 0.05));
    Material white = Lambertian(float3(0.73, 0.73, 0.73));
    Material green = Lambertian(float3(0.12, 0.45, 0.15));
    Material lightMat = DiffuseLight(float3(15, 15, 15));

    let leftWall = Quad(float3(555, 0, 0), float3(0, 555, 0), float3(0, 0, 555), green);
    let rightWall = Quad(float3(0, 0, 0), float3(0, 0, 555), float3(0, 555, 0), red);
    let floor = Quad(float3(0, 0, 0), float3(555, 0, 0), float3(0, 0, 555), white);
    let ceiling = Quad(float3(0, 555, 0), float3(0, 0, 555), float3(555, 0, 0), white);
    let backWall = Quad(float3(0, 0, 555), float3(555, 0, 0), float3(0, 555, 0), white);

    let tallBox = Box(float3(0, 0, 0), float3(165, 330, 165), white);
    let box = Box(float3(0, 0, 0), float3(165, 165, 165), white);

    let light = Quad(float3(343, 554, 332), float3(-130, 0, 0), float3(0, 0, -105), lightMat);

    let world = World<8>( { leftWall, rightWall, floor, ceiling, backWall, light, tallBox, box });
    return world;
}

[shader("fragment")]
float4 frag(VOut i) : SV_Target {
    float4 hitColor = float4(0, 0, 0, 1);

    float2 adjNdc = i.ndc;
    adjNdc.x *= i.aspect;

    let h = tan(params.vFov / 2.0);
    adjNdc *= h * params.focalLength;

    Ray ray;
    ray.origin = float3(278, 278, -300);
    ray.dir = float3(adjNdc, 1.0);

    Interval tInterval = Interval(0.001, 1.#INF);

    let world = cornellScene();
   
    var finalColor = float4(0.0);
    int halfRays = params.raysPerPixel / 2;
    for (int x = -halfRays; x <= halfRays; x++) {
        for (int y = -halfRays; y <= halfRays; y++) {
            float2 offset = float2(x, y) * (i.pixelDelta / 5.0);
            Ray jitteredRay = ray;
            jitteredRay.dir += float3(offset, 0);
            finalColor += world.color(jitteredRay, tInterval, adjNdc + offset);
        }
    }
    int r1 = (params.raysPerPixel + 1);
    finalColor /= float(r1 * r1);

    // linear to sRGB
    return float4(finalColor.rgb, finalColor.a);
}